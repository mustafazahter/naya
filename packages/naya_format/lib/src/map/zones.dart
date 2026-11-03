import '../json_reader.dart';

const _file = 'map/zones.json';

/// `map/zones.json`: ürünün bölgeleri (ön, arka alt gövde, kokpit...).
/// Kullanıcı "arkadan ses geliyor" dediğinde aramayı daraltmak için.
class ZonesFile {
  ZonesFile(this.zones);

  factory ZonesFile.fromJson(Object? json) {
    final r = JsonReader(json, _file);
    return ZonesFile([for (final z in r.objects('zones')) Zone._read(z)]);
  }

  final List<Zone> zones;

  Map<String, Object?> toJson() => {
    'zones': [for (final z in zones) z.toJson()],
  };
}

class Zone {
  const Zone({required this.id, required this.name, this.parent});

  factory Zone._read(JsonReader r) => Zone(
    id: r.string('id'),
    name: r.string('name'),
    parent: r.optionalString('parent'),
  );

  final String id;
  final String name;
  final String? parent;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (parent != null) 'parent': parent,
  };
}
