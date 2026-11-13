import 'package:shelf/shelf.dart';

import 'auth_service.dart';

const sessionCookieName = 'naya_session';
const _userKey = 'naya.user';

/// İstekte oturum açmış kullanıcı; misafirse `null`.
AuthUser? userOf(Request request) => request.context[_userKey] as AuthUser?;

/// Token'ı istekten okur: Android `Authorization: Bearer <token>` başlığı,
/// web httpOnly çerez gönderir.
String? sessionTokenOf(Request request) {
  final header = request.headers['authorization'];
  if (header != null && header.startsWith('Bearer ')) {
    final token = header.substring(7).trim();
    if (token.isNotEmpty) return token;
  }
  final cookies = request.headers['cookie'];
  if (cookies == null) return null;
  for (final cookie in cookies.split(';')) {
    final index = cookie.indexOf('=');
    if (index < 0) continue;
    if (cookie.substring(0, index).trim() == sessionCookieName) {
      final value = cookie.substring(index + 1).trim();
      return value.isEmpty ? null : value;
    }
  }
  return null;
}

/// Her istekte token'ı doğrular ve kullanıcıyı isteğe ekler. Token yoksa ya
/// da geçersizse istek misafir olarak devam eder; hangi ucun giriş
/// istediğine uçların kendisi karar verir.
Middleware authenticate(AuthService auth) =>
    (inner) => (request) async {
      final token = sessionTokenOf(request);
      if (token == null) return inner(request);
      final user = await auth.authenticate(token);
      if (user == null) return inner(request);
      return inner(request.change(context: {_userKey: user}));
    };

/// Oturum çerezi. `SameSite=Strict`: başka sitelerden gelen isteklerde
/// gönderilmez, CSRF'e karşı ayrıca token gerekmez.
String sessionCookie(String token, {required bool secure}) => [
  '$sessionCookieName=$token',
  'Path=/',
  'HttpOnly',
  'SameSite=Strict',
  'Max-Age=${AuthService.sessionLifetime.inSeconds}',
  if (secure) 'Secure',
].join('; ');

String clearedSessionCookie({required bool secure}) => [
  '$sessionCookieName=',
  'Path=/',
  'HttpOnly',
  'SameSite=Strict',
  'Max-Age=0',
  if (secure) 'Secure',
].join('; ');
