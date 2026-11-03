import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

void main() {
  late Map<String, List<int>> files;

  setUp(() => files = unzip(sampleFile().encode()));

  Map<String, Object?> manifestJson() =>
      jsonDecode(utf8.decode(files['naya.json']!)) as Map<String, Object?>;

  void setManifest(Map<String, Object?> json) =>
      files['naya.json'] = utf8.encode(jsonEncode(json));

  group('bütünlük', () {
    test('içeriği değişen dosya yakalanır', () {
      files['media/zincir-1.webp'] = [...files['media/zincir-1.webp']!]
        ..[0] ^= 1;
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<IntegrityException>()),
      );
    });

    test('sonradan eklenen dosya yakalanır', () {
      files['media/fazla.webp'] = [1, 2, 3];
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<IntegrityException>()),
      );
    });

    test('silinen dosya yakalanır', () {
      files.remove('map/zones.json');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<IntegrityException>()),
      );
    });
  });

  group('sürüm', () {
    test('farklı ana sürüm reddedilir', () {
      setManifest(manifestJson()..['formatVersion'] = '2.0.0');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(
          isA<UnsupportedVersionException>().having(
            (e) => e.version,
            'version',
            '2.0.0',
          ),
        ),
      );
    });

    test('aynı ana sürümün yenisi okunur', () {
      setManifest(manifestJson()..['formatVersion'] = '1.4.0');
      expect(NayaFile.decode(buildZip(files)).manifest.formatVersion, '1.4.0');
    });

    test('sürüm biçimi bozuksa manifest hatası verir', () {
      setManifest(manifestJson()..['formatVersion'] = 'bir');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<InvalidJsonException>()),
      );
    });
  });

  group('kap', () {
    test('ZIP olmayan bayt dizisi', () {
      expect(
        () => NayaFile.decode(utf8.encode('merhaba')),
        throwsA(isA<InvalidContainerException>()),
      );
    });

    test('mimetype ilk kayıt değilse', () {
      expect(
        () => NayaFile.decode(buildZip(files, mimetypeFirst: false)),
        throwsA(isA<InvalidContainerException>()),
      );
    });

    test('mimetype sıkıştırılmışsa', () {
      expect(
        () => NayaFile.decode(buildZip(files, compressMimetype: true)),
        throwsA(isA<InvalidContainerException>()),
      );
    });

    test('naya.json yoksa', () {
      files.remove('naya.json');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<InvalidContainerException>()),
      );
    });

    test('arşiv dışına çıkan yol', () {
      final file = sampleFile()..entries['../disari.txt'] = utf8.encode('x');
      expect(file.encode, throwsA(isA<InvalidContainerException>()));
    });
  });

  group('manifest', () {
    test('eksik alan hangi alan olduğunu söyler', () {
      setManifest(manifestJson()..remove('title'));
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(
          isA<InvalidJsonException>().having(
            (e) => e.message,
            'message',
            contains('"title"'),
          ),
        ),
      );
    });

    test('bilinmeyen tür', () {
      setManifest(manifestJson()..['kind'] = 'demo');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<InvalidJsonException>()),
      );
    });
  });

  group('harita', () {
    test('üstü olmayan parça', () {
      final json = readExample('parts.json');
      ((json['parts']! as List<Object?>)[1]!
              as Map<String, Object?>)['parent'] =
          'yok';
      expect(
        () => PartsFile.fromJson(json),
        throwsA(isA<InvalidJsonException>()),
      );
    });

    test('montaj ağacında döngü', () {
      final json = {
        'parts': [
          {'id': 'a', 'name': 'A', 'parent': 'b'},
          {'id': 'b', 'name': 'B', 'parent': 'a'},
        ],
      };
      expect(
        () => PartsFile.fromJson(json),
        throwsA(isA<InvalidJsonException>()),
      );
    });

    test('tanımsız belirtiye bağlı arıza', () {
      final json = readExample('faults.json');
      (json['symptoms']! as List<Object?>).removeAt(0);
      expect(
        () => FaultsFile.fromJson(json),
        throwsA(isA<InvalidJsonException>()),
      );
    });
  });
}
