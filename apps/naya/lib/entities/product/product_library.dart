import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_client.dart';
import 'product.dart';

/// Kütüphanede görünen her şey.
class ProductLibrary {
  const ProductLibrary({required this.templates, required this.userFiles});

  factory ProductLibrary.fromJson(Map<String, Object?> json) {
    List<Product> products(String key) => [
      for (final item in json[key] as List<Object?>? ?? const [])
        if (item is Map<String, Object?>) Product.fromJson(item),
    ];
    return ProductLibrary(
      templates: products('templates'),
      userFiles: products('userFiles'),
    );
  }

  final List<Product> templates;
  final List<Product> userFiles;

  Product? byId(String id) {
    for (final product in [...templates, ...userFiles]) {
      if (product.id == id) return product;
    }
    return null;
  }
}

/// Sunucudaki kütüphane: misafire yalnız şablonlar, oturum açana kendi
/// dosyaları da.
///
/// Otomatik yeniden deneme kapalı: açıkken hata yerine saniyelerce iskelet
/// görünüyor. Ekranda "Yeniden dene" düğmesi var.
final productLibraryProvider = FutureProvider<ProductLibrary>(
  (ref) async => ProductLibrary.fromJson(
    await ref.watch(apiClientProvider).getJson('/api/library'),
  ),
  retry: (_, _) => null,
);
