import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya/shared/api/api_client.dart';
import 'package:naya/shared/platform/model_cache_io.dart';
import 'package:naya/shared/platform/viewer_asset_server.dart';

/// Modeli parça parça, araya bekleme koyarak veren sahte API. Kaç kez
/// istendiğini ve gelen başlıkları sayar.
class _ModelServer {
  late HttpServer server;
  final requests = <HttpHeaders>[];
  var status = HttpStatus.ok;

  /// Her parçadan sonra beklenir; viewer inerken okuyabiliyor mu diye.
  Completer<void>? gate;

  static final body = List<int>.generate(300 * 1024, (i) => i % 251);

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.headers);
      final response = request.response..statusCode = status;
      if (status == HttpStatus.ok) {
        response.contentLength = body.length;
        const chunk = 64 * 1024;
        for (var i = 0; i < body.length; i += chunk) {
          response.add(body.sublist(i, (i + chunk).clamp(0, body.length)));
          await response.flush();
          if (i == 0 && gate != null) await gate!.future;
        }
      }
      await response.close();
    });
  }

  String get url => 'http://127.0.0.1:${server.port}';
}

Future<List<int>> _get(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    if (response.statusCode != 200) {
      throw HttpException('${response.statusCode}');
    }
    return (await response.toList()).expand((c) => c).toList();
  } finally {
    client.close();
  }
}

class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw StateError('asset yok');
}

void main() {
  late _ModelServer remote;
  late ApiClient api;
  late ViewerAssetServer local;
  final cache = ModelCache.instance;
  var run = 0;

  // Her test kendi ürün kimliğiyle: önbellek uygulama boyunca tek.
  String id() => 'urun$run';

  // Önbellek diskte kalıcı; önceki çalıştırmanın modelleri testi bozmasın.
  setUpAll(() async {
    final dir = Directory('${Directory.systemTemp.path}/models');
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  setUp(() async {
    run++;
    remote = _ModelServer();
    await remote.start();
    api = ApiClient(baseUrl: remote.url)..token = 'gizli';
    local = await ViewerAssetServer.start(_EmptyBundle());
  });

  tearDown(() async {
    await remote.server.close(force: true);
    await local.close();
  });

  String localUrl(String version) =>
      local.baseUrl +
      cache
          .localPath(api, id(), '/model.glb?v=$version', version: version)!
          .substring(2);

  test('model bir kez iner, sonra diskten gelir; token başlıkta', () async {
    final url = localUrl('aaaa');
    expect(await _get(url), _ModelServer.body);
    expect(await _get(url), _ModelServer.body);
    expect(remote.requests, hasLength(1));
    expect(remote.requests.single.value('authorization'), 'Bearer gizli');
  });

  test('önceden indirme sürerken açılan viewer aynı indirmeyi okur', () async {
    remote.gate = Completer<void>();
    cache.prefetch(api, id(), '/model.glb?v=bbbb', version: 'bbbb');
    final url = localUrl('bbbb');
    // İlk parça indi, indirme bekliyor; viewer şimdi istiyor.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final reading = _get(url);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    remote.gate!.complete();
    expect(await reading, _ModelServer.body);
    expect(remote.requests, hasLength(1));
  });

  test('yeni sürüm inince eskisi silinir', () async {
    await _get(localUrl('cccc'));
    final dir = Directory('${Directory.systemTemp.path}/models');
    bool has(String v) => File('${dir.path}/${id()}-$v.glb').existsSync();
    // Viewer son baytı aldıktan sonra `.part`ın adı değişir.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(has('cccc'), isTrue);
    await _get(localUrl('dddd'));
    // Temizlik indirme bitince arka planda.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(has('dddd'), isTrue);
    expect(has('cccc'), isFalse);
  });

  test('sunucu hata verirse viewer da hata alır, yarım dosya kalmaz', () async {
    remote.status = HttpStatus.notFound;
    await expectLater(_get(localUrl('eeee')), throwsA(isA<HttpException>()));
    final dir = Directory('${Directory.systemTemp.path}/models');
    expect(File('${dir.path}/${id()}-eeee.part').existsSync(), isFalse);
    expect(File('${dir.path}/${id()}-eeee.glb').existsSync(), isFalse);
  });

  test('sürüm yoksa önbellek devreye girmez', () {
    expect(cache.localPath(api, id(), '/model.glb', version: null), isNull);
  });

  test('bilinmeyen anahtar 404', () async {
    await expectLater(
      _get('${local.baseUrl}cached/yok-1234'),
      throwsA(isA<HttpException>()),
    );
  });
}
