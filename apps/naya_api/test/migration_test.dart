import 'dart:io';

import 'package:naya_api/server.dart';
import 'package:test/test.dart';

void main() {
  test('1. sürüm veritabanı açılınca yapay zekâ tabloları eklenir', () async {
    final dir = await Directory.systemTemp.createTemp('naya_migration');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/naya.db';

    // 3C'deki hali: yalnız hesap ve kütüphane tabloları, user_version 1.
    var db = NayaDatabase.open(path);
    await db.customSelect('SELECT 1').get();
    for (final table in [
      'messages',
      'conversations',
      'diagnoses',
      'ai_roles',
      'ai_keys',
      'dm_chunks',
    ]) {
      await db.customStatement('DROP TABLE $table');
    }
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = NayaDatabase.open(path);
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row.read<String>('name'))
        .get();
    expect(
      tables,
      containsAll([
        'users',
        'library_items',
        'ai_keys',
        'ai_roles',
        'diagnoses',
        'conversations',
        'messages',
        'dm_chunks',
      ]),
    );
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 2);
    await db.close();
  });
}
