import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:naya_format/naya_format.dart';

import 'parts_builder.dart';

/// Modeli olmayan S1000D verisi için şematik 3D: her yaprak parça bir
/// blok, bloklar sistemlerine göre gruplanmış ve renklendirilmiş.
///
/// Gerçek bir şekil değil, montaj ağacının haritası. Viewer'ın beklediği
/// yapı şablonlarla aynı: kökün altında tek sarmalayıcı düğüm, onun altında
/// her parça için adı `meshNodes`'taki adla aynı bir düğüm. Böylece seçme,
/// parlama, tarama ve parçalara ayırma olduğu gibi çalışır.
///
/// Bloğun yüksekliği parçanın DM sayısıyla biraz artar; içeriği çok olan
/// parça göze çarpar. Birimler metre, yukarı Y.
Uint8List schematicGlb(BuiltParts built) {
  final parts = built.parts;
  final children = <String, List<Part>>{};
  for (final p in parts) {
    if (p.parent != null) (children[p.parent!] ??= []).add(p);
  }
  List<Part> leavesUnder(Part p) {
    final kids = children[p.id];
    if (kids == null) return [p];
    return [for (final k in kids) ...leavesUnder(k)];
  }

  final systems = [
    for (final p in parts)
      if (p.parent == null) p,
  ];

  // Her sistem kare yakın bir ızgara; sistemler soldan sağa, satır
  // dolunca alta. Satır genişliği toplam alanın kareköküne göre.
  const cell = 0.4, block = 0.32, gap = 0.3;
  final grids = [
    for (final s in systems) (s, leavesUnder(s), _columns(leavesUnder(s))),
  ];
  final totalArea = grids.fold<double>(
    0,
    (sum, g) => sum + _width(g.$3) * _depth(g.$2.length, g.$3),
  );
  final rowLimit = max(sqrt(totalArea) * 1.6, 1.2);

  final nodes = <Map<String, Object?>>[];
  final materials = <Map<String, Object?>>[];
  final meshes = <Map<String, Object?>>[];
  var x = 0.0, z = 0.0, rowDepth = 0.0;
  for (final (i, (system, leaves, columns)) in grids.indexed) {
    final width = _width(columns);
    final depth = _depth(leaves.length, columns);
    if (x > 0 && x + width > rowLimit) {
      x = 0;
      z += rowDepth + gap;
      rowDepth = 0;
    }
    materials.add(_material(system.name, _palette[i % _palette.length]));
    meshes.add({
      'name': system.name,
      'primitives': [
        {
          'attributes': {'POSITION': 0, 'NORMAL': 1},
          'indices': 2,
          'material': i,
        },
      ],
    });
    for (final (k, leaf) in leaves.indexed) {
      final count = built.modulesOf[leaf.id]?.length ?? 0;
      final height = 0.12 + 0.04 * min(count, 6);
      nodes.add({
        'name': nodeNameOf(leaf.id),
        'mesh': i,
        'translation': [
          _round(x + (k % columns) * cell + cell / 2),
          _round(height / 2),
          _round(z + (k ~/ columns) * cell + cell / 2),
        ],
        'scale': [block, _round(height), block],
      });
    }
    x += width + gap;
    rowDepth = max(rowDepth, depth);
  }

  // Ortalamaya gerek yok: viewer modeli zemine oturtup yatayda kendisi
  // ortalıyor.
  final root = {
    'name': 'schematic',
    'children': [for (var n = 0; n < nodes.length; n++) n],
  };
  nodes.add(root);

  final bin = _cubeBuffer();
  final json = {
    'asset': {'version': '2.0', 'generator': 'naya_import'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [nodes.length - 1],
      },
    ],
    'nodes': nodes,
    'meshes': meshes,
    'materials': materials,
    'buffers': [
      {'byteLength': bin.length},
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': 288, 'target': 34962},
      {'buffer': 0, 'byteOffset': 288, 'byteLength': 288, 'target': 34962},
      {'buffer': 0, 'byteOffset': 576, 'byteLength': 72, 'target': 34963},
    ],
    'accessors': [
      {
        'bufferView': 0,
        'componentType': 5126,
        'count': 24,
        'type': 'VEC3',
        'min': [-0.5, -0.5, -0.5],
        'max': [0.5, 0.5, 0.5],
      },
      {'bufferView': 1, 'componentType': 5126, 'count': 24, 'type': 'VEC3'},
      {'bufferView': 2, 'componentType': 5123, 'count': 36, 'type': 'SCALAR'},
    ],
  };
  return _glb(utf8.encode(jsonEncode(json)), bin);
}

int _columns(List<Part> leaves) => max(1, sqrt(leaves.length).ceil());
double _width(int columns) => columns * 0.4;
double _depth(int count, int columns) => (count / columns).ceil() * 0.4;
double _round(double v) => (v * 1000).roundToDouble() / 1000;

/// Uygulamanın koyu temasıyla uyumlu, birbirinden ayrılan sakin tonlar.
const _palette = [
  [0.44, 0.62, 0.86],
  [0.86, 0.66, 0.36],
  [0.47, 0.74, 0.58],
  [0.80, 0.48, 0.48],
  [0.64, 0.54, 0.84],
  [0.42, 0.74, 0.78],
  [0.84, 0.76, 0.46],
  [0.70, 0.70, 0.72],
];

Map<String, Object?> _material(String name, List<double> rgb) => {
  'name': name,
  'pbrMetallicRoughness': {
    'baseColorFactor': [...rgb, 1.0],
    'metallicFactor': 0.1,
    'roughnessFactor': 0.6,
  },
};

/// Kenarı 1 olan, merkezi sıfırda bir küp: her yüz kendi normaliyle dört
/// köşe (24 köşe, 36 indis). Bütün bloklar bunu ölçekleyerek kullanır.
Uint8List _cubeBuffer() {
  const faces = [
    // normal, iki kenar yönü (köşeler normal yönünden saat yönünün tersine)
    ([1.0, 0.0, 0.0], [0.0, 0.0, -1.0], [0.0, 1.0, 0.0]),
    ([-1.0, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0]),
    ([0.0, 1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 0.0, -1.0]),
    ([0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0]),
    ([0.0, 0.0, 1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]),
    ([0.0, 0.0, -1.0], [-1.0, 0.0, 0.0], [0.0, 1.0, 0.0]),
  ];
  final data = ByteData(648);
  var v = 0;
  for (final (n, u, w) in faces) {
    for (final (su, sw) in const [(-1, -1), (1, -1), (1, 1), (-1, 1)]) {
      for (var a = 0; a < 3; a++) {
        final p = 0.5 * n[a] + 0.5 * su * u[a] + 0.5 * sw * w[a];
        data.setFloat32(v * 12 + a * 4, p, Endian.little);
        data.setFloat32(288 + v * 12 + a * 4, n[a], Endian.little);
      }
      v++;
    }
  }
  for (var f = 0; f < 6; f++) {
    final base = f * 4;
    const order = [0, 1, 2, 0, 2, 3];
    for (var k = 0; k < 6; k++) {
      data.setUint16(576 + (f * 6 + k) * 2, base + order[k], Endian.little);
    }
  }
  return data.buffer.asUint8List();
}

/// GLB kabı: başlık, 4 bayta boşlukla tamamlanmış JSON ve sıfırla
/// tamamlanmış ikili parça.
Uint8List _glb(List<int> json, Uint8List bin) {
  final jsonPadded = [...json, ...List.filled((4 - json.length % 4) % 4, 0x20)];
  final binPadded = [...bin, ...List.filled((4 - bin.length % 4) % 4, 0)];
  final total = 12 + 8 + jsonPadded.length + 8 + binPadded.length;
  final out = BytesBuilder();
  final header = ByteData(12)
    ..setUint32(0, 0x46546C67, Endian.little) // glTF
    ..setUint32(4, 2, Endian.little)
    ..setUint32(8, total, Endian.little);
  out.add(header.buffer.asUint8List());
  out.add(_chunkHeader(jsonPadded.length, 0x4E4F534A)); // JSON
  out.add(jsonPadded);
  out.add(_chunkHeader(binPadded.length, 0x004E4942)); // BIN
  out.add(binPadded);
  return out.toBytes();
}

Uint8List _chunkHeader(int length, int type) =>
    (ByteData(8)
          ..setUint32(0, length, Endian.little)
          ..setUint32(4, type, Endian.little))
        .buffer
        .asUint8List();
