import 'dart:io';

import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

/// S1000D'nin resmi bisiklet örnek verisiyle deneme.
///
/// Veri users.s1000d.org'dan kullanım koşulları kabul edilerek indiriliyor;
/// repoya konmuyor. Açılmış klasörün yolu S1000D_BIKE_DIR ile verilirse
/// koşar, yoksa atlanır:
///
///     S1000D_BIKE_DIR=~/s1000d/bike dart test test/official_bike_test.dart
void main() {
  final dir = Platform.environment['S1000D_BIKE_DIR'];

  test('resmi bisiklet verisinin tamamı okunur', () {
    final files = {
      for (final f in Directory(
        dir!,
      ).listSync(recursive: true).whereType<File>())
        f.path.substring(dir.length + 1): f.readAsBytesSync(),
    };
    final csdb = Csdb.read(files);

    printOnFailure(csdb.problems.join('\n'));
    expect(csdb.problems, isEmpty);
    expect(csdb.dataModules, isNotEmpty);
    expect(csdb.publications, isNotEmpty);
    expect(csdb.snsTree, isNotEmpty);
    expect(csdb.ipd, isNotEmpty);
    expect(csdb.chunks, isNotEmpty);

    stdout.writeln(
      '${csdb.dataModules.length} DM, ${csdb.publications.length} PM, '
      '${csdb.dataModuleLists.length} DML, ${csdb.icns.length} görsel, '
      '${csdb.chunks.length} parça, ${csdb.ipd.length} IPD satırı',
    );
    for (final system in csdb.snsTree) {
      stdout.writeln('${system.code} ${system.title}');
    }
    stdout.writeln('eksik başvuru: ${csdb.missingReferences.length}');
  }, skip: dir == null ? 'S1000D_BIKE_DIR verilmedi' : false);
}
