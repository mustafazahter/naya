import 'dart:convert';
import 'dart:typed_data';

/// Bir `.glb` dosyasındaki düğüm (node) adları.
///
/// GLB'nin ilk parçası (chunk) sahnenin JSON tanımı; geometriye dokunmadan
/// yalnız onu okuyoruz. `parts.json`'daki `meshNodes` adlarının modelde
/// gerçekten olup olmadığını kontrol etmek için yeterli.
///
/// [meshOnly] ise yalnız geometri taşıyan düğümler; gruplama için kullanılan
/// boş düğümler (kök gibi) atlanır.
Set<String> glbNodeNames(List<int> bytes, {bool meshOnly = false}) {
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  const magic = 0x46546C67; // "glTF"
  const jsonChunk = 0x4E4F534A; // "JSON"
  if (data.lengthInBytes < 20 || data.getUint32(0, Endian.little) != magic) {
    throw const FormatException('GLB değil');
  }
  final length = data.getUint32(12, Endian.little);
  final type = data.getUint32(16, Endian.little);
  if (type != jsonChunk || 20 + length > data.lengthInBytes) {
    throw const FormatException('GLB JSON bölümü okunamadı');
  }
  final json = jsonDecode(
    utf8.decode(bytes.sublist(20, 20 + length)),
  ) as Map<String, Object?>;
  final nodes = (json['nodes'] as List<Object?>?) ?? const [];
  return {
    for (final node in nodes)
      if (node is Map &&
          node['name'] is String &&
          (!meshOnly || node['mesh'] != null))
        node['name'] as String,
  };
}
