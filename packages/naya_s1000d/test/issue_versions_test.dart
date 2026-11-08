import 'dart:convert';

import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:naya_s1000d/src/issue.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'builders.dart';

XmlElement _rootWith(String attribute) =>
    XmlDocument.parse('<dmodule $attribute/>').rootElement;

void main() {
  group('şema adresinden issue', () {
    for (final (folder, expected) in [
      ('S1000D_4-0', '4.0'),
      ('S1000D_4-0-1', '4.0'),
      ('S1000D_4-1', '4.1'),
      ('S1000D_4-2', '4.2'),
      ('S1000D_5-0', '5.0'),
      ('S1000D_6-0', '6.0'),
      ('S1000D_10-12', '10.12'),
    ]) {
      test('$folder → $expected', () {
        expect(issueOf(_rootWith(schemaAttribute(folder))), expected);
      });
    }

    test('şema adresi yoksa null', () {
      expect(issueOf(_rootWith('')), isNull);
    });

    test('tanınmayan şema adresi null', () {
      expect(
        issueOf(
          _rootWith(
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
            'xsi:noNamespaceSchemaLocation="descript.xsd"',
          ),
        ),
        isNull,
      );
    });
  });

  group('desteklenen issue', () {
    for (final (issue, supported) in [
      ('3.0', false),
      ('2.3', false),
      ('4.0', true),
      ('4.2', true),
      ('5.0', true),
      ('6.0', true),
      (null, true),
      ('tanımsız', false),
    ]) {
      test('$issue → $supported', () {
        expect(isSupportedIssue(issue), supported);
      });
    }
  });

  group('DM issue farkları', () {
    for (final folder in [
      'S1000D_4-0',
      'S1000D_4-1',
      'S1000D_4-2',
      'S1000D_5-0',
    ]) {
      test('$folder aynı alanlarla okunur', () {
        final d = DataModule.parse(
          dmXml(rootAttributes: schemaAttribute(folder)),
        );
        expect(d.code.toString(), 'DMC-X-A-D00-00-00-00AA-040A-A');
        expect(d.techName, 'Zincir');
        expect(d.chunks.single.text, 'Metin.');
      });
    }

    test('şema adresi olmayan dosya okunur, issue boş kalır', () {
      expect(DataModule.parse(dmXml()).s1000dIssue, isNull);
    });

    test('desteklenmeyen issue CSDB\'yi durdurmaz', () {
      final csdb = Csdb.read({
        'csdb/DMC-ESKI-A-D00-00-00-00AA-040A-A.XML': utf8.encode(
          dmXml(rootAttributes: schemaAttribute('S1000D_3-0')),
        ),
        'csdb/DMC-X-A-D00-00-00-00AA-040A-A.XML': utf8.encode(dmXml()),
      });
      expect(csdb.dataModules, hasLength(1));
      expect(csdb.problems.single.message, contains('3.0'));
    });

    test('eski IPD: partRef yerine partNumber elemanı', () {
      final d = DataModule.parse(
        dmXml(
          content:
              '<illustratedPartsCatalog><catalogSeqNumber figureNumber="01" '
              'item="001" indenture="1"><itemSeqNumber>'
              '<partNumber>ESKI-1</partNumber>'
              '</itemSeqNumber></catalogSeqNumber></illustratedPartsCatalog>',
        ),
      );
      expect(d.ipdItems.single.partNumber, 'ESKI-1');
    });
  });

  group('aynı DM\'in sürümleri (DM issue numarası)', () {
    String version(String number, String inWork, {String lang = 'tr'}) => dmXml(
      issueInfo: '<issueInfo issueNumber="$number" inWork="$inWork"/>',
      language: '<language languageIsoCode="$lang" countryIsoCode="TR"/>',
    );

    final code = DmCode.parse('DMC-X-A-D00-00-00-00AA-040A-A');

    Csdb read(Iterable<String> xmls) {
      var i = 0;
      return Csdb.read({
        for (final xml in xmls)
          'csdb/DMC-X-A-D00-00-00-00AA-040A-A_${i++}.XML': utf8.encode(xml),
      });
    }

    test('sayısal karşılaştırma: 010, 002\'den yüksek', () {
      final csdb = read([version('002', '00'), version('010', '00')]);
      expect(csdb.dataModule(code)!.issueNumber, '010');
    });

    test('dolgusuz numaralar da sayısal karşılaştırılır', () {
      final csdb = read([version('9', '00'), version('10', '00')]);
      expect(csdb.dataModule(code)!.issueNumber, '10');
    });

    test('aynı issue\'da yüksek inWork kazanır', () {
      final csdb = read([version('001', '02'), version('001', '01')]);
      expect(csdb.dataModule(code)!.inWork, '02');
    });

    test('issue numarası inWork\'ten önce gelir', () {
      final csdb = read([version('002', '00'), version('001', '99')]);
      expect(csdb.dataModule(code)!.issueNumber, '002');
    });

    test('dil verilince o dilin son sürümü', () {
      final csdb = read([
        version('003', '00', lang: 'en'),
        version('001', '00'),
      ]);
      expect(csdb.dataModule(code, language: 'tr-TR')!.issueNumber, '001');
      expect(csdb.dataModule(code, language: 'de-DE'), isNull);
    });

    test('her dil için ayrı son sürüm parça üretir', () {
      final csdb = read([
        version('001', '00', lang: 'en'),
        version('002', '00', lang: 'en'),
        version('001', '00'),
      ]);
      expect(csdb.chunks, hasLength(2));
    });

    test('bulunmayan kod null', () {
      final csdb = read([version('001', '00')]);
      expect(
        csdb.dataModule(DmCode.parse('DMC-Y-A-D00-00-00-00AA-040A-A')),
        isNull,
      );
    });
  });
}
