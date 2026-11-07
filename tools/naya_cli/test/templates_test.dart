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
}
