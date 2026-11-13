import 'dart:io';

import 'package:path/path.dart' as p;

/// Sunucunun ortam değişkenlerinden okunan ayarları.
///
/// Yerelde hiçbirini vermek gerekmez: veritabanı ve dosyalar
/// `apps/naya_api/data` altına, şablonlar `templates/dist` klasöründen okunur.
class ApiConfig {
  const ApiConfig({
    required this.port,
    required this.databasePath,
    required this.storageDir,
    required this.templatesDir,
    this.adminEmail,
    this.adminPassword,
    this.secureCookies = false,
    this.allowedOrigins = const [],
  });

  factory ApiConfig.fromEnvironment([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    String? read(String key) {
      final value = env[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    final dataDir = p.join(Directory.current.path, 'data');
    return ApiConfig(
      port: int.parse(read('PORT') ?? '8080'),
      databasePath: read('DATABASE_PATH') ?? p.join(dataDir, 'naya.db'),
      storageDir: read('STORAGE_DIR') ?? p.join(dataDir, 'storage'),
      templatesDir:
          read('TEMPLATES_DIR') ??
          p.normalize(p.join(Directory.current.path, '../../templates/dist')),
      adminEmail: read('NAYA_ADMIN_EMAIL'),
      adminPassword: read('NAYA_ADMIN_PASSWORD'),
      secureCookies: read('NAYA_SECURE_COOKIES') == '1',
      allowedOrigins: (read('CORS_ORIGINS') ?? '')
          .split(',')
          .map((origin) => origin.trim())
          .where((origin) => origin.isNotEmpty)
          .toList(),
    );
  }

  final int port;
  final String databasePath;

  /// Yüklenen `.naya` dosyaları ve günlük yedekler burada durur.
  final String storageDir;

  /// Açılışta kütüphaneye şablon olarak eklenen `.naya` dosyaları.
  final String templatesDir;

  /// İkisi de verilmişse açılışta bu e-postayla bir admin hesabı açılır.
  final String? adminEmail;
  final String? adminPassword;

  /// HTTPS arkasında (Komuta) çerezlere `Secure` eklenir. Yerelde HTTP
  /// kullanıldığı için kapalı.
  final bool secureCookies;

  /// Çerezle istek atabilecek web adresleri. `localhost` her zaman açık;
  /// yerelde Flutter web başka bir portta çalışıyor.
  final List<String> allowedOrigins;

  String get libraryDir => p.join(storageDir, 'library');
  String get backupDir => p.join(storageDir, 'backups');
}
