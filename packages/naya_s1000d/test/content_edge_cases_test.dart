import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

import 'builders.dart';

DataModule _withContent(String content) =>
    DataModule.parse(dmXml(content: content));

String _para(String inner) => _withContent(
  '<description><levelledPara><para>$inner</para></levelledPara>'
  '</description>',
).chunks.single.text;

void main() {
  group('metin', () {
    test('satır içi elemandan sonra Türkçe ek ayrılmaz', () {
      expect(_para("<emphasis>zincir</emphasis>'in"), "zincir'in");
      expect(_para('<emphasis>zincir</emphasis>i takın.'), 'zinciri takın.');
    });

    test('alt ve üst simge kelimeyi bölmez', () {
      expect(_para('H<subScript>2</subScript>O'), 'H2O');
      expect(_para('10<superScript>3</superScript> Pa'), '103 Pa');
    });

    test('blok elemanlar yapışmaz', () {
      final text = _withContent(
        '<description><levelledPara><para>Bir</para><para>İki</para>'
        '</levelledPara></description>',
      ).chunks.single.text;
      expect(text, 'Bir İki');
    });

    test('satır sonları ve fazla boşluk teke iner', () {
      expect(_para('  bir\n\t  iki   üç  '), 'bir iki üç');
    });

    test('CDATA metne katılır', () {
      expect(_para('<![CDATA[a < b]]>'), 'a < b');
    });

    test('hazır varlıklar çözülür', () {
      expect(_para('a &lt; b &amp; c'), 'a < b & c');
    });
  });

  group('tanım', () {
    test('levelledPara yoksa tek parça', () {
      final d = _withContent('<description><para>Düz</para></description>');
      expect(d.chunks.single.section, '');
      expect(d.chunks.single.text, 'Düz');
    });

    test('boş paragraflar parça üretmez', () {
      final d = _withContent(
        '<description><levelledPara><title>Boş</title></levelledPara>'
        '<levelledPara><para>Dolu</para></levelledPara></description>',
      );
      expect(d.chunks.single.text, 'Dolu');
    });

    test('başlıksız ara seviye bölüm yoluna girmez', () {
      final d = _withContent(
        '<description><levelledPara><para>Üst</para>'
        '<levelledPara><title>Alt</title><para>Metin</para></levelledPara>'
        '</levelledPara></description>',
      );
      expect(d.chunks.map((c) => c.section), ['', 'Alt']);
    });
  });

  group('prosedür', () {
    test('mainProcedure yoksa yalnız ön koşullar', () {
      final d = _withContent(
        '<procedure><preliminaryRqmts><para>Hazır</para></preliminaryRqmts>'
        '</procedure>',
      );
      expect(d.chunks.map((c) => c.section), ['Ön koşullar']);
    });

    test('adım numarası boş adımda da ilerler', () {
      final d = _withContent(
        '<procedure><mainProcedure>'
        '<proceduralStep/>'
        '<proceduralStep><para>İkinci</para></proceduralStep>'
        '</mainProcedure></procedure>',
      );
      expect(d.chunks.single.section, 'Adım 2');
    });

    test('takım numarası parça numarası sayılmaz', () {
      final d = _withContent(
        '<procedure><preliminaryRqmts><supportEquipDescr><identNumber>'
        '<partAndSerialNumber><partNumber>TAKIM-1</partNumber>'
        '</partAndSerialNumber></identNumber></supportEquipDescr>'
        '<para>Hazır</para></preliminaryRqmts></procedure>',
      );
      expect(d.chunks.single.partNumbers, isEmpty);
    });

    test('aynı parça numarası bir kez yazılır', () {
      final d = _withContent(
        '<procedure><mainProcedure><proceduralStep><para>'
        '<partRef partNumberValue="P1"/>a <partRef partNumberValue="P1"/>'
        '</para></proceduralStep></mainProcedure></procedure>',
      );
      expect(d.chunks.single.partNumbers, ['P1']);
    });
  });

  group('arıza bulma', () {
    test('prosedür elemanı yoksa içerik tek parça', () {
      final d = _withContent(
        '<faultIsolation><para>Düz</para></faultIsolation>',
      );
      expect(d.chunks.single.section, '');
    });

    test('birden çok prosedürde adım numarası baştan başlar', () {
      String procedure(String text) =>
          '<faultIsolationProcedure><isolationProcedure>'
          '<isolationMainProcedure><isolationStep><para>$text</para>'
          '</isolationStep></isolationMainProcedure></isolationProcedure>'
          '</faultIsolationProcedure>';
      final d = _withContent(
        '<faultIsolation>${procedure('A')}${procedure('B')}</faultIsolation>',
      );
      expect(d.chunks.map((c) => c.section), ['Adım 1', 'Adım 1']);
    });
  });

  group('IPD', () {
    String catalog(String attributes, String inner) =>
        '<illustratedPartsCatalog><catalogSeqNumber $attributes>$inner'
        '</catalogSeqNumber></illustratedPartsCatalog>';

    test('öznitelikler yoksa varsayılanlar', () {
      final item = _withContent(catalog('', '<itemSeqNumber/>'))
          .ipdItems
          .single;
      expect(item.figure, '');
      expect(item.item, '');
      expect(item.indenture, 1);
      expect(item.name, '');
      expect(item.partNumber, isNull);
      expect(item.manufacturerCode, isNull);
      expect(item.quantity, isNull);
    });

    test('sayı olmayan girinti 1 sayılır', () {
      final item = _withContent(catalog('indenture="A"', '<itemSeqNumber/>'))
          .ipdItems
          .single;
      expect(item.indenture, 1);
    });

    test('itemSeqNumber yoksa satır çıkmaz', () {
      expect(_withContent(catalog('', '')).ipdItems, isEmpty);
    });

    test('katalog olmayan DM\'de catalogSeqNumber satır üretmez', () {
      final d = _withContent(
        '<description><catalogSeqNumber><itemSeqNumber/></catalogSeqNumber>'
        '<para>Metin</para></description>',
      );
      expect(d.ipdItems, isEmpty);
    });
  });

  test('bilinmeyen içerik türü tek parça olur', () {
    final d = _withContent('<crew><para>Sürücü</para></crew>');
    expect(d.contentType, 'crew');
    expect(d.chunks.single.section, '');
    expect(d.chunks.single.text, 'Sürücü');
  });

  group('SNS', () {
    DataModule dmAt(
      String system,
      String sub,
      String subSub,
      String assy,
      String name,
    ) => DataModule.parse(
      dmXml(
        title: '<dmTitle><techName>$name</techName></dmTitle>',
        code:
            '<dmCode modelIdentCode="X" systemDiffCode="A" '
            'systemCode="$system" subSystemCode="$sub" '
            'subSubSystemCode="$subSub" assyCode="$assy" disassyCode="00" '
            'disassyCodeVariant="AA" infoCode="040" infoCodeVariant="A" '
            'itemLocationCode="A"/>',
      ),
    );

    test('DM kodu hangi seviyede sıfırlanıyorsa o seviyeyi anlatır', () {
      final tree = buildSnsTree([
        dmAt('DA1', '0', '0', '00', 'Sistem'),
        dmAt('DA1', '1', '0', '00', 'Alt sistem'),
        dmAt('DA1', '1', '1', '00', 'Alt alt sistem'),
        dmAt('DA1', '1', '1', '10', 'Montaj'),
      ]);
      final system = tree.single;
      expect(system.title, 'Sistem');
      final sub = system.children.singleWhere((c) => c.code == 'DA1-1');
      expect(sub.title, 'Alt sistem');
      final subSub = sub.children.singleWhere((c) => c.code == 'DA1-11');
      expect(subSub.title, 'Alt alt sistem');
      final assy = subSub.children.singleWhere((c) => c.code == 'DA1-11-10');
      expect(assy.title, 'Montaj');
      expect(assy.level, SnsLevel.assembly);
      expect(system.allDataModules, hasLength(4));
    });

    test('dört haneli sıfır montaj kodu da üst seviyeyi anlatır', () {
      final tree = buildSnsTree([dmAt('DA1', '0', '0', '0000', 'Sistem')]);
      expect(tree.single.title, 'Sistem');
    });

    test('bozuk BREX yok sayılır', () {
      expect(snsTitles('<dmodule'), isEmpty);
      final tree = buildSnsTree([
        dmAt('DA1', '0', '0', '00', 'DM başlığı'),
      ], brexXml: '<dmodule');
      expect(tree.single.title, 'DM başlığı');
    });

    test('snsRules olmayan BREX başlık vermez', () {
      expect(snsTitles('<dmodule/>'), isEmpty);
    });

    test('BREX\'te boş başlık DM başlığını ezmez', () {
      const brex =
          '<snsRules><snsSystem><snsCode>DA1</snsCode><snsTitle/></snsSystem>'
          '</snsRules>';
      final tree = buildSnsTree([
        dmAt('DA1', '0', '0', '00', 'DM başlığı'),
      ], brexXml: brex);
      expect(tree.single.title, 'DM başlığı');
    });
  });
}
