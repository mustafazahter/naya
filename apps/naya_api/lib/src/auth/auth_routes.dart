import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http/json_response.dart';
import 'auth_middleware.dart';
import 'auth_service.dart';

/// `/api/auth` uçları.
///
/// Web istemcisi token'ı hiç görmez, yalnız çerez alır. Android çerez
/// tutmadığı için `X-Naya-Client: app` başlığı gönderir; ona token gövdede
/// döner ve `flutter_secure_storage`'da saklanır.
class AuthRoutes {
  AuthRoutes(this._auth, {required this.secureCookies});

  final AuthService _auth;
  final bool secureCookies;

  Router get router => Router()
    ..post('/register', _register)
    ..post('/login', _login)
    ..post('/logout', _logout)
    ..get('/me', _me);

  Future<Response> _register(Request request) async {
    final body = await readJsonObject(request);
    final email = body?['email'];
    final password = body?['password'];
    if (email is! String || password is! String) {
      return _badRequest();
    }
    try {
      final user = await _auth.register(email, password);
      final token = await _auth.startSession(user);
      return _signedIn(request, token, user, status: 201);
    } on AuthException catch (e) {
      final status = e.code == 'email_taken' ? 409 : 400;
      return jsonError(status, e.code, e.message);
    }
  }

  Future<Response> _login(Request request) async {
    final body = await readJsonObject(request);
    final email = body?['email'];
    final password = body?['password'];
    if (email is! String || password is! String) {
      return _badRequest();
    }
    try {
      final result = await _auth.login(email, password);
      return _signedIn(request, result.token, result.user);
    } on AuthException catch (e) {
      if (e.code == 'locked') {
        return jsonError(
          429,
          e.code,
          e.message,
          headers: {'retry-after': '${e.retryAfter!.inSeconds}'},
        );
      }
      return jsonError(401, e.code, e.message);
    }
  }

  Future<Response> _logout(Request request) async {
    final token = sessionTokenOf(request);
    if (token != null) await _auth.logout(token);
    return Response(
      204,
      headers: {'set-cookie': clearedSessionCookie(secure: secureCookies)},
    );
  }

  Response _me(Request request) {
    final user = userOf(request);
    if (user == null) return unauthorized();
    return jsonOk({'user': user.toJson()});
  }

  Response _signedIn(
    Request request,
    String token,
    AuthUser user, {
    int status = 200,
  }) {
    final isApp = request.headers['x-naya-client'] == 'app';
    return jsonOk(
      {'user': user.toJson(), if (isApp) 'token': token},
      status: status,
      headers: {'set-cookie': sessionCookie(token, secure: secureCookies)},
    );
  }

  static Response _badRequest() => jsonError(
    400,
    'bad_request',
    'İstek gövdesinde "email" ve "password" olmalı.',
  );
}
