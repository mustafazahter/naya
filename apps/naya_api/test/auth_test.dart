import 'package:naya_api/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late TestServer server;

  setUp(() async => server = await TestServer.start());
  tearDown(() => server.close());

  group('kayıt', () {
    test('hesap açar ve oturumu hemen başlatır', () async {
      final response = await server.send(
        'POST',
        '/api/auth/register',
        json: {'email': ' Enes@Ornek.com ', 'password': 'gizli-sifre'},
      );
      expect(response.statusCode, 201);
      final body = await readJson(response);
      expect(body['user'], {
        'id': 1,
        'email': 'enes@ornek.com',
        'role': 'user',
      });
      // Web istemcisi token'ı görmez, yalnız çerez alır.
      expect(body.containsKey('token'), isFalse);
      final cookie = response.headers['set-cookie']!;
      expect(cookie, startsWith('naya_session='));
      expect(cookie, contains('HttpOnly'));
      expect(cookie, contains('SameSite=Strict'));
      expect(cookie, isNot(contains('Secure')));

      final token = cookie.split(';').first.split('=').last;
      final me = await server.send(
        'GET',
        '/api/auth/me',
        headers: {'cookie': 'diger=1; naya_session=$token'},
      );
      expect(me.statusCode, 200);
    });

    test('uygulamaya token gövdede döner', () async {
      final token = await server.register('enes@ornek.com');
      final me = await server.send('GET', '/api/auth/me', token: token);
      expect((await readJson(me))['user'], containsPair('role', 'user'));
    });

    test('aynı e-posta ikinci kez açılamaz', () async {
      await server.register('enes@ornek.com');
      final response = await server.send(
        'POST',
        '/api/auth/register',
        json: {'email': 'ENES@ornek.com', 'password': 'baska-sifre'},
      );
      expect(response.statusCode, 409);
      expect(await readJson(response), {
        'error': {
          'code': 'email_taken',
          'message': 'Bu e-posta ile açılmış bir hesap var.',
        },
      });
    });

    test('kısa şifre ve bozuk e-posta reddedilir', () async {
      final short = await server.send(
        'POST',
        '/api/auth/register',
        json: {'email': 'enes@ornek.com', 'password': '1234567'},
      );
      expect(short.statusCode, 400);
      expect(
        await readJson(short),
        containsPair('error', containsPair('code', 'weak_password')),
      );

      final email = await server.send(
        'POST',
        '/api/auth/register',
        json: {'email': 'enes', 'password': 'gizli-sifre'},
      );
      expect(email.statusCode, 400);
    });

    test('eksik ya da bozuk gövde 400 verir', () async {
      final missing = await server.send(
        'POST',
        '/api/auth/register',
        json: {'email': 'enes@ornek.com'},
      );
      expect(missing.statusCode, 400);
      final broken = await server.send(
        'POST',
        '/api/auth/login',
        bytes: '{bozuk'.codeUnits,
      );
      expect(broken.statusCode, 400);
    });
  });

  group('giriş', () {
    setUp(() => server.register('enes@ornek.com'));

    test('doğru şifreyle yeni oturum açılır', () async {
      final token = await server.login('ENES@ornek.com');
      final me = await server.send('GET', '/api/auth/me', token: token);
      expect(me.statusCode, 200);
    });

    test('yanlış şifre ve bilinmeyen e-posta aynı cevabı alır', () async {
      final wrong = await server.send(
        'POST',
        '/api/auth/login',
        json: {'email': 'enes@ornek.com', 'password': 'yanlis-sifre'},
      );
      final unknown = await server.send(
        'POST',
        '/api/auth/login',
        json: {'email': 'yok@ornek.com', 'password': 'yanlis-sifre'},
      );
      expect(wrong.statusCode, 401);
      expect(unknown.statusCode, 401);
      expect(await wrong.readAsString(), await unknown.readAsString());
    });

    test('5 hatalı denemede hesap 15 dakika kilitlenir', () async {
      for (var i = 0; i < 4; i++) {
        final response = await _login(server, 'yanlis-sifre');
        expect(response.statusCode, 401);
      }
      final fifth = await _login(server, 'yanlis-sifre');
      expect(fifth.statusCode, 429);
      expect(fifth.headers['retry-after'], '900');

      // Kilitliyken doğru şifre de kabul edilmez.
      server.clock.advance(const Duration(minutes: 14));
      final locked = await _login(server, 'gizli-sifre');
      expect(locked.statusCode, 429);
      expect(
        (await readJson(locked))['error'],
        containsPair('message', contains('1 dakika')),
      );

      server.clock.advance(const Duration(minutes: 1));
      expect((await _login(server, 'gizli-sifre')).statusCode, 200);
    });

    test('başarılı giriş hatalı deneme sayacını sıfırlar', () async {
      for (var i = 0; i < 4; i++) {
        await _login(server, 'yanlis-sifre');
      }
      expect((await _login(server, 'gizli-sifre')).statusCode, 200);
      for (var i = 0; i < 4; i++) {
        expect((await _login(server, 'yanlis-sifre')).statusCode, 401);
      }
    });
  });

  group('oturum', () {
    test('çıkıştan sonra token geçersiz, çerez silinir', () async {
      final token = await server.register('enes@ornek.com');
      final logout = await server.send(
        'POST',
        '/api/auth/logout',
        token: token,
      );
      expect(logout.statusCode, 204);
      expect(logout.headers['set-cookie'], contains('Max-Age=0'));

      final me = await server.send('GET', '/api/auth/me', token: token);
      expect(me.statusCode, 401);
    });

    test('30 gün kullanılmayan oturum düşer', () async {
      final token = await server.register('enes@ornek.com');
      server.clock.advance(const Duration(days: 30));
      final me = await server.send('GET', '/api/auth/me', token: token);
      expect(me.statusCode, 401);
    });

    test('kullanıldıkça oturum uzar', () async {
      final token = await server.register('enes@ornek.com');
      for (var i = 0; i < 3; i++) {
        server.clock.advance(const Duration(days: 20));
        final me = await server.send('GET', '/api/auth/me', token: token);
        expect(me.statusCode, 200, reason: '${(i + 1) * 20}. gün');
      }
    });

    test('geçersiz token misafir sayılır', () async {
      final me = await server.send('GET', '/api/auth/me', token: 'uydurma');
      expect(me.statusCode, 401);
      final library = await server.send(
        'GET',
        '/api/library/',
        token: 'uydurma',
      );
      expect(library.statusCode, 200);
    });

    test('veritabanında token değil özeti durur', () async {
      final token = await server.register('enes@ornek.com');
      final rows = await server.api.db.select(server.api.db.sessions).get();
      expect(rows.single.tokenHash, isNot(token));
      expect(rows.single.tokenHash, hasLength(64));
    });
  });

  group('admin', () {
    test('açılışta admin hesabı açılır, ikinci açılışta dokunulmaz', () async {
      await server.api.auth.ensureAdmin('admin@naya.app', 'admin-sifre');
      await server.api.auth.ensureAdmin('admin@naya.app', 'baska-sifre');
      final token = await server.login('admin@naya.app', 'admin-sifre');
      final me = await server.send('GET', '/api/auth/me', token: token);
      expect((await readJson(me))['user'], containsPair('role', 'admin'));
    });

    test('var olan hesap admin yapılır', () async {
      await server.register('mustafa@ornek.com');
      await server.api.auth.ensureAdmin('mustafa@ornek.com', 'kullanilmaz');
      final token = await server.login('mustafa@ornek.com');
      final me = await server.send('GET', '/api/auth/me', token: token);
      expect((await readJson(me))['user'], containsPair('role', 'admin'));
    });
  });

  group('PasswordHasher', () {
    const hasher = PasswordHasher.fast();

    test('PHC biçiminde özet üretir ve doğrular', () async {
      final hash = await hasher.hash('gizli-sifre');
      expect(hash, startsWith(r'$argon2id$v=19$m=64,t=1,p=1$'));
      expect(await hasher.verify('gizli-sifre', hash), isTrue);
      expect(await hasher.verify('Gizli-sifre', hash), isFalse);
    });

    test('aynı şifre her seferinde farklı tuzla özetlenir', () async {
      expect(
        await hasher.hash('a1234567'),
        isNot(await hasher.hash('a1234567')),
      );
    });

    test('farklı ayarla üretilmiş özet de doğrulanır', () async {
      final hash = await const PasswordHasher(
        memoryKib: 128,
        iterations: 2,
      ).hash('gizli-sifre');
      expect(await hasher.verify('gizli-sifre', hash), isTrue);
    });

    test('bozuk özet false döner', () async {
      for (final broken in [
        '',
        r'$argon2i$v=19$m=64,t=1,p=1$a$b',
        r'$argon2id$v=19$m=0,t=1,p=1$YQ$YQ',
        r'$argon2id$v=19$m=64,t=1,p=1$!!$!!',
      ]) {
        expect(await hasher.verify('x', broken), isFalse, reason: broken);
      }
    });
  });
}

Future<Response> _login(TestServer server, String password) => server.send(
  'POST',
  '/api/auth/login',
  json: {'email': 'enes@ornek.com', 'password': password},
);
