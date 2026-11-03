import '../json_reader.dart';

const _file = 'map/parts.json';

/// `map/parts.json`: ürünün montaj ağacı.
///
/// [Part.parent] alanından çıkan ağaç üç yerde kullanılır: viewer'da
/// parçalara ayırma, teşhiste sistem → parça seçimi ve tarama sırası.
class PartsFile {
  PartsFile(this.parts);

  factory PartsFile.fromJson(Object? json) {
    final r = JsonReader(json, _file);
    final parts = [for (final p in r.objects('parts')) Part._read(p)];
    _checkTree(r, parts);
    return PartsFile(parts);
  }

  final List<Part> parts;

  late final Map<String, Part> _byId = {for (final p in parts) p.id: p};

  Part? operator [](String id) => _byId[id];

  /// Ağacın kökleri: üst parçası olmayanlar.
  List<Part> get roots => [
    for (final p in parts)
      if (p.parent == null) p,
  ];

  List<Part> childrenOf(String id) => [
    for (final p in parts)
      if (p.parent == id) p,
  ];

  Map<String, Object?> toJson() => {
    'parts': [for (final p in parts) p.toJson()],
  };

  /// Kimlikler benzersiz mi, her `parent` var olan bir parçayı mı gösteriyor
  /// ve ağaçta döngü var mı?
  static void _checkTree(JsonReader r, List<Part> parts) {
    final ids = <String>{};
    for (final p in parts) {
      if (!ids.add(p.id)) r.fail('"${p.id}" kimliği birden fazla kez geçiyor');
    }
    final parentOf = {for (final p in parts) p.id: p.parent};
    for (final p in parts) {
      if (p.parent != null && !ids.contains(p.parent)) {
        r.fail('"${p.id}" parçasının üstü "${p.parent}" bulunamadı');
      }
      // Yukarı doğru yürürken aynı parçaya dönülürse döngü vardır.
      final seen = <String>{p.id};
      var current = p.parent;
      while (current != null) {
        if (!seen.add(current)) r.fail('"${p.id}" montaj ağacında döngü var');
        current = parentOf[current];
      }
    }
  }
}

class Part {
  const Part({
    required this.id,
    required this.name,
    this.parent,
    this.sns,
    this.meshNodes = const [],
    this.zone,
    this.function,
    this.ipd,
    this.procedures = const {},
    this.media = const [],
    this.explode,
  });

  factory Part._read(JsonReader r) {
    final ipd = r.optionalObject('ipd');
    final explode = r.optionalObject('explode');
    return Part(
      id: r.string('id'),
      name: r.string('name'),
      parent: r.optionalString('parent'),
      sns: r.optionalString('sns'),
      meshNodes: r.strings('meshNodes', optional: true),
      zone: r.optionalString('zone'),
      function: r.optionalString('function'),
      ipd: ipd == null ? null : IpdRef._read(ipd),
      procedures: r.stringMap('procedures', optional: true),
      media: r.strings('media', optional: true),
      explode: explode == null ? null : Explode._read(explode),
    );
  }

  /// Noktalı kimlik, örneğin `eng.fuel.pump`.
  final String id;
  final String name;
  final String? parent;

  /// S1000D sistem numarası (SNS), örneğin `28-20`.
  final String? sns;

  /// 3D modelde bu parçaya ait node adları.
  final List<String> meshNodes;
  final String? zone;

  /// Parçanın ne işe yaradığı, tek cümle.
  final String? function;
  final IpdRef? ipd;

  /// İşlem türünden DMC'ye: `remove`, `install`, `inspect`...
  final Map<String, String> procedures;
  final List<String> media;
  final Explode? explode;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (parent != null) 'parent': parent,
    if (sns != null) 'sns': sns,
    if (meshNodes.isNotEmpty) 'meshNodes': meshNodes,
    if (zone != null) 'zone': zone,
    if (function != null) 'function': function,
    if (ipd != null) 'ipd': ipd!.toJson(),
    if (procedures.isNotEmpty) 'procedures': procedures,
    if (media.isNotEmpty) 'media': media,
    if (explode != null) 'explode': explode!.toJson(),
  };
}

/// Resimli parça kataloğundaki (IPD) yeri.
class IpdRef {
  const IpdRef({required this.dmc, required this.figure, required this.item});

  factory IpdRef._read(JsonReader r) => IpdRef(
    dmc: r.string('dmc'),
    figure: r.string('figure'),
    item: r.string('item'),
  );

  final String dmc;
  final String figure;
  final String item;

  Map<String, Object?> toJson() => {'dmc': dmc, 'figure': figure, 'item': item};
}

/// Parçalara ayırırken bu parçanın hangi yöne, ne kadar gideceği.
class Explode {
  const Explode({required this.dir, required this.dist});

  factory Explode._read(JsonReader r) =>
      Explode(dir: r.numbers('dir', length: 3), dist: r.number('dist'));

  final List<double> dir;
  final double dist;

  Map<String, Object?> toJson() => {'dir': dir, 'dist': dist};
}
