import 'package:args/command_runner.dart';

/// Henüz yazılmamış komutlar için yer tutucu. Komut listesi baştan belli
/// olsun diye kayıtlı; her biri ilgili görevde gerçek koduyla değişecek.
class PendingCommand extends Command<void> {
  PendingCommand(this.name, this.description);

  @override
  final String name;

  @override
  final String description;

  @override
  void run() {
    throw UsageException('"$name" komutu henüz hazır değil.', usage);
  }
}
