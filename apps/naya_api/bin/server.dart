import 'dart:io';

import 'package:naya_api/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(
    buildHandler(),
    InternetAddress.anyIPv4,
    port,
  );
  stdout.writeln(
    'naya_api http://localhost:${server.port} adresinde çalışıyor',
  );
}
