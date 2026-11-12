import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf.dart' as shelf show logRequests;
import 'package:shelf_router/shelf_router.dart';

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
    DateTime Function()? clock,
    this.logRequests = true,
  }) : auth = auth ?? AuthService(db, clock: clock),
       library = LibraryService(db, config.libraryDir, clock: clock),
       backups = BackupService(db, config.backupDir, clock: clock);

  final ApiConfig config;
  final NayaDatabase db;
  final AuthService auth;
  final LibraryService library;
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
      await auth.ensureAdmin(email, password);
    }
    await importTemplates();
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
