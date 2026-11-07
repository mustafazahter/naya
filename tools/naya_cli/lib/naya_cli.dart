import 'package:args/command_runner.dart';

import 'src/pack_command.dart';
import 'src/pending_command.dart';
import 'src/unpack_command.dart';
import 'src/validate_command.dart';

export 'src/glb.dart';
export 'src/pack_command.dart' show packFolder;
export 'src/template_check.dart';

/// `naya` komutunu ve alt komutlarını kurar.
CommandRunner<void> buildRunner() {
  return CommandRunner<void>('naya', '.naya dosyalarıyla çalışmak için araç.')
    ..addCommand(PackCommand())
    ..addCommand(UnpackCommand())
    ..addCommand(ValidateCommand())
    ..addCommand(
      PendingCommand('import', 'S1000D zip dosyasını .naya dosyasına çevirir.'),
    );
}
