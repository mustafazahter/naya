import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:naya_format/naya_format.dart';

/// `naya unpack <dosya.naya> -o <klasör>`
class UnpackCommand extends Command<void> {
  UnpackCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Açılacak klasör.',
      mandatory: true,
    );
  }

  @override
  final name = 'unpack';

  @override
  final description = 'Bir .naya dosyasını klasöre açar.';

  @override
  String get invocation => 'naya unpack <dosya.naya> -o <klasör>';

  @override
  void run() {
    final args = argResults!;
    if (args.rest.length != 1) usageException('Tek bir dosya verin.');
    final file = NayaFile.decode(File(args.rest.single).readAsBytesSync());
    final out = Directory(args.option('output')!);
    // Yollar decode sırasında kontrol edildi; klasör dışına yazamazlar.
    file.entries.forEach((path, bytes) {
      File('${out.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    });
    const encoder = JsonEncoder.withIndent('  ');
    File('${out.path}/naya.json')
        .writeAsStringSync('${encoder.convert(file.manifest.toJson())}\n');
    stdout.writeln('${out.path}: ${file.entries.length + 1} dosya');
  }
}
