/// Sunucu adresi derleme sırasında verilir:
/// `flutter run --dart-define=NAYA_API_URL=http://localhost:8080`
///
/// Komuta'daki web derlemesinde boş verilir (`--dart-define=NAYA_API_URL=`):
/// uygulama API ile aynı adresten sunulduğu için açıldığı adres kullanılır
/// ([resolveApiUrl]).
const apiUrl = String.fromEnvironment(
  'NAYA_API_URL',
  defaultValue: 'http://localhost:8080',
);

/// [apiUrl] boşsa sayfanın kendi adresi (`https://naya.….app`); sonda
/// eğik çizgi olmadan.
String resolveApiUrl(String configured, Uri page) {
  if (configured.isNotEmpty) return configured;
  return page.hasScheme && page.scheme.startsWith('http') ? page.origin : '';
}

/// three.js viewer'ın adresi. Boşsa uygulamaya gömülü viewer kullanılır
/// (`assets/viewer`, `packages/viewer_web` içinde `npm run bundle` ile
/// gelir). Viewer üzerinde çalışırken `npm run dev` ile açılan sunucu
/// verilebilir: `--dart-define=NAYA_VIEWER_URL=http://localhost:5173`.
const viewerUrl = String.fromEnvironment('NAYA_VIEWER_URL');
