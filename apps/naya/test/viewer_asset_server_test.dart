import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya/shared/platform/viewer_asset_server.dart';

/// Bellekteki birkaç dosyadan oluşan asset paketi.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw StateError('asset yok: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

Future<(int, String?, String)> _get(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    final body = await response.transform(utf8.decoder).join();
    return (response.statusCode, response.headers.contentType?.mimeType, body);
  } finally {
    client.close();
  }
}

void main() {
  // Bu testler gerçek bir yerel sunucuya bağlanır; testWidgets'ın HTTP'yi
  // kapatan ortamı yerine düz test kullanılıyor.
  late ViewerAssetServer server;

  setUp(() async {
    server = await ViewerAssetServer.start(
      _FakeBundle({
        'assets/viewer/index.html': '<!doctype html>viewer',
        'assets/viewer/assets/index.js': 'console.log(1)',
      }),
    );
  });

  tearDown(() => server.close());

  test('yalnız cihaz içi adreste açılır', () {
    expect(server.baseUrl, startsWith('http://127.0.0.1:'));
  });

  test('kök adres index.html verir', () async {
    final (status, type, body) = await _get(server.baseUrl);
    expect(status, 200);
    expect(type, 'text/html');
    expect(body, contains('viewer'));
  });

  test('sorgulu adres de index.html verir', () async {
    final (status, _, _) = await _get('${server.baseUrl}?embed&model=x.glb');
    expect(status, 200);
  });

  test('JavaScript doğru türle gider', () async {
    final (status, type, _) = await _get('${server.baseUrl}assets/index.js');
    expect(status, 200);
    expect(type, 'text/javascript');
  });

  test('olmayan dosya ve viewer dışı yol 404', () async {
    expect((await _get('${server.baseUrl}yok.js')).$1, 404);
    expect((await _get('${server.baseUrl}../pubspec.yaml')).$1, 404);
  });
}
