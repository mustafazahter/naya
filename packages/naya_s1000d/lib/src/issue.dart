import 'package:xml/xml.dart';

/// Dosyanın yazıldığı S1000D issue'su, şema adresinden okunur:
/// `http://www.s1000d.org/S1000D_5-0/xml_schema_flat/descript.xsd` → `5.0`.
/// Şema adresi yoksa null.
String? issueOf(XmlElement root) {
  for (final a in root.attributes) {
    if (a.name.local != 'noNamespaceSchemaLocation') continue;
    final m = RegExp(r'S1000D_(\d+)-(\d+)').firstMatch(a.value);
    if (m != null) return '${m[1]}.${m[2]}';
  }
  return null;
}

/// Okuyabildiğimiz en eski issue. 4.0'dan önce eleman adları tamamen farklı
/// (`dmaddres`, `avee`...); onları okumuyoruz.
bool isSupportedIssue(String? issue) {
  if (issue == null) return true; // şema adresi olmayan dosyaya şans ver
  final major = int.tryParse(issue.split('.').first) ?? 0;
  return major >= 4;
}
