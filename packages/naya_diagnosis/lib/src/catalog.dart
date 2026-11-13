import 'package:naya_format/naya_format.dart';

/// Teşhiste sorulan seçeneklerin kaynağı: ürünün sistemleri, parçaları ve
/// bilinen arızaları (`parts.json`, `faults.json`).
///
/// Sistem, parça ağacının kökündeki parçadır (Aktarma organları, Frenler).
/// Bir sistemin adayları onun altındaki bütün parçalardır; altında parça
/// yoksa (Kadro gibi) sistemin kendisi tek aday olur.
class DiagnosisCatalog {
  DiagnosisCatalog({
    required this.productTitle,
    required PartsFile parts,
    FaultsFile? faults,
  }) : _parts = parts.parts,
       _faults = faults?.faults ?? const [],
       _symptoms = {
         for (final s in faults?.symptoms ?? const <Symptom>[]) s.id: s.text,
       };

  final String productTitle;
  final List<Part> _parts;
  final List<Fault> _faults;
  final Map<String, String> _symptoms;

  late final Map<String, Part> _byId = {for (final p in _parts) p.id: p};

  Part? part(String id) => _byId[id];

  /// Ağacın kökündeki parçalar, dosyadaki sırayla.
  List<Part> get systems => [
    for (final p in _parts)
      if (p.parent == null || !_byId.containsKey(p.parent)) p,
  ];

  /// Sistemin teşhiste sorulacak parçaları.
  List<Part> partsOf(String systemId) {
    final below = [
      for (final p in _parts)
        if (p.id != systemId && systemOf(p.id) == systemId) p,
    ];
    final system = _byId[systemId];
    if (below.isEmpty && system != null) return [system];
    return below;
  }

  /// Parçanın bağlı olduğu sistem (kökteki üst parça).
  String systemOf(String partId) {
    var current = _byId[partId];
    var guard = 0;
    while (current != null && guard++ < _parts.length) {
      final parent = current.parent;
      if (parent == null || !_byId.containsKey(parent)) return current.id;
      current = _byId[parent];
    }
    return partId;
  }

  /// [ancestor], [id]'nin kendisi ya da üst parçalarından biri mi?
  bool isWithin(String id, String ancestor) {
    var current = _byId[id];
    var guard = 0;
    while (current != null && guard++ < _parts.length) {
      if (current.id == ancestor) return true;
      current = _byId[current.parent ?? ''];
    }
    return false;
  }

  /// Parçanın ve altındaki parçaların arızaları.
  List<Fault> faultsOf(String partId) => [
    for (final f in _faults)
      if (isWithin(f.part, partId)) f,
  ];

  Fault? fault(String id) {
    for (final f in _faults) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Arızanın belirtileri, metin olarak.
  List<String> symptomsOf(Fault fault) => [
    for (final id in fault.symptoms) _symptoms[id] ?? id,
  ];

  /// Sistem seçeneğinin modele giden açıklaması: adı, ne işe yaradığı,
  /// içindeki parçalar ve bilinen belirtiler.
  String describeSystem(Part system) {
    final members = partsOf(system.id).where((p) => p.id != system.id);
    final symptoms = _symptomTexts(system.id);
    return [
      '${system.name}.',
      ?system.function,
      if (members.isNotEmpty)
        'Parçaları: ${members.map((p) => p.name).join(', ')}.',
      if (symptoms.isNotEmpty) 'Bilinen belirtiler: ${symptoms.join('; ')}.',
    ].join(' ');
  }

  /// Parça seçeneğinin açıklaması.
  String describePart(Part part) {
    final symptoms = _symptomTexts(part.id);
    return [
      '${part.name}.',
      ?part.function,
      if (symptoms.isNotEmpty) 'Bilinen belirtiler: ${symptoms.join('; ')}.',
    ].join(' ');
  }

  /// Arıza seçeneğinin açıklaması.
  String describeFault(Fault fault) {
    final symptoms = symptomsOf(fault);
    return [
      fault.cause,
      if (symptoms.isNotEmpty) 'Belirtileri: ${symptoms.join('; ')}.',
    ].join(' ');
  }

  /// Parçanın ve altındakilerin arızalarındaki belirtiler, tekrarsız.
  List<String> _symptomTexts(String partId) {
    final texts = <String>[];
    for (final fault in faultsOf(partId)) {
      for (final text in symptomsOf(fault)) {
        if (!texts.contains(text)) texts.add(text);
      }
    }
    return texts;
  }
}
