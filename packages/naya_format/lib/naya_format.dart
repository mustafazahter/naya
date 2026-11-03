/// `.naya` dosya formatı: ZIP kabı, manifest ve harita dosyaları.
///
/// ```dart
/// final file = NayaFile.decode(bytes);
/// print(file.manifest.title);
/// final parts = file.parts?.parts ?? [];
/// ```
library;

export 'src/errors.dart';
export 'src/format_version.dart';
export 'src/manifest.dart';
export 'src/map/faults.dart';
export 'src/map/hotspots.dart';
export 'src/map/parts.dart';
export 'src/map/zones.dart';
export 'src/naya_file.dart';
