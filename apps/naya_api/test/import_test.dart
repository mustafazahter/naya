import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:naya_format/naya_format.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late TestServer server;
  late Uint8List bikeZip;

  setUpAll(() {
    final archive = Archive();
    final dir = Directory('../../templates/src/bisiklet/csdb');
    for (final f in dir.listSync().whereType<File>()) {
      archive.add(
        ArchiveFile.bytes(
          'bisiklet/${f.uri.pathSegments.last}',
          f.readAsBytesSync(),
        ),
      );
    }
    bikeZip = ZipEncoder().encodeBytes(archive);
  });

  setUp(() async => server = await TestServer.start());
  tearDown(() => server.close());

  Future<Response> importZip(List<int> bytes, String? token) =>
      server.send('POST', '/api/library/import', bytes: bytes, token: token);

  test('misafir içe aktaramaz', () async {
    final response = await importZip(bikeZip, null);
    expect(response.statusCode, 401);
  });

  test('S1000D zip\'i kullanıcının dosyası olarak eklenir', () async {
    final enes = await server.register('enes@ornek.com');
    final response = await importZip(bikeZip, enes);
    expect(response.statusCode, 201);
    final body = await readJson(response);

    final report = body['report']! as Map<String, Object?>;
    expect(report['dataModules'], 97);
    expect(report['unreadable'], isEmpty);
    expect(report['systems'], isNotEmpty);

    final item = body['item']! as Map<String, Object?>;
    expect(item['isTemplate'], false);
    expect(item['hasModel'], true);
    expect(item['moduleCount'], 97);
    expect(item['partCount'], report['parts']);

    final listing = await readJson(
      await server.send('GET', '/api/library/', token: enes),
    );
    expect(listing['userFiles'], [containsPair('id', item['id'])]);

    // Uygulamanın açarken istediği dosyalar.
    for (final path in [
      'map/parts.json',
      'map/faults.json',
      'model/product.glb',
    ]) {
      final entry = await server.send(
        'GET',
        '/api/library/${item['id']}/entries/$path',
        token: enes,
      );
      expect(entry.statusCode, 200, reason: path);
    }

    // Başkası göremez.
    final mustafa = await server.register('mustafa@ornek.com');
    final other = await server.send(
      'GET',
      '/api/library/${item['id']}',
      token: mustafa,
    );
    expect(other.statusCode, 404);
  });

  test('dışa aktarılan .naya tekrar yüklenince aynı içerik', () async {
    final enes = await server.register('enes@ornek.com');
    final imported = await readJson(await importZip(bikeZip, enes));
    final id = (imported['item']! as Map<String, Object?>)['id'];

    final download = await server.send(
      'GET',
      '/api/library/$id/file',
      token: enes,
    );
    expect(download.statusCode, 200);
    final bytes = await download.read().fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    final file = NayaFile.decode(bytes)..validate();
    expect(file.manifest.kind, NayaKind.imported);

    final reupload = await server.send(
      'POST',
      '/api/library/',
      bytes: bytes,
      token: enes,
    );
    expect(reupload.statusCode, 201);
    final again = await readJson(reupload);
    expect(again['id'], isNot(id));
    expect(
      again['partCount'],
      (imported['item']! as Map<String, Object?>)['partCount'],
    );
    expect(again['moduleCount'], 97);
  });

  test('zip olmayan dosya anlaşılır hatayla reddedilir', () async {
    final enes = await server.register('enes@ornek.com');
    final response = await importZip(utf8.encode('zip değil'), enes);
    expect(response.statusCode, 422);
    final body = await readJson(response);
    expect(body['error'], containsPair('code', 'invalid_zip'));
  });

  test('içinde DM olmayan zip reddedilir', () async {
    final enes = await server.register('enes@ornek.com');
    final archive = Archive()
      ..add(ArchiveFile.bytes('BENIOKU.txt', utf8.encode('merhaba')));
    final response = await importZip(ZipEncoder().encodeBytes(archive), enes);
    expect(response.statusCode, 422);
    expect(
      (await readJson(response))['error'],
      containsPair('code', 'no_modules'),
    );
  });
}
