import 'dart:io';

import 'package:naya_cli/naya_cli.dart';
import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

/// Repodaki şablon kaynakları her değişiklikte paketlenip doğrulanır;
/// bozuk bir DMC ya da olmayan bir model düğümü CI'da yakalanır.
void main() {
  group('bisiklet şablonu', () {
    late NayaFile file;
    late int size;

    setUpAll(() {
      final bytes = packFolder(Directory('../../templates/src/bisiklet'))
          .encode();
      size = bytes.length;
      file = NayaFile.decode(bytes);
    });

    test('bütün kontrollerden uyarısız geçer', () {
      expect(file.validate, returnsNormally);
      final report = checkContent(file);
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
    });

    test('kabul kriteri: 30+ parça, 15+ arıza, 50 MB altı', () {
      expect(file.parts!.parts.length, greaterThanOrEqualTo(30));
      expect(file.faults!.faults.length, greaterThanOrEqualTo(15));
      expect(size, lessThan(50 * 1024 * 1024));
    });

    test('modeldeki her düğüm en az bir parçaya bağlı', () {
      final nodes = glbNodeNames(
        file.entries['model/product.glb']!,
        meshOnly: true,
      );
      final used = {for (final p in file.parts!.parts) ...p.meshNodes};
      expect(nodes.difference(used), isEmpty);
    });

    test('S1000D içeriği okunur ve SNS ağacı BREX başlıklarını taşır', () {
      final csdb = Csdb.read({
        for (final e in file.entries.entries)
          if (e.key.startsWith('csdb/')) e.key: e.value,
      });
      expect(csdb.problems, isEmpty);
      expect(csdb.snsTree.map((n) => n.title), [
        'Bisiklet',
        'Kadro, çatal ve kumanda',
        'Aktarma organları',
        'Fren sistemi',
        'Tekerlekler',
      ]);
      expect(csdb.chunks.length, greaterThan(100));
    });
  });

  group('Corolla şablonu', () {
    late NayaFile file;
    late int size;
    late Csdb csdb;

    setUpAll(() {
      final bytes = packFolder(Directory('../../templates/src/corolla'))
          .encode();
      size = bytes.length;
      file = NayaFile.decode(bytes);
      csdb = Csdb.read({
        for (final e in file.entries.entries)
          if (e.key.startsWith('csdb/')) e.key: e.value,
      });
    });

    test('bütün kontrollerden uyarısız geçer', () {
      expect(file.validate, returnsNormally);
      final report = checkContent(file);
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
    });

    test('kabul kriteri: 30-60 parça, 15-25 arıza, 20-40 DM, 50 MB altı', () {
      expect(file.parts!.parts.length, inInclusiveRange(30, 60));
      expect(file.faults!.faults.length, inInclusiveRange(15, 25));
      expect(csdb.dataModules.length, inInclusiveRange(20, 40));
      expect(size, lessThan(50 * 1024 * 1024));
    });

    test('modeldeki her düğüm en az bir parçaya bağlı', () {
      final nodes = glbNodeNames(
        file.entries['model/product.glb']!,
        meshOnly: true,
      );
      final used = {for (final p in file.parts!.parts) ...p.meshNodes};
      expect(nodes.difference(used), isEmpty);
    });

    test('atıflar manifestte', () {
      expect(file.manifest.credits, hasLength(2));
      expect(
        file.manifest.credits.map((c) => c.license),
        everyElement('CC-BY-4.0'),
      );
    });

    test('S1000D içeriği okunur ve SNS ağacı BREX başlıklarını taşır', () {
      expect(csdb.problems, isEmpty);
      expect(csdb.snsTree.map((n) => n.title), [
        'Araç',
        'Gövde',
        'Motor',
        'Güç aktarma',
        'Fren sistemi',
        'Süspansiyon ve direksiyon',
        'Tekerlekler',
        'Elektrik ve aydınlatma',
      ]);
      expect(csdb.chunks.length, greaterThan(100));
    });
  });
}
