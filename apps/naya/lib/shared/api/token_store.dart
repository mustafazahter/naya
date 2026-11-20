import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Android'de oturum token'ının saklandığı yer. Web'de oturum httpOnly
/// çerezde durur; token JavaScript'e hiç gelmediği için saklanacak bir şey
/// yoktur.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Android Keystore ile şifrelenen depo (`flutter_secure_storage`).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'naya.session';

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on Object {
      // Keystore bozulduysa (yedekten geri yükleme gibi) yeniden giriş
      // istemek, uygulamanın açılmamasından iyidir.
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Web ve testler için: hiçbir şey kalıcı değil.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => kIsWeb ? MemoryTokenStore() : SecureTokenStore(),
);
