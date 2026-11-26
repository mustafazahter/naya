import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import 'procedure_kind.dart';

/// SNS ağacından çıkan parçalar ve her parçaya düşen DM'ler.
class BuiltParts {
  BuiltParts(this.parts, this.modulesOf);

  final List<Part> parts;

  /// Parça kimliği → o parçanın kendi DM'leri (alt parçalarınınki değil).
  final Map<String, List<DataModule>> modulesOf;

  /// DM kodu → parça kimliği.
  late final Map<DmCode, String> partOfModule = {
    for (final e in modulesOf.entries)
      for (final dm in e.value) dm.code: e.key,
  };
}

/// Şematik modeldeki düğümün adı. Nokta yerine alt çizgi: three.js düğüm
/// adlarındaki noktaları siler, uygulama da adı olduğu gibi geri alır.
String nodeNameOf(String partId) => 'p_${partId.replaceAll('.', '_')}';

/// SNS ağacından `parts.json` parçalarını kurar.
///
/// Ağaçtaki her seviye parça olmaz: kodu sıfır olan seviye (`DA1-10`'daki
/// alt-alt sistem `0`, montaj `00`) yalnız bir ara katman; o katmanın DM'leri
/// en yakın gerçek üst parçaya yazılır. Genel bilgi sistemi (`D00`, `00`)
/// parça değildir; ondan başka sistem yoksa yine de alınır, yoksa dosya
/// boş kalırdı.
///
/// Yapraklar şematik modelde birer blok olur; grup parçaların `meshNodes`'u
/// altlarındaki blokların hepsidir.
BuiltParts buildParts(List<SnsNode> tree) {
  final specific = tree.where((s) => !_isGeneral(s.code)).toList();
  final built = _build(specific.isEmpty ? tree : specific);
  return built;
}

bool _isGeneral(String systemCode) => RegExp(r'00$').hasMatch(systemCode);

BuiltParts _build(List<SnsNode> systems) {
  final parts = <_Draft>[];
  final modulesOf = <String, List<DataModule>>{};

  void visit(SnsNode node, _Draft? parent) {
    _Draft? here = parent;
    if (_isPart(node)) {
      here = _Draft(
        id: node.code.toLowerCase().replaceAll('-', '.'),
        name: node.title.trim().isEmpty ? node.code : node.title.trim(),
        sns: _snsOf(node),
        parent: parent,
      );
      parts.add(here);
      modulesOf[here.id] = [];
    }
    if (here != null) modulesOf[here.id]!.addAll(node.dataModules);
    for (final child in node.children) {
      visit(child, here);
    }
  }

  for (final system in systems) {
    visit(system, null);
  }

  final childCount = <String, int>{};
  for (final p in parts) {
    final parent = p.parent;
    if (parent != null) {
      childCount[parent.id] = (childCount[parent.id] ?? 0) + 1;
    }
  }
  List<String> leafNodesUnder(_Draft part) => [
    if ((childCount[part.id] ?? 0) == 0) nodeNameOf(part.id),
    for (final child in parts.where((c) => c.parent == part))
      ...leafNodesUnder(child),
  ];

  final result = [
    for (final p in parts)
      Part(
        id: p.id,
        name: p.name,
        parent: p.parent?.id,
        sns: p.sns,
        meshNodes: leafNodesUnder(p),
        procedures: _proceduresOf(modulesOf[p.id]!),
      ),
  ];
  return BuiltParts(result, modulesOf);
}

class _Draft {
  _Draft({
    required this.id,
    required this.name,
    required this.sns,
    this.parent,
  });

  final String id;
  final String name;
  final String sns;
  final _Draft? parent;
}

/// Sıfır kodlu seviyeler parça değil, ara katman.
bool _isPart(SnsNode node) {
  final code = node.code;
  return switch (node.level) {
    SnsLevel.system => true,
    // DA1-1: alt sistem 1.
    SnsLevel.subSystem => !code.endsWith('-0'),
    // DA1-10: alt-alt sistem 0.
    SnsLevel.subSubSystem => !code.endsWith('0'),
    // DA1-10-00: montaj 00.
    SnsLevel.assembly => !RegExp(r'-0+$').hasMatch(code),
  };
}

/// Uygulamanın tanıtım DM'ini bulmak için beklediği biçim: `DA1-10`
/// (sistem, alt sistem + alt-alt sistem), montajda `DA1-10-01`.
String _snsOf(SnsNode node) {
  final code = node.code;
  return switch (node.level) {
    SnsLevel.system => '$code-00',
    SnsLevel.subSystem => '${code}0',
    SnsLevel.subSubSystem || SnsLevel.assembly => code,
  };
}

/// Türü başına ilk (en küçük kodlu) prosedür.
Map<String, String> _proceduresOf(List<DataModule> modules) {
  final sorted = modules.toList()..sort((a, b) => a.code.compareTo(b.code));
  final procedures = <String, String>{};
  for (final dm in sorted) {
    final kind = procedureKind(dm.code.infoCode);
    if (kind != null) procedures.putIfAbsent(kind, dm.code.toString);
  }
  return procedures;
}
