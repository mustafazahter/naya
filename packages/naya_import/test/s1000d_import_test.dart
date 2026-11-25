import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:naya_format/naya_format.dart';
import 'package:naya_import/naya_import.dart';
import 'package:test/test.dart';

void main() {
  group('bisiklet şablonunun CSDB\'si', () {
    late Map<String, List<int>> files;
    late ImportResult result;

    setUpAll(() {
      final dir = Directory('../../templates/src/bisiklet/csdb');
      files = {
        for (final f in dir.listSync().whereType<File>())
          f.uri.pathSegments.last: f.readAsBytesSync(),
      };
      result = importS1000dZip(_zip(files), now: DateTime.utc(2026, 11, 26));
    });

    test('her dosya okunuyor ve csdb/ altına olduğu gibi konuyor', () {
      final r = result.report;
      expect(r.unreadable, isEmpty);
      expect(r.skipped, isEmpty);
      expect(
        r.dataModules + r.publications + r.dataModuleLists + r.illustrations,
        files.length,
      );
      for (final e in files.entries) {
        expect(result.file.entries['csdb/${e.key}'], e.value, reason: e.key);
      }
    });

    test('manifest içe aktarılmış dosyayı tarif ediyor', () {
      final m = result.file.manifest;
      expect(m.kind, NayaKind.imported);
      expect(m.id, 'nayabike-ice-aktarma');
      expect(m.title, isNotEmpty);
      expect(m.s1000d!.modelIdentCode, 'NAYABIKE');
      expect(m.s1000d!.issue, '5.0');
      expect(m.s1000d!.entry, startsWith('csdb/PMC-'));
      expect(m.model!.main, 'model/product.glb');
    });

    test('SNS ağacından parçalar, genel bilgi sistemi hariç', () {
      final parts = result.file.parts!.parts;
      expect(parts.length, greaterThan(10));
      expect(parts.where((p) => p.id.startsWith('d00')), isEmpty);
      expect(result.report.systems, isNotEmpty);
      // Her prosedür pakette var olan bir DM'i gösteriyor.
      final codes = {
        for (final name in files.keys)
          if (name.startsWith('DMC-')) name.split('_').first,
      };
      for (final p in parts) {
        for (final dmc in p.procedures.values) {
          expect(codes, contains(dmc), reason: p.id);
        }
      }
    });

    test('arıza bulma DM\'lerinden arızalar ve belirtiler', () {
      final faults = result.file.faults!;
      expect(faults.faults, isNotEmpty);
      expect(faults.symptoms, isNotEmpty);
      for (final f in faults.faults) {
        expect(f.isolation, startsWith('DMC-NAYABIKE-'));
        expect(f.cause, isNotEmpty);
      }
    });

    test('dosya yazılıp tekrar açılınca doğrulamadan geçiyor', () {
      final bytes = result.file.encode();
      final reopened = NayaFile.decode(bytes)..validate();
      expect(reopened.parts!.parts.length, result.file.parts!.parts.length);
      // Aynı girdi aynı baytları veriyor.
      final again = importS1000dZip(
        _zip(files),
        now: DateTime.utc(2026, 11, 26),
      );
      expect(again.file.encode(), bytes);
    });

    test('şematik modelde her yaprak parçanın bir düğümü var', () {
      final parts = result.file.parts!;
      final nodes = _glbNodes(result.file.entries['model/product.glb']!);
      final leaves = [
        for (final p in parts.parts)
          if (parts.childrenOf(p.id).isEmpty) p,
      ];
      for (final leaf in leaves) {
        expect(leaf.meshNodes, hasLength(1));
        expect(nodes, contains(leaf.meshNodes.single));
      }
      // Grup parça, altındaki bütün blokları kapsıyor.
      for (final p in parts.parts) {
        for (final child in parts.childrenOf(p.id)) {
          expect(p.meshNodes, containsAll(child.meshNodes));
        }
      }
      expect(nodes, contains('schematic'));
    });
  });

  group('SNS seviyeleri', () {
    test('sıfır kodlu seviye parça olmuyor, DM\'i üstüne düşüyor', () {
      final result = importS1000dFiles({
        _name('DA1-00-00', '040'): _dm('DA1-00-00', '040', 'Fren sistemi'),
        _name('DA1-10-00', '520'): _dm('DA1-10-00', '520', 'Ön fren'),
        _name('DA1-11-01', '421'): _dm(
          'DA1-11-01',
          '421',
          'Balata',
          body: _isolation(['Fren tutmuyor', 'Frenden ses geliyor']),
        ),
        _name('DA1-11-01', '920'): _dm('DA1-11-01', '920', 'Balata'),
      });
      final parts = {for (final p in result.file.parts!.parts) p.id: p};
      expect(parts.keys, ['da1', 'da1.1', 'da1.11', 'da1.11.01']);
      expect(parts['da1']!.name, 'Fren sistemi');
      expect(parts['da1']!.sns, 'DA1-00');
      expect(parts['da1.1']!.parent, 'da1');
      expect(parts['da1.1']!.sns, 'DA1-10');
      expect(parts['da1.1']!.procedures['remove'], contains('DA1-10-00'));
      expect(parts['da1.11.01']!.parent, 'da1.11');
      expect(parts['da1.11.01']!.procedures.keys, ['isolate', 'replace']);

      final faults = result.file.faults!;
      expect(faults.symptoms.map((s) => s.text), [
        'Fren tutmuyor',
        'Frenden ses geliyor',
      ]);
      expect(faults.faults, hasLength(2));
      expect(faults.faults.first.part, 'da1.11.01');
      expect(faults.faults.first.repair, contains('-920A-'));
    });

    test('yalnız genel bilgi sistemi varsa o da parça oluyor', () {
      final result = importS1000dFiles({
        _name('D00-00-00', '040'): _dm('D00-00-00', '040', 'Genel'),
      });
      expect(result.file.parts!.parts.single.id, 'd00');
      expect(result.report.title, 'Genel');
    });

    test('aynı arıza DM\'inin eski sürümü arızayı ikiletmiyor', () {
      final body = _isolation(['Zincir atlıyor']);
      final result = importS1000dFiles({
        _name('DA2-10-00', '421', issue: '001'): _dm(
          'DA2-10-00',
          '421',
          'Zincir',
          body: body,
          issue: '001',
        ),
        _name('DA2-10-00', '421', issue: '002'): _dm(
          'DA2-10-00',
          '421',
          'Zincir',
          body: body,
          issue: '002',
        ),
      });
      expect(result.file.faults!.faults, hasLength(1));
    });
  });

  group('zip', () {
    test('klasörler ve S1000D olmayan dosyalar', () {
      final zip = _zip({
        'paket/csdb/${_name('DA1-00-00', '040')}': _dm(
          'DA1-00-00',
          '040',
          'Fren',
        ),
        '__MACOSX/paket/._${_name('DA1-00-00', '040')}': [0, 1],
        'paket/BENIOKU.txt': utf8.encode('merhaba'),
      });
      final result = importS1000dZip(zip);
      expect(result.report.dataModules, 1);
      expect(result.report.skipped, hasLength(2));
      expect(
        result.file.entries.keys,
        contains('csdb/${_name('DA1-00-00', '040')}'),
      );
    });

    test('DM yoksa açıklayıcı hata', () {
      expect(
        () => importS1000dZip(_zip({'a.txt': utf8.encode('x')})),
        throwsA(
          isA<ImportException>().having((e) => e.code, 'code', 'no_modules'),
        ),
      );
    });

    test('zip olmayan dosya', () {
      expect(
        () => importS1000dZip(utf8.encode('zip değil')),
        throwsA(
          isA<ImportException>().having((e) => e.code, 'code', 'invalid_zip'),
        ),
      );
    });

    test('okunamayan DM rapora yazılıyor, diğerleri alınıyor', () {
      final result = importS1000dFiles({
        _name('DA1-00-00', '040'): _dm('DA1-00-00', '040', 'Fren'),
        _name('DA1-10-00', '520'): utf8.encode('<dmodule><bozuk'),
      });
      expect(result.report.dataModules, 1);
      expect(result.report.unreadable, hasLength(1));
    });
  });

  test('bilgi kodundan prosedür türü', () {
    expect(procedureKind('421'), 'isolate');
    expect(procedureKind('310'), 'inspect');
    expect(procedureKind('361'), 'measure');
    expect(procedureKind('271'), 'adjust');
    expect(procedureKind('241'), 'lubricate');
    expect(procedureKind('210'), 'refill');
    expect(procedureKind('250'), 'clean');
    expect(procedureKind('520'), 'remove');
    expect(procedureKind('720'), 'install');
    expect(procedureKind('920'), 'replace');
    expect(procedureKind('040'), isNull);
    expect(procedureKind('941'), isNull);
    expect(procedureKind('abc'), isNull);
  });
}

Uint8List _zip(Map<String, List<int>> files) {
  final archive = Archive();
  for (final e in files.entries) {
    archive.add(ArchiveFile.bytes(e.key, e.value));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// `DA1-10-00` gibi SNS ve bilgi kodundan DM dosya adı.
String _name(String sns, String info, {String issue = '001'}) =>
    'DMC-TEST-A-$sns-00A-${info}A-A_$issue-00_TR-TR.XML';

List<int> _dm(
  String sns,
  String info,
  String techName, {
  String? body,
  String issue = '001',
}) {
  final [system, subs, assy] = sns.split('-');
  final xml =
      '''
<dmodule xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.s1000d.org/S1000D_5-0/xml_schema_flat/descript.xsd">
  <identAndStatusSection><dmAddress>
    <dmIdent>
      <dmCode modelIdentCode="TEST" systemDiffCode="A" systemCode="$system" subSystemCode="${subs[0]}" subSubSystemCode="${subs[1]}" assyCode="$assy" disassyCode="00" disassyCodeVariant="A" infoCode="$info" infoCodeVariant="A" itemLocationCode="A"/>
      <issueInfo issueNumber="$issue" inWork="00"/>
      <language languageIsoCode="tr" countryIsoCode="TR"/>
    </dmIdent>
    <dmAddressItems><issueDate year="2026" month="11" day="26"/><dmTitle><techName>$techName</techName></dmTitle></dmAddressItems>
  </dmAddress><dmStatus/></identAndStatusSection>
  <content>${body ?? '<description><levelledPara><para>Metin.</para></levelledPara></description>'}</content>
</dmodule>''';
  return utf8.encode(xml);
}

String _isolation(List<String> descriptions) =>
    '<faultIsolation>${[for (final d in descriptions) '<faultIsolationProcedure><fault/><faultDescr><descr>$d</descr>'
          '</faultDescr><isolationProcedure><isolationProcedureEnd>'
          '<action>Bitti.</action></isolationProcedureEnd>'
          '</isolationProcedure></faultIsolationProcedure>'].join()}</faultIsolation>';

/// GLB'deki düğüm adları.
Set<String> _glbNodes(List<int> bytes) {
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  expect(data.getUint32(0, Endian.little), 0x46546C67);
  expect(data.getUint32(8, Endian.little), bytes.length);
  final length = data.getUint32(12, Endian.little);
  final json = jsonDecode(
    utf8.decode(bytes.sublist(20, 20 + length)),
  ) as Map<String, Object?>;
  return {
    for (final n in json['nodes']! as List<Object?>)
      (n! as Map<String, Object?>)['name']! as String,
  };
}
