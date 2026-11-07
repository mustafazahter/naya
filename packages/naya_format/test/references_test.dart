import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

/// Örnek dosyanın bir harita dosyasını [edit] ile değiştirip doğrular ve
/// bulunan sorunları döndürür.
List<String> problemsAfter(
  String map,
  void Function(Map<String, Object?> json) edit,
) {
  final json = readExample('$map.json');
  edit(json);
  final file = sampleFile()..putJson('map/$map.json', json);
  try {
    file.validate();
    return [];
  } on InvalidReferencesException catch (e) {
    return e.problems;
  }
}

List<Map<String, Object?>> listOf(Map<String, Object?> json, String key) =>
    (json[key]! as List).cast<Map<String, Object?>>();

void main() {
  test('örnek dosyanın bağları tutarlı', () {
    expect(sampleFile().validate, returnsNormally);
  });

  test('decode bağları kontrol etmez, validate eder', () {
    final file = sampleFile()
      ..putJson('map/hotspots.json', {
        'hotspots': [
          {
            'id': 'h.x',
            'part': 'yok',
            'position': [0, 0, 0],
          },
        ],
      });
    final read = NayaFile.decode(file.encode());
    expect(read.validate, throwsA(isA<InvalidReferencesException>()));
  });

  test('arıza olmayan parçayı gösteriyor', () {
    final problems = problemsAfter('faults', (j) {
      listOf(j, 'faults').first['part'] = 'yok.parca';
    });
    expect(problems, [contains('"yok.parca" yok')]);
  });

  test('etiket noktası olmayan parçayı gösteriyor', () {
    final problems = problemsAfter('hotspots', (j) {
      listOf(j, 'hotspots').first['part'] = 'yok';
    });
    expect(problems.single, contains('map/hotspots.json'));
  });

  test('parça olmayan bölgeyi gösteriyor', () {
    final problems = problemsAfter('parts', (j) {
      listOf(j, 'parts').first['zone'] = 'z.yok';
    });
    expect(problems.single, contains('"z.yok" yok'));
  });

  test('parça görseli dosyada yok', () {
    final problems = problemsAfter('parts', (j) {
      listOf(j, 'parts')[1]['media'] = ['media/yok.webp'];
    });
    expect(problems.single, contains('media/yok.webp'));
  });

  test('bölgenin üstü yok, bölge ağacında döngü var', () {
    final problems = problemsAfter('zones', (j) {
      final zones = listOf(j, 'zones');
      zones[0]['parent'] = 'z.yok';
      zones[1]['parent'] = 'z.rear';
      zones[2]['parent'] = 'z.middle';
    });
    expect(problems, hasLength(3));
    expect(problems.where((p) => p.contains('döngü')), hasLength(2));
  });

  test('aynı kimlik iki kez: bölge, belirti, arıza, nokta', () {
    expect(
      problemsAfter('zones', (j) => listOf(j, 'zones')[1]['id'] = 'z.front'),
      contains(contains('"z.front" bölgesi birden fazla')),
    );
    final faults = problemsAfter('faults', (j) {
      listOf(j, 'symptoms').add({...listOf(j, 'symptoms').first});
      listOf(j, 'faults').add({...listOf(j, 'faults').first});
    });
    expect(faults, hasLength(2));
    expect(
      problemsAfter('hotspots', (j) {
        listOf(j, 'hotspots').add({...listOf(j, 'hotspots').first});
      }),
      hasLength(1),
    );
  });

  test('bütün sorunlar tek hatada listelenir', () {
    final json = readExample('faults.json');
    for (final f in listOf(json, 'faults')) {
      f['part'] = 'yok';
    }
    final file = sampleFile()
      ..putJson('map/faults.json', json)
      ..entries.remove('map/parts.json')
      ..entries.remove('map/hotspots.json');
    expect(
      file.validate,
      throwsA(
        isA<InvalidReferencesException>().having(
          (e) => e.problems.length,
          'problems',
          listOf(json, 'faults').length,
        ),
      ),
    );
  });

  test('harita dosyası olmayan dosya geçerli', () {
    final file = NayaFile(manifest: sampleFile().manifest);
    expect(file.validate, returnsNormally);
  });
}
