import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Şifreleri Argon2id ile özetler ve doğrular.
///
/// Özet PHC biçiminde tek bir metin olarak saklanır:
/// `$argon2id$v=19$m=19456,t=2,p=1$<tuz>$<özet>`. Parametreler özetin
/// içinde durduğu için ileride değiştirilse de eski şifreler doğrulanır.
class PasswordHasher {
  /// Varsayılanlar OWASP'ın önerdiği en düşük Argon2id ayarı: 19 MiB
  /// bellek, 2 tur. Sunucuda bir giriş ~0,2 saniye sürüyor.
  const PasswordHasher({
    this.memoryKib = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  /// Testlerde kullanılan hızlı ayar; gerçek sunucuda kullanılmaz.
  const PasswordHasher.fast() : this(memoryKib: 64, iterations: 1);

  final int memoryKib;
  final int iterations;
  final int parallelism;

  static const _hashLength = 32;
  static const _saltLength = 16;
  static final _random = Random.secure();

  Future<String> hash(String password) async {
    final salt = List<int>.generate(_saltLength, (_) => _random.nextInt(256));
    final digest = await _derive(
      password,
      salt,
      memoryKib: memoryKib,
      iterations: iterations,
      parallelism: parallelism,
    );
    return '\$argon2id\$v=19\$m=$memoryKib,t=$iterations,p=$parallelism'
        '\$${_b64(salt)}\$${_b64(digest)}';
  }

  /// Şifre [encoded] özetle eşleşiyor mu. Bozuk bir özet `false` döner.
  Future<bool> verify(String password, String encoded) async {
    final parts = encoded.split(r'$');
    // ['', 'argon2id', 'v=19', 'm=..,t=..,p=..', tuz, özet]
    if (parts.length != 6 || parts[1] != 'argon2id') return false;
    final params = <String, int>{};
    for (final pair in parts[3].split(',')) {
      final kv = pair.split('=');
      if (kv.length == 2) params[kv[0]] = int.tryParse(kv[1]) ?? 0;
    }
    final m = params['m'] ?? 0;
    final t = params['t'] ?? 0;
    final p = params['p'] ?? 0;
    if (m <= 0 || t <= 0 || p <= 0) return false;

    final List<int> salt;
    final List<int> expected;
    try {
      salt = _unb64(parts[4]);
      expected = _unb64(parts[5]);
    } on FormatException {
      return false;
    }
    final actual = await _derive(
      password,
      salt,
      memoryKib: m,
      iterations: t,
      parallelism: p,
    );
    return _constantTimeEquals(actual, expected);
  }

  static Future<List<int>> _derive(
    String password,
    List<int> salt, {
    required int memoryKib,
    required int iterations,
    required int parallelism,
  }) async {
    final algorithm = Argon2id(
      memory: memoryKib,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: _hashLength,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return key.extractBytes();
  }

  // PHC biçimi dolgusuz base64 kullanır.
  static String _b64(List<int> bytes) =>
      base64.encode(bytes).replaceAll('=', '');

  static List<int> _unb64(String text) =>
      base64.decode(text.padRight((text.length + 3) ~/ 4 * 4, '='));

  /// Karşılaştırma süresi ilk farklı bayta göre değişmesin.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
