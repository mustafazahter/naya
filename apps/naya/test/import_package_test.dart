import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:naya/features/export_naya/file_actions.dart';
import 'package:naya/features/import_zip/import_package.dart';

void main() {
  test('sunucunun tarama raporu okunuyor', () {
    final summary = ImportSummary.fromJson({
      'title': 'Dağ bisikleti bakım el kitabı',
      'issue': '5.0',
      'dataModules': 97,
      'publications': 1,
      'illustrations': 14,
      'parts': 20,
      'faults': 8,
      'systems': [
        {'code': 'DA1', 'title': 'Aktarma organları', 'parts': 6},
      ],
      'unreadable': ['DMC-X.XML: XML okunamadı'],
      'missing': <String>[],
      'skipped': ['BENIOKU.txt'],
    });
    expect(summary.dataModules, 97);
    expect(summary.parts, 20);
    expect(summary.systems.single.code, 'DA1');
    expect(summary.systems.single.parts, 6);
    expect(summary.unreadable, hasLength(1));
    expect(summary.skipped, ['BENIOKU.txt']);
  });

  test('eksik alanlar sıfır ve boş sayılıyor', () {
    final summary = ImportSummary.fromJson({});
    expect(summary.dataModules, 0);
    expect(summary.systems, isEmpty);
    expect(summary.missing, isEmpty);
  });

  test('.naya uzantısı büyük küçük harfe bakmadan tanınıyor', () {
    expect(PickedPackage('Bisiklet.NAYA', Uint8List(0)).isNaya, isTrue);
    expect(PickedPackage('paket.zip', Uint8List(0)).isNaya, isFalse);
  });

  test('başlıktan dosya adı: yasak işaretler çıkar, Türkçe kalır', () {
    expect(
      nayaFileName('Dağ bisikleti bakım el kitabı'),
      'Dağ bisikleti bakım el kitabı.naya',
    );
    expect(nayaFileName('F-16 / Block 60: "uçak"'), 'F-16 Block 60 uçak.naya');
    expect(nayaFileName('  ?? '), 'urun.naya');
  });
}
