import 'dart:convert';

import 'package:shelf/shelf.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(
  Object? body, {
  int status = 200,
  Map<String, Object>? headers,
}) => Response(
  status,
  body: jsonEncode(body),
  headers: {..._jsonHeaders, ...?headers},
);

/// Bütün hatalar aynı biçimde döner:
/// `{"error": {"code": "...", "message": "..."}}`.
Response jsonError(
  int status,
  String code,
  String message, {
  Map<String, Object>? headers,
}) => Response(
  status,
  body: jsonEncode({
    'error': {'code': code, 'message': message},
  }),
  headers: {..._jsonHeaders, ...?headers},
);

Response unauthorized() =>
    jsonError(401, 'unauthorized', 'Bu işlem için giriş yapın.');

Response forbidden() =>
    jsonError(403, 'forbidden', 'Bu işlem için yetkiniz yok.');

Response notFound([String message = 'Bulunamadı.']) =>
    jsonError(404, 'not_found', message);

/// JSON uçlarına gelen gövde bundan büyük olamaz; giriş ve kayıt için
/// fazlasıyla yeterli. Sınır olmasa çok büyük bir gövde belleği doldurabilir.
const maxJsonBytes = 64 * 1024;

/// İstek gövdesini JSON nesnesi olarak okur. Gövde bozuksa, nesne değilse
/// ya da [maxJsonBytes]'tan büyükse `null` döner; çağıran 400 verir.
Future<Map<String, Object?>?> readJsonObject(Request request) async {
  final declared = request.contentLength;
  if (declared != null && declared > maxJsonBytes) return null;
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > maxJsonBytes) return null;
  }
  try {
    final body = jsonDecode(utf8.decode(bytes));
    return body is Map<String, Object?> ? body : null;
  } on FormatException {
    return null;
  }
}
