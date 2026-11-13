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

  Completer<void>? _scan;

  /// Viewer hiç cevap vermezse (model yüklenmedi) taramayı beklemeyi bırak.
  static const scanTimeout = Duration(seconds: 6);

  void attach(void Function(Map<String, Object?> command) send) => _send = send;

  void detach() {
    _send = null;
    scanFinished();
  }

  void explode(double amount) {
    exploded.value = amount > 0;
    _send?.call({'type': 'explode', 'amount': amount});
  }

  void xray(bool enabled) => _send?.call({'type': 'xray', 'enabled': enabled});

  void focus(String part) => _send?.call({'type': 'focus', 'part': part});

  /// Yalnız [part] görünür; null bütün modeli geri getirir.
  void isolate(String? part) => _send?.call({'type': 'isolate', 'part': part});

  /// Teşhis taraması: bant modelin boyunca geçer, parçalar [weights]
  /// (0-1) ile orantılı parlar. Viewer `scanDone` gönderince biter.
  Future<void> scan(Map<String, double> weights) {
    scanFinished();
    final send = _send;
    if (send == null) return Future.value();
    final done = Completer<void>();
    _scan = done;
    send({'type': 'scan', 'parts': _weighted(weights)});
    return done.future.timeout(scanTimeout, onTimeout: () {});
  }

  /// Viewer'dan `scanDone` geldi.
  void scanFinished() {
    final scan = _scan;
    _scan = null;
    if (scan != null && !scan.isCompleted) scan.complete();
  }

  /// Taramasız, doğrudan olasılığa göre parlatma. Boş harita vurguyu kaldırır.
  void highlight(Map<String, double> weights) =>
      _send?.call({'type': 'highlight', 'parts': _weighted(weights)});

  void reset() {
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
