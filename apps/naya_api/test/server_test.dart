import 'package:naya_api/server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late TestServer server;

  setUp(() async => server = await TestServer.start());
  tearDown(() => server.close());

  test('/health ayakta olduğunu söyler', () async {
    final response = await server.send('GET', '/health');
    expect(response.statusCode, 200);
    expect(await readJson(response), {'status': 'ok'});
  });

  test('kütüphane adresi sonda eğik çizgiyle de açılır', () async {
    for (final path in ['/api/library', '/api/library/']) {
      expect((await server.send('GET', path)).statusCode, 200, reason: path);
    }
  });

  test('bilinmeyen API ucu JSON hata döner', () async {
    final response = await server.send('GET', '/api/yok');
    expect(response.statusCode, 404);
    expect(
      await readJson(response),
      containsPair('error', isA<Map<String, Object?>>()),
    );
  });

  group('CORS', () {
    test('yereldeki web uygulaması çerezle istek atabilir', () async {
      final response = await server.send(
        'OPTIONS',
        '/api/auth/login',
        headers: {'origin': 'http://localhost:5050'},
      );
      expect(response.statusCode, 204);
      expect(
        response.headers['access-control-allow-origin'],
        'http://localhost:5050',
      );
      expect(response.headers['access-control-allow-credentials'], 'true');
    });

    test('başka siteler kabul edilmez', () async {
      final preflight = await server.send(
        'OPTIONS',
        '/api/auth/login',
        headers: {'origin': 'https://kotu.example'},
      );
      expect(preflight.statusCode, 403);
      final get = await server.send(
        'GET',
        '/api/library/',
        headers: {'origin': 'https://kotu.example'},
      );
      expect(get.headers.containsKey('access-control-allow-origin'), isFalse);
    });

    test('CORS_ORIGINS ile verilen adres kabul edilir', () async {
      final custom = await TestServer.start(
        env: {'CORS_ORIGINS': 'https://naya.example, https://ikinci.example'},
      );
      addTearDown(custom.close);
      final response = await custom.send(
        'OPTIONS',
        '/api/library/',
        headers: {'origin': 'https://ikinci.example'},
      );
      expect(response.statusCode, 204);
    });
  });

  test('HTTPS arkasında çerez Secure olur', () async {
    final secure = await TestServer.start(env: {'NAYA_SECURE_COOKIES': '1'});
    addTearDown(secure.close);
    final response = await secure.send(
      'POST',
      '/api/auth/register',
      json: {'email': 'enes@ornek.com', 'password': 'gizli-sifre'},
    );
    expect(response.headers['set-cookie'], endsWith('Secure'));
  });

  test('açılışta admin ve şablonlar hazırlanır', () async {
    final started = await TestServer.start(
      env: {
        'NAYA_ADMIN_EMAIL': 'admin@naya.app',
        'NAYA_ADMIN_PASSWORD': 'admin-sifre',
      },
    );
    addTearDown(started.close);
    await started.addTemplate(sampleNaya());
    await started.api.start();
    final token = await started.login('admin@naya.app', 'admin-sifre');
    final me = await started.send('GET', '/api/auth/me', token: token);
    expect((await readJson(me))['user'], containsPair('role', 'admin'));
    expect(await started.api.backups.backups(), hasLength(1));
  });

  test('ayarlar ortamdan okunur', () {
    final config = ApiConfig.fromEnvironment({
      'PORT': '9000',
      'DATABASE_PATH': '/veri/naya.db',
      'STORAGE_DIR': '/veri/dosyalar',
      'NAYA_ADMIN_EMAIL': ' ',
    });
    expect(config.port, 9000);
    expect(config.databasePath, '/veri/naya.db');
    expect(config.libraryDir, endsWith('library'));
    expect(config.adminEmail, isNull);
  });
}
