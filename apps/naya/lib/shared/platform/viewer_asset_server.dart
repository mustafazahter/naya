import 'dart:io';

import 'package:flutter/services.dart';

/// Gömülü viewer'ı (`assets/viewer`) Android WebView'e sunan küçük bir
/// HTTP sunucusu.
///
/// Neden: viewer ES modülü olarak derleniyor ve modeli `fetch` ile
/// indiriyor; `file://` adreslerinde ikisi de engelleniyor. Sunucu yalnız
/// cihazın kendi içinden (127.0.0.1) erişilebilir ve yalnız uygulamanın
/// asset'lerini okur; diskteki başka bir dosyaya ulaşamaz.
class ViewerAssetServer {
  ViewerAssetServer._(this._server);

  final HttpServer _server;

  static Future<ViewerAssetServer>? _shared;

  /// Uygulama boyunca tek sunucu; ilk çağrıda boş bir portta açılır.
  static Future<ViewerAssetServer> shared({AssetBundle? bundle}) {
    return _shared ??= start(bundle ?? rootBundle);
  }

  static Future<ViewerAssetServer> start(AssetBundle bundle) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) => _handle(bundle, request));
    return ViewerAssetServer._(server);
  }

  /// Viewer'ın kök adresi, sonunda `/` ile.
  String get baseUrl => 'http://127.0.0.1:${_server.port}/';

  Future<void> close() => _server.close(force: true);

  static Future<void> _handle(AssetBundle bundle, HttpRequest request) async {
    final response = request.response;
    var path = request.uri.path;
    if (path == '/' || path.isEmpty) path = '/index.html';
    try {
      final data = await bundle.load('assets/viewer$path');
      response.headers.contentType = _contentType(path);
      response.add(Uint8List.sublistView(data));
    } on Object {
      // Asset yoksa rootBundle hata fırlatır.
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }

  static ContentType _contentType(String path) {
    final ext = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
    return switch (ext) {
      'html' => ContentType.html,
      'js' => ContentType('text', 'javascript', charset: 'utf-8'),
      'css' => ContentType('text', 'css', charset: 'utf-8'),
      'json' => ContentType.json,
      'wasm' => ContentType('application', 'wasm'),
      'glb' => ContentType('model', 'gltf-binary'),
      'png' => ContentType('image', 'png'),
      'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
      'svg' => ContentType('image', 'svg+xml'),
      _ => ContentType.binary,
    };
  }
}
