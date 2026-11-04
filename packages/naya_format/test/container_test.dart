import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

/// Elle bir ZIP yerel başlığı kurar: yalnız ilk kaydın başı, gerisi yok.
/// Kap kontrolü önce yalnız bu kısma baktığı için yeterli.
Uint8List localHeader({required List<int> name, required List<int> data}) {
  final header = ByteData(30)
    ..setUint32(0, 0x04034b50, Endian.little)
    ..setUint16(8, 0, Endian.little) // sıkıştırma yok
    ..setUint16(26, name.length, Endian.little)
    ..setUint16(28, 0, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(name)
        ..add(data))
      .toBytes();
}

Matcher get throwsContainer => throwsA(isA<InvalidContainerException>());

void main() {
  late Map<String, List<int>> files;

  setUp(() => files = unzip(sampleFile().encode()));

  group('okurken kap', () {
    test('boş bayt dizisi', () {
      expect(() => NayaFile.decode(<int>[]), throwsContainer);
    });

    test('yarıda kesilmiş dosya', () {
      final bytes = sampleFile().encode();
      expect(
        () => NayaFile.decode(bytes.sublist(0, bytes.length ~/ 2)),
        throwsContainer,
      );
    });

    test('mimetype içeriği yanlış', () {
      final archive = Archive()
        ..add(
          ArchiveFile.noCompress(
            'mimetype',
            15,
            utf8.encode('application/zip'),
          ),
        );
      files.forEach((name, data) => archive.add(ArchiveFile.bytes(name, data)));
      expect(
        () => NayaFile.decode(ZipEncoder().encodeBytes(archive)),
        throwsContainer,
      );
    });

    test('ilk kaydın adı bozuk UTF-8 ise yine kap hatası verir', () {
      final bytes = localHeader(
        name: List.filled(8, 0xff),
        data: utf8.encode(nayaMimeType),
      );
      expect(() => NayaFile.decode(bytes), throwsContainer);
    });

    test('başlık doğru ama arşivin geri kalanı yok', () {
      final bytes = localHeader(
        name: utf8.encode('mimetype'),
        data: utf8.encode(nayaMimeType),
      );
      expect(() => NayaFile.decode(bytes), throwsContainer);
    });

    for (final name in ['../disari.txt', 'csdb/../../x', '/etc/passwd']) {
      test('arşiv dışına çıkan yol okunmaz: $name', () {
        files[name] = [1];
        expect(() => NayaFile.decode(buildZip(files)), throwsContainer);
      });
    }
  });

  group('yazarken kap', () {
    for (final name in [
      r'media\zincir.webp',
      'media//zincir.webp',
      'media/./zincir.webp',
      'C:/Windows/x.dll',
    ]) {
      test('geçersiz yol reddedilir: $name', () {
        final file = sampleFile()..entries[name] = Uint8List.fromList([1]);
        expect(file.encode, throwsContainer);
      });
    }

    for (final name in ['naya.json', 'mimetype']) {
      test('$name entries içine konamaz', () {
        final file = sampleFile()..entries[name] = utf8.encode('{}');
        expect(file.encode, throwsContainer);
      });
    }

    test('Türkçe karakterli dosya adı korunur', () {
      const name = 'media/çark-dişlisi-ön.webp';
      final file = sampleFile()..entries[name] = utf8.encode('ğüşiöç');
      final decoded = NayaFile.decode(file.encode());
      expect(decoded.entries[name], utf8.encode('ğüşiöç'));
    });

    test('boş dosya ve boş entries yazılıp okunur', () {
      final empty = NayaFile(manifest: sampleFile().manifest);
      final decoded = NayaFile.decode(empty.encode());
      expect(decoded.entries, isEmpty);
      expect(decoded.manifest.integrity!.files, isEmpty);

      final withEmptyEntry = sampleFile()
        ..entries['media/bos.bin'] = Uint8List(0);
      expect(
        NayaFile.decode(withEmptyEntry.encode()).entries['media/bos.bin'],
        isEmpty,
      );
    });

    test('kayıt sırası entries sırasından bağımsız', () {
      final a = sampleFile();
      final b = NayaFile(
        manifest: a.manifest,
        entries: Map.fromEntries(a.entries.entries.toList().reversed),
      );
      expect(b.encode(), a.encode());
    });
  });
}
