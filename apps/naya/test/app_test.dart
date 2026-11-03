import 'package:flutter_test/flutter_test.dart';
import 'package:naya/app/app.dart';

void main() {
  testWidgets('uygulama açılıyor', (tester) async {
    await tester.pumpWidget(const NayaApp());
    expect(find.textContaining('NAYA'), findsOneWidget);
  });
}
