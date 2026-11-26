/// Dağınık S1000D dosyalarını (zip) `.naya` dosyasına çevirir: montaj
/// ağacı SNS'ten, arızalar arıza bulma DM'lerinden, model şematik.
///
/// ```dart
/// final result = importS1000dZip(zipBytes);
/// print(result.report.dataModules);
/// final bytes = result.file.encode();
/// ```
library;

export 'src/import_exception.dart';
export 'src/procedure_kind.dart';
export 'src/s1000d_import.dart';
export 'src/schematic_glb.dart';
export 'src/zip_files.dart';
