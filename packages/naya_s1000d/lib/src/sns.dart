import 'package:xml/xml.dart';

import 'data_module.dart';
import 'xml_text.dart';

/// SNS ağacındaki bir düğüm: sistem, alt sistem, alt-alt sistem ya da
/// montaj.
///
/// Kodlar üst düğümle birleşik tutulur: `DA1`, `DA1-1`, `DA1-10`,
/// `DA1-10-00`. Böylece her düğümün kodu tek başına anlamlı.
class SnsNode {
  SnsNode({required this.code, required this.level, this.title = ''});

  final String code;
  final SnsLevel level;
  String title;
  final List<SnsNode> children = [];

  /// Yalnız montaj düğümlerinde dolu.
  final List<DataModule> dataModules = [];

  /// Bu düğüm ve altındaki bütün DM'ler.
  Iterable<DataModule> get allDataModules sync* {
    yield* dataModules;
    for (final c in children) {
      yield* c.allDataModules;
    }
  }

  SnsNode _child(String code, SnsLevel level) {
    for (final c in children) {
      if (c.code == code) return c;
    }
    final node = SnsNode(code: code, level: level);
    children.add(node);
    return node;
  }

  @override
  String toString() => '$code $title';
}

enum SnsLevel { system, subSystem, subSubSystem, assembly }

/// DM kodlarından SNS ağacını kurar.
///
/// Başlıklar önce BREX'teki `snsRules` bölümünden ([brexXml]), yoksa o
/// seviyeyi tanımlayan DM'in `techName`'inden alınır: `DA1-00-00` kodlu bir
/// DM `DA1` sisteminin kendisini anlatır.
List<SnsNode> buildSnsTree(
  Iterable<DataModule> dataModules, {
  String? brexXml,
}) {
  final titles = brexXml == null ? <String, String>{} : snsTitles(brexXml);
  final roots = <SnsNode>[];
  SnsNode root(String code) {
    for (final r in roots) {
      if (r.code == code) return r;
    }
    final node = SnsNode(code: code, level: SnsLevel.system);
    roots.add(node);
    return node;
  }

  final sorted = dataModules.toList()..sort((a, b) => a.code.compareTo(b.code));
  for (final dm in sorted) {
    final c = dm.code;
    final system = root(c.systemCode);
    final sub = system._child(
      '${c.systemCode}-${c.subSystemCode}',
      SnsLevel.subSystem,
    );
    final subSub = sub._child(
      '${c.systemCode}-${c.subSystemCode}${c.subSubSystemCode}',
      SnsLevel.subSubSystem,
    );
    final assy = subSub._child(c.sns, SnsLevel.assembly)..dataModules.add(dm);

    // DM'in kodu hangi seviyede sıfırlara iniyorsa o seviyeyi anlatıyor:
    // DA1-00-00 sistemi, DA1-10-00 alt sistemi, DA1-11-00 alt-alt sistemi.
    var described = assy;
    if (RegExp(r'^0+$').hasMatch(c.assyCode)) {
      if (c.subSubSystemCode != '0') {
        described = subSub;
      } else if (c.subSystemCode != '0') {
        described = sub;
      } else {
        described = system;
      }
    }
    if (described.title.isEmpty) described.title = dm.techName;
    if (assy.title.isEmpty) assy.title = dm.techName;
  }

  void applyTitles(SnsNode node) {
    final title = titles[node.code];
    if (title != null) node.title = title;
    node.children.forEach(applyTitles);
  }

  roots.forEach(applyTitles);
  return roots;
}

/// BREX DM'indeki SNS başlıkları, [SnsNode.code] biçiminde anahtarlarla.
Map<String, String> snsTitles(String brexXml) {
  final XmlElement root;
  try {
    root = XmlDocument.parse(brexXml).rootElement;
  } on XmlException {
    return {};
  }
  final titles = <String, String>{};
  String titleOf(XmlElement e) => optionalText(e.getElement('snsTitle')) ?? '';
  String codeOf(XmlElement e) => optionalText(e.getElement('snsCode')) ?? '';

  for (final system in root.findAllElements('snsSystem')) {
    final sc = codeOf(system);
    titles[sc] = titleOf(system);
    for (final sub in elementsNamed(system, 'snsSubSystem')) {
      final ss = codeOf(sub);
      titles['$sc-$ss'] = titleOf(sub);
      for (final subSub in elementsNamed(sub, 'snsSubSubSystem')) {
        final sss = codeOf(subSub);
        titles['$sc-$ss$sss'] = titleOf(subSub);
        for (final assy in elementsNamed(subSub, 'snsAssy')) {
          titles['$sc-$ss$sss-${codeOf(assy)}'] = titleOf(assy);
        }
      }
    }
  }
  titles.removeWhere((_, title) => title.isEmpty);
  return titles;
}
