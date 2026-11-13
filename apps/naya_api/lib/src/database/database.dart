import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Sessions,
    LibraryItems,
    AiKeys,
    AiRoles,
    Diagnoses,
    Conversations,
    Messages,
  ],
)
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

  /// 1: hesaplar ve kütüphane (3C). 2: yapay zekâ tabloları ve DM arama
  /// dizini (4A).
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createSearchIndex();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(aiKeys);
        await migrator.createTable(aiRoles);
        await migrator.createTable(diagnoses);
        await migrator.createTable(conversations);
        await migrator.createTable(messages);
        await _createSearchIndex();
      }
    },
  );

  /// DM metinlerinin tam metin arama dizini (FTS5). drift sanal tabloyu
  /// kendisi tanımlamadığı için elle kuruluyor; sorgular `DmSearch`'te.
  ///
  /// `remove_diacritics 2`: "fren balatasi" araması "balatası"nı da bulsun.
  Future<void> _createSearchIndex() => customStatement('''
    CREATE VIRTUAL TABLE IF NOT EXISTS dm_chunks USING fts5(
      library_item_id UNINDEXED,
      dmc UNINDEXED,
      title,
      body,
      tokenize = 'unicode61 remove_diacritics 2'
    )''');

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
