// 3D viewer web'de iframe, Android'de WebView içinde açılır. İkisi de aynı
// gömülü viewer'ı ve aynı mesajları kullanır (bkz. viewer_web/src/bridge.ts).
export 'model_frame_stub.dart'
    if (dart.library.js_interop) 'model_frame_web.dart'
    if (dart.library.io) 'model_frame_io.dart';
