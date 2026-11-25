import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:naya_import/naya_import.dart';

/// `naya import <paket.zip> -o <dosya.naya>`
///
/// Sunucudaki içe aktarmayla aynı kodu kullanır; ne bulunduğunu yazar.
class ImportCommand extends Command<void> {
  ImportCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Yazılacak .naya dosyası.',
      mandatory: true,
    );
  }

  @override
  final name = 'import';

  @override
  final description = 'S1000D zip dosyasını .naya dosyasına çevirir.';

  @override
  String get invocation => 'naya import <paket.zip> -o <dosya.naya>';

  @override
  void run() {
    final args = argResults!;
    if (args.rest.length != 1) usageException('Tek bir zip dosyası verin.');
    final ImportResult result;
    try {
      result = importS1000dZip(File(args.rest.single).readAsBytesSync());
    } on ImportException catch (e) {
      stderr.writeln(e.message);
      exitCode = 1;
      return;
    }
    final out = File(args.option('output')!);
    final bytes = result.file.encode();
    out.writeAsBytesSync(bytes);

    final r = result.report;
    stdout
      ..writeln('${r.title} (${r.modelIdentCode}, S1000D ${r.issue})')
      ..writeln(
        '${r.dataModules} DM, ${r.publications} PM, ${r.dataModuleLists} DML, '
        '${r.illustrations} çizim',
      )
      ..writeln('${r.parts} parça, ${r.faults} arıza');
    for (final s in r.systems) {
      stdout.writeln('  ${s.code} ${s.title} (${s.parts} alt parça)');
    }
    void list(String title, List<String> items) {
      if (items.isEmpty) return;
      stdout.writeln('$title (${items.length}):');
      for (final item in items.take(10)) {
        stdout.writeln('  $item');
      }
      if (items.length > 10) stdout.writeln('  …');
    }

    list('Okunamayan', r.unreadable);
    list('Eksik başvuru', r.missing);
    list('Atlanan', r.skipped);
    stdout.writeln('${out.path}: ${(bytes.length / 1024).round()} KB');
  }
}
