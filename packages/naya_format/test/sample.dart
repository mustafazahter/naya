import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:naya_format/naya_format.dart';

/// Testlerde kullanılan küçük bir bisiklet dosyası.
NayaFile sampleFile() {
  final file = NayaFile(
    manifest: NayaManifest.fromJson(readExample('naya.json')),
    entries: {
      'csdb/DMC-NAYABIKE-AAA-D00-00-00-00AA-520A-A_001-00_TR-TR.XML': utf8
          .encode('<dmodule><content>Zinciri sökün.</content></dmodule>'),
      'media/zincir-1.webp': Uint8List.fromList(
        List.generate(512, (i) => i % 251),
      ),
    },
  );
  for (final name in ['parts', 'faults', 'zones', 'hotspots']) {
    file.putJson('map/$name.json', readExample('$name.json'));
  }
  return file;
}

Map<String, Object?> readExample(String name) {
  final text = File('../../schemas/examples/$name').readAsStringSync();
  return jsonDecode(text) as Map<String, Object?>;
}

/// `NayaFile.encode` kullanmadan elle ZIP kurar; bozuk dosya senaryoları için.
Uint8List buildZip(
  Map<String, List<int>> files, {
  bool mimetypeFirst = true,
  bool compressMimetype = false,
}) {
  final archive = Archive();
  ArchiveFile mimetype() {
    final data = utf8.encode(nayaMimeType);
    return compressMimetype
        ? ArchiveFile.bytes('mimetype', data)
        : ArchiveFile.noCompress('mimetype', data.length, data);
  }

  if (mimetypeFirst) archive.add(mimetype());
  files.forEach((name, data) => archive.add(ArchiveFile.bytes(name, data)));
  if (!mimetypeFirst) archive.add(mimetype());
  return ZipEncoder().encodeBytes(archive);
}

/// Örnek dosyanın manifestini [edit] ile değiştirip yeniden okur.
/// Bütünlük özetleri değişmez; yalnız manifest elle bozulur.
NayaFile decodeWithManifest(void Function(Map<String, Object?> json) edit) {
  final files = unzip(sampleFile().encode());
  final json =
      jsonDecode(utf8.decode(files['naya.json']!)) as Map<String, Object?>;
  edit(json);
  files['naya.json'] = utf8.encode(jsonEncode(json));
  return NayaFile.decode(buildZip(files));
}

/// Kodlanmış bir dosyayı açıp kayıtlarını ad → bayt olarak verir.
Map<String, List<int>> unzip(List<int> bytes) => {
  for (final f in ZipDecoder().decodeBytes(bytes))
    if (f.name != 'mimetype') f.name: f.content,
};
