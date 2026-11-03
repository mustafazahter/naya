// 3D viewer yalnız web'de iframe ile gösteriliyor; Android tarafı (WebView)
// ayrı bir dosyada gelecek. Diğer platformlarda boş bir yer tutucu var.
export 'model_frame_stub.dart'
    if (dart.library.js_interop) 'model_frame_web.dart';
