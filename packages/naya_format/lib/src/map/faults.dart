import '../json_reader.dart';

const _file = 'map/faults.json';

/// `map/faults.json`: belirtiler ve bunlara yol açan arızalar.
class FaultsFile {
  FaultsFile({required this.symptoms, required this.faults});

  factory FaultsFile.fromJson(Object? json) {
    final r = JsonReader(json, _file);
    final symptoms = [for (final s in r.objects('symptoms')) Symptom._read(s)];
    final faults = [for (final f in r.objects('faults')) Fault._read(f)];

    final symptomIds = {for (final s in symptoms) s.id};
    for (final f in faults) {
      final unknown = f.symptoms.where((id) => !symptomIds.contains(id));
      if (unknown.isNotEmpty) {
        r.fail('"${f.id}" arızası tanımsız belirtiye bağlı: ${unknown.first}');
      }
    }
    return FaultsFile(symptoms: symptoms, faults: faults);
  }

  final List<Symptom> symptoms;
  final List<Fault> faults;

  List<Fault> faultsOf(String partId) => [
    for (final f in faults)
      if (f.part == partId) f,
  ];

  Map<String, Object?> toJson() => {
    'symptoms': [for (final s in symptoms) s.toJson()],
    'faults': [for (final f in faults) f.toJson()],
  };
}

class Symptom {
  const Symptom({required this.id, required this.text});

  factory Symptom._read(JsonReader r) =>
      Symptom(id: r.string('id'), text: r.string('text'));

  final String id;

  /// Kullanıcının ağzından, örneğin "Marş basıyor ama çalışmıyor".
  final String text;

  Map<String, Object?> toJson() => {'id': id, 'text': text};
}

class Fault {
  const Fault({
    required this.id,
    required this.part,
    required this.symptoms,
    required this.cause,
    required this.severity,
    this.isolation,
    this.repair,
  });

  factory Fault._read(JsonReader r) {
    final severity = r.integer('severity');
    if (severity < 1 || severity > 5) {
      r.fail('"severity" 1 ile 5 arasında olmalı');
    }
    return Fault(
      id: r.string('id'),
      part: r.string('part'),
      symptoms: r.strings('symptoms'),
      cause: r.string('cause'),
      severity: severity,
      isolation: r.optionalString('isolation'),
      repair: r.optionalString('repair'),
    );
  }

  final String id;

  /// Arızanın olduğu parçanın kimliği (`parts.json`).
  final String part;
  final List<String> symptoms;
  final String cause;

  /// 1 (önemsiz) ile 5 (kullanmak tehlikeli) arası.
  final int severity;

  /// Arıza tespit prosedürünün DMC'si.
  final String? isolation;

  /// Tamir prosedürünün DMC'si.
  final String? repair;

  Map<String, Object?> toJson() => {
    'id': id,
    'part': part,
    'symptoms': symptoms,
    'cause': cause,
    'severity': severity,
    if (isolation != null) 'isolation': isolation,
    if (repair != null) 'repair': repair,
  };
}
