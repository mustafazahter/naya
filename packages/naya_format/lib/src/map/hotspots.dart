import '../json_reader.dart';

const _file = 'map/hotspots.json';

/// `map/hotspots.json`: model üzerinde etiket gösterilecek noktalar.
class HotspotsFile {
  HotspotsFile(this.hotspots);

  factory HotspotsFile.fromJson(Object? json) {
    final r = JsonReader(json, _file);
    return HotspotsFile([
      for (final h in r.objects('hotspots')) Hotspot._read(h),
    ]);
  }

  final List<Hotspot> hotspots;

  Map<String, Object?> toJson() => {
    'hotspots': [for (final h in hotspots) h.toJson()],
  };
}

class Hotspot {
  const Hotspot({
    required this.id,
    required this.part,
    required this.position,
    this.label,
  });

  factory Hotspot._read(JsonReader r) => Hotspot(
    id: r.string('id'),
    part: r.string('part'),
    position: r.numbers('position', length: 3),
    label: r.optionalString('label'),
  );

  final String id;
  final String part;

  /// Model koordinatlarında `[x, y, z]`.
  final List<double> position;
  final String? label;

  Map<String, Object?> toJson() => {
    'id': id,
    'part': part,
    'position': position,
    if (label != null) 'label': label,
  };
}
