import 'package:drift/drift.dart';
import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import '../database/database.dart';

/// Arama sonucu: DM'in bir parçası (adım, bölüm, katalog satırı).
class DmPassage {
  const DmPassage({required this.dmc, required this.title, required this.text});

  final String dmc;
  final String title;
  final String text;
}

/// DM metinlerinde tam metin arama (SQLite FTS5, `dm_chunks` tablosu).
///
/// Kütüphaneye bir `.naya` eklenince DM'leri adım ve bölüm bazında
/// parçalanıp dizine yazılır; silinince dizinden de çıkar. Yapay zekâya
/// giden bağlam buradan seçilir.
class DmSearch {
  DmSearch(this._db);

  final NayaDatabase _db;

  /// Öğenin eski kayıtlarını silip DM'lerini yeniden dizine yazar.
  Future<int> index(String itemId, NayaFile file) async {
    final files = <String, List<int>>{
      for (final e in file.entries.entries)
        if (e.key.startsWith('csdb/')) e.key: e.value,
    };
    final chunks = Csdb.read(files).chunks;
    await _db.transaction(() async {
      await remove(itemId);
      for (final chunk in chunks) {
        await _db.customInsert(
          'INSERT INTO dm_chunks (library_item_id, dmc, title, body) '
          'VALUES (?, ?, ?, ?)',
          variables: [
            Variable.withString(itemId),
            Variable.withString('${chunk.dmc}'),
            Variable.withString(
              chunk.section.isEmpty
                  ? chunk.dmTitle
                  : '${chunk.dmTitle} › ${chunk.section}',
            ),
            Variable.withString(chunk.text),
          ],
        );
      }
    });
    return chunks.length;
  }

  Future<bool> isIndexed(String itemId) async {
    final row = await _db
        .customSelect(
          'SELECT 1 FROM dm_chunks WHERE library_item_id = ? LIMIT 1',
          variables: [Variable.withString(itemId)],
        )
        .getSingleOrNull();
    return row != null;
  }

  Future<void> remove(String itemId) => _db.customStatement(
    'DELETE FROM dm_chunks WHERE library_item_id = ?',
    [itemId],
  );

  /// [text]'teki kelimelerle en ilgili parçalar. Kelimelerden herhangi
  /// biri geçen parçalar bulunur, en çok eşleşen önce gelir.
  Future<List<DmPassage>> search(
    String itemId,
    String text, {
    int limit = 8,
  }) async {
    final query = ftsQuery(text);
    if (query == null) return const [];
    final rows = await _db
        .customSelect(
          'SELECT dmc, title, body FROM dm_chunks '
          'WHERE dm_chunks MATCH ? AND library_item_id = ? '
          'ORDER BY rank LIMIT ?',
          variables: [
            Variable.withString(query),
            Variable.withString(itemId),
            Variable.withInt(limit),
          ],
        )
        .get();
    return [
      for (final row in rows)
        DmPassage(
          dmc: row.read<String>('dmc'),
          title: row.read<String>('title'),
          text: row.read<String>('body'),
        ),
    ];
  }

  /// Belirli DM'lerin parçaları, dosyadaki sırayla.
  Future<List<DmPassage>> passagesOf(String itemId, String dmc) async {
    final rows = await _db
        .customSelect(
          'SELECT dmc, title, body FROM dm_chunks '
          'WHERE library_item_id = ? AND dmc = ? ORDER BY rowid',
          variables: [Variable.withString(itemId), Variable.withString(dmc)],
        )
        .get();
    return [
      for (final row in rows)
        DmPassage(
          dmc: row.read<String>('dmc'),
          title: row.read<String>('title'),
          text: row.read<String>('body'),
        ),
    ];
  }

  /// Kullanıcının yazdığından FTS5 sorgusu. Her kelime tırnak içine alınır
  /// (FTS5'in kendi işaretleri, `AND`, `*` gibi, sorguyu bozmasın) ve
  /// `OR` ile bağlanır. Kısa kelimeler ("ve", "bu") atlanır.
  static String? ftsQuery(String text) {
    final words = text
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.length >= 3)
        .toSet()
        .take(20);
    if (words.isEmpty) return null;
    return words.map((w) => '"$w"').join(' OR ');
  }
}
