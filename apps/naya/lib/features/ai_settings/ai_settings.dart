import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/session/session.dart';
import '../../shared/api/api_client.dart';

/// Kullanıcının OpenRouter anahtarının durumu. Anahtarın kendisi sunucudan
/// hiç geri gelmez; yalnız son dört hanesi.
class KeyStatus {
  const KeyStatus({
    required this.configured,
    required this.hasKey,
    this.hint,
    this.updatedAt,
  });

  factory KeyStatus.fromJson(Map<String, Object?> json) => KeyStatus(
    configured: json['configured'] as bool? ?? false,
    hasKey: json['hasKey'] as bool? ?? false,
    hint: json['hint'] as String?,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal(),
  );

  /// Sunucuda `NAYA_MASTER_KEY` var mı? Yoksa anahtar saklanamaz.
  final bool configured;
  final bool hasKey;

  /// `…a1b2`
  final String? hint;
  final DateTime? updatedAt;
}

/// OpenRouter'daki bir model. Fiyat milyon token başına dolar.
class AiModel {
  const AiModel({
    required this.id,
    required this.name,
    required this.kind,
    this.contextLength,
    this.inputPrice,
    this.outputPrice,
  });

  factory AiModel.fromJson(Map<String, Object?> json) => AiModel(
    id: json['id']! as String,
    name: json['name'] as String? ?? json['id']! as String,
    kind: json['kind'] as String? ?? 'chat',
    contextLength: json['contextLength'] as int?,
    inputPrice: (json['inputPrice'] as num?)?.toDouble(),
    outputPrice: (json['outputPrice'] as num?)?.toDouble(),
  );

  final String id;
  final String name;

  /// `chat` ya da `decision` (Jev gibi olasılık döndüren modeller).
  final String kind;
  final int? contextLength;
  final double? inputPrice;
  final double? outputPrice;
}

/// Modellerin görevleri: sohbet (açıklama, cevap) ve karar (teşhis).
enum AiRole {
  chat('chat', 'Sohbet modeli', 'Açıklamaları ve cevapları yazar.'),
  decision(
    'decision',
    'Karar modeli',
    'Teşhiste olasılıkları verir. Olasılık döndüren bir model olmalı.',
  );

  const AiRole(this.key, this.label, this.help);

  final String key;
  final String label;
  final String help;

  /// Seçim listesinde bu role uygun modeller.
  bool fits(AiModel model) => model.kind == key;
}

final keyStatusProvider = FutureProvider.autoDispose<KeyStatus>((ref) async {
  // Giriş, çıkış ya da hesap değişince yeniden sorulur.
  ref.watch(sessionProvider.select((s) => s.value?.id));
  return KeyStatus.fromJson(
    await ref.watch(apiClientProvider).getJson('/api/ai/key'),
  );
}, retry: (_, _) => null);

/// Liste sunucuda 24 saat önbellekte; anahtar yokken de gelir.
final aiModelsProvider = FutureProvider.autoDispose<List<AiModel>>((ref) async {
  final json = await ref.watch(apiClientProvider).getJson('/api/ai/models');
  final models = [
    for (final m in json['models'] as List<Object?>? ?? const [])
      if (m is Map<String, Object?>) AiModel.fromJson(m),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return models;
}, retry: (_, _) => null);

final aiRolesProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  ref.watch(sessionProvider.select((s) => s.value?.id));
  final json = await ref.watch(apiClientProvider).getJson('/api/ai/roles');
  return _rolesOf(json);
}, retry: (_, _) => null);

// Aşağıdakiler istekten önce [ProviderScope]'u alır: kullanıcı beklerken
// sayfadan çıkarsa [WidgetRef] artık kullanılamaz.

/// Anahtarı sunucuya gönderir; sunucu OpenRouter'a sorup doğrular.
Future<void> saveApiKey(WidgetRef ref, String key) async {
  final container = ProviderScope.containerOf(ref.context, listen: false);
  await container.read(apiClientProvider).putJson('/api/ai/key', {
    'key': key.trim(),
  });
  container.invalidate(keyStatusProvider);
}

Future<void> deleteApiKey(WidgetRef ref) async {
  final container = ProviderScope.containerOf(ref.context, listen: false);
  await container.read(apiClientProvider).delete('/api/ai/key');
  container.invalidate(keyStatusProvider);
}

Future<void> setRoleModel(WidgetRef ref, AiRole role, String modelId) async {
  final container = ProviderScope.containerOf(ref.context, listen: false);
  await container.read(apiClientProvider).putJson('/api/ai/roles', {
    role.key: modelId,
  });
  container.invalidate(aiRolesProvider);
}

Map<String, String> _rolesOf(Map<String, Object?> json) {
  final roles = json['roles'];
  if (roles is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in roles.entries)
      if (key is String && value is String) key: value,
  };
}
