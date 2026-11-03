/// Viewer'a komut göndermek için. Komutların biçimi
/// `packages/viewer_web/src/bridge.ts` içindeki `ViewerCommand` ile aynı.
class ModelFrameController {
  void Function(Map<String, Object?> command)? _send;

  void attach(void Function(Map<String, Object?> command) send) => _send = send;

  void detach() => _send = null;

  void explode(double amount) =>
      _send?.call({'type': 'explode', 'amount': amount});

  void xray(bool enabled) => _send?.call({'type': 'xray', 'enabled': enabled});

  void focus(String part) => _send?.call({'type': 'focus', 'part': part});

  void reset() => _send?.call({'type': 'reset'});
}
