import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

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

    for (final bad in [
      '',
      'DMC-',
      'DMC-S1000DBIKE-AAA-DA1-10-00-00AA-041A',
      'DMC-S1000DBIKE-AAA-DA1-100-00-00AA-041A-A',
      'DMC-S1000DBIKE-AAA-DA1-10-00-0-041A-A',
      'DMC-S1000DBIKE-AAA-DA1-10-00-00AA-041-A',
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
  });

  test('eşitlik ve sıralama koda göre', () {
    final a = DmCode.parse('DMC-X-A-D00-00-00-00AA-040A-A');
    final b = DmCode.parse('DMC-X-A-D00-00-00-00AA-520A-A');
    expect(a, DmCode.parse(a.toString()));
    expect({a, DmCode.parse(a.toString())}, hasLength(1));
    expect([b, a]..sort(), [a, b]);
  });
}
