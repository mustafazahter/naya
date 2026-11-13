import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Kullanıcıların OpenRouter anahtarlarını AES-GCM ile şifreler.
///
/// Ana anahtar `NAYA_MASTER_KEY` ortam değişkeninden gelir (32 bayt,
/// base64). Şifreli metin kullanıcının kimliğine bağlanır (AAD): bir
/// satır başka kullanıcının satırına kopyalansa çözülemez.
///
/// Saklanan biçim: 12 bayt nonce + şifreli metin + 16 bayt doğrulama kodu.
class KeyVault {
  KeyVault(List<int> masterKey) : _key = SecretKey(masterKey) {
    if (masterKey.length != 32) {
      throw ArgumentError('NAYA_MASTER_KEY 32 bayt olmalı (base64).');
    }
  }

  /// `NAYA_MASTER_KEY` değerinden; boşsa ya da bozuksa `null`.
  static KeyVault? fromBase64(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final bytes = base64.decode(value);
      return bytes.length == 32 ? KeyVault(bytes) : null;
    } on FormatException {
      return null;
    }
  }

  final SecretKey _key;
  static final _algorithm = AesGcm.with256bits();

  Future<Uint8List> encrypt(String plain, {required int userId}) async {
    final box = await _algorithm.encrypt(
      utf8.encode(plain),
      secretKey: _key,
      aad: _aad(userId),
    );
    return Uint8List.fromList(box.concatenation());
  }

  /// Doğrulama tutmazsa (bozuk satır, yanlış ana anahtar) `null`.
  Future<String?> decrypt(List<int> stored, {required int userId}) async {
    try {
      final box = SecretBox.fromConcatenation(
        stored,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );
      final plain = await _algorithm.decrypt(
        box,
        secretKey: _key,
        aad: _aad(userId),
      );
      return utf8.decode(plain);
    } on SecretBoxAuthenticationError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static List<int> _aad(int userId) => utf8.encode('naya-ai-key:$userId');
}
