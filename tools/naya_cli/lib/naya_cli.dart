import 'package:args/command_runner.dart';

import 'src/pending_command.dart';

/// `naya` komutunu ve alt komutlarını kurar.
CommandRunner<void> buildRunner() {
  return CommandRunner<void>('naya', '.naya dosyalarıyla çalışmak için araç.')
    ..addCommand(
      PendingCommand('pack', 'Bir klasörü .naya dosyasına paketler.'),
    )
    ..addCommand(PendingCommand('unpack', 'Bir .naya dosyasını klasöre açar.'))
    ..addCommand(PendingCommand('validate', 'Bir .naya dosyasını doğrular.'))
    ..addCommand(
      PendingCommand('import', 'S1000D zip dosyasını .naya dosyasına çevirir.'),
    );
}
