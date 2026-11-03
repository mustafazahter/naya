import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

void main() {
  test('yazılıp okunan dosya birebir aynı', () {
    final original = sampleFile();
    final decoded = NayaFile.decode(original.encode());

    expect(decoded.entries.keys, unorderedEquals(original.entries.keys));
    for (final name in original.entries.keys) {
      expect(decoded.entries[name], original.entries[name], reason: name);
    }
    final withoutIntegrity = decoded.manifest.withIntegrity(null).toJson();
    expect(withoutIntegrity, original.manifest.withIntegrity(null).toJson());
  });

  test('aynı içerik her seferinde aynı baytları verir', () {
    final first = sampleFile().encode();
    final again = NayaFile.decode(first).encode();
    expect(again, first);
  });

  test('mimetype ilk kayıt ve sıkıştırmasız', () {
    final bytes = sampleFile().encode();
    expect(ascii.decode(bytes.sublist(30, 38)), 'mimetype');
    expect(bytes[8] | bytes[9] << 8, 0, reason: 'sıkıştırma yöntemi');
    expect(
      utf8.decode(bytes.sublist(38, 38 + nayaMimeType.length)),
      nayaMimeType,
    );
  });

  test('bütünlük özetleri yazarken hesaplanır', () {
    final decoded = NayaFile.decode(sampleFile().encode());
    final hashes = decoded.manifest.integrity!.files;
    expect(hashes.keys, unorderedEquals(decoded.entries.keys));
    expect(hashes.values, everyElement(matches(RegExp(r'^[0-9a-f]{64}$'))));
  });

  test('harita dosyaları modellere ayrışır', () {
    final file = NayaFile.decode(sampleFile().encode());
    final parts = file.parts!;
    expect(parts.roots.map((p) => p.id), ['drive', 'brakes']);
    expect(parts.childrenOf('drive').single.name, 'Zincir');
    expect(parts['drive.chain']!.explode!.dir, [0, -1, 0]);
    expect(file.faults!.faultsOf('drive.chain').single.severity, 2);
    expect(file.zones!.zones, hasLength(3));
    expect(file.hotspots!.hotspots.first.position, [0.1, 0.32, 0.0]);
  });
}
