import 'errors.dart';
import 'format_version.dart';
import 'json_reader.dart';

const _file = 'naya.json';

/// Dosyanın nereden geldiği.
enum NayaKind {
  /// Bizim hazırladığımız şablon.
  template,

  /// Dışarıdan zip olarak içe aktarılmış S1000D paketi.
  imported,

  /// Kullanıcının düzenlediği ya da kendi oluşturduğu dosya.
  user,
}

/// `naya.json`: dosyanın kimliği, içerik özeti ve bütünlük bilgisi.
class NayaManifest {
  const NayaManifest({
    required this.id,
    required this.kind,
    required this.title,
    this.formatVersion = currentFormatVersion,
    this.language = 'tr',
    this.product,
    this.s1000d,
    this.model,
    this.credits = const [],
    this.generator,
    this.created,
    this.integrity,
  });

  factory NayaManifest.fromJson(Object? json) {
    final r = JsonReader(json, _file);
    if (r.string('format') != 'naya') r.fail('"format" alanı "naya" olmalı');

    final kindName = r.string('kind');
    final kind = NayaKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) r.fail('bilinmeyen "kind": $kindName');

    final created = r.optionalString('created');
    return NayaManifest(
      formatVersion: r.string('formatVersion'),
      id: r.string('id'),
      kind: kind,
      language: r.string('language'),
      title: r.string('title'),
      product: _map(r.optionalObject('product'), ProductInfo._read),
      s1000d: _map(r.optionalObject('s1000d'), S1000dInfo._read),
      model: _map(r.optionalObject('model'), ModelInfo._read),
      credits: [
        for (final c in r.objects('credits', optional: true)) Credit._read(c),
      ],
      generator: r.optionalString('generator'),
      created: created == null ? null : _parseDate(r, created),
      integrity: _map(r.optionalObject('integrity'), Integrity._read),
    );
  }

  final String formatVersion;
  final String id;
  final NayaKind kind;
  final String language;
  final String title;
  final ProductInfo? product;
  final S1000dInfo? s1000d;
  final ModelInfo? model;
  final List<Credit> credits;
  final String? generator;
  final DateTime? created;

  /// Yazarken [NayaFile.encode] tarafından doldurulur.
  final Integrity? integrity;

  NayaManifest withIntegrity(Integrity? integrity) => NayaManifest(
    formatVersion: formatVersion,
    id: id,
    kind: kind,
    language: language,
    title: title,
    product: product,
    s1000d: s1000d,
    model: model,
    credits: credits,
    generator: generator,
    created: created,
    integrity: integrity,
  );

  Map<String, Object?> toJson() => {
    'format': 'naya',
    'formatVersion': formatVersion,
    'id': id,
    'kind': kind.name,
    'language': language,
    'title': title,
    if (product != null) 'product': product!.toJson(),
    if (s1000d != null) 's1000d': s1000d!.toJson(),
    if (model != null) 'model': model!.toJson(),
    if (credits.isNotEmpty) 'credits': [for (final c in credits) c.toJson()],
    if (generator != null) 'generator': generator,
    if (created != null) 'created': created!.toUtc().toIso8601String(),
    if (integrity != null) 'integrity': integrity!.toJson(),
  };

  static T? _map<T>(JsonReader? r, T Function(JsonReader) read) =>
      r == null ? null : read(r);

  static DateTime _parseDate(JsonReader r, String value) {
    final date = DateTime.tryParse(value);
    if (date == null) r.fail('"created" geçerli bir tarih değil: $value');
    return date;
  }

  /// Ham JSON'dan yalnız sürümü okur ve desteklenip desteklenmediğine bakar.
  ///
  /// Manifestin geri kalanı ayrıştırılmadan önce çağrılır: ileride 2.x'te
  /// alanlar değişirse kullanıcı "bozuk dosya" değil "yeni sürüm" mesajı görür.
  static void checkVersion(Object? json) {
    final r = JsonReader(json, _file);
    final version = r.string('formatVersion');
    final major = majorVersionOf(version);
    if (major == null) {
      throw InvalidJsonException(
        _file,
        '"formatVersion" x.y.z biçiminde olmalı: $version',
      );
    }
    if (major != supportedMajorVersion) {
      throw UnsupportedVersionException(version);
    }
  }
}

class ProductInfo {
  const ProductInfo({
    required this.category,
    this.make,
    this.model,
    this.variant,
    this.year,
  });

  factory ProductInfo._read(JsonReader r) => ProductInfo(
    category: r.string('category'),
    make: r.optionalString('make'),
    model: r.optionalString('model'),
    variant: r.optionalString('variant'),
    year: r.optionalInteger('year'),
  );

  /// `car`, `bicycle`, `tank`, `aircraft` gibi.
  final String category;
  final String? make;
  final String? model;
  final String? variant;
  final int? year;

  Map<String, Object?> toJson() => {
    'category': category,
    if (make != null) 'make': make,
    if (model != null) 'model': model,
    if (variant != null) 'variant': variant,
    if (year != null) 'year': year,
  };
}

class S1000dInfo {
  const S1000dInfo({
    required this.issue,
    required this.modelIdentCode,
    this.entry,
  });

  factory S1000dInfo._read(JsonReader r) => S1000dInfo(
    issue: r.string('issue'),
    modelIdentCode: r.string('modelIdentCode'),
    entry: r.optionalString('entry'),
  );

  /// S1000D sürümü, örneğin `"5.0"`.
  final String issue;
  final String modelIdentCode;

  /// Okumaya başlanacak yayın modülü (PM), `csdb/` altında.
  final String? entry;

  Map<String, Object?> toJson() => {
    'issue': issue,
    'modelIdentCode': modelIdentCode,
    if (entry != null) 'entry': entry,
  };
}

class ModelInfo {
  const ModelInfo({
    required this.main,
    this.details = const {},
    this.units = 'm',
    this.upAxis = 'Y',
    this.compression,
  });

  factory ModelInfo._read(JsonReader r) => ModelInfo(
    main: r.string('main'),
    details: r.stringMap('details', optional: true),
    units: r.optionalString('units') ?? 'm',
    upAxis: r.optionalString('upAxis') ?? 'Y',
    compression: r.optionalString('compression'),
  );

  /// Dış gövde ve ana montajlar, örneğin `model/product.glb`.
  final String main;

  /// Montaj kimliğinden ağır detay dosyasına: `{"eng": "model/detail/engine.glb"}`.
  final Map<String, String> details;
  final String units;
  final String upAxis;
  final String? compression;

  Map<String, Object?> toJson() => {
    'main': main,
    if (details.isNotEmpty) 'details': details,
    'units': units,
    'upAxis': upAxis,
    if (compression != null) 'compression': compression,
  };
}

/// Dosyadaki bir varlığın (model, görsel) kaynağı ve lisansı.
class Credit {
  const Credit({
    required this.asset,
    required this.author,
    required this.license,
    this.source,
  });

  factory Credit._read(JsonReader r) => Credit(
    asset: r.string('asset'),
    author: r.string('author'),
    license: r.string('license'),
    source: r.optionalString('source'),
  );

  final String asset;
  final String author;
  final String license;
  final String? source;

  Map<String, Object?> toJson() => {
    'asset': asset,
    'author': author,
    if (source != null) 'source': source,
    'license': license,
  };
}

/// Her dosyanın SHA-256 özeti. `mimetype` ve `naya.json` dahil değildir.
class Integrity {
  const Integrity(this.files, {this.algorithm = 'sha256'});

  factory Integrity._read(JsonReader r) {
    final algorithm = r.string('algorithm');
    if (algorithm != 'sha256') r.fail('desteklenmeyen özet: $algorithm');
    return Integrity(r.stringMap('files'), algorithm: algorithm);
  }

  final String algorithm;

  /// Dosya yolundan onaltılık özete.
  final Map<String, String> files;

  Map<String, Object?> toJson() => {'algorithm': algorithm, 'files': files};
}
