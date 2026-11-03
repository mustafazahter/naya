import 'package:flutter_test/flutter_test.dart';
import 'package:naya/app/app.dart';
import 'package:naya/shared/ui/theme.dart';

void main() {
  // Testte ağdan font indirilmesin.
  NayaFonts.useGoogleFonts = false;

  testWidgets('kütüphane açılıyor', (tester) async {
    await tester.pumpWidget(const NayaApp());
    expect(find.text('Neyi inceliyoruz?'), findsOneWidget);
    expect(find.text('Bisiklet'), findsOneWidget);
  });
}
