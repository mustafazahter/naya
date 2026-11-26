import 'dart:convert';

import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:xml/xml.dart';

import 'parts_builder.dart';

/// Arıza bulma DM'lerinden (`faultIsolation`) `faults.json` kurar.
///
/// Her `faultIsolationProcedure` bir arıza olur. Arızanın tarifi
/// (`faultDescr`) hem belirti hem neden olarak yazılır; dışarıdan gelen
/// veride ayrı bir neden metni yok. Arıza, bulma DM'inin düştüğü parçaya
/// bağlanır; onarım o parçanın değiştirme, yoksa sökme, yoksa ayar
/// prosedürü. Önem derecesi bilinmediği için 3.
///
/// [xmlOf] bir DM'in metnini verir; bulunamazsa arıza DM'in başlığından
/// kurulur.
FaultsFile buildFaults(
  BuiltParts built,
  Iterable<DataModule> modules,
  String? Function(DataModule dm) xmlOf,
) {
  final partsById = {for (final p in built.parts) p.id: p};
  final symptoms = <String, Symptom>{};
  final faults = <Fault>[];
  final perPart = <String, int>{};

  // Aynı DM'in eski sürümleri de pakette olabilir; her kod bir kez, en
  // yeni sürümüyle sayılır.
  final latest = <DmCode, DataModule>{};
  for (final dm in modules.where((m) => m.contentType == 'faultIsolation')) {
    final current = latest[dm.code];
    if (current == null || _issueKey(dm).compareTo(_issueKey(current)) > 0) {
      latest[dm.code] = dm;
    }
  }
  final isolation = latest.values.toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  for (final dm in isolation) {
    final partId = built.partOfModule[dm.code];
    if (partId == null) continue;
    final part = partsById[partId]!;
    final descriptions = _faultDescriptions(xmlOf(dm));
    if (descriptions.isEmpty) descriptions.add(dm.title);
    for (final text in descriptions) {
      final symptom = symptoms.putIfAbsent(
        text,
        () => Symptom(id: 'sym.${symptoms.length + 1}', text: text),
      );
      final n = perPart[partId] = (perPart[partId] ?? 0) + 1;
      faults.add(
        Fault(
          id: 'f.$partId.$n',
          part: partId,
          symptoms: [symptom.id],
          cause: text,
          severity: 3,
          isolation: dm.code.toString(),
          repair:
              part.procedures['replace'] ??
              part.procedures['remove'] ??
              part.procedures['adjust'],
        ),
      );
    }
  }
  return FaultsFile(symptoms: symptoms.values.toList(), faults: faults);
}

/// DM'deki her arıza bulma prosedürünün tarifi; okunamazsa boş liste.
List<String> _faultDescriptions(String? xml) {
  if (xml == null) return [];
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    return [];
  }
  final texts = <String>[];
  for (final procedure in doc.findAllElements('faultIsolationProcedure')) {
    final descr = procedure.getElement('faultDescr');
    final text = descr == null ? '' : _plain(descr.innerText);
    if (text.isNotEmpty && !texts.contains(text)) texts.add(text);
  }
  return texts;
}

String _issueKey(DataModule dm) =>
    '${dm.issueNumber.padLeft(3, '0')}-${dm.inWork.padLeft(2, '0')}';

String _plain(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Baytlardan UTF-8 metin (baştaki BOM atılır); çözülemezse null.
String? decodeXml(List<int> bytes) {
  try {
    final text = utf8.decode(bytes);
    return text.startsWith('﻿') ? text.substring(1) : text;
  } on FormatException {
    return null;
  }
}
