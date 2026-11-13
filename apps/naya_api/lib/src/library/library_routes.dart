import 'dart:convert';
import 'dart:typed_data';

import 'package:naya_format/naya_format.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/auth_middleware.dart';
import '../database/database.dart';
import '../http/json_response.dart';
import 'library_service.dart';

/// `/api/library` uçları.
///
/// - `GET  /`                     kütüphane (misafire yalnız şablonlar)
/// - `GET  /<id>`                 tek öğenin bilgisi
/// - `GET  /<id>/file`            `.naya` dosyasının kendisi
/// - `GET  /<id>/entries/<yol>`   dosyanın içinden tek bir kayıt
/// - `POST /`                     `.naya` yükleme (gövde ham dosya)
/// - `DELETE /<id>`               silme
class LibraryRoutes {
  LibraryRoutes(this._library);

  final LibraryService _library;

  Router get router => Router()
    ..get('/', _list)
    ..post('/', _upload)
    ..get('/<id>', _item)
    ..delete('/<id>', _delete)
    ..get('/<id>/file', _download)
    ..get('/<id>/entries/<path|.*>', _entry);

  Future<Response> _list(Request request) async {
    final listing = await _library.list(userOf(request));
    return jsonOk({
      'templates': [for (final item in listing.templates) itemJson(item)],
      'userFiles': [for (final item in listing.userFiles) itemJson(item)],
    });
  }

  Future<Response> _item(Request request, String id) async {
    final item = await _library.find(id, userOf(request));
    if (item == null) return _missing();
    return jsonOk(itemJson(item));
  }

  Future<Response> _download(Request request, String id) async {
    final item = await _library.find(id, userOf(request));
    if (item == null) return _missing();
    if (_notModified(request, item)) return _notModifiedResponse(item);
    final file = _library.fileOf(item);
    return Response.ok(
      file.openRead(),
      headers: {
        'content-type': nayaMimeType,
        'content-length': '${item.sizeBytes}',
        'content-disposition': _attachment(item),
        ..._cacheHeaders(item),
        ..._sandboxHeaders,
      },
    );
  }

  Future<Response> _entry(Request request, String id, String path) async {
    final item = await _library.find(id, userOf(request));
    if (item == null) return _missing();
    if (_notModified(request, item)) return _notModifiedResponse(item);
    final entryPath = Uri.decodeComponent(path);
    final bytes = await _library.readEntry(item, entryPath);
    if (bytes == null) return notFound('Dosyada "$entryPath" yok.');
    return Response.ok(
      bytes,
      headers: {
        'content-type': _contentTypeOf(entryPath),
        'content-length': '${bytes.length}',
        ..._cacheHeaders(item),
        ..._sandboxHeaders,
      },
    );
  }

  Future<Response> _upload(Request request) async {
    final user = userOf(request);
    if (user == null) return unauthorized();

    final declared = request.contentLength;
    if (declared != null && declared > LibraryService.maxFileBytes) {
      return _tooLarge();
    }
    final bytes = await _readBody(request);
    if (bytes == null) return _tooLarge();
    if (bytes.isEmpty) {
      return jsonError(400, 'bad_request', 'Gövdede bir .naya dosyası yok.');
    }

    try {
      final item = await _library.addUserFile(user, bytes);
      return jsonOk(itemJson(item), status: 201);
    } on LibraryException catch (e) {
      return jsonOk(
        {
          'error': {
            'code': e.code,
            'message': e.message,
            if (e.problems.isNotEmpty) 'problems': e.problems,
          },
        },
        status: e.code == 'too_large' || e.code == 'quota_exceeded' ? 413 : 422,
      );
    }
  }

  Future<Response> _delete(Request request, String id) async {
    final user = userOf(request);
    if (user == null) return unauthorized();
    final item = await _library.find(id, user);
    if (item == null) return _missing();
    if (!LibraryService.canDelete(item, user)) return forbidden();
    await _library.delete(item);
    return Response(204);
  }

  /// Uygulamanın kütüphane kartlarında kullandığı alanlar.
  static Map<String, Object?> itemJson(LibraryItemRow item) {
    final manifest = jsonDecode(item.manifestJson) as Map<String, Object?>;
    return {
      'id': item.id,
      // Manifestteki kimlik; şablon güncellenince de aynı kalır.
      'key': manifest['id'],
      'title': item.title,
      'subtitle': item.subtitle,
      'category': item.category,
      'isTemplate': item.templateKey != null,
      'partCount': item.partCount,
      'faultCount': item.faultCount,
      'moduleCount': item.moduleCount,
      'hasModel': item.hasModel,
      'model': manifest['model'],
      'credits': manifest['credits'] ?? const <Object>[],
      'sizeBytes': item.sizeBytes,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Gövdeyi en fazla 50 MB okur; aşarsa `null`. `Content-Length` hiç
  /// gönderilmese de sınır böylece korunur.
  static Future<Uint8List?> _readBody(Request request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
      if (builder.length > LibraryService.maxFileBytes) return null;
    }
    return builder.takeBytes();
  }

  // Dosyanın özeti değişmedikçe içeriği de değişmez; ETag olarak yeterli.
  static Map<String, String> _cacheHeaders(LibraryItemRow item) => {
    'etag': '"${item.sha256}"',
    'cache-control': item.templateKey != null
        ? 'public, max-age=300'
        : 'private, max-age=300',
  };

  /// Kayıtlar kullanıcının yüklediği dosyadan geliyor. İçinde betikli bir
  /// SVG ya da XML olabilir; adres doğrudan açılsa bile tarayıcı onu
  /// uygulamanın adresinde çalıştırmasın diye sayfa kum havuzuna alınır ve
  /// tür tahmini kapatılır. `<img>` ve `fetch` ile okumayı etkilemez.
  static const _sandboxHeaders = {
    'x-content-type-options': 'nosniff',
    'content-security-policy': "default-src 'none'; sandbox",
  };

  static bool _notModified(Request request, LibraryItemRow item) =>
      request.headers['if-none-match'] == '"${item.sha256}"';

  static Response _notModifiedResponse(LibraryItemRow item) =>
      Response.notModified(headers: _cacheHeaders(item));

  static String _attachment(LibraryItemRow item) {
    final ascii = item.title.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '_');
    final utf = Uri.encodeComponent('${item.title}.naya');
    return 'attachment; filename="$ascii.naya"; filename*=UTF-8\'\'$utf';
  }

  static String _contentTypeOf(String path) =>
      switch (p.extension(path).toLowerCase()) {
        '.json' => 'application/json; charset=utf-8',
        '.xml' => 'application/xml; charset=utf-8',
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.png' => 'image/png',
        '.webp' => 'image/webp',
        '.svg' => 'image/svg+xml',
        '.glb' => 'model/gltf-binary',
        '.gltf' => 'model/gltf+json',
        '.txt' || '.md' => 'text/plain; charset=utf-8',
        _ => 'application/octet-stream',
      };

  static Response _missing() => notFound('Kütüphanede böyle bir dosya yok.');

  static Response _tooLarge() =>
      jsonError(413, 'too_large', 'Dosya 50 MB’tan büyük olamaz.');
}
