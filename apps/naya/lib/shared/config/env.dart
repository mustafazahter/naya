/// Sunucu adresi derleme sırasında verilir:
/// `flutter run --dart-define=NAYA_API_URL=http://localhost:8080`
const apiUrl = String.fromEnvironment(
  'NAYA_API_URL',
  defaultValue: 'http://localhost:8080',
);

/// three.js viewer'ın adresi. Yerelde `packages/viewer_web` içinde
/// `npm run dev` ile 5173'te açılır.
const viewerUrl = String.fromEnvironment(
  'NAYA_VIEWER_URL',
  defaultValue: 'http://localhost:5173',
);
