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

/// [bytes] içinde [from] adını [to] ile değiştirir; ikisi aynı uzunlukta
/// olmalı. [count] verilirse yalnız ilk o kadar geçiş değişir (önce yerel
/// başlık, sonra merkez dizin gelir).
Uint8List renameInZip(Uint8List bytes, String from, String to, {int? count}) {
  final a = utf8.encode(from), b = utf8.encode(to);
  assert(a.length == b.length);
  final out = Uint8List.fromList(bytes);
  var done = 0;
  for (var i = 0; i + a.length <= out.length; i++) {
    if (count != null && done == count) break;
    var match = true;
    for (var j = 0; j < a.length && match; j++) {
      match = out[i + j] == a[j];
    }
    if (match) {
      out.setRange(i, i + b.length, b);
      done++;
    }
  }
  return out;
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

  group('aynı ad', () {
    // archive paketi ZIP yazarken aynı adı tekilleştirdiği için çift kayıt
    // önce iki farklı adla yazılıp sonra baytlarda yeniden adlandırılıyor.
    Uint8List withTwo(String first, String second) {
      return buildZip({
        ...files,
        first: utf8.encode('bir'),
        second: utf8.encode('iki'),
      });
    }

    test('aynı ad iki kez geçerse reddedilir', () {
      final bytes = renameInZip(
        withTwo('media/a.txt', 'media/b.txt'),
        'media/b.txt',
        'media/a.txt',
      );
      expect(
        () => NayaFile.decode(bytes),
        throwsA(
          isA<InvalidContainerException>().having(
            (e) => e.message,
            'message',
            contains('iki kez'),
          ),
        ),
      );
    });

    test('yalnız büyük/küçük harfle ayrışan adlar reddedilir', () {
      final bytes = withTwo('media/a.txt', 'media/A.txt');
      expect(() => NayaFile.decode(bytes), throwsContainer);
    });

    test('yerel başlıktaki ad merkez dizinden farklıysa reddedilir', () {
      final bytes = renameInZip(
        withTwo('media/a.txt', 'media/b.txt'),
        'media/b.txt',
        'media/c.txt',
        count: 1,
      );
      expect(
        () => NayaFile.decode(bytes),
        throwsA(
          isA<InvalidContainerException>().having(
            (e) => e.message,
            'message',
            contains('yerel başlıkta'),
          ),
        ),
      );
    });

    test('yazarken büyük/küçük harf çakışması reddedilir', () {
      final file = sampleFile()..entries['media/Zincir-1.webp'] = Uint8List(1);
      expect(file.encode, throwsContainer);
      final manifest = sampleFile()..entries['NAYA.json'] = Uint8List(1);
      expect(manifest.encode, throwsContainer);
    });
  });
}
