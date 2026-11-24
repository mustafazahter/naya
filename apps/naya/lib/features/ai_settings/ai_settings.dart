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
    inputPrice: _price(json['inputPrice']),
    outputPrice: _price(json['outputPrice']),
  );

  /// Eksi fiyat (yönlendirici modeller) bilinmiyor sayılır.
  static double? _price(Object? value) =>
      value is num && value >= 0 ? value.toDouble() : null;

  final String id;
  final String name;

  /// `chat` ya da `decision` (Jev gibi olasılık döndüren modeller).
  final String kind;
  final int? contextLength;
  final double? inputPrice;
  final double? outputPrice;

  /// Model listesindeki alt satır:
  /// `deepseek/… · 1M · 1M token: girdi $0.051, çıktı $0.2`.
  String get details {
    final parts = [id];
    final context = contextLength;
    if (context != null) parts.add(_tokens(context));
    final input = inputPrice;
    final output = outputPrice;
    if (input != null && output != null) {
      parts.add(
        '1M token: girdi \$${_dollars(input)}, çıktı \$${_dollars(output)}',
      );
    }
    return parts.join(' · ');
  }

  static String _tokens(int count) => count >= 1000000
      ? '${_trim((count / 1000000).toStringAsFixed(1))}M'
      : '${(count / 1000).round()}K';

  /// 1'in altında iki anlamlı basamak (0.0507 → 0.051), üstünde en çok
  /// iki ondalık (10 → 10, 2.5 → 2.5). Çok küçük fiyat üslü sayıya
  /// (1.2e-7) dönmesin diye `<0.0001` yazılır.
  static String _dollars(double v) {
    if (v == 0) return '0';
    if (v < 0.0001) return '<0.0001';
    if (v < 1) return _trim(v.toStringAsPrecision(2));
    return _trim(v.toStringAsFixed(2));
  }

  static String _trim(String number) => number.contains('.')
      ? number.replaceFirst(RegExp(r'\.?0+$'), '')
      : number;
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
