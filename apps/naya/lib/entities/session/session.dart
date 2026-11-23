import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/token_store.dart';

/// Oturum açmış kullanıcı. Misafirde oturum `null`.
class Account {
  const Account({required this.id, required this.email, required this.role});

  factory Account.fromJson(Map<String, Object?> json) => Account(
    id: json['id']! as int,
    email: json['email']! as String,
    role: json['role'] as String? ?? 'user',
  );

  final int id;
  final String email;

  /// `user` ya da `admin`.
  final String role;

  bool get isAdmin => role == 'admin';

  /// Avatarda görünen harf.
  String get initial => email.isEmpty ? '?' : email[0].toUpperCase();
}

/// Kim giriş yapmış? Açılışta Android'de saklı token, web'de çerez ile
/// `GET /api/auth/me` sorulur. Giriş ve çıkış `features/sign_in`'de.
class SessionNotifier extends AsyncNotifier<Account?> {
  @override
  Future<Account?> build() async {
    final api = ref.read(apiClientProvider);
    final store = ref.read(tokenStoreProvider);
    api.token = await store.read();
    try {
      final json = await api.getJson('/api/auth/me');
      return Account.fromJson(json['user']! as Map<String, Object?>);
    } on ApiException catch (e) {
      // Süresi dolmuş token'ı tutmanın anlamı yok. Sunucuya ulaşılamadıysa
      // token kalır ve biraz sonra yeniden sorulur; o arada misafir görünür.
      if (e.statusCode == 401) {
        api.token = null;
        await store.clear();
      } else {
        final retry = Timer(_retryAfter, ref.invalidateSelf);
        ref.onDispose(retry.cancel);
      }
      return null;
    }
  }

  static const _retryAfter = Duration(seconds: 15);

  /// Giriş ya da kayıt cevabıyla oturumu başlatır. Android'de sunucu
  /// token'ı gövdede verir; web'de çerez zaten yazıldı.
  Future<void> signedIn(Map<String, Object?> response) async {
    final token = response['token'];
    if (token is String) {
      ref.read(apiClientProvider).token = token;
      await ref.read(tokenStoreProvider).write(token);
    }
    state = AsyncData(
      Account.fromJson(response['user']! as Map<String, Object?>),
    );
  }

  Future<void> signedOut() async {
    ref.read(apiClientProvider).token = null;
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Account?>(
  SessionNotifier.new,
  retry: (_, _) => null,
);
