/// Bir görselin (çizim, fotoğraf, 3D) kimliği (ICN) ve dosyası.
///
/// ICN iki biçimde yazılabiliyor (model kodlu ve CAGE kodlu); ikisinde de son
/// iki alan sürüm ve güvenlik sınıfı. Aradaki alanları v1'de ayırmıyoruz.
class Icn {
  const Icn({required this.ident, required this.path});

  /// Dosya yolundan okur: `csdb/ICN-...-01.CGM` → ident `ICN-...-01`.
  /// ICN dosyası değilse null.
  static Icn? fromPath(String path) {
    final name = path.split('/').last;
    if (!name.toUpperCase().startsWith('ICN-')) return null;
    final dot = name.lastIndexOf('.');
    return Icn(ident: dot < 0 ? name : name.substring(0, dot), path: path);
  }

  final String ident;
  final String path;

  /// Dosya uzantısı küçük harfle: `cgm`, `png`, `svg`...
  String get extension {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }

  String get issueNumber {
    final p = ident.split('-');
    return p.length >= 3 ? p[p.length - 2] : '';
  }

  String get securityClassification => ident.split('-').last;
}
