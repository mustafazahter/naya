import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Oturum token'ları: istemciye giden rastgele değer ve veritabanına
/// yazılan özeti.
abstract final class SessionToken {
  static final _random = Random.secure();

  /// 32 rastgele bayt, adreste ve çerezde sorunsuz taşınsın diye
  /// dolgusuz base64url.
  static String generate() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Veritabanında yalnız bu durur. Token zaten rastgele olduğu için tuz
  /// ya da yavaş bir özet gerekmiyor.
  static String hash(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
