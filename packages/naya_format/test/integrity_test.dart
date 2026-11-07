import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

Map<String, Object?> hashesOf(Map<String, Object?> manifest) =>
    (manifest['integrity']! as Map<String, Object?>)['files']!
        as Map<String, Object?>;

void main() {
  test('"integrity" alanı yoksa dosya okunmaz', () {
    expect(
      () => decodeWithManifest((m) => m.remove('integrity')),
      throwsA(isA<IntegrityException>()),
    );
  });

  test('büyük harfli özet de kabul edilir', () {
    final file = decodeWithManifest(
      (m) => hashesOf(m).updateAll((_, v) => (v! as String).toUpperCase()),
    );
    expect(file.entries, isNotEmpty);
  });

  test('bütün sorunlar tek hatada listelenir', () {
    final files = unzip(sampleFile().encode());
    files['media/zincir-1.webp'] = [...files['media/zincir-1.webp']!]..[0] ^= 1;
    files.remove('map/zones.json');
    files['media/fazla.webp'] = [1];

    expect(
      () => NayaFile.decode(buildZip(files)),
      throwsA(
        isA<IntegrityException>().having(
          (e) => e.problems,
          'problems',
          unorderedEquals([
            'media/zincir-1.webp değiştirilmiş',
            'map/zones.json eksik',
            'media/fazla.webp manifestte kayıtlı değil',
          ]),
        ),
      ),
    );
  });

  test('manifest kendini ya da mimetype\'ı listeleyemez', () {
    // Bu iki dosya entries'te tutulmadığı için listede görünürlerse
    // "eksik" sayılırlar.
    expect(
      () => decodeWithManifest((m) => hashesOf(m)['naya.json'] = 'aa'),
      throwsA(isA<IntegrityException>()),
    );
  });

  test('yazarken eski özetler kullanılmaz', () {
    final file = NayaFile.decode(sampleFile().encode());
    file.entries['media/zincir-1.webp'] = utf8.encode('yeni görsel');
    // Manifest hâlâ eski özeti taşıyor; encode yenisini hesaplamalı.
    final again = NayaFile.decode(file.encode());
    expect(again.entries['media/zincir-1.webp'], utf8.encode('yeni görsel'));
  });

  test('silinen kayıt yazarken listeden de çıkar', () {
    final file = NayaFile.decode(sampleFile().encode());
    file.entries.remove('map/hotspots.json');
    final again = NayaFile.decode(file.encode());
    expect(
      again.manifest.integrity!.files,
      isNot(contains('map/hotspots.json')),
    );
    expect(again.hotspots, isNull);
  });
}
