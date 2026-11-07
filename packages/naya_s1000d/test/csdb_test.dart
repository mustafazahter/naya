import 'dart:convert';

import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final csdb = fixtureCsdb();

  test('bütün dosyalar sorunsuz okunur', () {
    expect(csdb.problems, isEmpty);
    expect(csdb.dataModules, hasLength(7));
    expect(csdb.publications, hasLength(1));
    expect(csdb.dataModuleLists, hasLength(1));
    expect(csdb.icns, hasLength(2));
  });

  test('aynı DM\'in en yüksek sürümü seçilir', () {
    final d = csdb.dataModule(
      DmCode.parse('DMC-NAYABIKE-AAA-D00-00-00-00AA-040A-A'),
    );
    expect(d!.issueNumber, '002');
    expect(csdb.chunks.where((c) => c.text.contains('Eski metin')), isEmpty);
  });

  group('SNS ağacı', () {
    final tree = csdb.snsTree;

    test('sistemler sıralı, başlıklar BREX\'ten', () {
      expect(tree.map((n) => '${n.code} ${n.title}'), [
        'D00 Bisiklet',
        'DA1 Aktarma organları',
        'DA2 Fren sistemi',
      ]);
    });

    test('alt seviyeler ve DM\'ler', () {
      final assy = tree[1].children.single.children.single.children.single;
      expect(assy.code, 'DA1-10-00');
      expect(assy.level, SnsLevel.assembly);
      expect(assy.title, 'Zincir');
      expect(assy.dataModules.single.infoName, 'Sökme');
      expect(tree[2].allDataModules, hasLength(2));
    });

    test('BREX yoksa başlık sistemi anlatan DM\'den', () {
      final noBrex = Csdb.read(
        Map.of(fixtureFiles())..removeWhere((k, _) => k.contains('022A')),
      );
      expect(noBrex.snsTree[2].title, 'Fren sistemi');
      // DA1'i anlatan DM yok; alt sistemi anlatan sökme DM'i var.
      expect(noBrex.snsTree[1].title, isEmpty);
      expect(noBrex.snsTree[1].children.single.title, 'Zincir');
    });
  });

  test('PM bölümleri ve DM sırası', () {
    final pm = csdb.publications.single;
    expect(pm.code, 'PMC-NAYABIKE-C3002-00001-00');
    expect(pm.title, 'Bisiklet bakım el kitabı');
    expect(pm.entries.map((e) => e.title), [
      'Tanım',
      'Bakım',
      'Parça kataloğu',
    ]);
    expect(pm.entries[1].children.map((e) => e.title), [
      'Aktarma organları',
      'Frenler',
    ]);
    expect(pm.entries.first.dmRefs.first.title, 'Bisiklet');
    expect(pm.allDmRefs, hasLength(5));
  });

  test('DML', () {
    final dml = csdb.dataModuleLists.single;
    expect(dml.code, 'DML-NAYABIKE-C3002-S-2026-00001');
    expect(dml.entries, hasLength(7));
    expect(dml.entries.last.issueType, 'deleted');
  });

  test('ICN dosyası', () {
    final icn = csdb.icns['ICN-NAYABIKE-AAA-DA10000-0-C3002-00001-A-001-01']!;
    expect(icn.extension, 'png');
    expect(icn.issueNumber, '001');
    expect(icn.securityClassification, '01');
    expect(icn.path, startsWith('csdb/'));
  });

  test('IPD satırları DM koduyla', () {
    expect(csdb.ipd, hasLength(4));
    expect(csdb.ipd.first.dmc.infoCode, '941');
  });

  test('eksik başvurular: takma DM\'i yok, silinmiş DM sayılmaz', () {
    expect(csdb.missingReferences, [
      'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A → '
          'DMC-NAYABIKE-AAA-DA1-10-00-00AA-720A-A',
    ]);
  });

  test('eksik görsel listelenir', () {
    final files = Map.of(fixtureFiles())
      ..removeWhere((k, _) => k.contains('00002-A'));
    expect(
      Csdb.read(files).missingReferences,
      contains(contains('ICN-NAYABIKE-AAA-D000000-0-C3002-00002-A-001-01')),
    );
  });

  test('bozuk dosyalar okumayı durdurmaz, sorun olarak yazılır', () {
    final files = Map.of(fixtureFiles())
      ..['csdb/DMC-BOZUK-A-D00-00-00-00AA-040A-A.XML'] = utf8.encode('<dmod')
      ..['csdb/PMC-BOZUK.XML'] = utf8.encode('<dmodule/>')
      ..['csdb/DML-BOZUK.XML'] = [0xff, 0xfe, 0x00]
      ..['csdb/okubeni.txt'] = utf8.encode('yok sayılır');
    final read = Csdb.read(files);
    expect(read.dataModules, hasLength(7));
    expect(read.problems.map((p) => p.file), [
      'csdb/DMC-BOZUK-A-D00-00-00-00AA-040A-A.XML',
      'csdb/DML-BOZUK.XML',
      'csdb/PMC-BOZUK.XML',
    ]);
  });

  test('UTF-8 BOM ile başlayan dosya okunur', () {
    const name = 'DMC-NAYABIKE-AAA-DA2-00-00-00AA-040A-A_001-00_TR-TR.XML';
    final read = Csdb.read({
      'csdb/$name': [0xEF, 0xBB, 0xBF, ...utf8.encode(fixture(name))],
    });
    expect(read.problems, isEmpty);
    expect(read.dataModules, hasLength(1));
  });
}
