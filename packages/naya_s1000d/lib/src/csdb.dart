import 'dart:convert';

import 'chunk.dart';
import 'data_module.dart';
import 'dm_code.dart';
import 'errors.dart';
import 'icn.dart';
import 'ipd.dart';
import 'publication_module.dart';
import 'sns.dart';

/// Bir klasör dolusu S1000D dosyası (CSDB): DM'ler, PM'ler, DML'ler ve
/// görseller.
///
/// Okunamayan dosyalar okumayı durdurmaz; [problems] listesine yazılır.
/// İçe aktarmada kullanıcıya "şu 3 dosya okunamadı" diyebilmek için.
class Csdb {
  Csdb._();

  /// Dosya yolu → içerik. Tür, dosya adının başından anlaşılır: `DMC-`,
  /// `PMC-`, `DML-`, `ICN-`. Diğer dosyalar yok sayılır.
  factory Csdb.read(Map<String, List<int>> files) {
    final csdb = Csdb._();
    final paths = files.keys.toList()..sort();
    for (final path in paths) {
      final name = path.split('/').last.toUpperCase();
      if (name.startsWith('ICN-')) {
        final icn = Icn.fromPath(path)!;
        csdb.icns[icn.ident] = icn;
        continue;
      }
      if (!name.endsWith('.XML')) continue;
      try {
        final xml = _decode(files[path]!, path);
        if (name.startsWith('DMC-')) {
          final dm = DataModule.parse(xml, file: path);
          csdb.dataModules.add(dm);
          if (dm.contentType == 'brex') csdb._brexXml ??= xml;
        } else if (name.startsWith('PMC-')) {
          csdb.publications.add(PublicationModule.parse(xml, file: path));
        } else if (name.startsWith('DML-')) {
          csdb.dataModuleLists.add(DataModuleList.parse(xml, file: path));
        }
      } on S1000dException catch (e) {
        csdb.problems.add(e);
      }
    }
    return csdb;
  }

  final List<DataModule> dataModules = [];
  final List<PublicationModule> publications = [];
  final List<DataModuleList> dataModuleLists = [];

  /// ICN kimliği → dosya.
  final Map<String, Icn> icns = {};
  final List<S1000dException> problems = [];
  String? _brexXml;

  /// Kodu verilen DM'in en yüksek sürümü; birden fazla dil varsa [language]
  /// ile seçilir.
  DataModule? dataModule(DmCode code, {String? language}) {
    DataModule? best;
    for (final dm in dataModules) {
      if (dm.code != code) continue;
      if (language != null && dm.language != language) continue;
      if (best == null || _issueKey(dm).compareTo(_issueKey(best)) > 0) {
        best = dm;
      }
    }
    return best;
  }

  /// SNS ağacı; BREX varsa başlıklar oradan.
  late final List<SnsNode> snsTree = buildSnsTree(_latest, brexXml: _brexXml);

  /// Bütün DM'lerin aranabilir parçaları (her DM'in yalnız son sürümü).
  late final List<Chunk> chunks = [for (final dm in _latest) ...dm.chunks];

  /// Bütün IPD satırları.
  List<IpdItemRef> get ipd => [
    for (final dm in _latest)
      for (final item in dm.ipdItems) IpdItemRef(dm.code, item),
  ];

  /// DM'lerde, PM'lerde ve DML'lerde başvurulan ama CSDB'de olmayan DM'ler
  /// ve görseller. Okumayı bozmaz; içe aktarmada uyarı olarak gösterilir.
  List<String> get missingReferences {
    final codes = {for (final dm in dataModules) dm.code};
    final missing = <String>{};
    void check(String from, DmCode code) {
      if (!codes.contains(code)) missing.add('$from → $code');
    }

    for (final dm in _latest) {
      for (final ref in dm.dmRefs) {
        check(dm.code.toString(), ref);
      }
      for (final icn in dm.icnRefs) {
        if (!icns.containsKey(icn)) missing.add('${dm.code} → $icn');
      }
    }
    for (final pm in publications) {
      for (final ref in pm.allDmRefs) {
        check(pm.code, ref.code);
      }
    }
    for (final dml in dataModuleLists) {
      for (final entry in dml.entries) {
        if (entry.issueType != 'deleted') check(dml.code, entry.code);
      }
    }
    return missing.toList()..sort();
  }

  /// Her (kod, dil) için yalnız en yüksek sürüm.
  List<DataModule> get _latest {
    final best = <String, DataModule>{};
    for (final dm in dataModules) {
      final key = '${dm.code}_${dm.language}';
      final current = best[key];
      if (current == null || _issueKey(dm).compareTo(_issueKey(current)) > 0) {
        best[key] = dm;
      }
    }
    return best.values.toList();
  }

  static String _issueKey(DataModule dm) =>
      '${dm.issueNumber.padLeft(3, '0')}-${dm.inWork.padLeft(2, '0')}';

  static String _decode(List<int> bytes, String path) {
    try {
      final text = utf8.decode(bytes);
      return text.startsWith('﻿') ? text.substring(1) : text;
    } on FormatException {
      throw S1000dException('UTF-8 değil', file: path);
    }
  }
}

/// Bir IPD satırı ve geldiği DM.
class IpdItemRef {
  const IpdItemRef(this.dmc, this.item);

  final DmCode dmc;
  final IpdItem item;
}
