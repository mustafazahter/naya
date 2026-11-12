import 'dart:io';

import 'package:naya_api/server.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late TestServer server;

  setUp(() async => server = await TestServer.start());
  tearDown(() => server.close());

  test('günde bir yedek alınır', () async {
    await server.register('enes@ornek.com');
    final first = await server.api.backups.runIfDue();
    expect(p.basename(first!.path), 'naya-2026-11-12.db');
    expect(await server.api.backups.runIfDue(), isNull);

    server.clock.advance(const Duration(days: 1));
    expect(await server.api.backups.runIfDue(), isNotNull);
    expect(await server.api.backups.backups(), hasLength(2));
  });

  test('yedek açılabilir bir veritabanı ve verileri içeriyor', () async {
    await server.register('enes@ornek.com');
    final backup = await server.api.backups.runIfDue();
    final copy = NayaDatabase.open(backup!.path);
    addTearDown(copy.close);
    final users = await copy.select(copy.users).get();
    expect(users.single.email, 'enes@ornek.com');
  });

  test('son 7 kopya kalır', () async {
    for (var day = 0; day < 10; day++) {
      await server.api.backups.runIfDue();
      server.clock.advance(const Duration(days: 1));
    }
    final names = [
      for (final file in await server.api.backups.backups())
        p.basename(file.path),
    ];
    expect(names, hasLength(7));
    expect(names.first, 'naya-2026-11-15.db');
    expect(names.last, 'naya-2026-11-21.db');
  });

  test('yarıda kalmış geçici dosya engel olmaz', () async {
    final dir = Directory(server.api.config.backupDir)
      ..createSync(recursive: true);
    File(p.join(dir.path, 'naya-2026-11-12.db.tmp')).writeAsStringSync('yarım');
    expect(await server.api.backups.runIfDue(), isNotNull);
  });
}
