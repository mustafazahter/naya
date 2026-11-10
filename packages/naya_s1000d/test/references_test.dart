import 'dart:convert';

import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

import 'builders.dart';

const _otherCode =
    'modelIdentCode="X" systemDiffCode="A" systemCode="DA1" '
    'subSystemCode="1" subSubSystemCode="0" assyCode="00" disassyCode="00" '
    'disassyCodeVariant="AA" infoCode="520" infoCodeVariant="A" '
    'itemLocationCode="A"';
const _self = 'DMC-X-A-D00-00-00-00AA-040A-A';
const _other = 'DMC-X-A-DA1-10-00-00AA-520A-A';

String _description(String inner) =>
    '<description><levelledPara><para>$inner</para></levelledPara>'
    '</description>';

Map<String, List<int>> _withDm(String content) => {
  'csdb/$_self.XML': utf8.encode(dmXml(content: _description(content))),
};

void main() {
  group('DM içinden başvuru', () {
    test('hedef yoksa eksik olarak listelenir', () {
      final csdb = Csdb.read(_withDm(dmRefXml(_otherCode)));
      expect(csdb.problems, isEmpty);
      expect(csdb.missingReferences, ['$_self → $_other']);
    });

    test('hedef varsa listelenmez', () {
      final csdb = Csdb.read({
        ..._withDm(dmRefXml(_otherCode)),
        'csdb/$_other.XML': utf8.encode(dmXml(code: '<dmCode $_otherCode/>')),
      });
      expect(csdb.missingReferences, isEmpty);
    });

    test('aynı DM\'e iki başvuru tek satır', () {
      final ref = dmRefXml(_otherCode);
      final csdb = Csdb.read(_withDm('$ref $ref'));
      expect(csdb.dataModules.single.dmRefs, hasLength(1));
      expect(csdb.missingReferences, hasLength(1));
    });

    test('dmCode\'u olmayan dmRef atlanır', () {
      final d = DataModule.parse(
        dmXml(content: _description('<dmRef><dmRefIdent/></dmRef>')),
      );
      expect(d.dmRefs, isEmpty);
    });

    test('özniteliği eksik dmCode DM\'i sorunlu yapar', () {
      final csdb = Csdb.read(_withDm(dmRefXml('modelIdentCode="X"')));
      expect(csdb.dataModules, isEmpty);
      expect(csdb.problems.single.file, 'csdb/$_self.XML');
    });

    test('kendine başvuran DM eksik sayılmaz', () {
      final csdb = Csdb.read(_withDm(dmRefXml(dmCodeAttributes)));
      expect(csdb.missingReferences, isEmpty);
    });

    test('durum bölümündeki brexDmRef içerik başvurusu sayılmaz', () {
      final d = DataModule.parse(
        dmXml(status: '<brexDmRef>${dmRefXml(_otherCode)}</brexDmRef>'),
      );
      expect(d.dmRefs, isEmpty);
    });

    test('eski sürümün başvurusu sorulmaz, yalnız son sürümünki', () {
      final v1 = dmXml(content: _description(dmRefXml(_otherCode)));
      final v2 = dmXml(issueInfo: '<issueInfo issueNumber="002" inWork="00"/>');
      final csdb = Csdb.read({
        'csdb/${_self}_001.XML': utf8.encode(v1),
        'csdb/${_self}_002.XML': utf8.encode(v2),
      });
      expect(csdb.missingReferences, isEmpty);
    });
  });

  group('PM ve DML başvuruları', () {
    test('PM\'de eksik DM yayın koduyla listelenir', () {
      final csdb = Csdb.read({
        'csdb/PMC-X.XML': utf8.encode(
          pmXml('<pmEntry>${dmRefXml(_otherCode)}</pmEntry>'),
        ),
      });
      expect(csdb.missingReferences, ['PMC-X-C3002-00001-00 → $_other']);
    });

    test('iç içe PM bölümlerindeki başvurular sırayla gelir', () {
      final pm = PublicationModule.parse(
        pmXml(
          '<pmEntry>${dmRefXml(dmCodeAttributes)}'
          '<pmEntry>${dmRefXml(_otherCode)}</pmEntry></pmEntry>',
        ),
      );
      expect(pm.allDmRefs.map((r) => r.code.toString()), [_self, _other]);
    });

    test('DML\'de silinmiş kayıt eksik sayılmaz, diğerleri sayılır', () {
      final csdb = Csdb.read({
        'csdb/DML-X.XML': utf8.encode(
          dmlXml(
            '<dmlEntry issueType="deleted">${dmRefXml(_otherCode)}</dmlEntry>'
            '<dmlEntry issueType="new">${dmRefXml(dmCodeAttributes)}</dmlEntry>',
          ),
        ),
      });
      expect(csdb.missingReferences, ['DML-X-C3002-S-2026-00001 → $_self']);
    });

    test('DM olmayan DML kaydı (PM başvurusu) atlanır', () {
      final dml = DataModuleList.parse(
        dmlXml('<dmlEntry issueType="new"><pmRef/></dmlEntry>'),
      );
      expect(dml.entries, isEmpty);
    });
  });

  group('görsel başvuruları', () {
    const icn = 'ICN-X-00001-001-01';
    String figure(String id) =>
        '<figure><graphic infoEntityIdent="$id"/></figure>';

    test('dosyası yoksa eksik olarak listelenir', () {
      final csdb = Csdb.read(_withDm(figure(icn)));
      expect(csdb.missingReferences, ['$_self → $icn']);
    });

    test('dosya uzantısı ve klasörü başvuruyu etkilemez', () {
      final csdb = Csdb.read({
        ..._withDm(figure(icn)),
        'baska/klasor/$icn.CGM': [0],
      });
      expect(csdb.missingReferences, isEmpty);
    });

    test('symbol ve multimediaObject de görsel sayılır', () {
      final d = DataModule.parse(
        dmXml(
          content: _description(
            '<symbol infoEntityIdent="ICN-A"/>'
            '<multimediaObject infoEntityIdent="ICN-B"/>'
            '<graphic infoEntityIdent="ICN-A"/>',
          ),
        ),
      );
      expect(d.icnRefs, ['ICN-A', 'ICN-B']);
    });
  });

  group('Icn.fromPath', () {
    test('ICN olmayan dosya null', () {
      expect(Icn.fromPath('csdb/DMC-X.XML'), isNull);
    });

    test('uzantısız dosya', () {
      final icn = Icn.fromPath('ICN-X-001-01')!;
      expect(icn.ident, 'ICN-X-001-01');
      expect(icn.extension, '');
      expect(icn.issueNumber, '001');
      expect(icn.securityClassification, '01');
    });

    test('ters bölülü yol', () {
      expect(Icn.fromPath('a\\ICN-X-001-01.png')!.ident, 'ICN-X-001-01');
    });
  });
}
