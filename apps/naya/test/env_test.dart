import 'package:flutter_test/flutter_test.dart';
import 'package:naya/shared/config/env.dart';

void main() {
  test('adres verildiyse o kullanılır', () {
    expect(
      resolveApiUrl('http://localhost:8080', Uri.parse('https://naya.app/')),
      'http://localhost:8080',
    );
  });

  test('boşsa sayfanın kendi adresi (Komuta: aynı servis)', () {
    expect(
      resolveApiUrl('', Uri.parse('https://naya.example.app/urun/bisiklet')),
      'https://naya.example.app',
    );
  });

  test('sayfa adresi yoksa (Android) boş kalır', () {
    expect(resolveApiUrl('', Uri.parse('file:///')), '');
  });
}
