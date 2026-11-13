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

  /// JSON gövdeli POST; cevap JSON nesnesi.
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final http.Response response;
    try {
      response = await _http.post(
        uri(path),
        headers: {..._headers, 'content-type': 'application/json'},
        body: jsonEncode(body),
      );
    } on http.ClientException {
      throw const ApiException(0, 'offline', 'Sunucuya ulaşılamadı.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFrom(response);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, Object?>) {
      throw const ApiException(
        200,
        'bad_response',
        'Sunucudan beklenmedik cevap.',
      );
    }
    return decoded;
  }

  Future<Map<String, Object?>> getJson(String path) async {
    final body = jsonDecode(utf8.decode(await getBytes(path)));
    if (body is! Map<String, Object?>) {
      throw const ApiException(
        200,
        'bad_response',
        'Sunucudan beklenmedik cevap.',
      );
    }
    return body;
  }

  Future<String> getText(String path) async =>
      utf8.decode(await getBytes(path));

  Future<Uint8List> getBytes(String path) async {
    final http.Response response;
    try {
      response = await _http.get(uri(path), headers: _headers);
    } on http.ClientException {
      throw const ApiException(0, 'offline', 'Sunucuya ulaşılamadı.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw _errorFrom(response);
  }

  void close() => _http.close();

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
  final client = ApiClient(baseUrl: apiUrl);
  ref.onDispose(client.close);
  return client;
});
