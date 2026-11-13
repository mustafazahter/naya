import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import '../../shared/api/api_client.dart';

/// Bir ürünün çalışma alanında kullanılan içeriği: parça haritası, arızalar
/// ve `.naya` içindeki DM ve çizimlerin yolları.
///
/// `.naya`'nın tamamı (model dahil ~8 MB) indirilmez; sunucudan yalnız
/// gereken kayıtlar tek tek alınır.
class ProductContent {
  ProductContent({
    required this.productId,
    required this.parts,
    this.faults,
    Iterable<String> entryNames = const [],
  }) {
    // Sıralı gezilince aynı DM'in sonraki sayısı (`_002-00`) sonra gelir
    // ve öncekinin yerine geçer.
    final sorted = entryNames.toList()..sort();
    for (final path in sorted) {
      final name = path.split('/').last.toUpperCase();
      if (name.startsWith('DMC-')) {
        _addDm(name, path);
      } else if (name.startsWith('ICN-')) {
        _addIcn(name, path);
      }
    }
  }

  /// `DMC-..._001-00_TR-TR.XML`. Aynı DM birden çok dilde varsa Türkçesi
  /// seçilir; dil aynıysa en yeni sayı kalır.
  void _addDm(String name, String path) {
    final code = name.split('_').first;
    final existing = _dmPaths[code];
    final isTurkish = name.contains('_TR-');
    final existingTurkish =
        existing != null && existing.toUpperCase().contains('_TR-');
    if (existing == null || isTurkish || !existingTurkish) {
      _dmPaths[code] = path;
    }
  }

  /// `ICN-....JPG`. Aynı çizimin birden çok biçimi varsa `Image.network`'ün
  /// açabildiği bir resim (PNG, JPG, WEBP) tercih edilir; SVG gibi diğerleri
  /// yalnız başka seçenek yoksa kalır.
  void _addIcn(String name, String path) {
    final dot = name.lastIndexOf('.');
    final key = dot < 0 ? name : name.substring(0, dot);
    final existing = _icnPaths[key];
    if (existing == null || _isRaster(path) || !_isRaster(existing)) {
      _icnPaths[key] = path;
    }
  }

  static bool _isRaster(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  final String productId;
  final PartsFile parts;
  final FaultsFile? faults;

  final _dmPaths = <String, String>{};
  final _icnPaths = <String, String>{};

  late final Map<String, Part> _byId = {for (final p in parts.parts) p.id: p};

  Part? part(String id) => _byId[id];

  Fault? fault(String id) {
    for (final f in faults?.faults ?? const <Fault>[]) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// `.naya` içindeki DM dosyası; `DMC-` ile ya da onsuz kod alır.
  String? dmPath(String dmc) {
    final code = dmc.toUpperCase().trim();
    return _dmPaths[code.startsWith('DMC-') ? code : 'DMC-$code'];
  }

  /// `.naya` içindeki çizim dosyası (`ICN-...`).
  String? icnPath(String icn) => _icnPaths[icn.toUpperCase()];

  /// Modeldeki bir düğüme dokunulunca kartı açılacak parça.
  ///
  /// Bir düğüme birden çok parça bağlı olabilir: `drive_chain` hem
  /// "Aktarma organları" grubunda hem "Zincir"de. Seçim sırası:
  /// 1. en az düğümü olan parçalar (grup parçaları elenir),
  /// 2. bunlardan diğer adayları en çok kapsayan (`handlebar` → gidon
  ///    ve kumanda, kollar onun çocuğu),
  /// 3. ağaçta daha üstte olan, sonra dosyadaki sıra.
  Part? partForNode(String node) {
    final candidates = partsOnNode(node);
    if (candidates.isEmpty) return null;
    final fewest = candidates
        .map((p) => p.meshNodes.length)
        .reduce((a, b) => a < b ? a : b);
    final narrow = candidates
        .where((p) => p.meshNodes.length == fewest)
        .toList();
    int covered(Part p) =>
        narrow.where((other) => _isAncestor(p.id, other.id)).length;
    narrow.sort((a, b) {
      final byCover = covered(b).compareTo(covered(a));
      if (byCover != 0) return byCover;
      return depth(a.id).compareTo(depth(b.id));
    });
    return narrow.first;
  }

  /// Düğüme bağlı bütün parçalar, dosyadaki sırayla.
  List<Part> partsOnNode(String node) =>
      parts.parts.where((p) => p.meshNodes.contains(node)).toList();

  /// Kartta gösterilecek, aynı düğümdeki diğer parçalar: grup parçaları
  /// (birden çok düğümü olanlar) hariç.
  List<Part> siblingsOnNode(String node, Part shown) => [
    for (final p in partsOnNode(node))
      if (p.id != shown.id && p.meshNodes.length <= shown.meshNodes.length) p,
  ];

  List<Part> childrenOf(String id) =>
      parts.parts.where((p) => p.parent == id).toList();

  /// Kökten parçanın kendisine kadar: Aktarma organları › Zincir.
  List<Part> pathTo(String id) {
    final path = <Part>[];
    for (Part? p = _byId[id]; p != null; p = _byId[p.parent ?? '']) {
      path.insert(0, p);
      if (path.length > parts.parts.length) break;
    }
    return path;
  }

  int depth(String id) => pathTo(id).length - 1;

  /// Parçanın ve alt parçalarının arızaları, en ciddisi önce. Ön frenin
  /// kartında balata ve disk arızaları da görünür.
  List<Fault> faultsFor(String id) {
    final list = [
      for (final f in faults?.faults ?? const <Fault>[])
        if (f.part == id || _isAncestor(id, f.part)) f,
    ];
    list.sort((a, b) => b.severity.compareTo(a.severity));
    return list;
  }

  /// Arızaların belirtileri; sohbette öneri olarak gösteriliyor.
  List<Symptom> get symptoms => faults?.symptoms ?? const [];

  String symptomText(String id) {
    for (final s in symptoms) {
      if (s.id == id) return s.text;
    }
    return id;
  }

  /// Modeldeki düğümün ekranda görünecek adı.
  String nodeLabel(String node) => partForNode(node)?.name ?? node;

  /// [ancestor], [id]'nin üst montajlarından biri mi?
  bool _isAncestor(String ancestor, String id) {
    var current = _byId[id]?.parent;
    var guard = 0;
    while (current != null && guard++ < parts.parts.length) {
      if (current == ancestor) return true;
      current = _byId[current]?.parent;
    }
    return false;
  }
}

/// `.naya` içindeki bir kaydın sunucudaki adresi: çizimler, model.
Uri productEntryUri(ApiClient api, String productId, String path) =>
    api.uri(productEntryPath(productId, path));

/// Kayıt adresinin yolu. Dosya adındaki `#`, `?` gibi işaretler adresi
/// bozmasın diye her parça ayrı kodlanır; sunucu bir kez çözer.
String productEntryPath(String productId, String path) {
  final encoded = path.split('/').map(Uri.encodeComponent).join('/');
  return '/api/library/$productId/entries/$encoded';
}

/// Ürünün parça haritası ve arızaları. `naya.json`'daki bütünlük listesi
/// dosyadaki bütün kayıtların adını verdiği için DM'ler ayrıca listelenmez.
final productContentProvider = FutureProvider.family<ProductContent, String>((
  ref,
  productId,
) async {
  final api = ref.watch(apiClientProvider);
  final base = '/api/library/$productId/entries';
  final (manifest, parts, faults) = await (
    api.getJson('$base/naya.json'),
    api.getJson('$base/map/parts.json'),
    _optional(api.getJson('$base/map/faults.json')),
  ).wait;
  final integrity = manifest['integrity'];
  final files = integrity is Map ? integrity['files'] : null;
  return ProductContent(
    productId: productId,
    parts: PartsFile.fromJson(parts),
    faults: faults == null ? null : FaultsFile.fromJson(faults),
    entryNames: files is Map ? files.keys.cast<String>() : const [],
  );
}, retry: (_, _) => null);

/// Okuyucuda açılacak DM.
final dataModuleProvider =
    FutureProvider.family<DmDocument, ({String productId, String dmc})>((
      ref,
      key,
    ) async {
      final content = await ref.watch(
        productContentProvider(key.productId).future,
      );
      final path = content.dmPath(key.dmc);
      if (path == null) {
        throw ApiException(404, 'not_found', '${key.dmc} bu dosyada yok.');
      }
      final xml = await ref
          .watch(apiClientProvider)
          .getText(productEntryPath(key.productId, path));
      return DmDocument.parse(xml, file: path);
    }, retry: (_, _) => null);

/// Harita dosyası isteğe bağlı; yoksa null.
Future<Map<String, Object?>?> _optional(
  Future<Map<String, Object?>> request,
) async {
  try {
    return await request;
  } on ApiException catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}
