import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:naya_cli/naya_cli.dart';
import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

/// Yalnız JSON bölümü olan küçük bir GLB.
Uint8List glbWithNodes(List<String> names) {
  List<int> json = utf8.encode(
    jsonEncode({
      'asset': {'version': '2.0'},
      'nodes': [
        for (final n in names) {'name': n},
      ],
    }),
  );
  // JSON bölümü 4 bayta hizalanır; boşlukla doldurulur.
  json = [...json, ...List.filled((4 - json.length % 4) % 4, 0x20)];
  final header = ByteData(20)
    ..setUint32(0, 0x46546C67, Endian.little)
    ..setUint32(4, 2, Endian.little)
    ..setUint32(8, 20 + json.length, Endian.little)
    ..setUint32(12, json.length, Endian.little)
    ..setUint32(16, 0x4E4F534A, Endian.little);
  return Uint8List.fromList([...header.buffer.asUint8List(), ...json]);
}

/// S1000D fixture'larından küçük bir şablon klasörü kurar.
Directory sampleTemplate() {
  final dir = Directory.systemTemp.createTempSync('naya_cli_test');
  final csdb = Directory('../../packages/naya_s1000d/test/fixtures/csdb');
  for (final f in csdb.listSync().whereType<File>()) {
    final target = File('${dir.path}/csdb/${f.uri.pathSegments.last}');
    target.parent.createSync(recursive: true);
    f.copySync(target.path);
  }
  File('${dir.path}/model/product.glb')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(glbWithNodes(['drive_chain', 'frame']));
  File('${dir.path}/naya.json').writeAsStringSync(
    jsonEncode({
      'format': 'naya',
      'formatVersion': '1.0.0',
      'id': 'deneme',
      'kind': 'template',
      'language': 'tr',
      'title': 'Deneme',
      's1000d': {
        'issue': '5.0',
        'modelIdentCode': 'NAYABIKE',
        'entry': 'csdb/PMC-NAYABIKE-C3002-00001-00_001-00_TR-TR.XML',
      },
      'model': {'main': 'model/product.glb'},
    }),
  );
  File('${dir.path}/map/parts.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode({
        'parts': [
          {
            'id': 'drive.chain',
            'name': 'Zincir',
            'meshNodes': ['drive_chain'],
            'procedures': {'remove': 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A'},
          },
        ],
      }),
    );
  File('${dir.path}/README.md').writeAsStringSync('pakete girmez');
  File('${dir.path}/csdb/.DS_Store').writeAsStringSync('gizli');
  return dir;
}

void main() {
  late Directory dir;
  setUp(() => dir = sampleTemplate());
  tearDown(() => dir.deleteSync(recursive: true));

  test('GLB düğüm adları okunur', () {
    expect(glbNodeNames(glbWithNodes(['a', 'b'])), {'a', 'b'});
    expect(() => glbNodeNames([1, 2, 3]), throwsFormatException);
  });

  test('pack yalnız kabın klasörlerini alır, gizli dosyaları atlar', () {
    final file = packFolder(dir);
    expect(file.entries.keys, contains('model/product.glb'));
    expect(file.entries.keys, contains('map/parts.json'));
    expect(file.entries.keys.where((k) => k.contains('README')), isEmpty);
    expect(file.entries.keys.where((k) => k.contains('.DS_Store')), isEmpty);
  });

  test('paketlenen dosya kontrollerden geçer', () {
    final file = NayaFile.decode(packFolder(dir).encode());
    final report = checkContent(file);
    expect(report.errors, isEmpty);
    // Fixture'daki sökme DM'i olmayan takma DM'ini gösteriyor.
    expect(report.warnings, contains(contains('720A')));
  });

  test('olmayan DMC, model düğümü ve S1000D girişi hata verir', () {
    File('${dir.path}/map/parts.json').writeAsStringSync(
      jsonEncode({
        'parts': [
          {
            'id': 'drive.chain',
            'name': 'Zincir',
            'meshNodes': ['yok_dugum'],
            'procedures': {
              'remove': 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-999A-A',
              'install': 'DMC-bozuk',
            },
          },
        ],
      }),
    );
    File('${dir.path}/csdb/PMC-NAYABIKE-C3002-00001-00_001-00_TR-TR.XML')
        .deleteSync();
    final report = checkContent(packFolder(dir));
    expect(report.errors, hasLength(4));
    expect(report.errors, contains(contains('yok_dugum')));
    expect(report.errors, contains(contains('999A')));
    expect(report.errors, contains(contains('geçerli bir DMC değil')));
    expect(report.errors, contains(contains('S1000D girişi')));
  });

  test('pack, unpack ve validate komutları', () async {
    final out = '${dir.path}/cikti/deneme.naya';
    await buildRunner().run(['pack', dir.path, '-o', out]);
    expect(File(out).existsSync(), isTrue);
    await buildRunner().run(['validate', out]);
    expect(exitCode, 0);
    final opened = '${dir.path}/acilan';
    await buildRunner().run(['unpack', out, '-o', opened]);
    expect(File('$opened/naya.json').existsSync(), isTrue);
    expect(File('$opened/model/product.glb').existsSync(), isTrue);
  });
}
