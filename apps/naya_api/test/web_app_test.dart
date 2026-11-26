import 'dart:io';

import 'package:test/test.dart';

import 'support.dart';

void main() {
  late TestServer server;
  late Directory web;

  setUp(() async {
    web = await Directory.systemTemp.createTemp('naya_web_test');
    File('${web.path}/index.html').writeAsStringSync('<html>naya</html>');
    File('${web.path}/main.dart.js').writeAsStringSync('// uygulama');
    Directory('${web.path}/assets').createSync();
    File('${web.path}/assets/logo.svg').writeAsStringSync('<svg/>');
    server = await TestServer.start(env: {'WEB_DIR': web.path});
  });
  tearDown(() async {
    await server.close();
    await web.delete(recursive: true);
  });

  Future<String> body(String path) async =>
      (await server.send('GET', path)).readAsString();

  test('kök adres uygulamayı açar', () async {
    final response = await server.send('GET', '/');
    expect(response.statusCode, 200);
    expect(await response.readAsString(), '<html>naya</html>');
  });

  test('Flutter adresleri yenilenince de index.html gelir', () async {
    for (final path in [
      '/urun/bisiklet',
      '/urun/bisiklet/gecmis',
      '/ayarlar',
      // Parça adında nokta olabilir (Blender düğümü).
      '/urun/x/parca/Wheel.001',
    ]) {
      final response = await server.send('GET', path);
      expect(response.statusCode, 200, reason: path);
      expect(response.headers['content-type'], startsWith('text/html'));
      expect(await response.readAsString(), '<html>naya</html>');
    }
  });

  test('dosyalar sunulur; hiçbiri önbellekte eskimez', () async {
    final script = await server.send('GET', '/main.dart.js');
    expect(script.statusCode, 200);
    expect(script.headers['cache-control'], 'no-cache');
    // Viewer'ın index.html'i ve manifest'ler de assets/ altında; adları
    // değişmeden yenilenir.
    final logo = await server.send('GET', '/assets/logo.svg');
    expect(logo.headers['cache-control'], 'no-cache');
    expect(await logo.readAsString(), '<svg/>');
  });

  test('olmayan dosya 404 kalır, HTML dönmez', () async {
    final response = await server.send('GET', '/assets/yok.js');
    expect(response.statusCode, 404);
  });

  test('API ve sağlık ucu etkilenmez', () async {
    expect(await body('/health'), contains('ok'));
    final missing = await server.send('GET', '/api/yok');
    expect(missing.statusCode, 404);
    expect(await missing.readAsString(), contains('"error"'));
    final library = await server.send('GET', '/api/library');
    expect(library.statusCode, 200);
  });
}
