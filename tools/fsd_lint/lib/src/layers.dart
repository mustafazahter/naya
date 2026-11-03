import 'package:path/path.dart' as p;

/// FSD katmanları, en üstten en alta.
const layers = ['app', 'pages', 'widgets', 'features', 'entities', 'shared'];

/// Bir dosyanın `lib/` altındaki yeri: katman ve dilim.
///
/// `lib/features/diagnose/model.dart` için katman `features`, dilim `diagnose`.
/// `app` ve `shared` dilimlere bölünmez.
class LayerPath {
  const LayerPath(this.layer, this.slice);

  final String layer;
  final String? slice;

  int get rank => layers.indexOf(layer);

  /// Dosya yolundan katmanı çıkarır; `lib/` altında bir katmanda değilse null.
  static LayerPath? fromFile(String path) {
    final parts = p.split(p.normalize(path));
    final lib = parts.lastIndexOf('lib');
    // Kural yalnız Flutter uygulamasında geçerli: apps/naya/lib/...
    if (lib < 2 || parts[lib - 2] != 'apps' || parts[lib - 1] != 'naya') {
      return null;
    }
    if (lib + 2 > parts.length - 1) return null;
    final layer = parts[lib + 1];
    if (!layers.contains(layer)) return null;
    final hasSlice = lib + 3 < parts.length;
    return LayerPath(layer, hasSlice ? parts[lib + 2] : null);
  }
}

/// [from] katmanındaki bir dosyanın [to] katmanını import edip edemeyeceği.
///
/// Alttaki katmanlar serbest. Aynı katmanda yalnız aynı dilim içinden import
/// yapılabilir; `app` ve `shared` kendi içinde serbesttir.
bool canImport(LayerPath from, LayerPath to) {
  if (to.rank > from.rank) return true;
  if (to.rank < from.rank) return false;
  if (from.layer == 'app' || from.layer == 'shared') return true;
  return from.slice != null && from.slice == to.slice;
}
