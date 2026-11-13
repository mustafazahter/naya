/// S1000D içeriğini okur: DM, PM, DML ve ICN; DMC, SNS ağacı, IPD ve arama
/// için parçalara bölünmüş içerik.
///
/// ```dart
/// final csdb = Csdb.read(files);
/// for (final system in csdb.snsTree) print(system.title);
/// final chunks = csdb.chunks; // FTS'e girecek parçalar
/// ```
library;

export 'src/chunk.dart';
export 'src/csdb.dart';
export 'src/data_module.dart';
export 'src/dm_code.dart';
export 'src/dm_document.dart';
export 'src/errors.dart';
export 'src/icn.dart';
export 'src/ipd.dart';
export 'src/publication_module.dart';
export 'src/sns.dart';
