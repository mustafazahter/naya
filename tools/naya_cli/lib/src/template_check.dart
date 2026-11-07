import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import 'glb.dart';

/// Bir `.naya` dosyasının içerik kontrolü sonucu.
class CheckReport {
  final errors = <String>[];
  final warnings = <String>[];

  bool get ok => errors.isEmpty;
}

/// [file] üzerinde `naya_format`'ın yapamadığı kontrolleri yapar:
/// S1000D dosyaları okunuyor mu, harita dosyalarındaki DMC'ler CSDB'de var
/// mı, `meshNodes` modelde var mı, manifestin gösterdiği dosyalar var mı?
///
/// Kap ve bütünlük kontrolü `NayaFile.decode`'da, harita dosyaları arası
/// bağlar `NayaFile.validate`'te; burada tekrar edilmiyor.
CheckReport checkContent(NayaFile file) {
  final report = CheckReport();
  final entries = file.entries;
  final manifest = file.manifest;

  final model = manifest.model;
  if (model != null && !entries.containsKey(model.main)) {
    report.errors.add('naya.json: model "${model.main}" dosyada yok');
  }
  final entry = manifest.s1000d?.entry;
  if (entry != null && !entries.containsKey(entry)) {
    report.errors.add('naya.json: S1000D girişi "$entry" dosyada yok');
  }
  for (final credit in manifest.credits) {
    if (!entries.containsKey(credit.asset)) {
      report.warnings.add('naya.json: atıf yapılan "${credit.asset}" yok');
    }
  }

  final csdb = Csdb.read({
    for (final e in entries.entries)
      if (e.key.startsWith('csdb/')) e.key: e.value,
  });
  for (final problem in csdb.problems) {
    report.errors.add(problem.toString());
  }
  for (final missing in csdb.missingReferences) {
    report.warnings.add('csdb: eksik başvuru $missing');
  }

  final codes = {for (final dm in csdb.dataModules) dm.code.toString()};
  void checkDmc(String where, String? dmc) {
    if (dmc == null) return;
    try {
      if (!codes.contains(DmCode.parse(dmc).toString())) {
        report.errors.add('$where: "$dmc" CSDB\'de yok');
      }
    } on S1000dException {
      report.errors.add('$where: "$dmc" geçerli bir DMC değil');
    }
  }

  final nodeNames = _nodeNames(file, report);
  for (final part in file.parts?.parts ?? <Part>[]) {
    final where = 'map/parts.json: ${part.id}';
    part.procedures.forEach((kind, dmc) => checkDmc('$where ($kind)', dmc));
    checkDmc('$where (ipd)', part.ipd?.dmc);
    if (nodeNames == null) continue;
    for (final node in part.meshNodes) {
      if (!nodeNames.contains(node)) {
        report.errors.add('$where: "$node" düğümü modelde yok');
      }
    }
  }
  for (final fault in file.faults?.faults ?? <Fault>[]) {
    final where = 'map/faults.json: ${fault.id}';
    checkDmc('$where (isolation)', fault.isolation);
    checkDmc('$where (repair)', fault.repair);
  }
  return report;
}

Set<String>? _nodeNames(NayaFile file, CheckReport report) {
  final main = file.manifest.model?.main;
  final bytes = main == null ? null : file.entries[main];
  if (bytes == null) return null;
  try {
    return glbNodeNames(bytes);
  } on FormatException catch (e) {
    report.errors.add('$main: ${e.message}');
    return null;
  }
}
