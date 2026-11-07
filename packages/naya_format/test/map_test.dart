import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

Matcher get throwsJsonError => throwsA(isA<InvalidJsonException>());

/// Örnek dosyadaki ilk kaydı [edit] ile değiştirir.
Map<String, Object?> editFirst(
  String example,
  String list,
  void Function(Map<String, Object?> item) edit,
) {
  final json = readExample(example);
  edit((json[list]! as List<Object?>).first! as Map<String, Object?>);
  return json;
}

void main() {
  group('dosya içinde', () {
    test('olmayan harita dosyası null döner', () {
      final file = sampleFile()..entries.remove('map/zones.json');
      expect(NayaFile.decode(file.encode()).zones, isNull);
    });

    test('bozuk harita JSON\'u okunurken dosya adını söyler', () {
      final file = sampleFile()
        ..entries['map/parts.json'] = utf8.encode('{bozuk');
      final decoded = NayaFile.decode(file.encode());
      expect(
        () => decoded.parts,
        throwsA(
          isA<InvalidJsonException>().having(
            (e) => e.file,
            'file',
            'map/parts.json',
          ),
        ),
      );
    });
  });

  group('parts.json', () {
    test('aynı kimlik iki kez', () {
      final json = readExample('parts.json');
      final parts = json['parts']! as List<Object?>;
      parts.add(Map<String, Object?>.of(parts.first! as Map<String, Object?>));
      expect(() => PartsFile.fromJson(json), throwsJsonError);
    });

    test('parça kendi üstü olamaz', () {
      final json = {
        'parts': [
          {'id': 'a', 'name': 'A', 'parent': 'a'},
        ],
      };
      expect(() => PartsFile.fromJson(json), throwsJsonError);
    });

    test('uzun döngü de yakalanır', () {
      final json = {
        'parts': [
          {'id': 'a', 'name': 'A', 'parent': 'c'},
          {'id': 'b', 'name': 'B', 'parent': 'a'},
          {'id': 'c', 'name': 'C', 'parent': 'b'},
          {'id': 'd', 'name': 'D'},
        ],
      };
      expect(() => PartsFile.fromJson(json), throwsJsonError);
    });

    test('boş liste geçerli', () {
      expect(PartsFile.fromJson({'parts': <Object?>[]}).roots, isEmpty);
    });

    test('ağaç sorguları', () {
      final parts = PartsFile.fromJson({
        'parts': [
          {'id': 'a', 'name': 'A'},
          {'id': 'a.b', 'name': 'B', 'parent': 'a'},
          {'id': 'a.c', 'name': 'C', 'parent': 'a'},
        ],
      });
      expect(parts.roots.map((p) => p.id), ['a']);
      expect(parts.childrenOf('a').map((p) => p.id), ['a.b', 'a.c']);
      expect(parts.childrenOf('a.b'), isEmpty);
      expect(parts['yok'], isNull);
    });

    test('parçalama yönü üç sayı olmalı', () {
      final json = editFirst('parts.json', 'parts', (p) {
        p['explode'] = {
          'dir': [0, 1],
          'dist': 0.1,
        };
      });
      expect(() => PartsFile.fromJson(json), throwsJsonError);
    });

    test('meshNodes yalnız metin içerir', () {
      final json = editFirst('parts.json', 'parts', (p) {
        p['meshNodes'] = ['zincir', 3];
      });
      expect(() => PartsFile.fromJson(json), throwsJsonError);
    });

    test('procedures değerleri metin olmalı', () {
      final json = editFirst('parts.json', 'parts', (p) {
        p['procedures'] = {'remove': 7};
      });
      expect(() => PartsFile.fromJson(json), throwsJsonError);
    });
  });

  group('faults.json', () {
    for (final severity in [0, 6]) {
      test('önem derecesi $severity reddedilir', () {
        final json = editFirst('faults.json', 'faults', (f) {
          f['severity'] = severity;
        });
        expect(() => FaultsFile.fromJson(json), throwsJsonError);
      });
    }

    test('önem derecesi kesirli olamaz', () {
      final json = editFirst('faults.json', 'faults', (f) {
        f['severity'] = 2.5;
      });
      expect(() => FaultsFile.fromJson(json), throwsJsonError);
    });

    test('"symptoms" listesi eksik', () {
      final json = readExample('faults.json')..remove('symptoms');
      expect(() => FaultsFile.fromJson(json), throwsJsonError);
    });

    test('faultsOf yalnız o parçanın arızalarını verir', () {
      final faults = FaultsFile.fromJson(readExample('faults.json'));
      for (final f in faults.faultsOf('drive.chain')) {
        expect(f.part, 'drive.chain');
      }
      expect(faults.faultsOf('yok'), isEmpty);
    });
  });

  group('hotspots.json ve zones.json', () {
    test('konum üç sayı olmalı', () {
      final json = editFirst('hotspots.json', 'hotspots', (h) {
        h['position'] = [0, 0, 'üst'];
      });
      expect(() => HotspotsFile.fromJson(json), throwsJsonError);
    });

    test('bölge adı eksik', () {
      final json = editFirst('zones.json', 'zones', (z) => z.remove('name'));
      expect(() => ZonesFile.fromJson(json), throwsJsonError);
    });
  });

  test('her harita toJson → fromJson ile aynı kalır', () {
    final parts = PartsFile.fromJson(readExample('parts.json'));
    final faults = FaultsFile.fromJson(readExample('faults.json'));
    final zones = ZonesFile.fromJson(readExample('zones.json'));
    final hotspots = HotspotsFile.fromJson(readExample('hotspots.json'));

    expect(PartsFile.fromJson(parts.toJson()).toJson(), parts.toJson());
    expect(FaultsFile.fromJson(faults.toJson()).toJson(), faults.toJson());
    expect(ZonesFile.fromJson(zones.toJson()).toJson(), zones.toJson());
    expect(
      HotspotsFile.fromJson(hotspots.toJson()).toJson(),
      hotspots.toJson(),
    );
  });
}
