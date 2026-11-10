import 'package:xml/xml.dart';

import 'errors.dart';

/// Veri modülü kodu (DMC), örneğin
/// `DMC-S1000DBIKE-AAA-DA1-00-00-00AA-041A-A`.
///
/// Alanlar Issue 4.0 ve sonrasındaki `dmCode` elemanının öznitelikleriyle
/// aynı adı taşır. Öğrenme kodu (learnCode) v1'de okunmuyor.
class DmCode implements Comparable<DmCode> {
  const DmCode({
    required this.modelIdentCode,
    required this.systemDiffCode,
    required this.systemCode,
    required this.subSystemCode,
    required this.subSubSystemCode,
    required this.assyCode,
    required this.disassyCode,
    required this.disassyCodeVariant,
    required this.infoCode,
    required this.infoCodeVariant,
    required this.itemLocationCode,
  });

  /// `DMC-` ile ya da onsuz yazılmış kodu okur. Dosya adındaki `_001-00_TR-TR`
  /// gibi ekler varsa yok sayılır.
  factory DmCode.parse(String text) {
    var code = text.trim();
    if (code.toUpperCase().startsWith('DMC-')) code = code.substring(4);
    code = code.split('_').first;
    if (code.contains('.')) code = code.substring(0, code.indexOf('.'));
    final p = code.split('-');
    // MIC-SDC-SC-(SS)(SSS)-AC-DC(DCV)-IC(ICV)-ILC
    if (p.length < 8 ||
        p.take(8).any((field) => field.isEmpty) ||
        p[3].length != 2 ||
        p[5].length < 3 ||
        p[6].length != 4 ||
        p[7].length != 1) {
      throw S1000dException('Geçersiz DMC: $text');
    }
    return DmCode(
      modelIdentCode: p[0],
      systemDiffCode: p[1],
      systemCode: p[2],
      subSystemCode: p[3][0],
      subSubSystemCode: p[3][1],
      assyCode: p[4],
      disassyCode: p[5].substring(0, 2),
      disassyCodeVariant: p[5].substring(2),
      infoCode: p[6].substring(0, 3),
      infoCodeVariant: p[6].substring(3),
      itemLocationCode: p[7],
    );
  }

  /// `<dmCode>` elemanını okur.
  factory DmCode.fromElement(XmlElement e) {
    String attr(String name) {
      final value = e.getAttribute(name);
      if (value == null || value.isEmpty) {
        throw S1000dException('dmCode: "$name" özniteliği eksik');
      }
      return value;
    }

    return DmCode(
      modelIdentCode: attr('modelIdentCode'),
      systemDiffCode: attr('systemDiffCode'),
      systemCode: attr('systemCode'),
      subSystemCode: attr('subSystemCode'),
      subSubSystemCode: attr('subSubSystemCode'),
      assyCode: attr('assyCode'),
      disassyCode: attr('disassyCode'),
      disassyCodeVariant: attr('disassyCodeVariant'),
      infoCode: attr('infoCode'),
      infoCodeVariant: attr('infoCodeVariant'),
      itemLocationCode: attr('itemLocationCode'),
    );
  }

  final String modelIdentCode;
  final String systemDiffCode;
  final String systemCode;
  final String subSystemCode;
  final String subSubSystemCode;
  final String assyCode;
  final String disassyCode;
  final String disassyCodeVariant;
  final String infoCode;
  final String infoCodeVariant;
  final String itemLocationCode;

  /// SNS yolu: sistem, alt sistem + alt-alt sistem, montaj.
  /// Örneğin `DA1-00-00`.
  String get sns => '$systemCode-$subSystemCode$subSubSystemCode-$assyCode';

  /// Bilgi koduna göre DM'in türü.
  InfoKind get kind => InfoKind.of(infoCode);

  @override
  String toString() =>
      'DMC-$modelIdentCode-$systemDiffCode-$systemCode-'
      '$subSystemCode$subSubSystemCode-$assyCode-'
      '$disassyCode$disassyCodeVariant-$infoCode$infoCodeVariant-'
      '$itemLocationCode';

  @override
  bool operator ==(Object other) =>
      other is DmCode && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  int compareTo(DmCode other) => toString().compareTo(other.toString());
}

/// Bilgi kodunun (infoCode) kabaca anlamı. Teşhiste ve arayüzde DM'leri
/// gruplamak için yeterli; tam liste S1000D Chap 8.4'te.
enum InfoKind {
  description('Tanım'),
  operation('Kullanım'),
  servicing('Servis'),
  inspection('Muayene ve test'),
  faultReport('Arıza bulma'),
  removal('Sökme'),
  installation('Takma'),
  repair('Tamir'),
  storage('Depolama'),
  partsCatalog('Parça kataloğu'),
  other('Diğer');

  const InfoKind(this.label);

  final String label;

  static InfoKind of(String infoCode) {
    final n = int.tryParse(infoCode);
    if (n == null) return other;
    if (infoCode == '941' || infoCode == '942') return partsCatalog;
    return switch (n ~/ 100) {
      0 => description,
      1 => operation,
      2 => servicing,
      3 => inspection,
      4 => faultReport,
      5 => removal,
      6 => repair,
      7 => installation,
      8 => storage,
      _ => other,
    };
  }
}
