import '../../shared/utils/turkish_text.dart';

/// Ürün kategorisi; kartlardaki çizimi ve varsayılan kamerayı belirler.
enum ProductCategory {
  car,
  bicycle,
  tank,
  aircraft;

  /// Manifestteki `product.category`. Tanınmayan kategori (içe aktarılan
  /// dosyalar) şimdilik araba çizimiyle gösterilir; genel bir çizim 5C'de.
  static ProductCategory fromName(String? name) => values.firstWhere(
    (c) => c.name == name,
    orElse: () => ProductCategory.car,
  );
}

/// Kütüphanede görünen bir ürün (şablon ya da kullanıcı dosyası).
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.partCount,
    required this.faultCount,
    required this.moduleCount,
    this.key,
    this.isTemplate = true,
    this.modelPath,
    this.credits = const [],
  });

  /// `/api/library` cevabındaki bir öğe.
  factory Product.fromJson(Map<String, Object?> json) {
    final model = json['model'];
    final hasModel = json['hasModel'] == true;
    return Product(
      id: json['id']! as String,
      key: json['key'] as String?,
      title: json['title']! as String,
      subtitle: json['subtitle'] as String? ?? '',
      category: ProductCategory.fromName(json['category'] as String?),
      partCount: (json['partCount'] as num?)?.toInt() ?? 0,
      faultCount: (json['faultCount'] as num?)?.toInt() ?? 0,
      moduleCount: (json['moduleCount'] as num?)?.toInt() ?? 0,
      isTemplate: json['isTemplate'] == true,
      modelPath: hasModel && model is Map ? model['main'] as String? : null,
      credits: [
        for (final credit in json['credits'] as List<Object?>? ?? const [])
          if (credit is Map<String, Object?>) Credit.fromJson(credit),
      ],
    );
  }

  /// Kütüphanedeki kimlik; adreste görünür (`/urun/<id>`).
  final String id;

  /// Manifestteki kimlik (`bisiklet-dag`); şablonun sunucudaki kimliği
  /// değişse de aynı kalır.
  final String? key;
  final String title;
  final String subtitle;
  final ProductCategory category;
  final int partCount;
  final int faultCount;

  /// S1000D veri modülü (DM) sayısı.
  final int moduleCount;
  final bool isTemplate;

  /// `.naya` içindeki 3D model (`model/product.glb`); modeli yoksa null.
  final String? modelPath;

  /// Model ve görseller için atıflar (CC BY).
  final List<Credit> credits;

  /// Gerçek modelin render'ı. Yoksa kartta teknik çizim gösterilir.
  String? get thumbnail => _thumbnails[key];

  static const _thumbnails = {'bisiklet-dag': 'assets/templates/bisiklet.webp'};

  /// Başlıkta ya da açıklamada [query] geçiyor mu; büyük/küçük harf önemsiz.
  bool matches(String query) {
    final needle = turkishLowerCase(query.trim());
    return turkishLowerCase('$title $subtitle').contains(needle);
  }
}

class Credit {
  const Credit({required this.author, required this.license, this.source});

  factory Credit.fromJson(Map<String, Object?> json) => Credit(
    author: json['author'] as String? ?? '',
    license: json['license'] as String? ?? '',
    source: json['source'] as String?,
  );

  final String author;
  final String license;
  final String? source;
}
