import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya/shared/ui/rich_message.dart';

String _plain(List<InlineSpan> spans) =>
    spans.map((s) => (s as TextSpan).text).join();

void main() {
  const base = TextStyle(fontSize: 14);

  test('kalın, italik ve kod işaretleri metinden kalkar, biçim olur', () {
    final spans = RichMessage.inlineSpans(
      'Önce **arıza lambasına** bak, *sonra* `P0300` koduna.',
      base,
    );
    expect(_plain(spans), 'Önce arıza lambasına bak, sonra P0300 koduna.');
    final bold = spans.whereType<TextSpan>().firstWhere(
      (s) => s.text == 'arıza lambasına',
    );
    expect(bold.style?.fontWeight, FontWeight.w600);
    final italic = spans.whereType<TextSpan>().firstWhere(
      (s) => s.text == 'sonra',
    );
    expect(italic.style?.fontStyle, FontStyle.italic);
  });

  test('yarım kalan işaret ve sayı içindeki yıldız düz kalır', () {
    expect(
      _plain(RichMessage.inlineSpans('Lamba **yanıyor mu', base)),
      'Lamba **yanıyor mu',
    );
    expect(_plain(RichMessage.inlineSpans('2*3 ve 4*5', base)), '2*3 ve 4*5');
  });

  testWidgets('listeler ve paragraflar ayrı satırlarda', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RichMessage(
            'Şunlara bak:\n\n- Buji\n- **Bobin**\n1. Kabloları sök\n\n# Not\nSon.',
          ),
        ),
      ),
    );
    expect(find.text('•'), findsNWidgets(2));
    expect(find.text('1.'), findsOneWidget);
    expect(find.textContaining('Bobin'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('#'), findsNothing);
  });
}
