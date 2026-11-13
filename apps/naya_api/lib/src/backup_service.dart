import 'dart:io';

import 'package:path/path.dart' as p;

import 'database/database.dart';

/// Günlük veritabanı yedeği: `VACUUM INTO` ile tutarlı bir kopya,
/// `naya-YYYY-AA-GG.db` adıyla; en yeni [keep] kopya kalır.
///
/// Sunucu sürekli açık olmayabileceği için zamanlayıcı saatte bir bakar ve
/// bugünün yedeği yoksa alır. Açılışta da bir kez çalışır.
class BackupService {
  BackupService(
    this._db,
    this.backupDir, {
    this.keep = 7,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final NayaDatabase _db;
  final String backupDir;
  final int keep;
  final DateTime Function() _clock;

  static final _namePattern = RegExp(r'^naya-\d{4}-\d{2}-\d{2}\.db$');

  /// Bugünün yedeği yoksa alır. Aldığı dosyayı, almadıysa `null` döner.
  Future<File?> runIfDue() async {
    await Directory(backupDir).create(recursive: true);
    final target = File(p.join(backupDir, _nameFor(_clock())));
    if (await target.exists()) return null;

    // VACUUM INTO var olan dosyanın üstüne yazmıyor; yarıda kalmış bir
    // denemeden kalan geçici dosya varsa önce siliniyor.
    final temp = File('${target.path}.tmp');
    if (await temp.exists()) await temp.delete();
    await _db.vacuumInto(temp.path);
    await temp.rename(target.path);
    await _prune();
    return target;
  }

  Future<List<File>> backups() async {
    final dir = Directory(backupDir);
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File && _namePattern.hasMatch(p.basename(e.path)))
        .cast<File>()
        .toList();
    // Ad tarihi içerdiği için alfabetik sıra tarih sırası.
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files;
  }

  Future<void> _prune() async {
    final files = await backups();
    if (files.length <= keep) return;
    for (final old in files.take(files.length - keep)) {
      await old.delete();
    }
  }

  static String _nameFor(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'naya-${time.year}-${two(time.month)}-${two(time.day)}.db';
  }
}
