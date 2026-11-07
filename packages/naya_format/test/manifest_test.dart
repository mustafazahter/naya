import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

/// Hatanın [InvalidJsonException] olduğunu ve mesajında [text] geçtiğini
/// bekler; kullanıcı hangi alanın bozuk olduğunu görebilmeli.
Matcher throwsJsonError(String text) => throwsA(
  isA<InvalidJsonException>().having(
    (e) => e.message,
    'message',
    contains(text),
  ),
);

void main() {
  group('okurken manifest', () {
    test('JSON değil', () {
      final files = unzip(sampleFile().encode())
        ..['naya.json'] = utf8.encode('{"format": ');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsJsonError('JSON okunamadı'),
      );
    });

    test('UTF-8 değil', () {
      final files = unzip(sampleFile().encode())..['naya.json'] = [0xff, 0xfe];
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsA(isA<InvalidJsonException>()),
      );
    });

    test('nesne yerine liste', () {
      final files = unzip(sampleFile().encode())
        ..['naya.json'] = utf8.encode('[]');
      expect(
        () => NayaFile.decode(buildZip(files)),
        throwsJsonError('nesne bekleniyordu'),
      );
    });

    test('"format" naya değil', () {
      expect(
        () => decodeWithManifest((m) => m['format'] = 'epub'),
        throwsJsonError('"format"'),
      );
    });

    test('alan yanlış tipte', () {
      expect(
        () => decodeWithManifest((m) => m['title'] = 42),
        throwsJsonError('"title" alanı metin olmalı'),
      );
    });

    test('iç içe alandaki hata yolunu söyler', () {
      expect(
        () => decodeWithManifest(
          (m) => (m['credits']! as List<Object?>).add({'asset': 'x'}),
        ),
        throwsJsonError('credits[1]: "author" alanı eksik'),
      );
    });

    test('"created" tarih değil', () {
      expect(
        () => decodeWithManifest((m) => m['created'] = 'dün'),
        throwsJsonError('"created"'),
      );
    });

    test('desteklenmeyen özet algoritması', () {
      expect(
        () => decodeWithManifest(
          (m) => (m['integrity']! as Map<String, Object?>)['algorithm'] = 'md5',
        ),
        throwsJsonError('md5'),
      );
    });

    test('bilinmeyen alanlar yok sayılır', () {
      final file = decodeWithManifest((m) => m['yeniAlan'] = true);
      expect(file.manifest.title, 'Bisiklet');
    });
  });

  group('alanlar', () {
    test('isteğe bağlı alanlar olmadan okunur', () {
      final manifest = NayaManifest.fromJson({
        'format': 'naya',
        'formatVersion': '1.0.0',
        'id': 'kucuk',
        'kind': 'user',
        'language': 'tr',
        'title': 'Küçük',
      });
      expect(manifest.product, isNull);
      expect(manifest.model, isNull);
      expect(manifest.credits, isEmpty);
      expect(manifest.integrity, isNull);
    });

    test('model birimi ve yukarı ekseni varsayılanlarla dolar', () {
      final json = readExample('naya.json')
        ..['model'] = {'main': 'model/product.glb'};
      final model = NayaManifest.fromJson(json).model!;
      expect(model.units, 'm');
      expect(model.upAxis, 'Y');
      expect(model.details, isEmpty);
    });

    test('her tür adı okunur', () {
      for (final kind in NayaKind.values) {
        final json = readExample('naya.json')..['kind'] = kind.name;
        expect(NayaManifest.fromJson(json).kind, kind);
      }
    });

    test('tarih UTC olarak yazılır', () {
      final json = readExample('naya.json')
        ..['created'] = '2026-11-03T03:00:00+03:00';
      final manifest = NayaManifest.fromJson(json);
      expect(manifest.toJson()['created'], '2026-11-03T00:00:00.000Z');
    });

    test('toJson → fromJson aynı manifesti verir', () {
      final original = NayaManifest.fromJson(readExample('naya.json'));
      final again = NayaManifest.fromJson(original.toJson());
      expect(again.toJson(), original.toJson());
    });
  });

  group('sürüm', () {
    test('ana sürüm ayrıştırılır', () {
      expect(majorVersionOf('1.0.0'), 1);
      expect(majorVersionOf('12.3.4'), 12);
      expect(majorVersionOf('1.0'), isNull);
      expect(majorVersionOf('v1.0.0'), isNull);
      expect(majorVersionOf('1.0.0-beta'), isNull);
      expect(majorVersionOf(''), isNull);
    });

    for (final version in ['0.9.0', '2.0.0', '10.0.0']) {
      test('$version reddedilir', () {
        expect(
          () => decodeWithManifest((m) => m['formatVersion'] = version),
          throwsA(isA<UnsupportedVersionException>()),
        );
      });
    }

    test('yeni sürümde alanlar değişmiş olsa da "yeni sürüm" denir', () {
      // 2.x'te başlık başka bir yere taşınmış olabilir; kullanıcı
      // "bozuk dosya" değil "yeni sürüm" görmeli.
      expect(
        () => decodeWithManifest(
          (m) => m
            ..['formatVersion'] = '2.0.0'
            ..remove('title')
            ..['kind'] = 'yeni-tur',
        ),
        throwsA(isA<UnsupportedVersionException>()),
      );
    });

    test('sürüm alanı yoksa ya da sayıysa manifest hatası', () {
      expect(
        () => decodeWithManifest((m) => m.remove('formatVersion')),
        throwsJsonError('"formatVersion" alanı eksik'),
      );
      expect(
        () => decodeWithManifest((m) => m['formatVersion'] = 1),
        throwsJsonError('"formatVersion" alanı metin olmalı'),
      );
    });

    test('hata mesajı kullanıcıya gösterilebilir', () {
      const e = UnsupportedVersionException('2.1.0');
      expect(e.toString(), contains('2.1.0'));
      expect(e.toString(), contains('1.x'));
    });
  });
}
