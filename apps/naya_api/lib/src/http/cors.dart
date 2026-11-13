import 'package:shelf/shelf.dart';

/// Başka bir adresten açılan web uygulamasının çerezle istek atabilmesi.
///
/// Komuta'da API ile web derlemesi aynı adresten sunulduğu için orada CORS
/// gerekmiyor. Yerelde Flutter web `localhost:5050` gibi ayrı bir portta
/// çalıştığından `localhost` adresleri her zaman kabul ediliyor; diğerleri
/// [allowedOrigins] ile açılır.
Middleware cors(List<String> allowedOrigins) {
  bool allowed(String origin) {
    if (allowedOrigins.contains(origin)) return true;
    final uri = Uri.tryParse(origin);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  return (inner) => (request) async {
    final origin = request.headers['origin'];
    final headers = origin != null && allowed(origin)
        ? {
            'access-control-allow-origin': origin,
            'access-control-allow-credentials': 'true',
            'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
            'access-control-allow-headers':
                'content-type, authorization, x-naya-client',
            'access-control-max-age': '600',
            'vary': 'origin',
          }
        : const <String, String>{};

    if (request.method == 'OPTIONS') {
      return Response(headers.isEmpty ? 403 : 204, headers: headers);
    }
    final response = await inner(request);
    return response.change(headers: headers);
  };
}
