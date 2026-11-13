import 'package:drift/drift.dart';

import '../database/database.dart';
import 'ai_provider.dart';
import 'key_vault.dart';

/// Kullanıcının seçebileceği roller ve varsayılan modelleri.
abstract final class AiRole {
  /// Sohbet ve açıklama.
  static const chat = 'chat';

  /// Teşhis kararları (Jev).
  static const decision = 'decision';

  static const defaults = {
    chat: 'deepseek/deepseek-v4.1-flash',
    decision: '~typesafe/jev-latest',
  };
}

/// Anahtar, roller ve model listesi.
///
/// Anahtar sunucuya bir kez gelir: doğrulanır, [KeyVault] ile şifrelenir
/// ve saklanır. Bir daha istemciye dönmez; ayarlarda yalnız son dört
/// karakteri görünür.
class AiSettings {
  AiSettings(
    this._db,
    this._provider, {
    this._vault,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final NayaDatabase _db;
  final AiProvider _provider;
  final KeyVault? _vault;
  final DateTime Function() _clock;

  static const modelCacheDuration = Duration(hours: 24);
  List<AiModel>? _models;
  DateTime? _modelsFetchedAt;

  /// `NAYA_MASTER_KEY` verilmemişse anahtar saklanamaz.
  bool get canStoreKeys => _vault != null;

  Future<AiKeyRow?> keyRow(int userId) => (_db.select(
    _db.aiKeys,
  )..where((k) => k.userId.equals(userId))).getSingleOrNull();

  Future<void> saveKey(int userId, String apiKey) async {
    final vault = _requireVault();
    final key = apiKey.trim();
    if (key.length < 8 || key.length > 512 || key.contains(RegExp(r'\s'))) {
      throw const AiException(
        'invalid_key',
        'Bu bir OpenRouter anahtarına benzemiyor.',
        status: 400,
      );
    }
    await _provider.checkKey(key);
    final secret = await vault.encrypt(key, userId: userId);
    await _db
        .into(_db.aiKeys)
        .insertOnConflictUpdate(
          AiKeysCompanion.insert(
            userId: Value(userId),
            secret: secret,
            hint: key.substring(key.length - 4),
            updatedAt: _clock(),
          ),
        );
  }

  Future<void> deleteKey(int userId) =>
      (_db.delete(_db.aiKeys)..where((k) => k.userId.equals(userId))).go();

  /// Çözülmüş anahtar; yoksa `no_key` hatası.
  Future<String> apiKeyOf(int userId) async {
    final vault = _requireVault();
    final row = await keyRow(userId);
    if (row == null) {
      throw const AiException(
        'no_key',
        'Yapay zekâ için önce ayarlardan OpenRouter anahtarınızı girin.',
        status: 409,
      );
    }
    final key = await vault.decrypt(row.secret, userId: userId);
    if (key == null) {
      throw const AiException(
        'no_key',
        'Kayıtlı anahtar okunamadı; ayarlardan yeniden girin.',
        status: 409,
      );
    }
    return key;
  }

  /// Rol → model; seçilmemiş roller varsayılanla.
  Future<Map<String, String>> roles(int userId) async {
    final rows = await (_db.select(
      _db.aiRoles,
    )..where((r) => r.userId.equals(userId))).get();
    return {
      ...AiRole.defaults,
      for (final row in rows)
        if (AiRole.defaults.containsKey(row.role)) row.role: row.model,
    };
  }

  Future<void> setRole(int userId, String role, String model) async {
    if (!AiRole.defaults.containsKey(role)) {
      throw AiException('bad_request', 'Bilinmeyen rol: $role', status: 400);
    }
    final trimmed = model.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw const AiException(
        'bad_request',
        'Model adı geçersiz.',
        status: 400,
      );
    }
    await _db
        .into(_db.aiRoles)
        .insertOnConflictUpdate(
          AiRolesCompanion.insert(userId: userId, role: role, model: trimmed),
        );
  }

  /// OpenRouter'daki modeller; 24 saat bellekte tutulur.
  Future<List<AiModel>> models() async {
    final fetchedAt = _modelsFetchedAt;
    final cached = _models;
    if (cached != null &&
        fetchedAt != null &&
        _clock().difference(fetchedAt) < modelCacheDuration) {
      return cached;
    }
    final fresh = await _provider.listModels();
    _models = fresh;
    _modelsFetchedAt = _clock();
    return fresh;
  }

  KeyVault _requireVault() {
    final vault = _vault;
    if (vault == null) {
      throw const AiException(
        'not_configured',
        'Sunucuda NAYA_MASTER_KEY tanımlı değil; yapay zekâ kapalı.',
        status: 503,
      );
    }
    return vault;
  }
}
