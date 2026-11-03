import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Sunucunun tüm uç noktaları burada toplanır.
Handler buildHandler() {
  final router = Router()..get('/health', _health);
  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

Response _health(Request request) {
  return Response.ok(
    jsonEncode({'status': 'ok'}),
    headers: {'content-type': 'application/json'},
  );
}
