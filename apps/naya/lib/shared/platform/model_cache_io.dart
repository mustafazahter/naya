import 'dart:async';
import 'dart:io';

import '../api/api_client.dart';

/// Android: 3D modelleri uygulamanın önbellek klasöründe tutar ve gömülü
/// viewer'a cihazdaki yerel sunucudan ([ViewerAssetServer]) verir.
///
/// Neden: WebView'in kendi HTTP önbelleği küçük ve uygulama kapanınca
/// çoğu zaman boşalıyor; bisikletin 7,8 MB'lık modeli her açılışta yeniden
/// iniyordu. Modeller sürümlü anahtarla (`<ürün>-<sürüm>.glb`) saklanır;
/// dosya güncellenince sürüm değişir, eskisi silinir.
///
/// İndirme viewer'dan bağımsızdır: kütüphanedeyken arka planda başlar
/// ([prefetch]); kullanıcı o sırada ürünü açarsa viewer inen baytları
/// geldikçe okur, aynı dosya iki kez inmez. Viewer kapansa da indirme
/// sürer ve sonraki açılışa hazır olur.
class ModelCache {
  ModelCache._();

  static final instance = ModelCache._();

  /// Önbelleğin üst sınırı; aşılınca en eski kullanılan model silinir.
  static const maxBytes = 200 * 1024 * 1024;

  final _sources = <String, _Source>{};
  final _downloads = <String, _Download>{};
  Future<void> _queue = Future.value();

  /// Bu oturumda önceden indirilmesi istenenler; kütüphane her yeniden
  /// çizildiğinde aynı model kuyruğa tekrar girmesin.
  final _requested = <String>{};

  Directory get _dir => Directory('${Directory.systemTemp.path}/models');

  /// Viewer'ın modeli istediği yol (viewer sayfasına göre). Sürüm yoksa
  /// (eski sunucu) önbelleğe alınmaz, null döner; viewer sunucudan alır.
  String? localPath(
    ApiClient api,
    String productId,
    String path, {
    required String? version,
  }) {
    final key = _keyOf(productId, version);
    if (key == null) return null;
    _sources[key] = _Source(api, path);
    return './cached/$key';
  }

  /// Arka planda indirir; zaten varsa ya da iniyorsa bir şey yapmaz.
  /// İndirmeler sırayla: aynı anda dört model inip bağlantıyı boğmasın.
  void prefetch(
    ApiClient api,
    String productId,
    String path, {
    required String? version,
  }) {
    final key = _keyOf(productId, version);
    if (key == null || !_requested.add(key)) return;
    _sources[key] = _Source(api, path);
    _queue = _queue.then((_) async {
      if (_downloads.containsKey(key) || await _file(key).exists()) return;
      try {
        await _start(key).done.future;
      } on Object {
        _requested.remove(key);
        // Arka plan indirmesi sessizce düşer; açılınca yeniden denenir.
      }
    });
  }

  /// Yerel sunucudan gelen `/cached/<key>` isteğini cevaplar.
  Future<void> serve(String key, HttpResponse response) async {
    try {
      final file = _file(key);
      if (await file.exists()) {
        unawaited(file.setLastModified(DateTime.now()).catchError((_) {}));
        response.headers
          ..contentType = ContentType('model', 'gltf-binary')
          ..contentLength = await file.length();
        await response.addStream(file.openRead());
        return;
      }
      if (!_downloads.containsKey(key) && !_sources.containsKey(key)) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final download = _downloads[key] ?? _start(key);
      await download.headers.future;
      response.headers.contentType = ContentType('model', 'gltf-binary');
      if (download.total != null) {
        response.headers.contentLength = download.total!;
      }
      await response.addStream(download.read());
    } on Object {
      // Başlık gönderilmediyse hata kodu; gönderildiyse bağlantı kesilir,
      // viewer "Model yüklenemedi" gösterir.
      try {
        response.statusCode = HttpStatus.badGateway;
      } on StateError {
        // Başlıklar gitmiş.
      }
    } finally {
      await response.close().catchError((_) {});
    }
  }

  _Download _start(String key) {
    final source = _sources[key]!;
    final download = _Download(_part(key), _file(key));
    _downloads[key] = download;
    unawaited(_run(key, source, download));
    return download;
  }

  Future<void> _run(String key, _Source source, _Download download) async {
    final client = HttpClient();
    RandomAccessFile? out;
    try {
      await _dir.create(recursive: true);
      final request = await client.getUrl(source.api.uri(source.path));
      source.api.authHeaders.forEach(request.headers.set);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Model indirilemedi (${response.statusCode})');
      }
      download.total = response.contentLength >= 0
          ? response.contentLength
          : null;
      out = await download.part.open(mode: FileMode.write);
      download.headers.complete();
      await for (final chunk in response) {
        await out.writeFrom(chunk);
        download.received += chunk.length;
        download.tick();
      }
      await out.close();
      out = null;
      // Okuyucular kalanı okuyup dosyayı kapatsın; açık dosyanın adı her
      // sistemde değiştirilemiyor (Windows).
      await download.markWritten();
      await download.part.rename(_file(key).path);
      download.finish();
      unawaited(_cleanUp(key));
    } on Object catch (e) {
      await out?.close().catchError((_) {});
      if (await download.part.exists()) {
        await download.part.delete().catchError((_) => download.part);
      }
      download.fail(e);
    } finally {
      _downloads.remove(key);
      client.close();
    }
  }

  /// Aynı ürünün eski sürümlerini ve sınırı aşan eski modelleri siler.
  Future<void> _cleanUp(String keptKey) async {
    try {
      final product = keptKey.substring(0, keptKey.lastIndexOf('-'));
      final files = await _dir
          .list()
          .where((e) => e is File && e.path.endsWith('.glb'))
          .cast<File>()
          .toList();
      for (final f in files) {
        final name = f.uri.pathSegments.last;
        if (name != '$keptKey.glb' && name.startsWith('$product-')) {
          await f.delete();
        }
      }
      final rest = <(File, FileStat)>[
        for (final f in files)
          if (await f.exists()) (f, await f.stat()),
      ]..sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
      var total = rest.fold<int>(0, (sum, e) => sum + e.$2.size);
      for (final (file, stat) in rest) {
        if (total <= maxBytes) break;
        if (file.uri.pathSegments.last == '$keptKey.glb') continue;
        await file.delete();
        total -= stat.size;
      }
    } on Object {
      // Temizlik başarısızsa bir sonrakinde denenir.
    }
  }

  File _file(String key) => File('${_dir.path}/$key.glb');
  File _part(String key) => File('${_dir.path}/$key.part');

  /// Dosya adında yalnız güvenli karakterler.
  static String? _keyOf(String productId, String? version) {
    if (version == null) return null;
    String safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return '${safe(productId)}-${safe(version)}';
  }
}

class _Source {
  const _Source(this.api, this.path);

  final ApiClient api;
  final String path;
}

/// Süren bir indirme. Okuyucular diske yazılanı geldikçe okur.
class _Download {
  _Download(this.part, this.file) {
    // Arka plan indirmesini kimse beklemeyebilir; hatası işlenmemiş hata
    // olarak düşmesin. Okuyucular hatayı [error]'dan görür.
    headers.future.ignore();
    done.future.ignore();
  }

  final File part;

  /// Bitince [part]ın yeni adı.
  final File file;
  final headers = Completer<void>();
  final done = Completer<void>();
  int received = 0;
  int? total;
  Object? error;
  final _ticks = StreamController<void>.broadcast();

  /// Bütün baytlar diske yazıldı; okuyucular kalanı okuyup çıkar.
  var _written = false;
  var _readers = 0;
  Completer<void>? _idle;

  void tick() => _ticks.add(null);

  /// Yazma bitti; açık okuyucuların hepsi dosyayı kapatınca tamamlanır.
  Future<void> markWritten() {
    _written = true;
    _ticks.add(null);
    if (_readers == 0) return Future.value();
    return (_idle = Completer<void>()).future;
  }

  void finish() {
    if (!done.isCompleted) done.complete();
    _ticks.add(null);
  }

  void fail(Object e) {
    error = e;
    if (!headers.isCompleted) headers.completeError(e);
    if (!done.isCompleted) done.completeError(e);
    _ticks.add(null);
  }

  /// Baştan itibaren okur: yazılmış kısmı hemen, gerisini geldikçe.
  Stream<List<int>> read() async* {
    // Yazma bittiyse ad değişmek üzere ya da değişmiş; bitmesini bekleyip
    // son dosyadan okunur.
    if (_written) {
      await done.future;
      yield* file.openRead();
      return;
    }
    _readers++;
    RandomAccessFile? input;
    try {
      input = await part.open();
      var position = 0;
      while (true) {
        if (position < received) {
          final chunk = await input.read(received - position);
          position += chunk.length;
          yield chunk;
          continue;
        }
        if (error != null) throw error!;
        if (_written) break;
        await _ticks.stream.first;
      }
    } finally {
      await input?.close();
      _readers--;
      if (_readers == 0) _idle?.complete();
    }
  }
}
