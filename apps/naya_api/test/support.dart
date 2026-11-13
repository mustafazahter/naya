import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:naya_api/server.dart';
import 'package:naya_format/naya_format.dart';
import 'package:shelf/shelf.dart';

/// Testlerde elle ilerletilen saat.
class TestClock {
  DateTime now = DateTime(2026, 11, 12, 10);

  void advance(Duration duration) => now = now.add(duration);
}

/// Bellekteki veritabanı ve geçici klasörle kurulmuş bir sunucu.
class TestServer {
  TestServer._(this.api, this.clock, this.dir);

  static Future<TestServer> start({Map<String, String> env = const {}}) async {
    final dir = await Directory.systemTemp.createTemp('naya_api_test');
    final clock = TestClock();
    final config = ApiConfig.fromEnvironment({
      'STORAGE_DIR': '${dir.path}/storage',
      'TEMPLATES_DIR': '${dir.path}/templates',
      ...env,
    });
    final db = NayaDatabase.memory();
    final api = NayaApi(
      config: config,
      db: db,
      logRequests: false,
      auth: AuthService(
        db,
        hasher: const PasswordHasher.fast(),
        clock: () => clock.now,
      ),
      clock: () => clock.now,
    );
    return TestServer._(api, clock, dir);
  }

  final NayaApi api;
  final TestClock clock;
  final Directory dir;
  late final Handler handler = api.handler;

  Future<void> close() async {
    await api.close();
    await dir.delete(recursive: true);
  }

  Future<Response> send(
    String method,
    String path, {
    Object? json,
    List<int>? bytes,
    Stream<List<int>>? stream,
    String? token,
    Map<String, String> headers = const {},
  }) async {
    final Object? body = json != null ? jsonEncode(json) : (bytes ?? stream);
    return handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body,
        headers: {
          if (json != null) 'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
          ...headers,
        },
      ),
    );
  }

  /// Uygulama gibi kaydolur, token'ı döner.
  Future<String> register(String email, [String password = 'gizli-sifre']) =>
      _tokenFrom(
        send(
          'POST',
          '/api/auth/register',
          json: {'email': email, 'password': password},
          headers: {'x-naya-client': 'app'},
        ),
      );

  Future<String> login(String email, [String password = 'gizli-sifre']) =>
      _tokenFrom(
        send(
          'POST',
          '/api/auth/login',
          json: {'email': email, 'password': password},
          headers: {'x-naya-client': 'app'},
        ),
      );

  /// Şablon klasörüne bir `.naya` koyar ve şablonları içeri alır.
  Future<void> addTemplate(Uint8List bytes, {String name = 'sablon'}) async {
    final templates = Directory(api.config.templatesDir);
    await templates.create(recursive: true);
    await File('${templates.path}/$name.naya').writeAsBytes(bytes);
    await api.importTemplates();
  }

  static Future<String> _tokenFrom(Future<Response> pending) async {
    final response = await pending;
    final body = await readJson(response);
    if (response.statusCode >= 300) {
      throw StateError('${response.statusCode}: $body');
    }
    return body['token']! as String;
  }
}

Future<Map<String, Object?>> readJson(Response response) async =>
    jsonDecode(await response.readAsString()) as Map<String, Object?>;

/// `schemas/examples` altındaki örneklerden küçük, geçerli bir `.naya`.
Uint8List sampleNaya({
  String id = 'bisiklet-ornek',
  String title = 'Bisiklet',
}) {
  final manifest = _example('naya.json')
    ..['id'] = id
    ..['title'] = title
    ..remove('integrity');
  final file = NayaFile(
    manifest: NayaManifest.fromJson(manifest),
    entries: {
      'csdb/DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A_001-00_TR-TR.XML': utf8
          .encode('<dmodule><content>Zinciri sökün.</content></dmodule>'),
      'media/zincir-1.webp': Uint8List.fromList(
        List.generate(512, (i) => i % 251),
      ),
    },
  );
  for (final name in ['parts', 'faults', 'zones', 'hotspots']) {
    file.putJson('map/$name.json', _example('$name.json'));
  }
  return file.encode();
}

Map<String, Object?> _example(String name) {
  final text = File('../../schemas/examples/$name').readAsStringSync();
  return jsonDecode(text) as Map<String, Object?>;
}
