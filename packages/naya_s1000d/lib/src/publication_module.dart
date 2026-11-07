import 'package:xml/xml.dart';

import 'dm_code.dart';
import 'errors.dart';
import 'xml_text.dart';

/// Yayın modülü (PM): DM'leri bir kitap gibi bölümlere dizer. Uygulamada
/// "içindekiler" olarak gösterilir.
class PublicationModule {
  const PublicationModule({
    required this.code,
    required this.title,
    required this.entries,
  });

  factory PublicationModule.parse(String xml, {String? file}) {
    final root = _root(xml, 'pm', file);
    final pmCode = firstDescendant(root, 'pmCode');
    if (pmCode == null) {
      throw S1000dException('pmIdent/pmCode bulunamadı', file: file);
    }
    final title = firstDescendant(root, 'pmTitle');
    final content = root.getElement('content');
    return PublicationModule(
      code: [
        'PMC',
        pmCode.getAttribute('modelIdentCode'),
        pmCode.getAttribute('pmIssuer'),
        pmCode.getAttribute('pmNumber'),
        pmCode.getAttribute('pmVolume'),
      ].whereType<String>().join('-'),
      title: optionalText(title) ?? '',
      entries: content == null
          ? const []
          : [
              for (final e in elementsNamed(content, 'pmEntry'))
                PmEntry._read(e),
            ],
    );
  }

  /// `PMC-S1000DBIKE-C3002-LOAP1-00` gibi.
  final String code;
  final String title;
  final List<PmEntry> entries;

  /// Bütün bölümlerdeki DM başvuruları, yayındaki sırasıyla.
  List<PmDmRef> get allDmRefs => [for (final e in entries) ...e.allDmRefs];
}

/// PM'deki bir bölüm; içinde DM başvuruları ve alt bölümler olabilir.
class PmEntry {
  const PmEntry({
    required this.title,
    required this.dmRefs,
    required this.children,
  });

  factory PmEntry._read(XmlElement e) {
    final title = e.getElement('pmEntryTitle');
    return PmEntry(
      title: optionalText(title) ?? '',
      dmRefs: [
        for (final ref in elementsNamed(e, 'dmRef'))
          PmDmRef(
            code: _codeOf(ref),
            title: optionalText(firstDescendant(ref, 'dmTitle')),
          ),
      ],
      children: [for (final c in elementsNamed(e, 'pmEntry')) PmEntry._read(c)],
    );
  }

  final String title;
  final List<PmDmRef> dmRefs;
  final List<PmEntry> children;

  List<PmDmRef> get allDmRefs => [
    ...dmRefs,
    for (final c in children) ...c.allDmRefs,
  ];
}

class PmDmRef {
  const PmDmRef({required this.code, this.title});

  final DmCode code;

  /// PM'de yazan başlık; DM'in kendi başlığıyla aynı olmayabilir.
  final String? title;
}

/// Veri modülü listesi (DML): projede hangi DM'lerin olduğunu söyler.
class DataModuleList {
  const DataModuleList({required this.code, required this.entries});

  factory DataModuleList.parse(String xml, {String? file}) {
    final root = _root(xml, 'dml', file);
    final dmlCode = firstDescendant(root, 'dmlCode');
    if (dmlCode == null) {
      throw S1000dException('dmlIdent/dmlCode bulunamadı', file: file);
    }
    return DataModuleList(
      code: [
        'DML',
        dmlCode.getAttribute('modelIdentCode'),
        dmlCode.getAttribute('senderIdent'),
        dmlCode.getAttribute('dmlType')?.toUpperCase(),
        dmlCode.getAttribute('yearOfDataIssue'),
        dmlCode.getAttribute('seqNumber'),
      ].whereType<String>().join('-'),
      entries: [
        for (final entry in root.findAllElements('dmlEntry'))
          for (final ref in elementsNamed(entry, 'dmRef'))
            DmlEntry(
              code: _codeOf(ref),
              issueType: entry.getAttribute('issueType'),
            ),
      ],
    );
  }

  final String code;
  final List<DmlEntry> entries;
}

class DmlEntry {
  const DmlEntry({required this.code, this.issueType});

  final DmCode code;

  /// `new`, `changed`, `deleted`...
  final String? issueType;
}

/// Bir `dmRef` elemanının gösterdiği DM kodu.
DmCode _codeOf(XmlElement dmRef) {
  final code = firstDescendant(dmRef, 'dmCode');
  if (code == null) throw const S1000dException('dmRef içinde dmCode yok');
  return DmCode.fromElement(code);
}

XmlElement _root(String xml, String name, String? file) {
  final XmlElement root;
  try {
    root = XmlDocument.parse(xml).rootElement;
  } on XmlException catch (e) {
    throw S1000dException('XML okunamadı: ${e.message}', file: file);
  }
  if (root.name.local != name) {
    throw S1000dException(
      'Kök eleman "$name" değil: ${root.name.local}',
      file: file,
    );
  }
  return root;
}
