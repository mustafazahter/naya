import 'dart:async';
import 'dart:io';

import 'package:naya_api/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final config = ApiConfig.fromEnvironment();
  final api = NayaApi(
    config: config,
    db: NayaDatabase.open(config.databasePath),
  );
  await api.start();

  final server = await shelf_io.serve(
    api.handler,
    InternetAddress.anyIPv4,
    config.port,
  );
  stdout.writeln(
    'naya_api http://localhost:${server.port} adresinde çalışıyor '
    '(veritabanı: ${config.databasePath})',
  );

  // Ctrl+C ya da Komuta'nın durdurma sinyalinde veritabanı düzgün
  // kapansın; WAL dosyası ana dosyaya işlensin.
  final signals = [
    ProcessSignal.sigint,
    if (!Platform.isWindows) ProcessSignal.sigterm,
  ];
  for (final signal in signals) {
    unawaited(
      signal.watch().first.then((_) async {
        await server.close();
        await api.close();
        exit(0);
      }),
    );
  }
}
