import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf.dart' as shelf show logRequests;
import 'package:shelf_router/shelf_router.dart';

import 'src/ai/ai_provider.dart';
import 'src/ai/ai_routes.dart';
import 'src/ai/ai_settings.dart';
import 'src/ai/assistant.dart';
import 'src/ai/dm_search.dart';
import 'src/ai/key_vault.dart';
import 'src/ai/open_router.dart';
import 'src/auth/auth_middleware.dart';
import 'src/auth/auth_routes.dart';
import 'src/auth/auth_service.dart';
import 'src/backup_service.dart';
import 'src/config.dart';
import 'src/database/database.dart';
import 'src/http/cors.dart';
import 'src/http/json_response.dart';
import 'src/library/library_routes.dart';
import 'src/library/library_service.dart';

export 'src/ai/ai_provider.dart';
export 'src/ai/ai_settings.dart';
export 'src/ai/assistant.dart';
export 'src/ai/dm_search.dart';
export 'src/ai/key_vault.dart';
export 'src/ai/open_router.dart';
export 'src/auth/auth_service.dart';
export 'src/auth/password_hasher.dart';
export 'src/backup_service.dart';
export 'src/config.dart';
export 'src/database/database.dart';
export 'src/library/library_service.dart';

/// Sunucunun parçaları bir arada: veritabanı, servisler ve HTTP uçları.
/// Testler bunu bellekteki bir veritabanıyla kurar.
class NayaApi {
  NayaApi({
    required this.config,
    required this.db,
    AuthService? auth,
    AiProvider? aiProvider,
    DateTime Function()? clock,
    this.logRequests = true,
  }) : auth = auth ?? AuthService(db, clock: clock),
       search = DmSearch(db),
       aiProvider = aiProvider ?? OpenRouterProvider(),
       backups = BackupService(db, config.backupDir, clock: clock) {
    library = LibraryService(
      db,
      config.libraryDir,
      search: search,
      clock: clock,
    );
    aiSettings = AiSettings(
      db,
      this.aiProvider,
      vault: KeyVault.fromBase64(config.masterKey),
      clock: clock,
    );
    assistant = Assistant(
      db: db,
      provider: this.aiProvider,
      settings: aiSettings,
      library: library,
      search: search,
      clock: clock,
    );
  }

  final ApiConfig config;
  final NayaDatabase db;
  final AuthService auth;
  final DmSearch search;
  final AiProvider aiProvider;
  late final LibraryService library;
  late final AiSettings aiSettings;
  late final Assistant assistant;
  final BackupService backups;

  /// Her isteği konsola yazar; testlerde kapalı.
  final bool logRequests;

  Timer? _dailyTimer;

  Handler get handler {
    final api = Router()
      ..mount(
        '/auth',
        AuthRoutes(auth, secureCookies: config.secureCookies).router.call,
      )
      ..mount('/library', LibraryRoutes(library).router.call)
      ..mount(
        '/ai',
        AiRoutes(
          settings: aiSettings,
          assistant: assistant,
          library: library,
        ).router.call,
      )
      ..all('/<_|.*>', (Request _) => notFound('Böyle bir API ucu yok.'));

    final router = Router()
      ..get('/health', _health)
      ..mount('/api', api.call);

    var pipeline = const Pipeline();
    if (logRequests) pipeline = pipeline.addMiddleware(shelf.logRequests());
    return pipeline
        .addMiddleware(cors(config.allowedOrigins))
        .addMiddleware(authenticate(auth))
        .addHandler(router.call);
  }

  /// Açılış işleri: admin hesabı, şablonlar, ilk yedek ve günlük
  /// zamanlayıcı.
  Future<void> start() async {
    final email = config.adminEmail;
    final password = config.adminPassword;
    if (email != null && password != null) {
      try {
        await auth.ensureAdmin(email, password);
      } on AuthException catch (e) {
        // Sunucu yine açılsın; sorun günlükte görünür.
        stderr.writeln('Admin hesabı hazırlanamadı: ${e.message}');
      }
    }
    await importTemplates();
    final indexed = await library.indexMissing();
    if (indexed > 0) stdout.writeln('Arama dizinine eklendi: $indexed dosya');
    if (!aiSettings.canStoreKeys) {
      stderr.writeln(
        'NAYA_MASTER_KEY yok ya da 32 bayt değil; yapay zekâ kapalı.',
      );
    }
    await _daily();
    _dailyTimer = Timer.periodic(const Duration(hours: 1), (_) => _daily());
  }

  /// `templatesDir` içindeki her `.naya` dosyasını şablon olarak ekler.
  /// Bozuk bir dosya diğerlerini engellemez; sorunu yazar ve geçer.
  Future<List<String>> importTemplates() async {
    final dir = Directory(config.templatesDir);
    if (!await dir.exists()) {
      stderr.writeln(
        'Şablon klasörü yok: ${config.templatesDir} '
        '(tools/dev.sh şablonları paketler)',
      );
      return [];
    }
    final imported = <String>[];
    final files = await dir
        .list()
        .where((e) => e is File && p.extension(e.path) == '.naya')
        .cast<File>()
        .toList();
    for (final file in files) {
      try {
        final item = await library.importTemplate(await file.readAsBytes());
        imported.add(item.title);
      } on LibraryException catch (e) {
        stderr.writeln('${file.path}: ${e.message} ${e.problems.join('; ')}');
      }
    }
    return imported;
  }

  Future<void> close() async {
    _dailyTimer?.cancel();
    await db.close();
  }

  Future<void> _daily() async {
    try {
      final backup = await backups.runIfDue();
      if (backup != null) stdout.writeln('Yedek alındı: ${backup.path}');
      await auth.deleteExpiredSessions();
    } on Object catch (e) {
      // Yedek alınamaması sunucuyu durdurmamalı; bir saat sonra yine
      // denenir.
      stderr.writeln('Yedek alınamadı: $e');
    }
  }

  Response _health(Request request) => jsonOk({'status': 'ok'});
}
