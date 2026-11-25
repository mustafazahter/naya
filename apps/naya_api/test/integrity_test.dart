import 'dart:io';

import 'package:naya_api/server.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late NayaDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('naya_integrity');
    db = NayaDatabase.open('${dir.path}/naya.db');
    for (var i = 0; i < 200; i++) {
      await db.customStatement(
        'INSERT INTO dm_chunks (library_item_id, dmc, title, body) '
        'VALUES (?, ?, ?, ?)',
        ['item', 'DMC-$i', 'Fren $i', 'balata disk kaliper hidrolik $i'],
      );
    }
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('dosya WAL değil, DELETE günlük kipinde açılır', () async {
    final row = await db.customSelect('PRAGMA journal_mode').getSingle();
    expect(row.data.values.single, 'delete');
  });

  test('sağlam veritabanında denetim sorun bulmaz', () async {
    final report = await db.checkIntegrity();
    expect(report.problem, isNull);
    expect(report.searchRebuilt, isFalse);
    expect(await DmSearch(db).search('item', 'balata'), isNotEmpty);
  });

  test('bozuk arama dizini istek düşürmez, açılışta yeniden kurulur', () async {
    // Dizinin segment bloklarını çöple doldur: canlıdaki
    // "database disk image is malformed" (267) hatasının aynısı.
    await db.customStatement(
      'UPDATE dm_chunks_data SET block = randomblob(length(block)) '
      'WHERE id > 10',
    );
    final search = DmSearch(db);
    expect(await search.search('item', 'balata disk'), isEmpty);

    final report = await db.checkIntegrity();
    expect(report.searchRebuilt, isTrue);
    expect(report.searchProblem, isNotNull);
    expect(await search.isIndexed('item'), isFalse);

    await db.customStatement(
      'INSERT INTO dm_chunks (library_item_id, dmc, title, body) '
      "VALUES ('item', 'DMC-1', 'Fren', 'balata')",
    );
    expect(await search.search('item', 'balata'), hasLength(1));
    expect((await db.checkIntegrity()).searchRebuilt, isFalse);
  });
}
