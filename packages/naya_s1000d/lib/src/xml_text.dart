import 'package:xml/xml.dart';

/// Bir elemanın metni; boşluklar tek boşluğa indirilir.
///
/// [skip] içindeki alt elemanların metni alınmaz (örneğin bir adımın metnini
/// alırken iç adımlar ayrıca işleniyorsa).
String textOf(XmlNode node, {Set<String> skip = const {}}) {
  final buffer = StringBuffer();
  void walk(XmlNode n) {
    if (n is XmlText || n is XmlCDATA) {
      buffer.write(n.value);
    } else if (n is XmlElement) {
      if (n != node && skip.contains(n.name.local)) return;
      n.children.forEach(walk);
      // Blok elemanlar arasına boşluk koy; "Adım 1" ile "Adım 2" yapışmasın.
      buffer.write(' ');
    }
  }

  walk(node);
  return buffer
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      // Satır içi elemandan sonra eklenen boşluk noktalamadan önce kalmasın:
      // "<emphasis>zincir</emphasis>." → "zincir ." değil "zincir."
      .replaceAllMapped(RegExp(r' ([.,;:!?)])'), (m) => m[1]!)
      .trim();
}

/// İlk [name] çocuğu ya da torunu.
XmlElement? firstDescendant(XmlElement e, String name) =>
    e.findAllElements(name).firstOrNull;

/// Doğrudan çocuklar içinde [name] adlı olanlar.
Iterable<XmlElement> elementsNamed(XmlElement e, String name) =>
    e.childElements.where((c) => c.name.local == name);

/// Elemanın metni; eleman yoksa null.
String? optionalText(XmlElement? e) => e == null ? null : textOf(e);

/// Elemanların [name] özniteliği; özniteliği olmayanlar atlanır, aynı değer
/// bir kez yazılır.
List<String> attributeValues(Iterable<XmlElement> elements, String name) {
  final values = <String>{};
  for (final e in elements) {
    final value = e.getAttribute(name);
    if (value != null) values.add(value);
  }
  return values.toList();
}
