import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:naya_format/naya_format.dart';
import 'package:path/path.dart' as p;

import '../ai/dm_search.dart';
import '../auth/auth_service.dart';
import '../database/database.dart';

/// Kütüphane işlemlerinde kullanıcıya gösterilecek hata.
class LibraryException implements Exception {
  const LibraryException(this.code, this.message, {this.problems = const []});

  final String code;
  final String message;

  /// Doğrulamadan geçmeyen dosyada bulunan sorunlar.
  final List<String> problems;

  @override
  String toString() => '$code: $message';
}

/// Kütüphanede görünenler: herkese açık şablonlar ve kullanıcının kendi
/// dosyaları.
class LibraryListing {
  const LibraryListing(this.templates, this.userFiles);

  final List<LibraryItemRow> templates;
  final List<LibraryItemRow> userFiles;
}

/// `.naya` dosyalarını diskte saklar, bilgilerini veritabanında tutar.
///
/// Dosyalar `<storageDir>/library/<id>.naya` olarak, olduğu gibi durur;
/// indirmede aynı baytlar döner. İçinden tek dosya istendiğinde (parça
/// haritası, bir DM, çizim) `.naya` açılır ve son açılanlar bellekte
/// tutulur.
class LibraryService {
  LibraryService(
    this._db,
    this.libraryDir, {
    this.maxBytesPerUser = 500 * 1024 * 1024,
    this.search,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Verilirse eklenen dosyanın DM'leri arama dizinine yazılır.
  final DmSearch? search;

  final NayaDatabase _db;
  final String libraryDir;
  final DateTime Function() _clock;

  /// Bir kullanıcının yükleyebileceği toplam boyut. Kayıt herkese açık ve
  /// disk 10 GB; tek kişi diski dolduramasın. Admin için sınır yok.
  final int maxBytesPerUser;

  /// Mimari kararı: şablonlar 50 MB altında. Kullanıcı dosyalarına da aynı
  /// sınırı koyuyoruz; Komuta'daki disk 10 GB.
  static const maxFileBytes = 50 * 1024 * 1024;

  static const _cacheSize = 4;
  final _openFiles = <String, NayaFile>{};
  static final _random = Random.secure();

  Future<LibraryListing> list(AuthUser? user) async {
    final templates =
        await (_db.select(_db.libraryItems)
              ..where((i) => i.templateKey.isNotNull())
              ..orderBy([(i) => OrderingTerm.asc(i.title)]))
            .get();
    final userFiles = user == null
        ? <LibraryItemRow>[]
        : await (_db.select(_db.libraryItems)
                ..where((i) => i.ownerId.equals(user.id))
                ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
              .get();
    return LibraryListing(templates, userFiles);
  }

  /// [user]'ın görebildiği öğe; göremiyorsa yokmuş gibi `null`.
  Future<LibraryItemRow?> find(String id, AuthUser? user) async {
    final item = await (_db.select(
      _db.libraryItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (item == null || !canRead(item, user)) return null;
    return item;
  }

  static bool canRead(LibraryItemRow item, AuthUser? user) =>
      item.templateKey != null ||
      (user != null && (user.isAdmin || item.ownerId == user.id));

  /// Şablonu yalnız admin, kullanıcı dosyasını sahibi ya da admin siler.
  static bool canDelete(LibraryItemRow item, AuthUser user) =>
      user.isAdmin || (item.templateKey == null && item.ownerId == user.id);

  File fileOf(LibraryItemRow item) => File(p.join(libraryDir, item.fileName));

  /// Öğenin `.naya` dosyası, açılmış hali. Son açılan birkaç dosya
  /// bellekte tutulur.
  Future<NayaFile> open(LibraryItemRow item) async {
    final cacheKey = '${item.id}:${item.sha256}';
    var file = _openFiles.remove(cacheKey);
    if (file == null) {
      file = NayaFile.decode(await fileOf(item).readAsBytes());
      if (_openFiles.length >= _cacheSize) {
        _openFiles.remove(_openFiles.keys.first);
      }
    }
    // Sona eklemek "en son kullanılan" demek; en eski baştan atılır.
    _openFiles[cacheKey] = file;
    return file;
  }

  /// Arama dizininde hiç kaydı olmayan öğeleri dizine yazar. Dizin 4A'da
  /// geldiği için ondan önce eklenmiş dosyalar böyle tamamlanır.
  Future<int> indexMissing() async {
    final search = this.search;
    if (search == null) return 0;
    var count = 0;
    for (final item in await _db.select(_db.libraryItems).get()) {
      if (await search.isIndexed(item.id)) continue;
      try {
        await search.index(item.id, await open(item));
        count++;
      } on Object catch (e) {
        // Diskte eksik ya da bozuk bir dosya sunucunun açılmasını
        // engellemesin; o dosya aranmaz, sorun günlükte görünür.
        stderr.writeln('Arama dizinine eklenemedi (${item.id}): $e');
      }
    }
    return count;
  }

  /// `.naya` içindeki bir dosya; yoksa `null`.
  Future<Uint8List?> readEntry(LibraryItemRow item, String path) async {
    final file = await open(item);
    if (path == 'naya.json') {
      return utf8.encode(jsonEncode(file.manifest.toJson()));
    }
    return file.entries[path];
  }

  /// Kullanıcının yüklediği dosyayı doğrular ve kaydeder.
  Future<LibraryItemRow> addUserFile(AuthUser owner, Uint8List bytes) async {
    final file = _decodeAndValidate(bytes);
    if (!owner.isAdmin) {
      final used = await _usedBytes(owner.id);
      if (used + bytes.length > maxBytesPerUser) {
        final limitMb = maxBytesPerUser ~/ (1024 * 1024);
        throw LibraryException(
          'quota_exceeded',
          'Yükleme sınırına ulaştınız: kişi başına en fazla $limitMb MB. '
              'Eski dosyalarınızdan birini silin.',
        );
      }
    }
    final id = _newId();
    final fileName = '$id.naya';
    await _writeFile(fileName, bytes);
    final now = _clock();
    final row = _rowFor(
      file,
      bytes,
      id: id,
      fileName: fileName,
      ownerId: owner.id,
      templateKey: null,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.libraryItems).insert(row);
    await search?.index(id, file);
    return row;
  }

  /// Şablonu ekler; aynı manifest `id`'li şablon varsa ve dosya değiştiyse
  /// onun yerine geçer. Kimliği korunur, böylece uygulamadaki adresler
  /// bozulmaz. Dosya aynıysa hiçbir şey yapmaz.
  Future<LibraryItemRow> importTemplate(Uint8List bytes) async {
    final file = _decodeAndValidate(bytes);
    final key = file.manifest.id;
    final existing = await (_db.select(
      _db.libraryItems,
    )..where((i) => i.templateKey.equals(key))).getSingleOrNull();
    final digest = sha256.convert(bytes).toString();
    if (existing != null && existing.sha256 == digest) return existing;

    final id = existing?.id ?? _newId();
    final fileName = '$id.naya';
    await _writeFile(fileName, bytes);
    final now = _clock();
    final row = _rowFor(
      file,
      bytes,
      id: id,
      fileName: fileName,
      ownerId: null,
      templateKey: key,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _db.into(_db.libraryItems).insertOnConflictUpdate(row);
    _openFiles.removeWhere((cacheKey, _) => cacheKey.startsWith('$id:'));
    await search?.index(id, file);
    return row;
  }

  Future<void> delete(LibraryItemRow item) async {
    await (_db.delete(
      _db.libraryItems,
    )..where((i) => i.id.equals(item.id))).go();
    _openFiles.removeWhere((cacheKey, _) => cacheKey.startsWith('${item.id}:'));
    await search?.remove(item.id);
    final file = fileOf(item);
    if (await file.exists()) await file.delete();
  }

  /// Kullanıcının yüklediği dosyaların toplam boyutu.
  Future<int> _usedBytes(int ownerId) async {
    final total = _db.libraryItems.sizeBytes.sum();
    final query = _db.selectOnly(_db.libraryItems)
      ..addColumns([total])
      ..where(_db.libraryItems.ownerId.equals(ownerId));
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  static NayaFile _decodeAndValidate(Uint8List bytes) {
    if (bytes.length > maxFileBytes) {
      throw const LibraryException(
        'too_large',
        'Dosya 50 MB’tan büyük olamaz.',
      );
    }
    try {
      return NayaFile.decode(bytes)..validate();
    } on InvalidReferencesException catch (e) {
      throw LibraryException(
        'invalid_file',
        'Dosyadaki parça ve arıza bağlantıları tutarsız.',
        problems: e.problems,
      );
    } on IntegrityException catch (e) {
      throw LibraryException(
        'invalid_file',
        'Dosya bozuk: içindeki dosyalar özetleriyle uyuşmuyor.',
        problems: e.problems,
      );
    } on NayaFormatException catch (e) {
      throw LibraryException(
        'invalid_file',
        'Bu bir .naya dosyası değil ya da okunamıyor.',
        problems: [e.message],
      );
    }
  }

  LibraryItemRow _rowFor(
    NayaFile file,
    Uint8List bytes, {
    required String id,
    required String fileName,
    required int? ownerId,
    required String? templateKey,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final manifest = file.manifest;
    final modules = file.entries.keys.where(
      (name) => name.startsWith('csdb/') && p.basename(name).startsWith('DMC-'),
    );
    return LibraryItemRow(
      id: id,
      templateKey: templateKey,
      ownerId: ownerId,
      title: manifest.title,
      subtitle: manifest.product?.variant ?? '',
      category: manifest.product?.category ?? 'other',
      partCount: file.parts?.parts.length ?? 0,
      faultCount: file.faults?.faults.length ?? 0,
      moduleCount: modules.length,
      hasModel:
          manifest.model != null &&
          file.entries.containsKey(manifest.model!.main),
      manifestJson: jsonEncode(manifest.toJson()),
      fileName: fileName,
      sizeBytes: bytes.length,
      sha256: sha256.convert(bytes).toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Önce geçici dosyaya yazıp sonra adını değiştiriyoruz; yazma yarıda
  /// kalırsa eski dosya bozulmaz.
  Future<void> _writeFile(String fileName, Uint8List bytes) async {
    await Directory(libraryDir).create(recursive: true);
    final target = p.join(libraryDir, fileName);
    final temp = File('$target.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target);
  }

  static String _newId() {
    final bytes = List<int>.generate(9, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
