import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:naya_cli/naya_cli.dart';

Future<void> main(List<String> args) async {
  try {
    await buildRunner().run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  }
}
