import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'http_client.dart';

/// Sunucudan gelen ya da sunucuya ulaşılamadığında oluşan hata.
/// [message] doğrudan ekranda gösterilebilir.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  /// Sunucuya hiç ulaşılamadıysa 0.
  final int statusCode;
  final String code;
  final String message;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// `naya_api` ile konuşan ince katman. Uç adlarını bilmez; onları
/// kullanan sağlayıcılar (kütüphane, ürün içeriği) bilir.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _http = client ?? createHttpClient();

  final String baseUrl;
  final http.Client _http;

  /// Android'de girişten sonra sunucunun verdiği oturum token'ı. Web'de
  /// oturum çerezde durur, bu boş kalır.
  String? token;

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  /// Web'de ek başlık gönderilmez: oturum çerezde, token JavaScript'e hiç
  /// gelmemeli. Android'de sunucu girişte token'ı gövdede yalnız
  /// `x-naya-client: app` görürse verir.
  Map<String, String> get _headers => kIsWeb
      ? const {}
      : {
          'x-naya-client': 'app',
          if (token != null) 'authorization': 'Bearer $token',
        };

  /// `Image.network` gibi kendi isteğini atan yerler için oturum başlığı.
  /// Android'de kullanıcının kendi dosyasındaki çizimler onsuz 404 verir;
  /// web'de çerez kendiliğinden gider, boş döner.
  Map<String, String> get authHeaders =>
      kIsWeb || token == null ? const {} : {'authorization': 'Bearer $token'};

  /// Ham baytlı POST (`.naya` ya da zip yükleme); cevap JSON nesnesi.
  Future<Map<String, Object?>> postBytes(
    String path,
    List<int> bytes, {
    String contentType = 'application/octet-stream',
  }) async {
    final response = await _check(
      () => _http.post(
        uri(path),
        headers: {..._headers, 'content-type': contentType},
        body: bytes,
      ),
    );
    return _decodeObject(response.bodyBytes);
  }

  /// JSON gövdeli POST; cevap JSON nesnesi.
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) => _sendJson('POST', path, body);

  Future<Map<String, Object?>> putJson(
    String path,
    Map<String, Object?> body,
  ) => _sendJson('PUT', path, body);

  /// Gövdesiz DELETE; sunucu 204 döner.
  Future<void> delete(String path) async {
    await _check(() => _http.delete(uri(path), headers: _headers));
  }

  Future<Map<String, Object?>> getJson(String path) async =>
      _decodeObject(await getBytes(path));

  Future<String> getText(String path) async =>
      utf8.decode(await getBytes(path));

  Future<Uint8List> getBytes(String path) async =>
      (await _check(() => _http.get(uri(path), headers: _headers))).bodyBytes;

  /// Cevabı beklemeden akış olarak okunan JSON POST (sohbet, SSE).
  /// Akış başlamadan gelen hata (giriş yok, anahtar yok) [ApiException]
  /// olarak fırlar.
  Future<Stream<List<int>>> postStream(
    String path,
    Map<String, Object?> body,
  ) async {
    final request = http.Request('POST', uri(path))
      ..headers.addAll({
        ..._headers,
        'content-type': 'application/json',
        'accept': 'text/event-stream',
      })
      ..body = jsonEncode(body);
    final http.StreamedResponse response;
    try {
      response = await _http.send(request);
    } on http.ClientException {
      throw _offline;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFrom(await http.Response.fromStream(response));
    }
    return response.stream;
  }

  void close() => _http.close();

  Future<Map<String, Object?>> _sendJson(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    final request = http.Request(method, uri(path))
      ..headers.addAll({..._headers, 'content-type': 'application/json'})
      ..body = jsonEncode(body);
    final response = await _check(
      () async => http.Response.fromStream(await _http.send(request)),
    );
    return _decodeObject(response.bodyBytes);
  }

  /// İsteği gönderir; ağ hatasını ve 2xx dışı cevabı [ApiException]'a
  /// çevirir.
  Future<http.Response> _check(Future<http.Response> Function() send) async {
    final http.Response response;
    try {
      response = await send();
    } on http.ClientException {
      throw _offline;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFrom(response);
    }
    return response;
  }

  static const _offline = ApiException(0, 'offline', 'Sunucuya ulaşılamadı.');

  /// 204 gibi gövdesiz cevaplar boş nesne sayılır (çıkış).
  static Map<String, Object?> _decodeObject(List<int> bytes) {
    if (bytes.isEmpty) return const {};
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const ApiException(
        200,
        'bad_response',
        'Sunucudan beklenmedik cevap.',
      );
    }
    return decoded;
  }

  /// Sunucu hataları `{"error": {"code", "message"}}` biçiminde döner;
  /// başka bir şey gelirse (vekil sunucu sayfası gibi) genel bir mesaj.
  static ApiException _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is Map) {
        final error = body['error'] as Map;
        return ApiException(
          response.statusCode,
          error['code'] as String? ?? 'error',
          error['message'] as String? ?? 'Bir sorun oluştu.',
        );
      }
    } on FormatException {
      // Aşağıdaki genel mesaj.
    }
    return ApiException(
      response.statusCode,
      'error',
      'Sunucu hata verdi (${response.statusCode}).',
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(baseUrl: resolveApiUrl(apiUrl, Uri.base));
  ref.onDispose(client.close);
  return client;
});
