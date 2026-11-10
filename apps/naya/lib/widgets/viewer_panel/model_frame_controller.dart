/// Viewer'a komut göndermek için. Komutların biçimi
/// `packages/viewer_web/src/bridge.ts` içindeki `ViewerCommand` ile aynı.
///
/// Parça kimlikleri modeldeki düğüm adlarıdır (`drive_chain`); `parts.json`
/// kimliklerinden (`drive.chain`) çeviri `meshNodes` ile yapılır.
class ModelFrameController {
  void Function(Map<String, Object?> command)? _send;

  void attach(void Function(Map<String, Object?> command) send) => _send = send;

  void detach() => _send = null;

  void explode(double amount) =>
      _send?.call({'type': 'explode', 'amount': amount});

  void xray(bool enabled) => _send?.call({'type': 'xray', 'enabled': enabled});

  void focus(String part) => _send?.call({'type': 'focus', 'part': part});

  /// Yalnız [part] görünür; null bütün modeli geri getirir.
  void isolate(String? part) => _send?.call({'type': 'isolate', 'part': part});

  /// Teşhis taraması: bant modelin boyunca geçer, parçalar [weights]
  /// (0-1 olasılık) ile orantılı parlar. Bitince viewer `scanDone` gönderir.
  void scan(Map<String, double> weights) =>
      _send?.call({'type': 'scan', 'parts': _weighted(weights)});

  /// Taramasız, doğrudan olasılığa göre parlatma. Boş harita vurguyu kaldırır.
  void highlight(Map<String, double> weights) =>
      _send?.call({'type': 'highlight', 'parts': _weighted(weights)});

  void reset() => _send?.call({'type': 'reset'});

  static List<Map<String, Object?>> _weighted(Map<String, double> weights) => [
    for (final e in weights.entries) {'id': e.key, 'weight': e.value},
  ];
}
