import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

import 'sample.dart';

JsonSchema schema(String name) {
  final text = File('../../schemas/$name.schema.json').readAsStringSync();
  return JsonSchema.create(jsonDecode(text) as Object);
}

void expectValid(String name, Object? json) {
  final result = schema(name).validate(json);
  expect(result.errors, isEmpty, reason: '$name: ${result.errors.join(', ')}');
}

void main() {
  const examples = {
    'naya': 'naya.json',
    'parts': 'parts.json',
    'faults': 'faults.json',
    'zones': 'zones.json',
    'hotspots': 'hotspots.json',
  };

  examples.forEach((name, example) {
    test('$example şemaya uyuyor', () {
      expectValid(name, readExample(example));
    });
  });

  test('yazılan dosyanın tamamı şemalara uyuyor', () {
    final file = NayaFile.decode(sampleFile().encode());
    expectValid('naya', file.manifest.toJson());
    expectValid('parts', file.parts!.toJson());
    expectValid('faults', file.faults!.toJson());
    expectValid('zones', file.zones!.toJson());
    expectValid('hotspots', file.hotspots!.toJson());
  });

  test('şema hatalı dosyayı yakalar', () {
    final json = readExample('faults.json');
    ((json['faults']! as List<Object?>).first!
            as Map<String, Object?>)['severity'] =
        9;
    expect(schema('faults').validate(json).isValid, isFalse);
  });

  const required = {
    'naya': ['format', 'formatVersion', 'id', 'kind', 'language', 'title'],
    'parts': ['parts'],
    'faults': ['symptoms', 'faults'],
    'zones': ['zones'],
    'hotspots': ['hotspots'],
  };
  required.forEach((name, fields) {
    for (final field in fields) {
      test('$name şeması "$field" alanı olmayan dosyayı reddeder', () {
        final json = readExample(examples[name]!)..remove(field);
        expect(schema(name).validate(json).isValid, isFalse);
      });
    }
  });

  // 1.x içinde eklenecek yeni alanlar eski okuyucuda yok sayılır; Dart
  // okuyucu da şema da bu yüzden bilinmeyen alanı kabul eder.
  test('bilinmeyen alanlar şemadan geçer (ileri uyum)', () {
    final manifest = readExample('naya.json')..['yeniAlan'] = 1;
    expectValid('naya', manifest);
    final parts = readExample('parts.json');
    ((parts['parts']! as List).first as Map<String, Object?>)['yeni'] = 'x';
    expectValid('parts', parts);
  });

  test('isteğe bağlı alanları olmayan manifest şemaya uyar', () {
    final file = NayaFile(
      manifest: const NayaManifest(
        id: 'kucuk',
        kind: NayaKind.user,
        title: 'Küçük',
      ),
    );
    expectValid('naya', NayaFile.decode(file.encode()).manifest.toJson());
  });

  test('2.x manifest şemaya uymaz', () {
    final json = readExample('naya.json')..['formatVersion'] = '2.0.0';
    expect(schema('naya').validate(json).isValid, isFalse);
  });
}
