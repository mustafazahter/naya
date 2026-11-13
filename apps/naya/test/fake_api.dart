import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naya/shared/api/api_client.dart';

/// Testlerde sunucunun yerine geçer. Kütüphanede taslaktaki ürünler var;
/// bisikletin içeriği (parça haritası, arızalar, DM'ler) repodaki gerçek
/// şablondan okunur.
///
/// [diagnose] verilirse `POST /api/ai/diagnose` gövdeyi alıp bu cevabı
/// döner; verilmezse giriş yapılmamış gibi 401.
ApiClient fakeApi({
  int failLibraryTimes = 0,
  http.Response Function(Map<String, Object?> body)? diagnose,
}) {
  var libraryCalls = 0;
  return ApiClient(
    baseUrl: 'http://api.test',
    client: MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/ai/diagnose' && request.method == 'POST') {
        if (diagnose == null) {
          return _error(401, 'unauthorized', 'Bu işlem için giriş yapın.');
        }
        return diagnose(jsonDecode(request.body) as Map<String, Object?>);
      }
      if (path == '/api/library') {
        if (libraryCalls++ < failLibraryTimes) {
          return _error(503, 'unavailable', 'Sunucu kapalı.');
        }
        return _json(sampleLibrary);
      }
      const prefix = '/api/library/bisiklet/entries/';
      if (!path.startsWith(prefix)) {
        return _error(404, 'not_found', 'Kütüphanede böyle bir dosya yok.');
      }
      final entry = path.substring(prefix.length);
      if (entry == 'naya.json') return _json(_manifest());
      final file = File('$templateDir/$entry');
      if (!file.existsSync()) return _error(404, 'not_found', 'Dosyada yok.');
      return http.Response.bytes(file.readAsBytesSync(), 200);
    }),
  );
}

const templateDir = '../../templates/src/bisiklet';

Map<String, Object?> _manifest() {
  final names = [
    for (final f in Directory('$templateDir/csdb').listSync())
      'csdb/${f.uri.pathSegments.last}',
    'map/parts.json',
    'map/faults.json',
  ];
  return {
    'id': 'bisiklet-dag',
    'integrity': {
      'algorithm': 'sha256',
      'files': {for (final n in names) n: ''},
    },
  };
}

/// Sunucunun teşhis cevabı biçiminde JSON.
http.Response jsonResponse(Object body, {int status = 200}) =>
    _json(body).withStatus(status);

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _error(int status, String code, String message) => _json({
  'error': {'code': code, 'message': message},
}).withStatus(status);

extension on http.Response {
  http.Response withStatus(int status) =>
      http.Response.bytes(bodyBytes, status, headers: headers);
}

Map<String, Object?> _item(
  String id,
  String title,
  String subtitle,
  String category, {
  bool template = true,
  String? key,
  bool model = false,
}) => {
  'id': id,
  'key': key ?? id,
  'title': title,
  'subtitle': subtitle,
  'category': category,
  'isTemplate': template,
  'partCount': 39,
  'faultCount': 29,
  'moduleCount': 26,
  'hasModel': model,
  if (model) 'model': {'main': 'model/product.glb'},
  'credits': [
    {'author': 'T-FLEX CAD ST (Free)', 'license': 'CC-BY-4.0'},
  ],
};

final sampleLibrary = {
  'templates': [
    _item('araba', 'Araba', 'Binek otomobil, benzinli', 'car'),
    _item(
      'bisiklet',
      'Bisiklet',
      'Dağ bisikleti · 24 vites · disk fren',
      'bicycle',
      key: 'bisiklet-dag',
      model: true,
    ),
    _item('tank', 'Tank', 'Ana muharebe tankı, genel bakım', 'tank'),
    _item('ucak', 'Savaş uçağı', 'Tek motorlu, genel bakım', 'aircraft'),
  ],
  'userFiles': [
    _item(
      'jenerator',
      'Jeneratör 5 kVA',
      'İçe aktarıldı · 2 gün önce',
      'car',
      template: false,
    ),
  ],
};
