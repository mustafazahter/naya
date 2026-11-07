import 'dm_code.dart';

/// Bir DM'in arama (FTS) ve yapay zekâ bağlamı için ayrılmış bir parçası:
/// tanımda bir paragraf grubu, prosedürde bir adım, katalogda bir satır.
///
/// Teşhiste cevaba kaynak gösterebilmek için her parça geldiği DM'i,
/// bölümünü ve içinde geçen parça numaralarını taşır.
class Chunk {
  const Chunk({
    required this.dmc,
    required this.dmTitle,
    required this.section,
    required this.text,
    this.partNumbers = const [],
    this.icns = const [],
  });

  final DmCode dmc;
  final String dmTitle;

  /// DM içindeki yeri: "Bileşenler › Zincir", "Adım 3", "Şekil 1, öğe 4".
  /// DM'in tamamıysa boş.
  final String section;
  final String text;
  final List<String> partNumbers;
  final List<String> icns;

  InfoKind get kind => dmc.kind;

  /// SNS yolu; teşhiste "hangi sistem?" sorusu için.
  String get sns => dmc.sns;

  @override
  String toString() => '$dmc [$section] $text';
}
