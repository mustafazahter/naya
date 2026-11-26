import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'import_exception.dart';

/// Zip içindeki S1000D dosyaları ve atlananlar.
class ZipFiles {
  const ZipFiles(this.files, this.skipped);

  /// Dosya adı (klasörsüz) → içerik.
  final Map<String, Uint8List> files;

  /// S1000D dosyası olmadığı ya da aynı adla ikinci kez geçtiği için
  /// alınmayanlar, zip içindeki yollarıyla.
  final List<String> skipped;
}

/// Zip'i açar ve S1000D dosyalarını (`DMC-`, `PMC-`, `DML-`, `ICN-`)
/// klasörlerinden bağımsız olarak toplar.
///
/// Dışarıdan gelen dosya olduğu için sınırlıdır: en çok [maxFiles] kayıt,
/// açılmış halde toplam [maxBytes] ve dosya başına [maxEntryBytes]. Deflate
/// 1000'e 1'e yakın sıkıştırabildiği için toplam sınır, oluşacak `.naya`'nın
/// sınırının (50 MB) iki katı; içerik bellekte birkaç kez tutuluyor.
ZipFiles readZip(
  List<int> bytes, {
  int maxFiles = 5000,
  int maxBytes = 100 * 1024 * 1024,
  int maxEntryBytes = 50 * 1024 * 1024,
}) {
  const invalid = ImportException(
    'invalid_zip',
    'Zip dosyası açılamadı; bozuk ya da zip değil.',
  );
  // archive paketi zip olmayan baytları hata vermeden boş arşiv sayıyor;
  // imzaya ("PK") kendimiz bakıyoruz.
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) throw invalid;
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw invalid;
  }

  final entries = archive.where((f) => f.isFile).toList();
  if (entries.length > maxFiles) {
    throw ImportException(
      'too_many_files',
      'Zip içinde $maxFiles dosyadan fazlası var.',
    );
  }
  var total = 0;
  for (final f in entries) {
    if (f.size > maxEntryBytes) {
      throw ImportException(
        'too_large',
        '${f.name} açılınca ${maxEntryBytes ~/ (1024 * 1024)} MB’ı geçiyor.',
      );
    }
    total += f.size;
  }
  if (total > maxBytes) {
    throw ImportException(
      'too_large',
      'Zip açılınca ${maxBytes ~/ (1024 * 1024)} MB’ı geçiyor.',
    );
  }

  final files = <String, Uint8List>{};
  final skipped = <String>[];
  final sorted = entries.toList()..sort((a, b) => a.name.compareTo(b.name));
  for (final entry in sorted) {
    final name = entry.name.replaceAll('\\', '/').split('/').last;
    // macOS'un eklediği gizli kopyalar (`__MACOSX/._DMC-...`).
    final hidden = entry.name.startsWith('__MACOSX/') || name.startsWith('._');
    if (hidden || !isS1000dFileName(name) || files.containsKey(name)) {
      skipped.add(entry.name);
      continue;
    }
    // Bozuk sıkıştırma ya da CRC hatası burada çıkar.
    try {
      files[name] = entry.content;
    } on Object {
      throw ImportException(
        'invalid_zip',
        'Zip içindeki ${entry.name} açılamadı; dosya bozuk.',
      );
    }
  }
  return ZipFiles(files, skipped);
}

/// DM, PM, DML ya da çizim (ICN) dosyası mı?
bool isS1000dFileName(String name) {
  final upper = name.toUpperCase();
  if (upper.startsWith('ICN-')) return upper.contains('.');
  return (upper.startsWith('DMC-') ||
          upper.startsWith('PMC-') ||
          upper.startsWith('DML-')) &&
      upper.endsWith('.XML');
}
