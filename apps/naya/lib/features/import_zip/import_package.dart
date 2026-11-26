import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../entities/product/product.dart';
import '../../shared/api/api_client.dart';

/// Sunucunun kabul ettiği en büyük dosya; daha büyüğünü yüklemeye
/// başlamadan söyleriz (`LibraryService.maxFileBytes`).
const maxPackageBytes = 50 * 1024 * 1024;

/// Seçilen dosya: S1000D zip'i ya da daha önce dışa aktarılmış `.naya`.
class PickedPackage {
  const PickedPackage(this.name, this.bytes);

  final String name;
  final Uint8List bytes;

  bool get isNaya => name.toLowerCase().endsWith('.naya');
}

/// Dosya seçicisini açar. Vazgeçilirse null. Uzantıyı biz denetliyoruz:
/// Android'in seçicisi `.naya`'yı bir türe eşleyemediği için süzgeç
/// verilirse dosya hiç görünmüyor.
Future<PickedPackage?> pickPackage() async {
  final file = await FilePicker.pickFile(dialogTitle: 'S1000D paketi seç');
  if (file == null) return null;
  final name = file.name;
  final lower = name.toLowerCase();
  if (!lower.endsWith('.zip') && !lower.endsWith('.naya')) {
    throw const ImportFailure(
      'Yalnız .zip (S1000D dosyaları) ya da .naya dosyası içe aktarılabilir.',
    );
  }
  final size = file.lengthSync() ?? await file.length();
  if (size != null && size > maxPackageBytes) throw _tooLarge;
  final bytes = await file.readAsBytes();
  if (bytes.length > maxPackageBytes) throw _tooLarge;
  return PickedPackage(name, bytes);
}

const _tooLarge = ImportFailure('Dosya 50 MB’tan büyük olamaz.');

/// Kullanıcıya olduğu gibi gösterilecek içe aktarma hatası.
class ImportFailure implements Exception {
  const ImportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Paketi sunucuya gönderir. Zip çevrilir ve rapor gelir; `.naya`
/// olduğu gibi eklenir, raporu yoktur.
Future<ImportOutcome> uploadPackage(
  ApiClient api,
  PickedPackage package,
) async {
  try {
    if (package.isNaya) {
      final item = await api.postBytes(
        '/api/library/',
        package.bytes,
        contentType: 'application/vnd.naya+zip',
      );
      return ImportOutcome(Product.fromJson(item));
    }
    final body = await api.postBytes(
      '/api/library/import',
      package.bytes,
      contentType: 'application/zip',
    );
    return ImportOutcome(
      Product.fromJson(body['item']! as Map<String, Object?>),
      ImportSummary.fromJson(body['report']! as Map<String, Object?>),
    );
  } on ApiException catch (e) {
    throw ImportFailure(e.message);
  }
}

/// Eklenen dosya ve (zip'se) taramanın özeti.
class ImportOutcome {
  const ImportOutcome(this.product, [this.summary]);

  final Product product;
  final ImportSummary? summary;
}

/// Sunucunun tarama raporu (`naya_import` `ImportReport`).
class ImportSummary {
  const ImportSummary({
    required this.title,
    required this.issue,
    required this.dataModules,
    required this.publications,
    required this.illustrations,
    required this.parts,
    required this.faults,
    required this.systems,
    required this.unreadable,
    required this.missing,
    required this.skipped,
  });

  factory ImportSummary.fromJson(Map<String, Object?> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    List<String> strings(String key) => [
      for (final s in json[key] as List<Object?>? ?? const [])
        if (s is String) s,
    ];
    return ImportSummary(
      title: json['title'] as String? ?? '',
      issue: json['issue'] as String? ?? '',
      dataModules: count('dataModules'),
      publications: count('publications'),
      illustrations: count('illustrations'),
      parts: count('parts'),
      faults: count('faults'),
      systems: [
        for (final s in json['systems'] as List<Object?>? ?? const [])
          if (s is Map<String, Object?>)
            (
              code: s['code'] as String? ?? '',
              title: s['title'] as String? ?? '',
              parts: (s['parts'] as num?)?.toInt() ?? 0,
            ),
      ],
      unreadable: strings('unreadable'),
      missing: strings('missing'),
      skipped: strings('skipped'),
    );
  }

  final String title;
  final String issue;
  final int dataModules;
  final int publications;
  final int illustrations;
  final int parts;
  final int faults;
  final List<({String code, String title, int parts})> systems;
  final List<String> unreadable;
  final List<String> missing;
  final List<String> skipped;
}
