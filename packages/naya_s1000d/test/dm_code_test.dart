import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('DmCode.parse', () {
    test('tam kod', () {
      final c = DmCode.parse('DMC-S1000DBIKE-AAA-DA1-10-00-00AA-041A-A');
      expect(c.modelIdentCode, 'S1000DBIKE');
      expect(c.systemDiffCode, 'AAA');
      expect(c.systemCode, 'DA1');
      expect(c.subSystemCode, '1');
      expect(c.subSubSystemCode, '0');
      expect(c.assyCode, '00');
      expect(c.disassyCode, '00');
      expect(c.disassyCodeVariant, 'AA');
      expect(c.infoCode, '041');
      expect(c.infoCodeVariant, 'A');
      expect(c.itemLocationCode, 'A');
      expect(c.sns, 'DA1-10-00');
    });

    test('dosya adındaki sürüm, dil ve uzantı yok sayılır', () {
      final c = DmCode.parse(
        'DMC-NAYABIKE-AAA-D00-00-00-01AA-941A-A_001-00_TR-TR.XML',
      );
      expect(c.toString(), 'DMC-NAYABIKE-AAA-D00-00-00-01AA-941A-A');
    });

    test('DMC- öneki olmadan, dört haneli montaj kodu, uzun varyant', () {
      final c = DmCode.parse('ABC-A-D00-00-0000-00ABC-520A-B');
      expect(c.assyCode, '0000');
      expect(c.disassyCodeVariant, 'ABC');
      expect(c.kind, InfoKind.removal);
    });

    test('yazılıp tekrar okunduğunda aynı kod', () {
      const text = 'DMC-S1000DBIKE-AAA-DA2-00-00-00AA-421A-A';
      expect(DmCode.parse(text).toString(), text);
      expect(DmCode.parse('dmc-${text.substring(4)}').toString(), text);
    });

    test('baştaki ve sondaki boşluk yok sayılır', () {
      expect(
        DmCode.parse('  DMC-X-A-D00-00-00-00AA-040A-A\n').toString(),
        'DMC-X-A-D00-00-00-00AA-040A-A',
      );
    });

    test('küçük harf uzantı yok sayılır', () {
      expect(
        DmCode.parse('DMC-X-A-D00-00-00-00AA-040A-A.xml').itemLocationCode,
        'A',
      );
    });

    test('öğrenme kodu okunmaz, DMC aynı kalır', () {
      expect(
        DmCode.parse('DMC-X-A-D00-00-00-00AA-040A-A-H10A-A').toString(),
        'DMC-X-A-D00-00-00-00AA-040A-A',
      );
    });

    test('tek ve üç haneli varyant', () {
      expect(DmCode.parse('X-A-D00-00-00-00A-040A-A').disassyCodeVariant, 'A');
      expect(
        DmCode.parse('X-A-D00-00-00-00ABC-040A-A').disassyCodeVariant,
        'ABC',
      );
    });

    test('fromElement ile parse aynı kodu verir', () {
      final doc = XmlDocument.parse(
        '<dmCode modelIdentCode="X" systemDiffCode="A" systemCode="D00" '
        'subSystemCode="0" subSubSystemCode="0" assyCode="00" '
        'disassyCode="00" disassyCodeVariant="AA" infoCode="040" '
        'infoCodeVariant="A" itemLocationCode="A"/>',
      );
      expect(
        DmCode.fromElement(doc.rootElement),
        DmCode.parse('DMC-X-A-D00-00-00-00AA-040A-A'),
      );
    });

    test('fromElement: boş öznitelik eksik sayılır', () {
      final doc = XmlDocument.parse('<dmCode modelIdentCode=""/>');
      expect(
        () => DmCode.fromElement(doc.rootElement),
        throwsA(
          isA<S1000dException>().having(
            (e) => e.message,
            'message',
            contains('modelIdentCode'),
          ),
        ),
      );
    });

    for (final bad in [
      '',
      'DMC-',
      'DMC-S1000DBIKE-AAA-DA1-10-00-00AA-041A',
      'DMC-S1000DBIKE-AAA-DA1-100-00-00AA-041A-A',
      'DMC-S1000DBIKE-AAA-DA1-10-00-0-041A-A',
      'DMC-S1000DBIKE-AAA-DA1-10-00-00AA-041-A',
      'DMC--AAA-DA1-10-00-00AA-041A-A',
      'DMC-S1000DBIKE--DA1-10-00-00AA-041A-A',
      'DMC-S1000DBIKE-AAA--10-00-00AA-041A-A',
      'DMC-S1000DBIKE-AAA-DA1-10--00AA-041A-A',
      '   ',
      '_001-00_TR-TR.XML',
    ]) {
      test('geçersiz: "$bad"', () {
        expect(() => DmCode.parse(bad), throwsA(isA<S1000dException>()));
      });
    }
  });

  test('bilgi kodundan tür', () {
    expect(InfoKind.of('040'), InfoKind.description);
    expect(InfoKind.of('310'), InfoKind.inspection);
    expect(InfoKind.of('421'), InfoKind.faultReport);
    expect(InfoKind.of('520'), InfoKind.removal);
    expect(InfoKind.of('720'), InfoKind.installation);
    expect(InfoKind.of('941'), InfoKind.partsCatalog);
    expect(InfoKind.of('99X'), InfoKind.other);
    expect(InfoKind.of('100'), InfoKind.operation);
    expect(InfoKind.of('200'), InfoKind.servicing);
    expect(InfoKind.of('660'), InfoKind.repair);
    expect(InfoKind.of('800'), InfoKind.storage);
    expect(InfoKind.of('942'), InfoKind.partsCatalog);
    expect(InfoKind.of('920'), InfoKind.other);
    expect(InfoKind.of(''), InfoKind.other);
  });

  test('eşitlik ve sıralama koda göre', () {
    final a = DmCode.parse('DMC-X-A-D00-00-00-00AA-040A-A');
    final b = DmCode.parse('DMC-X-A-D00-00-00-00AA-520A-A');
    expect(a, DmCode.parse(a.toString()));
    expect({a, DmCode.parse(a.toString())}, hasLength(1));
    expect([b, a]..sort(), [a, b]);
  });
}
