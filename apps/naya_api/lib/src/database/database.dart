import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Sessions, LibraryItems])
class NayaDatabase extends _$NayaDatabase {
  NayaDatabase(super.executor);

  /// Diskteki veritabanını açar; klasör yoksa oluşturur.
  factory NayaDatabase.open(String path) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    return NayaDatabase(
      NativeDatabase.createInBackground(file, setup: _configure),
    );
  }

  /// Testler için bellekte, her seferinde boş bir veritabanı.
  factory NayaDatabase.memory() =>
      NayaDatabase(NativeDatabase.memory(setup: _configure));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (migrator) => migrator.createAll());

  /// SQLite'ın kendi yedek komutu: o anki tutarlı bir kopyayı [path]'e
  /// yazar. Yazma sürerken de güvenle çalışır.
  Future<void> vacuumInto(String path) =>
      customStatement('VACUUM INTO ?', [path]);

  static void _configure(Database db) {
    // WAL: okumalar yazmayı, yazma okumaları bekletmiyor.
    // busy_timeout: yedek alınırken gelen yazma hemen hata vermesin.
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA busy_timeout = 5000');
  }
}
