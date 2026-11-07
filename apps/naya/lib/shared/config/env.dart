/// Sunucu adresi derleme sırasında verilir:
/// `flutter run --dart-define=NAYA_API_URL=http://localhost:8080`
const apiUrl = String.fromEnvironment(
  'NAYA_API_URL',
  defaultValue: 'http://localhost:8080',
);

/// three.js viewer'ın adresi. Boşsa uygulamaya gömülü viewer kullanılır
/// (`assets/viewer`, `packages/viewer_web` içinde `npm run bundle` ile
/// gelir). Viewer üzerinde çalışırken `npm run dev` ile açılan sunucu
/// verilebilir: `--dart-define=NAYA_VIEWER_URL=http://localhost:5173`.
const viewerUrl = String.fromEnvironment('NAYA_VIEWER_URL');
