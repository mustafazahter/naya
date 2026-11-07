import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:naya_format/naya_format.dart';

/// `naya pack <klasör> -o <dosya.naya>`
///
/// Klasörde `naya.json` ve kabın klasörleri (`csdb/`, `model/`, `map/`,
/// `media/`, `ai/`) bulunur. Bütünlük özetleri paketlerken hesaplanır;
/// klasördeki `naya.json`'da olmalarına gerek yok.
class PackCommand extends Command<void> {
  PackCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Yazılacak .naya dosyası.',
      mandatory: true,
    );
  }

  @override
  final name = 'pack';

  @override
  final description = 'Bir klasörü .naya dosyasına paketler.';

  @override
  String get invocation => 'naya pack <klasör> -o <dosya.naya>';

  /// Kaba giren klasörler; geri kalan her şey (README, betikler) dışarıda
  /// kalır.
  static const folders = ['csdb', 'model', 'map', 'media', 'ai'];

  @override
  void run() {
    final args = argResults!;
    if (args.rest.length != 1) usageException('Tek bir klasör verin.');
    final file = packFolder(Directory(args.rest.single));
    file.validate();
    final output = File(args.option('output')!);
    output.parent.createSync(recursive: true);
    final bytes = file.encode();
    output.writeAsBytesSync(bytes);
    final mb = (bytes.length / 1024 / 1024).toStringAsFixed(1);
    stdout.writeln('${output.path}: ${file.entries.length + 2} kayıt, $mb MB');
  }
}

/// [dir] klasörünü bellekte bir [NayaFile]'a çevirir.
NayaFile packFolder(Directory dir) {
  final manifestFile = File('${dir.path}/naya.json');
  if (!manifestFile.existsSync()) {
    throw UsageException('${manifestFile.path} bulunamadı', '');
  }
  final json = jsonDecode(manifestFile.readAsStringSync());
  final manifest = NayaManifest.fromJson(json);

  final entries = <String, Uint8List>{};
  for (final folder in PackCommand.folders) {
    final sub = Directory('${dir.path}/$folder');
    if (!sub.existsSync()) continue;
    for (final f in sub.listSync(recursive: true).whereType<File>()) {
      final path = f.path.substring(dir.path.length + 1).replaceAll(r'\', '/');
      // macOS'un .DS_Store gibi gizli dosyaları pakete girmesin.
      if (path.split('/').any((s) => s.startsWith('.'))) continue;
      entries[path] = f.readAsBytesSync();
    }
  }
  return NayaFile(manifest: manifest, entries: entries);
}
