import 'dart:io';

import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

import 'builders.dart';

const _refTo720 =
    'modelIdentCode="X" systemDiffCode="A" systemCode="DA1" '
    'subSystemCode="1" subSubSystemCode="0" assyCode="00" disassyCode="00" '
    'disassyCodeVariant="AA" infoCode="720" infoCodeVariant="A" '
    'itemLocationCode="A"';

DmDocument _parse(String content) => DmDocument.parse(dmXml(content: content));

/// Arıza bulma akışlarının blokları, sırayla.
List<DmBlock> _isolationBlocks(DmDocument doc) => [
  for (final isolation in doc.blocks.whereType<DmIsolation>())
    ...isolation.blocks,
];

void main() {
  group('prosedür', () {
    final doc = _parse('''
<procedure>
  <preliminaryRqmts>
    <reqCondGroup><reqCondNoRef><reqCond>Bisiklet sehpada.</reqCond></reqCondNoRef></reqCondGroup>
    <reqSupportEquips><supportEquipDescrGroup>
      <supportEquipDescr><name>Zincir aparatı</name>
        <identNumber><manufacturerCode>N</manufacturerCode>
          <partAndSerialNumber><partNumber>TL-1</partNumber></partAndSerialNumber>
        </identNumber>
        <reqQuantity unitOfMeasure="EA">1</reqQuantity>
      </supportEquipDescr>
    </supportEquipDescrGroup></reqSupportEquips>
    <reqSupplies><supplyDescrGroup><supplyDescr><name>Zincir yağı</name></supplyDescr></supplyDescrGroup></reqSupplies>
    <reqSpares><noSpares/></reqSpares>
    <reqSafety><safetyRqmts>
      <warning><warningAndCautionPara>Eldiven takın.</warningAndCautionPara></warning>
      <caution><warningAndCautionPara>Kadroyu çizmeyin.</warningAndCautionPara></caution>
    </safetyRqmts></reqSafety>
  </preliminaryRqmts>
  <mainProcedure>
    <proceduralStep><para>Vitesi küçüğe alın.</para>
      <figure><title>Aktarma</title><graphic infoEntityIdent="ICN-X-00001-A-001-01"/></figure>
    </proceduralStep>
    <proceduralStep><title>Pimi çıkarın</title>
      <note><notePara>Pimi tamamen çıkarmayın.</notePara></note>
      <proceduralStep><para>Aparatı takın.</para></proceduralStep>
      <proceduralStep><para>Kolu çevirin.</para></proceduralStep>
    </proceduralStep>
    <proceduralStep><para>Şunları kontrol edin:<randomList>
      <listItem><para>Baklalar</para></listItem>
      <listItem><para>Pimler</para></listItem>
    </randomList></para></proceduralStep>
  </mainProcedure>
  <closeRqmts><reqCondGroup><reqCondDm><reqCond>Sonraki işlem:</reqCond>${dmRefXml(_refTo720)}</reqCondDm></reqCondGroup></closeRqmts>
</procedure>''');

    test('ön koşullar ayrı ayrı okunur', () {
      final r = doc.requirements!;
      expect(r.conditions.single.text, 'Bisiklet sehpada.');
      final tool = r.equipment.single;
      expect(tool.name, 'Zincir aparatı');
      expect(tool.partNumber, 'TL-1');
      expect(tool.manufacturerCode, 'N');
      expect(tool.quantity, '1');
      expect(tool.unit, 'EA');
      expect(r.supplies.single.name, 'Zincir yağı');
      expect(r.spares, isEmpty);
      expect(r.safety.map((s) => s.kind), [
        DmAdmonitionKind.warning,
        DmAdmonitionKind.caution,
      ]);
      expect(r.safety.first.paragraphs, ['Eldiven takın.']);
    });

    test('adımlar iç içe numaralanır', () {
      final steps = doc.blocks.cast<DmStep>();
      expect(steps.map((s) => s.number), ['1', '2', '3']);
      final second = steps.elementAt(1);
      expect(second.title, 'Pimi çıkarın');
      expect(second.blocks.first, isA<DmAdmonition>());
      final inner = second.blocks.whereType<DmStep>();
      expect(inner.map((s) => s.number), ['2.1', '2.2']);
      expect(
        (inner.first.blocks.single as DmParagraph).text.text,
        'Aparatı takın.',
      );
    });

    test('adımdaki çizim ICN ile gelir', () {
      final figure = (doc.blocks.first as DmStep).blocks
          .whereType<DmFigure>()
          .single;
      expect(figure.title, 'Aktarma');
      expect(figure.icns, ['ICN-X-00001-A-001-01']);
    });

    test('paragraf içindeki liste ayrı blok olur', () {
      final blocks = (doc.blocks.last as DmStep).blocks;
      expect((blocks.first as DmParagraph).text.text, 'Şunları kontrol edin:');
      final list = blocks.last as DmList;
      expect(list.ordered, isFalse);
      expect(list.items.map((i) => i.text), ['Baklalar', 'Pimler']);
    });

    test('son işlemdeki başvuru metinden ayrılır', () {
      final close = doc.closing.single as DmParagraph;
      expect(close.text.text, 'Sonraki işlem:');
      expect(close.text.refs.single.infoCode, '720');
    });

    test('başlık bilgisi DataModule ile aynı', () {
      expect(doc.techName, 'Zincir');
      expect(doc.contentType, 'procedure');
      expect(doc.code.toString(), startsWith('DMC-X-A-D00'));
    });
  });

  group('arıza bulma', () {
    final doc = _parse('''
<faultIsolation><faultIsolationProcedure>
  <fault faultCode="X-1"/>
  <faultDescr><descr>Fren tutmuyor.</descr></faultDescr>
  <isolationProcedure>
    <preliminaryRqmts><reqCondGroup><noConds/></reqCondGroup><reqSafety><noSafety/></reqSafety></preliminaryRqmts>
    <isolationMainProcedure>
      <isolationStep id="s1">
        <action>Balatayı ölçün.</action>
        <isolationStepQuestion>0,5 mm'den ince mi?</isolationStepQuestion>
        <isolationStepAnswer><yesNoAnswer><yesAnswer nextActionRefId="e1"/><noAnswer nextActionRefId="s2"/></yesNoAnswer></isolationStepAnswer>
      </isolationStep>
      <isolationStep id="s2">
        <action>Basıncı ölçün.</action>
        <isolationStepQuestion>Basınç kaç?</isolationStepQuestion>
        <isolationStepAnswer><listOfChoices>
          <choice nextActionRefId="e1">2700 hPa üstü</choice>
          <choice nextActionRefId="e2">100 hPa altı</choice>
        </listOfChoices></isolationStepAnswer>
      </isolationStep>
      <isolationProcedureEnd id="e1"><action>Balatayı değiştirin. ${dmRefXml(_refTo720)}</action></isolationProcedureEnd>
      <isolationProcedureEnd id="e2"><action>Servise başvurun.</action></isolationProcedureEnd>
    </isolationMainProcedure>
  </isolationProcedure>
</faultIsolationProcedure></faultIsolation>''');

    test('arıza tanımı en başta', () {
      final section = doc.blocks.first as DmSection;
      expect(section.title, 'Arıza');
      expect(
        (section.blocks.single as DmParagraph).text.text,
        'Fren tutmuyor.',
      );
    });

    test('boş ön koşullar yok sayılır', () {
      expect(doc.requirements, isNull);
    });

    test('evet/hayır cevapları hedefleriyle okunur', () {
      final step = _isolationBlocks(doc).whereType<DmIsolationStep>().first;
      expect(step.number, '1');
      expect(step.action.text, 'Balatayı ölçün.');
      expect(step.question.text, "0,5 mm'den ince mi?");
      expect(step.choices.map((c) => (c.kind, c.target)), [
        (DmAnswerKind.yes, 'e1'),
        (DmAnswerKind.no, 's2'),
      ]);
    });

    test('çoktan seçmeli cevaplar metinleriyle okunur', () {
      final step = _isolationBlocks(doc).whereType<DmIsolationStep>().last;
      expect(step.choices.map((c) => (c.kind, c.label, c.target)), [
        (DmAnswerKind.choice, '2700 hPa üstü', 'e1'),
        (DmAnswerKind.choice, '100 hPa altı', 'e2'),
      ]);
    });

    test('sonuçlar başvurularıyla gelir', () {
      final ends = _isolationBlocks(doc).whereType<DmIsolationEnd>().toList();
      expect(ends.map((e) => e.id), ['e1', 'e2']);
      expect(ends.first.text.text, 'Balatayı değiştirin.');
      expect(ends.first.text.refs.single.infoCode, '720');
      expect(ends.last.text.refs, isEmpty);
    });
  });

  group('zor içerikler', () {
    const step = '<proceduralStep><para>Zinciri sökün.</para></proceduralStep>';

    test('geçerlilik bilgisiyle başlayan içerikte gövde kaybolmaz', () {
      final doc = _parse('''
<referencedApplicGroup><applic><displayText><simplePara>Dağ bisikleti</simplePara></displayText></applic></referencedApplicGroup>
<procedure><mainProcedure>$step</mainProcedure></procedure>''');
      expect(doc.contentType, 'procedure');
      expect(doc.blocks.whereType<DmStep>(), hasLength(1));
      expect(doc.module.chunks, isNotEmpty);
    });

    test('Issue 4.1 uyarı listesi en üstte, prosedür arkasında', () {
      final doc = _parse('''
<warningsAndCautions><warning id="w1"><warningAndCautionPara>Eldiven giyin.</warningAndCautionPara></warning></warningsAndCautions>
<procedure><mainProcedure>$step</mainProcedure></procedure>''');
      expect(doc.contentType, 'procedure');
      final first = doc.blocks.first as DmAdmonition;
      expect(first.kind, DmAdmonitionKind.warning);
      expect(first.paragraphs, ['Eldiven giyin.']);
      expect(doc.blocks.whereType<DmStep>(), hasLength(1));
    });

    test('commonInfo bir bölüm olarak gelir', () {
      final doc = _parse('''
<procedure><commonInfo><para>Genel bilgi metni.</para></commonInfo>
<mainProcedure>$step</mainProcedure></procedure>''');
      final section = doc.blocks.first as DmSection;
      expect(section.title, 'Genel bilgi');
      expect(_flatten(doc), contains('genel bilgi metni.'));
    });

    group('arıza bulma', () {
      final doc = _parse('''
<faultIsolation>
<faultIsolationProcedure><isolationProcedure><isolationMainProcedure>
  <isolationStep>
    <note><notePara>Bisiklet sehpada olmalı.</notePara></note>
    <action>Birinci</action><action>İkinci</action>
  </isolationStep>
  <isolationStep>
    <isolationStepQuestion>Ses var mı?</isolationStepQuestion>
    <isolationStepAnswer><yesNoAnswer><yesAnswer nextActionRefId="yok"/><noAnswer nextActionRefId="son"/></yesNoAnswer></isolationStepAnswer>
  </isolationStep>
  <isolationProcedureEnd id="son"><action>Bitir A</action><action>Bitir B</action></isolationProcedureEnd>
</isolationMainProcedure></isolationProcedure></faultIsolationProcedure>
<faultIsolationProcedure><isolationProcedure><isolationMainProcedure>
  <isolationStep><action>Tekeri çevirin.</action>
    <isolationStepQuestion>Sürtüyor mu?</isolationStepQuestion>
    <isolationStepAnswer><yesNoAnswer><yesAnswer nextActionRefId="e2"/><noAnswer nextActionRefId="e2"/></yesNoAnswer></isolationStepAnswer>
  </isolationStep>
  <isolationProcedureEnd id="e2"><action>Göbeği kontrol edin.</action></isolationProcedureEnd>
</isolationMainProcedure></isolationProcedure></faultIsolationProcedure>
</faultIsolation>''');

      test('her işlem ayrı akış', () {
        final flows = doc.blocks.whereType<DmIsolation>().toList();
        expect(flows, hasLength(2));
        final second = flows.last.blocks.first as DmIsolationStep;
        expect(second.number, '1');
        expect(second.action.text, 'Tekeri çevirin.');
      });

      test('birden çok action ve adımdaki not kaybolmaz', () {
        final step = _isolationBlocks(doc).first as DmIsolationStep;
        expect(step.action.text, 'Birinci\nİkinci');
        expect(step.notes.single.paragraphs, ['Bisiklet sehpada olmalı.']);
        final end = _isolationBlocks(doc).whereType<DmIsolationEnd>().first;
        expect(end.text.text, 'Bitir A\nBitir B');
      });

      test('cevabı olmayan adım sıradakine götürür', () {
        final flow = doc.blocks.whereType<DmIsolation>().first.blocks;
        final first = flow[0] as DmIsolationStep;
        final second = flow[1] as DmIsolationStep;
        expect(first.choices.single.kind, DmAnswerKind.next);
        expect(first.choices.single.target, second.id);
        expect(second.id, isNot(first.id));
      });
    });
  });

  group('tanım', () {
    test('başlıklı bölümler iç içe okunur', () {
      final doc = _parse('''
<description>
  <levelledPara><title>Genel</title><para>Aktarma organları.</para>
    <levelledPara><title>Zincir</title><para>Baklalardan oluşur.</para></levelledPara>
  </levelledPara>
  <figure><title>Görünüm</title><graphic infoEntityIdent="ICN-1"/><graphic infoEntityIdent="ICN-2"/></figure>
</description>''');
      final general = doc.blocks.first as DmSection;
      expect(general.title, 'Genel');
      expect((general.blocks.last as DmSection).title, 'Zincir');
      expect((doc.blocks.last as DmFigure).icns, ['ICN-1', 'ICN-2']);
      expect(doc.requirements, isNull);
      expect(doc.closing, isEmpty);
    });

    test('tanınmayan eleman metniyle paragraf olur', () {
      final doc = _parse(
        '<description><levelledPara><table><tgroup><tbody><row>'
        '<entry>Lastik basıncı</entry><entry>3 bar</entry>'
        '</row></tbody></tgroup></table></levelledPara></description>',
      );
      final section = doc.blocks.single as DmSection;
      expect(
        (section.blocks.single as DmParagraph).text.text,
        'Lastik basıncı 3 bar',
      );
    });

    test('sıralı liste numaralı işaretlenir', () {
      final doc = _parse(
        '<description><levelledPara><sequentialList>'
        '<listItem><para>Bir</para></listItem>'
        '</sequentialList></levelledPara></description>',
      );
      final list = (doc.blocks.single as DmSection).blocks.single as DmList;
      expect(list.ordered, isTrue);
    });
  });

  test('parça kataloğu satırları DataModule ile aynı', () {
    final doc = _parse('''
<illustratedPartsCatalog><catalogSeqNumber figureNumber="01" item="001" indenture="1">
  <itemSeqNumber itemSeqNumberValue="00A"><quantityPerNextHigherAssy>1</quantityPerNextHigherAssy>
    <partRef partNumberValue="NB-1" manufacturerCodeValue="N"/>
    <partSegment><itemIdentData><descrForPart>Kadro</descrForPart></itemIdentData></partSegment>
  </itemSeqNumber>
</catalogSeqNumber></illustratedPartsCatalog>''');
    final catalog = doc.blocks.single as DmCatalog;
    expect(catalog.items.single.name, 'Kadro');
    expect(catalog.items.single.partNumber, 'NB-1');
  });

  test('içeriği olmayan DM boş döner', () {
    final doc = DmDocument.parse(dmXml(content: ''));
    expect(doc.blocks, isEmpty);
    expect(doc.requirements, isNull);
  });

  test('bozuk XML S1000dException fırlatır', () {
    expect(
      () => DmDocument.parse('<dmodule><content>'),
      throwsA(isA<S1000dException>()),
    );
  });

  test('bisiklet şablonunun bütün DM\'leri okunur ve metin kaybolmaz', () {
    final dir = Directory('../../templates/src/bisiklet/csdb');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('DMC-'))
        .toList();
    expect(files, hasLength(26));
    for (final file in files) {
      final doc = DmDocument.parse(file.readAsStringSync());
      final shown = _flatten(doc);
      for (final chunk in doc.module.chunks) {
        for (final word in _words(chunk.text)) {
          expect(
            shown,
            contains(word),
            reason: '${file.uri.pathSegments.last}: "$word" okuyucuda yok',
          );
        }
      }
    }
  });
}

Iterable<String> _words(String text) => RegExp(
  r'[\p{L}\p{N}]{3,}',
  unicode: true,
).allMatches(text.toLowerCase()).map((m) => m[0]!);

/// Okuyucunun ekrana çıkaracağı bütün metin, küçük harfle.
String _flatten(DmDocument doc) {
  final buffer = StringBuffer();
  void blocks(List<DmBlock> list) {
    for (final block in list) {
      switch (block) {
        case DmParagraph(:final text):
          buffer.write(' $text');
        case DmAdmonition(:final paragraphs):
          buffer.write(' ${paragraphs.join(' ')}');
        case DmFigure(:final title):
          buffer.write(' $title');
        case DmList(:final items):
          buffer.write(' ${items.join(' ')}');
        case DmSection(:final title, blocks: final inner):
          buffer.write(' $title');
          blocks(inner);
        case DmStep(:final title, blocks: final inner):
          buffer.write(' ${title ?? ''}');
          blocks(inner);
        case DmIsolation(blocks: final inner):
          blocks(inner);
        case final DmIsolationStep step:
          blocks(step.notes);
          buffer.write(' ${step.action} ${step.question}');
          buffer.write(' ${step.choices.map((c) => c.label).join(' ')}');
        case DmIsolationEnd(:final text):
          buffer.write(' $text');
        case DmCatalog(:final items):
          for (final i in items) {
            buffer.write(
              ' ${i.name} ${i.partNumber ?? ''} ${i.quantity ?? ''}',
            );
          }
      }
    }
  }

  final r = doc.requirements;
  if (r != null) {
    buffer.write(' ${r.conditions.join(' ')}');
    for (final item in [...r.equipment, ...r.supplies, ...r.spares]) {
      buffer.write(
        ' ${item.name} ${item.manufacturerCode ?? ''} '
        '${item.partNumber ?? ''} ${item.quantity}',
      );
    }
    blocks(r.safety);
  }
  blocks(doc.blocks);
  blocks(doc.closing);
  return buffer.toString().toLowerCase();
}
