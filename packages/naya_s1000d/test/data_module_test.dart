import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

DataModule dm(String name) => DataModule.parse(fixture(name), file: name);

void main() {
  group('kimlik', () {
    final d = dm('DMC-NAYABIKE-AAA-D00-00-00-00AA-040A-A_002-00_TR-TR.XML');

    test('kod, dil, sürüm, tarih, issue', () {
      expect(d.code.toString(), 'DMC-NAYABIKE-AAA-D00-00-00-00AA-040A-A');
      expect(d.language, 'tr-TR');
      expect(d.issueNumber, '002');
      expect(d.inWork, '00');
      expect(d.issueDate, DateTime.utc(2026, 11, 7));
      expect(d.s1000dIssue, '5.0');
      expect(d.title, 'Bisiklet - Tanım');
      expect(d.contentType, 'description');
    });

    test('Issue 4.1 DM okunur', () {
      final old = dm('DMC-NAYABIKE-AAA-DA2-00-00-00AA-040A-A_001-00_TR-TR.XML');
      expect(old.s1000dIssue, '4.1');
      expect(old.chunks.single.text, contains('Jant frenleri'));
    });
  });

  group('tanım', () {
    final d = dm('DMC-NAYABIKE-AAA-D00-00-00-00AA-040A-A_002-00_TR-TR.XML');

    test('her paragraf grubu başlık yoluyla ayrı parça', () {
      expect(d.chunks.map((c) => c.section), [
        'Genel',
        'Bileşenler',
        'Bileşenler › Zincir',
        'Bileşenler › Frenler',
      ]);
    });

    test('üst paragraf alt paragrafların metnini tekrar etmez', () {
      final top = d.chunks.firstWhere((c) => c.section == 'Bileşenler');
      expect(top.text, 'Ana bileşenler aşağıda anlatılmıştır.');
    });

    test('başvurulan DM listelenir', () {
      expect(d.dmRefs.single.toString(), endsWith('DA1-10-00-00AA-520A-A'));
    });
  });

  group('prosedür', () {
    final d = dm('DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A_001-00_TR-TR.XML');

    test('ön koşullar, adımlar ve son işlemler', () {
      expect(d.chunks.map((c) => c.section), [
        'Ön koşullar',
        'Adım 1',
        'Adım 2: Pimi çıkarın',
        'Son işlemler',
      ]);
    });

    test('iç adımlar üst adımın parçasında', () {
      final step = d.chunks[2];
      expect(step.text, contains('Kolu pim dışarı'));
      expect(step.text, contains('Zinciri ayırın.'));
      expect(step.icns, ['ICN-NAYABIKE-AAA-DA10000-0-C3002-00001-A-001-01']);
    });

    test('güvenlik uyarısı ve yedek parça numarası ön koşullarda', () {
      final pre = d.chunks.first;
      expect(pre.text, contains('eldiven'));
      expect(pre.partNumbers, ['NB-CH-116']);
    });

    test('DOCTYPE içindeki ENTITY tanımları okumayı bozmaz', () {
      expect(d.icnRefs, ['ICN-NAYABIKE-AAA-DA10000-0-C3002-00001-A-001-01']);
    });

    test('parçalar SNS ve türü taşır', () {
      expect(d.chunks.every((c) => c.sns == 'DA1-10-00'), isTrue);
      expect(d.chunks.first.kind, InfoKind.removal);
      expect(d.chunks.first.dmTitle, 'Zincir - Sökme');
    });
  });

  test('arıza bulma: tanım, adımlar, sonuçlar', () {
    final d = dm('DMC-NAYABIKE-AAA-DA2-00-00-00AA-421A-A_001-00_TR-TR.XML');
    expect(d.chunks.map((c) => c.section), [
      'Arıza tanımı',
      'Adım 1',
      'Adım 2',
      'Sonuç',
      'Sonuç',
    ]);
    expect(d.chunks[1].text, contains("1 mm'den az mı?"));
  });

  group('IPD', () {
    final d = dm('DMC-NAYABIKE-AAA-D00-00-00-01AA-941A-A_001-00_TR-TR.XML');

    test('her varyant ayrı satır', () {
      expect(d.ipdItems, hasLength(4));
      final chain = d.ipdItems[1];
      expect(chain.figure, '01');
      expect(chain.item, '002');
      expect(chain.indenture, 2);
      expect(chain.itemVariant, '00A');
      expect(chain.name, 'Zincir, 116 bakla');
      expect(chain.partNumber, 'NB-CH-116');
      expect(chain.manufacturerCode, 'C3002');
      expect(chain.quantity, '1');
    });

    test('her katalog öğesi bir parça, parça numaralarıyla', () {
      expect(d.chunks.map((c) => c.section), [
        'Şekil 01, öğe 001',
        'Şekil 01, öğe 002',
        'Şekil 01, öğe 003',
      ]);
      expect(d.chunks[1].partNumbers, ['NB-CH-116', 'NB-CH-112']);
    });
  });

  test('BREX aranabilir parça üretmez', () {
    final d = dm('DMC-NAYABIKE-AAA-D00-00-00-00AA-022A-D_001-00_TR-TR.XML');
    expect(d.contentType, 'brex');
    expect(d.chunks, isEmpty);
  });

  group('bozuk DM', () {
    Matcher fails(String text) => throwsA(
      isA<S1000dException>()
          .having((e) => e.file, 'file', 'x.xml')
          .having((e) => e.message, 'message', contains(text)),
    );

    test('XML değil', () {
      expect(() => DataModule.parse('<dmodule>', file: 'x.xml'), fails('XML'));
    });

    test('kök dmodule değil', () {
      expect(() => DataModule.parse('<pm/>', file: 'x.xml'), fails('dmodule'));
    });

    test('dmCode yok', () {
      expect(
        () => DataModule.parse('<dmodule><content/></dmodule>', file: 'x.xml'),
        fails('dmCode'),
      );
    });

    test('dmCode özniteliği eksik', () {
      final xml = fixture(
        'DMC-NAYABIKE-AAA-DA2-00-00-00AA-040A-A_001-00_TR-TR.XML',
      ).replaceFirst(' infoCode="040"', '');
      expect(() => DataModule.parse(xml, file: 'x.xml'), fails('infoCode'));
    });

    test('4.0 öncesi issue reddedilir', () {
      final xml = fixture(
        'DMC-NAYABIKE-AAA-DA2-00-00-00AA-040A-A_001-00_TR-TR.XML',
      ).replaceFirst('S1000D_4-1', 'S1000D_3-0');
      expect(() => DataModule.parse(xml, file: 'x.xml'), fails('3.0'));
    });
  });
}
