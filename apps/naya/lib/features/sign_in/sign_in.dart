import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/product/product_library.dart';
import '../../entities/session/session.dart';
import '../../shared/api/api_client.dart';

/// E-posta ve şifreyle giriş yapar; [register] ise önce hesap açar
/// (sunucu kayıtta oturumu da açar). Hata [ApiException] olarak fırlar,
/// mesajı doğrudan gösterilebilir.
Future<void> signIn(
  WidgetRef ref, {
  required String email,
  required String password,
  bool register = false,
}) async {
  final response = await ref.read(apiClientProvider).postJson(
    register ? '/api/auth/register' : '/api/auth/login',
    {'email': email.trim(), 'password': password},
  );
  await ref.read(sessionProvider.notifier).signedIn(response);
  // Misafirken görünmeyen kullanıcı dosyaları gelsin.
  ref.invalidate(productLibraryProvider);
}

/// Sunucudaki oturumu kapatır. Sunucuya ulaşılamasa da yerelde çıkılır.
Future<void> signOut(WidgetRef ref) async {
  try {
    await ref.read(apiClientProvider).postJson('/api/auth/logout', const {});
  } on ApiException {
    // Token yerelde silinince zaten kullanılmaz; süresi dolunca da biter.
  }
  await ref.read(sessionProvider.notifier).signedOut();
  ref.invalidate(productLibraryProvider);
}

/// Sunucunun hesap hatalarını kullanıcıya uygun metne çevirir.
String signInErrorText(Object error) => switch (error) {
  ApiException(code: 'locked') =>
    'Çok fazla hatalı deneme. 15 dakika sonra yeniden dene.',
  ApiException(:final message) => message,
  _ => 'Bir sorun oluştu, yeniden dene.',
};
