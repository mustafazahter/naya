import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naya/app/app.dart';

void main() {
  // Testte ağdan font indirilmesin.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('kütüphane açılıyor', (tester) async {
    await tester.pumpWidget(const NayaApp());
    expect(find.text('Neyi inceliyoruz?'), findsOneWidget);
    expect(find.text('Bisiklet'), findsOneWidget);
  });
}
