import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late TestServer server;

  setUp(() async {
    server = await TestServer.start();
    await server.addTemplate(sampleNaya(id: 'bisiklet', title: 'Bisiklet'));
  });
  tearDown(() => server.close());

  Future<Map<String, Object?>> listing([String? token]) async =>
      readJson(await server.send('GET', '/api/library/', token: token));

  Future<String> upload(String token, {String title = 'Jeneratör'}) async {
    final response = await server.send(
      'POST',
      '/api/library/',
      bytes: sampleNaya(id: 'jenerator', title: title),
      token: token,
    );
    expect(response.statusCode, 201);
    return (await readJson(response))['id']! as String;
  }

  group('liste', () {
    test('misafir yalnız şablonları görür', () async {
      final body = await listing();
      final templates = body['templates']! as List<Object?>;
      expect(templates, hasLength(1));
      expect(templates.single, containsPair('title', 'Bisiklet'));
      expect(templates.single, containsPair('isTemplate', true));
      expect(templates.single, containsPair('partCount', greaterThan(0)));
      expect(templates.single, containsPair('moduleCount', 1));
      expect(body['userFiles'], isEmpty);
    });

    test(
      'kullanıcı şablonlarla birlikte yalnız kendi dosyalarını görür',
      () async {
        final enes = await server.register('enes@ornek.com');
        final mustafa = await server.register('mustafa@ornek.com');
        await upload(enes);

        final mine = await listing(enes);
        expect(mine['templates'], hasLength(1));
        expect(mine['userFiles'], [containsPair('title', 'Jeneratör')]);

        final theirs = await listing(mustafa);
        expect(theirs['userFiles'], isEmpty);
      },
    );
  });

  group('yükleme', () {
    test('misafir yükleyemez', () async {
      final response = await server.send(
        'POST',
        '/api/library/',
        bytes: sampleNaya(),
      );
      expect(response.statusCode, 401);
    });

    test('yüklenen dosya aynı baytlarla indirilir', () async {
      final token = await server.register('enes@ornek.com');
      final bytes = sampleNaya(id: 'jenerator', title: 'Jeneratör 5 kVA');
      final created = await server.send(
        'POST',
        '/api/library/',
        bytes: bytes,
        token: token,
      );
      final id = (await readJson(created))['id'];

      final download = await server.send(
        'GET',
        '/api/library/$id/file',
        token: token,
      );
      expect(download.statusCode, 200);
      expect(download.headers['content-type'], nayaMimeType);
      expect(
        download.headers['content-disposition'],
        contains("filename*=UTF-8''Jenerat%C3%B6r%205%20kVA.naya"),
      );
      final downloaded = await download.read().expand((c) => c).toList();
      expect(downloaded, bytes);
    });

    test('.naya olmayan dosya sorunlarıyla reddedilir', () async {
      final token = await server.register('enes@ornek.com');
      final response = await server.send(
        'POST',
        '/api/library/',
        bytes: utf8.encode('bu bir zip değil'),
        token: token,
      );
      expect(response.statusCode, 422);
      final error =
          (await readJson(response))['error']! as Map<String, Object?>;
      expect(error['code'], 'invalid_file');
      expect(error['problems'], isNotEmpty);
    });

    test('bağlantıları bozuk dosya reddedilir', () async {
      final file = NayaFile.decode(sampleNaya());
      final parts = jsonDecode(
        utf8.decode(file.entries['map/parts.json']!),
      ) as Map<String, Object?>;
      // Arızalar artık var olmayan parçaları gösteriyor.
      parts['parts'] = <Object?>[];
      file.putJson('map/parts.json', parts);
      final token = await server.register('enes@ornek.com');
      final response = await server.send(
        'POST',
        '/api/library/',
        bytes: file.encode(),
        token: token,
      );
      expect(response.statusCode, 422);
    });

    test('50 MB üstü, uzunluk bildirilmese de okunurken kesilir', () async {
      final token = await server.register('enes@ornek.com');
      final chunk = List<int>.filled(1024 * 1024, 0);
      var sent = 0;
      // 1 MB'lık parçalarla 60 MB; sunucu 51. MB'ta okumayı bırakmalı.
      Stream<List<int>> body() async* {
        for (var i = 0; i < 60; i++) {
          sent++;
          yield chunk;
        }
      }

      final response = await server.send(
        'POST',
        '/api/library/',
        stream: body(),
        token: token,
      );
      expect(response.statusCode, 413);
      expect(sent, lessThan(60));
    });

    test('boş gövde 400 verir', () async {
      final token = await server.register('enes@ornek.com');
      final response = await server.send(
        'POST',
        '/api/library/',
        bytes: const [],
        token: token,
      );
      expect(response.statusCode, 400);
    });
  });

  group('erişim', () {
    test('başkasının dosyası yokmuş gibi görünür', () async {
      final enes = await server.register('enes@ornek.com');
      final mustafa = await server.register('mustafa@ornek.com');
      final id = await upload(enes);
      for (final path in ['/api/library/$id', '/api/library/$id/file']) {
        expect(
          (await server.send('GET', path, token: mustafa)).statusCode,
          404,
        );
        expect((await server.send('GET', path)).statusCode, 404);
      }
    });

    test('admin her dosyayı açabilir', () async {
      final enes = await server.register('enes@ornek.com');
      final id = await upload(enes);
      await server.api.auth.ensureAdmin('admin@naya.app', 'admin-sifre');
      final admin = await server.login('admin@naya.app', 'admin-sifre');
      final response = await server.send(
        'GET',
        '/api/library/$id',
        token: admin,
      );
      expect(response.statusCode, 200);
    });
  });

  group('içerik', () {
    late String templateId;

    setUp(() async {
      final templates = (await listing())['templates']! as List<Object?>;
      templateId = (templates.single! as Map<String, Object?>)['id']! as String;
    });

    test('misafir şablonun parça haritasını okur', () async {
      final response = await server.send(
        'GET',
        '/api/library/$templateId/entries/map/parts.json',
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], startsWith('application/json'));
      final parts = await readJson(response);
      expect(parts['parts'], isNotEmpty);
    });

    test('DM ve görseller doğru türle döner', () async {
      final dm = await server.send(
        'GET',
        '/api/library/$templateId/entries/csdb/DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A_001-00_TR-TR.XML',
      );
      expect(dm.headers['content-type'], startsWith('application/xml'));
      expect(await dm.readAsString(), contains('Zinciri sökün.'));

      final image = await server.send(
        'GET',
        '/api/library/$templateId/entries/media/zincir-1.webp',
      );
      expect(image.headers['content-type'], 'image/webp');
    });

    test('manifest de okunabilir', () async {
      final response = await server.send(
        'GET',
        '/api/library/$templateId/entries/naya.json',
      );
      expect(await readJson(response), containsPair('id', 'bisiklet'));
    });

    test('olmayan kayıt 404 verir', () async {
      final response = await server.send(
        'GET',
        '/api/library/$templateId/entries/map/yok.json',
      );
      expect(response.statusCode, 404);
    });

    test('ETag eşleşirse 304 döner', () async {
      final first = await server.send('GET', '/api/library/$templateId/file');
      final etag = first.headers['etag']!;
      final second = await server.send(
        'GET',
        '/api/library/$templateId/entries/map/parts.json',
        headers: {'if-none-match': etag},
      );
      expect(second.statusCode, 304);
    });
  });

  group('silme', () {
    test('sahibi kendi dosyasını siler, dosya diskten de gider', () async {
      final token = await server.register('enes@ornek.com');
      final id = await upload(token);
      final rows = await server.api.db.select(server.api.db.libraryItems).get();
      final file = server.api.library.fileOf(
        rows.firstWhere((row) => row.id == id),
      );
      expect(file.existsSync(), isTrue);

      final response = await server.send(
        'DELETE',
        '/api/library/$id',
        token: token,
      );
      expect(response.statusCode, 204);
      expect(file.existsSync(), isFalse);
      expect((await listing(token))['userFiles'], isEmpty);
    });

    test('kullanıcı şablon silemez, admin siler', () async {
      final templates = (await listing())['templates']! as List<Object?>;
      final id = (templates.single! as Map<String, Object?>)['id'];

      final user = await server.register('enes@ornek.com');
      final denied = await server.send(
        'DELETE',
        '/api/library/$id',
        token: user,
      );
      expect(denied.statusCode, 403);

      await server.api.auth.ensureAdmin('admin@naya.app', 'admin-sifre');
      final admin = await server.login('admin@naya.app', 'admin-sifre');
      final allowed = await server.send(
        'DELETE',
        '/api/library/$id',
        token: admin,
      );
      expect(allowed.statusCode, 204);
    });

    test('misafir silemez', () async {
      final templates = (await listing())['templates']! as List<Object?>;
      final id = (templates.single! as Map<String, Object?>)['id'];
      final response = await server.send('DELETE', '/api/library/$id');
      expect(response.statusCode, 401);
    });
  });

  group('şablonlar', () {
    test('aynı dosya ikinci açılışta tekrar eklenmez', () async {
      await server.api.importTemplates();
      expect((await listing())['templates'], hasLength(1));
    });

    test('yeni sürüm eskisinin yerine geçer, kimliği korunur', () async {
      final before =
          ((await listing())['templates']! as List<Object?>).single!
              as Map<String, Object?>;
      await server.addTemplate(
        sampleNaya(id: 'bisiklet', title: 'Dağ bisikleti'),
      );
      final after =
          ((await listing())['templates']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(after['id'], before['id']);
      expect(after['title'], 'Dağ bisikleti');

      // Önbellekteki eski içerik de bırakılır.
      final manifest = await server.send(
        'GET',
        '/api/library/${after['id']}/entries/naya.json',
      );
      expect(await readJson(manifest), containsPair('title', 'Dağ bisikleti'));
    });

    test('bozuk şablon diğerlerini engellemez', () async {
      await server.addTemplate(utf8.encode('bozuk'), name: 'bozuk');
      expect((await listing())['templates'], hasLength(1));
    });
  });
}
