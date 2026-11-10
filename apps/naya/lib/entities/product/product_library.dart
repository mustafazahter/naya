import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';

/// Kütüphanede görünen her şey.
class ProductLibrary {
  const ProductLibrary({required this.templates, required this.userFiles});

  final List<Product> templates;
  final List<Product> userFiles;

  Product? byId(String id) {
    for (final product in [...templates, ...userFiles]) {
      if (product.id == id) return product;
    }
    return null;
  }
}

/// Kütüphane verisi. Sunucu gelene kadar (3C) örnek listeyi döner; ekranlar
/// yükleme ve hata durumlarını şimdiden buradan okur.
///
/// Otomatik yeniden deneme kapalı: açıkken hata yerine saniyelerce iskelet
/// görünüyor. Ekranda "Yeniden dene" düğmesi var.
final productLibraryProvider = FutureProvider<ProductLibrary>(
  (ref) async => const ProductLibrary(
    templates: sampleTemplates,
    userFiles: sampleUserFiles,
  ),
  retry: (_, _) => null,
);
