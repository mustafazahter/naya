import 'package:flutter/foundation.dart';

import '../../entities/product/product.dart';
import '../../entities/product/product_content.dart';
import '../../shared/api/api_client.dart';
import '../../shared/platform/model_cache.dart';

/// Ürünün modelini önceden indirir; karta dokununca beklenmesin.
void prefetchModel(ApiClient api, Product product) {
  final path = product.modelPath;
  if (path == null) return;
  ModelCache.instance.prefetch(
    api,
    product.id,
    productEntryPath(product.id, path, version: product.version),
    version: product.version,
  );
}

/// Kütüphane açılınca: Android'de şablonların modelleri sırayla arka planda
/// iner ve diskte kalır, sonraki açılışlar ağsız. Kullanıcı dosyaları
/// yalnız açılınca iner: sayısı ve boyu sınırsız, önbelleğin 200 MB'ını
/// aşınca her açılışta silinip yeniden iniyor, mobil veri harcıyordu.
/// Web'de hepsini indirmek yavaş bağlantıda (~10 MB'lık ilk açılışın
/// üstüne) sayfayı boğar; orada yalnız fare kartın üstüne gelince
/// ([prefetchModel]).
void prefetchLibraryModels(ApiClient api, Iterable<Product> products) {
  if (kIsWeb) return;
  for (final product in products.where((p) => p.isTemplate)) {
    prefetchModel(api, product);
  }
}
