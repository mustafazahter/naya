import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

/// Flutter web derlemesini API ile aynı adresten sunar (Komuta'da tek
/// servis). `/api` ve `/health` API'ye gider; geri kalan her GET önce
/// [webDir] içindeki dosyalara bakar, bulunamazsa `index.html` döner.
/// Böylece `/urun/bisiklet/gecmis` gibi adresler sayfa yenilenince de
/// açılır; yönlendirmeyi Flutter yapar.
Handler withWebApp(Handler api, String webDir) {
  final files = createStaticHandler(webDir, defaultDocument: 'index.html');
  final index = File(p.join(webDir, 'index.html'));
  return (request) async {
    final path = request.url.path;
    final isApi = path == 'health' || path == 'api' || path.startsWith('api/');
    final isRead = request.method == 'GET' || request.method == 'HEAD';
    if (isApi || !isRead) return api(request);

    final response = await files(request);
    if (response.statusCode != 404) return _withCaching(response);
    // Eksik bir dosya (betik, çizim, model) 404 kalsın; yoksa HTML olarak
    // gelir ve hata anlaşılmaz olur. Yalnız bilinen uzantılar: parça adında
    // nokta olabilir (`/urun/x/parca/Wheel.001`), o adres sayfadır.
    if (_fileExtensions.contains(p.url.extension(path).toLowerCase())) {
      return response;
    }
    return Response.ok(
      request.method == 'HEAD' ? null : index.openRead(),
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-cache',
      },
    );
  };
}

const _fileExtensions = {
  '.js',
  '.mjs',
  '.css',
  '.map',
  '.json',
  '.wasm',
  '.html',
  '.txt',
  '.xml',
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.gif',
  '.svg',
  '.ico',
  '.glb',
  '.gltf',
  '.bin',
  '.ttf',
  '.otf',
  '.woff',
  '.woff2',
  '.naya',
};

/// Yeni sürüm yayınlanınca tarayıcı eski uygulamada kalmasın: her dosya
/// her açılışta yeniden doğrulanır (değişmediyse sunucu 304 döner, dosya
/// yeniden inmez). Uzun önbellek tehlikeli: `assets/` altındaki
/// `AssetManifest`, `FontManifest` ve viewer'ın `index.html`'i adı
/// değişmeden yenilenir; eskisi bir gün kalırsa yeni sürümün dosyalarını
/// bulamaz.
Response _withCaching(Response response) =>
    response.change(headers: {'cache-control': 'no-cache'});
