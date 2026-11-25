import 'dart:typed_data';

import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import 'faults_builder.dart';
import 'import_exception.dart';
import 'parts_builder.dart';
import 'schematic_glb.dart';
import 'zip_files.dart';

/// İçe aktarmanın sonucu: oluşan `.naya` ve kullanıcıya gösterilecek rapor.
class ImportResult {
  const ImportResult(this.file, this.report);

  final NayaFile file;
  final ImportReport report;
}

/// Taramada ne bulunduğu. Sihirbaz bunu "ekle" demeden önce gösterir.
class ImportReport {
  const ImportReport({
    required this.title,
    required this.modelIdentCode,
    required this.issue,
    required this.dataModules,
    required this.publications,
    required this.dataModuleLists,
    required this.illustrations,
    required this.parts,
    required this.faults,
    required this.systems,
    required this.unreadable,
    required this.missing,
    required this.skipped,
  });

  final String title;
  final String modelIdentCode;

  /// Çoğunluğun yazıldığı S1000D issue'su, örneğin `5.0`.
  final String issue;
  final int dataModules;
  final int publications;
  final int dataModuleLists;
  final int illustrations;
  final int parts;
  final int faults;

  /// Sistemler: kod, başlık, altındaki parça sayısı.
  final List<SystemSummary> systems;

  /// Okunamayan dosyalar ve nedeni.
  final List<String> unreadable;

  /// Başvurulan ama pakette olmayan DM'ler ve çizimler.
  final List<String> missing;

  /// S1000D dosyası olmadığı için alınmayanlar.
  final List<String> skipped;

  Map<String, Object?> toJson() => {
    'title': title,
    'modelIdentCode': modelIdentCode,
    'issue': issue,
    'dataModules': dataModules,
    'publications': publications,
    'dataModuleLists': dataModuleLists,
    'illustrations': illustrations,
    'parts': parts,
    'faults': faults,
    'systems': [for (final s in systems) s.toJson()],
    'unreadable': unreadable,
    'missing': missing,
    'skipped': skipped,
  };
}

class SystemSummary {
  const SystemSummary(this.code, this.title, this.parts);

  final String code;
  final String title;
  final int parts;

  Map<String, Object?> toJson() => {
    'code': code,
    'title': title,
    'parts': parts,
  };
}

/// Zip içindeki S1000D dosyalarını `.naya` dosyasına çevirir.
///
/// S1000D dosyaları `csdb/` altına olduğu gibi konur (formatın ilkesi:
/// orijinal içeriğe dokunulmaz). Üstüne NAYA katmanı eklenir: SNS'ten
/// montaj ağacı (`map/parts.json`), arıza bulma DM'lerinden arızalar
/// (`map/faults.json`) ve ağaçtan şematik bir model.
///
/// Okunabilen tek bir DM bile yoksa [ImportException] fırlatır.
ImportResult importS1000dZip(List<int> zipBytes, {DateTime? now}) {
  final zip = readZip(zipBytes);
  return importS1000dFiles(zip.files, skipped: zip.skipped, now: now);
}

/// [importS1000dZip]'in zip açılmış hali: dosya adı → içerik.
ImportResult importS1000dFiles(
  Map<String, List<int>> files, {
  List<String> skipped = const [],
  DateTime? now,
}) {
  final csdb = Csdb.read(files);
  if (csdb.dataModules.isEmpty) {
    throw ImportException(
      'no_modules',
      csdb.problems.isEmpty
          ? 'Zip içinde S1000D veri modülü (DMC-*.XML) bulunamadı.'
          : 'Zip içindeki veri modüllerinin hiçbiri okunamadı.',
    );
  }

  final built = buildParts(csdb.snsTree);
  final xmlByFile = <String, String?>{};
  String? xmlOf(DataModule dm) {
    final name = _fileOf(dm, files.keys);
    if (name == null) return null;
    return xmlByFile.putIfAbsent(name, () => decodeXml(files[name]!));
  }

  final faults = buildFaults(built, csdb.dataModules, xmlOf);
  final modelIdentCode = csdb.dataModules.first.code.modelIdentCode;
  final title = _titleOf(csdb, modelIdentCode);
  final issue = _issueOf(csdb.dataModules);
  final entryPm = _entryPm(files.keys);

  final file =
      NayaFile(
          manifest: NayaManifest(
            id: '${modelIdentCode.toLowerCase()}-ice-aktarma',
            kind: NayaKind.imported,
            title: title,
            product: const ProductInfo(
              category: 'other',
              variant: 'İçe aktarılan S1000D verisi',
            ),
            s1000d: S1000dInfo(
              issue: issue,
              modelIdentCode: modelIdentCode,
              entry: entryPm == null ? null : 'csdb/$entryPm',
            ),
            model: const ModelInfo(main: 'model/product.glb'),
            generator: 'naya_import 0.1.0',
            created: (now ?? DateTime.now()).toUtc(),
          ),
          entries: {
            for (final e in files.entries)
              'csdb/${e.key}': Uint8List.fromList(e.value),
            'model/product.glb': schematicGlb(built),
          },
        )
        ..putJson('map/parts.json', PartsFile(built.parts).toJson())
        ..putJson('map/faults.json', faults.toJson());

  final report = ImportReport(
    title: title,
    modelIdentCode: modelIdentCode,
    issue: issue,
    dataModules: csdb.dataModules.length,
    publications: csdb.publications.length,
    dataModuleLists: csdb.dataModuleLists.length,
    illustrations: csdb.icns.length,
    parts: built.parts.length,
    faults: faults.faults.length,
    systems: [
      for (final p in built.parts)
        if (p.parent == null)
          SystemSummary(
            p.sns?.split('-').first ?? p.id,
            p.name,
            _descendants(built.parts, p.id),
          ),
    ],
    unreadable: [
      for (final e in csdb.problems)
        e.file == null ? e.message : '${e.file}: ${e.message}',
    ],
    missing: csdb.missingReferences,
    skipped: skipped,
  );
  return ImportResult(file, report);
}

/// Bir DM'in hangi dosyadan okunduğu. Dosya adı kodla ve sürümle başlar:
/// `DMC-…-A_001-00_TR-TR.XML`.
String? _fileOf(DataModule dm, Iterable<String> names) {
  final prefix = '${dm.code}_${dm.issueNumber}-${dm.inWork}'.toUpperCase();
  for (final name in names) {
    if (name.toUpperCase().startsWith(prefix)) return name;
  }
  final bare = dm.code.toString().toUpperCase();
  for (final name in names) {
    final upper = name.toUpperCase();
    if (upper.startsWith('${bare}_') || upper.startsWith('$bare.')) return name;
  }
  return null;
}

/// Başlık: yayının (PM) adı, yoksa genel tanıtım DM'inin (`…-00-00-00`)
/// teknik adı, yoksa model kodu.
String _titleOf(Csdb csdb, String modelIdentCode) {
  for (final pm in csdb.publications) {
    if (pm.title.trim().isNotEmpty) return pm.title.trim();
  }
  final general = csdb.dataModules.where(
    (dm) =>
        RegExp(r'0+$').hasMatch(dm.code.systemCode) &&
        dm.code.infoCode.startsWith('0'),
  );
  for (final dm in general) {
    if (dm.techName.trim().isNotEmpty) return dm.techName.trim();
  }
  return modelIdentCode;
}

String _issueOf(List<DataModule> modules) {
  final counts = <String, int>{};
  for (final dm in modules) {
    final issue = dm.s1000dIssue;
    if (issue != null) counts[issue] = (counts[issue] ?? 0) + 1;
  }
  if (counts.isEmpty) return 'bilinmiyor';
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// Giriş yayını: adı en küçük PM dosyası (ilk yayın).
String? _entryPm(Iterable<String> names) {
  final pms = names.where((n) => n.toUpperCase().startsWith('PMC-')).toList()
    ..sort();
  return pms.firstOrNull;
}

int _descendants(List<Part> parts, String id) {
  var count = 0;
  for (final p in parts.where((p) => p.parent == id)) {
    count += 1 + _descendants(parts, p.id);
  }
  return count;
}
