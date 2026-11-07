/// Ürün kategorisi; kartlardaki çizimi ve varsayılan kamerayı belirler.
enum ProductCategory { car, bicycle, tank, aircraft }

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
    this.isTemplate = true,
    this.modelFile,
    this.thumbnail,
  });

  final String id;
  final String title;
  final String subtitle;
  final ProductCategory category;
  final int partCount;
  final int faultCount;

  /// S1000D veri modülü (DM) sayısı.
  final int moduleCount;
  final bool isTemplate;

  /// Viewer'ın yükleyeceği model, viewer'a göre göreli yol.
  final String? modelFile;

  /// Gerçek modelin render'ı. Yoksa kartta teknik çizim gösterilir.
  final String? thumbnail;
}

/// Taslak için örnek veriler. Gerçek liste sunucudan gelecek.
const sampleTemplates = [
  Product(
    id: 'araba',
    title: 'Araba',
    subtitle: 'Binek otomobil, benzinli',
    category: ProductCategory.car,
    partCount: 48,
    faultCount: 22,
    moduleCount: 36,
  ),
  Product(
    id: 'bisiklet',
    title: 'Bisiklet',
    subtitle: 'Dağ bisikleti · 24 vites · disk fren',
    category: ProductCategory.bicycle,
    partCount: 39,
    faultCount: 29,
    moduleCount: 26,
    modelFile: './models/bicycle.glb',
    thumbnail: 'assets/templates/bisiklet.webp',
  ),
  Product(
    id: 'tank',
    title: 'Tank',
    subtitle: 'Ana muharebe tankı, genel bakım',
    category: ProductCategory.tank,
    partCount: 54,
    faultCount: 19,
    moduleCount: 33,
  ),
  Product(
    id: 'ucak',
    title: 'Savaş uçağı',
    subtitle: 'Tek motorlu, genel bakım',
    category: ProductCategory.aircraft,
    partCount: 58,
    faultCount: 24,
    moduleCount: 40,
  ),
];

const sampleUserFiles = [
  Product(
    id: 'jenerator',
    title: 'Jeneratör 5 kVA',
    subtitle: 'İçe aktarıldı · 2 gün önce',
    category: ProductCategory.car,
    partCount: 18,
    faultCount: 0,
    moduleCount: 12,
    isTemplate: false,
  ),
];
