import 'dart:async';

import 'package:flutter/foundation.dart';

/// Viewer'a komut göndermek için. Komutların biçimi
/// `packages/viewer_web/src/bridge.ts` içindeki `ViewerCommand` ile aynı.
///
/// Parça kimlikleri modeldeki düğüm adlarıdır (`drive_chain`); `parts.json`
/// kimliklerinden (`drive.chain`) çeviri `meshNodes` ile yapılır.
class ModelFrameController {
  void Function(Map<String, Object?> command)? _send;

  /// Model parçalarına ayrılmış mı? Düğme ve teşhis animasyonu aynı
  /// durumu görsün diye burada.
  final exploded = ValueNotifier<bool>(false);

  /// Süren taramanın numarası ve bitince tamamlanacak olan.
  int _scanId = 0;
  Completer<bool>? _scan;

  /// Viewer hiç cevap vermezse (model yüklenmedi) taramayı beklemeyi bırak.
  static const scanTimeout = Duration(seconds: 6);

  void attach(void Function(Map<String, Object?> command) send) => _send = send;

  void detach() {
    _send = null;
    _endScan(false);
  }

  void explode(double amount) {
    final send = _send;
    if (send == null) return;
    exploded.value = amount > 0;
    send({'type': 'explode', 'amount': amount});
  }

  void xray(bool enabled) => _send?.call({'type': 'xray', 'enabled': enabled});

  void focus(String part) => _send?.call({'type': 'focus', 'part': part});

  /// Yalnız [part] görünür; null bütün modeli geri getirir.
  void isolate(String? part) => _send?.call({'type': 'isolate', 'part': part});

  /// Teşhis taraması: bant modelin boyunca geçer, parçalar [weights]
  /// (0-1) ile orantılı parlar. Viewer `scanDone` gönderince biter.
  ///
  /// Tarama sonuna kadar sürdüyse `true`; yenisi başladıysa, model
  /// sıfırlandıysa ya da viewer cevap vermediyse `false`. Böylece yarıda
  /// kalan bir taramanın ardından kamera hareketi yapılmaz.
  Future<bool> scan(Map<String, double> weights) {
    _endScan(false);
    final send = _send;
    if (send == null) return Future.value(false);
    final done = Completer<bool>();
    _scan = done;
    send({'type': 'scan', 'id': ++_scanId, 'parts': _weighted(weights)});
    return done.future.timeout(scanTimeout, onTimeout: () => false);
  }

  /// Viewer'dan `scanDone` geldi. Önceki, yarıda kesilen taramanın cevabı
  /// da gelir; yalnız son taramanın numarası sayılır.
  void scanFinished(int id) {
    if (id == _scanId) _endScan(true);
  }

  void _endScan(bool finished) {
    final scan = _scan;
    _scan = null;
    if (scan != null && !scan.isCompleted) scan.complete(finished);
  }

  /// Taramasız, doğrudan olasılığa göre parlatma. Boş harita vurguyu kaldırır.
  void highlight(Map<String, double> weights) {
    _endScan(false);
    _send?.call({'type': 'highlight', 'parts': _weighted(weights)});
  }

  void reset() {
    _endScan(false);
    exploded.value = false;
    _send?.call({'type': 'reset'});
  }

  void dispose() {
    detach();
    exploded.dispose();
  }

  static List<Map<String, Object?>> _weighted(Map<String, double> weights) => [
    for (final e in weights.entries) {'id': e.key, 'weight': e.value},
  ];
}
