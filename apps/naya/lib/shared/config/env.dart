/// Sunucu adresi derleme sırasında verilir:
/// `flutter run --dart-define=NAYA_API_URL=http://localhost:8080`
const apiUrl = String.fromEnvironment(
  'NAYA_API_URL',
  defaultValue: 'http://localhost:8080',
);
