import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:naya_format/naya_format.dart';

import 'template_check.dart';

/// `naya validate <dosya.naya>`
///
/// Sırasıyla: kap ve bütünlük, harita dosyaları arası bağlar, S1000D
/// dosyaları ve harita ile S1000D/model arasındaki bağlar. Hata varsa çıkış
/// kodu 1; yalnız uyarı varsa 0.
class ValidateCommand extends Command<void> {
  @override
  final name = 'validate';

  @override
  final description = 'Bir .naya dosyasını doğrular.';

  @override
  String get invocation => 'naya validate <dosya.naya>';

  @override
  void run() {
    final args = argResults!;
    if (args.rest.length != 1) usageException('Tek bir dosya verin.');
    final path = args.rest.single;

    final CheckReport report;
    try {
      final file = NayaFile.decode(File(path).readAsBytesSync());
      file.validate();
      report = checkContent(file);
    } on NayaFormatException catch (e) {
      stderr.writeln('$path: $e');
      exitCode = 1;
      return;
    }

    for (final w in report.warnings) {
      stdout.writeln('uyarı: $w');
    }
    for (final e in report.errors) {
      stderr.writeln('hata: $e');
    }
    if (report.ok) {
      stdout.writeln('$path: geçerli');
    } else {
      stderr.writeln('$path: ${report.errors.length} hata');
      exitCode = 1;
    }
  }
}
