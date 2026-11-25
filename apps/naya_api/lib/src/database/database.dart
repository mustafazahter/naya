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

  /// Açılışta veritabanını ve arama dizinini denetler. Arama dizini
  /// (`dm_chunks`) bozuksa silip boş olarak yeniden kurar; içi sonra
  /// `LibraryService.indexMissing` ile baştan dolar. Ana tablolardaki bir
  /// bozulma burada onarılmaz, yalnız sonuçta bildirilir (yedekten dönmek
  /// insan kararı).
  Future<IntegrityReport> checkIntegrity() async {
    String? problem;
    try {
      final rows = await customSelect('PRAGMA quick_check').get();
      final lines = [for (final row in rows) row.data.values.first.toString()];
      if (lines.length != 1 || lines.single != 'ok') {
        problem = lines.take(5).join('; ');
      }
    } on Object catch (e) {
      problem = '$e';
    }
    try {
      await customStatement(
        "INSERT INTO dm_chunks(dm_chunks) VALUES('integrity-check')",
      );
      return IntegrityReport(problem: problem, searchRebuilt: false);
    } on Object catch (e) {
      await _dropSearchIndex();
      await _createSearchIndex();
      return IntegrityReport(
        problem: problem,
        searchRebuilt: true,
        searchProblem: '$e',
      );
    }
  }

  /// Bozuk FTS tablosu bazen `DROP TABLE` ile de silinemez; o zaman
  /// şemadaki kayıtları doğrudan kaldırılır (SQLite belgelerindeki yol).
  Future<void> _dropSearchIndex() async {
    try {
      await customStatement('DROP TABLE IF EXISTS dm_chunks');
      return;
    } on Object {
      // Aşağıdaki yola düş.
    }
    await customStatement('PRAGMA writable_schema = ON');
    try {
      await customStatement(
        "DELETE FROM sqlite_schema WHERE name = 'dm_chunks' "
        "OR name LIKE 'dm\\_chunks\\_%' ESCAPE '\\'",
      );
    } finally {
      await customStatement('PRAGMA writable_schema = OFF');
    }
    await customStatement('VACUUM');
  }

  /// SQLite'ın kendi yedek komutu: o anki tutarlı bir kopyayı [path]'e
  /// yazar. Yazma sürerken de güvenle çalışır.
  Future<void> vacuumInto(String path) =>
      customStatement('VACUUM INTO ?', [path]);

  static void _configure(Database db) {
    // DELETE (WAL değil): yayında eski ve yeni sunucu aynı ağ diskindeki
    // dosyayı kısa süre birlikte açıyor. WAL'ın paylaşılan bellek dosyası
    // ağ diskinde iki süreç arasında güvenli değil ve FTS dizinini bozdu.
    // busy_timeout: yedek alınırken gelen yazma hemen hata vermesin.
    // Kip değişimi kilit ister: eski sunucu dosyayı hâlâ tutuyorsa bu
    // açılışta WAL kalır, bir sonraki açılışta değişir; açılış düşmez.
    db.execute('PRAGMA busy_timeout = 5000');
    try {
      final mode = db.select('PRAGMA journal_mode = DELETE').first.values.first;
      if (mode != 'delete' && mode != 'memory') {
        stderr.writeln('Günlük kipi değişmedi, şimdilik $mode');
      }
    } on Object catch (e) {
      stderr.writeln('Günlük kipi değiştirilemedi: $e');
    }
    db.execute('PRAGMA foreign_keys = ON');
  }
}

/// [NayaDatabase.checkIntegrity] sonucu.
class IntegrityReport {
  const IntegrityReport({
    required this.problem,
    required this.searchRebuilt,
    this.searchProblem,
  });

  /// `PRAGMA quick_check` bir sorun bulduysa ilk satırları; yoksa `null`.
  final String? problem;

  /// Arama dizini bozuk bulunup boş olarak yeniden kuruldu mu.
  final bool searchRebuilt;
  final String? searchProblem;
}
