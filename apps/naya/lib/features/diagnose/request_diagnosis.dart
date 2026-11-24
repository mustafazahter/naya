import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/product/product_content.dart';
import '../../entities/session/session.dart';
import '../../shared/api/api_client.dart';

/// Yazılan belirtiyi sunucuya teşhis ettirir (`POST /api/ai/diagnose`).
///
/// [earlier], aynı konuşmada daha önce yazılanlar: sistem bir soru
/// sorduysa kullanıcının cevabı önceki belirtilerle birlikte değerlendirilir.
/// Sunucu teşhisi kaydeder; geçmişte aynen açılabilir.
Future<Diagnosis> requestDiagnosis(
  ApiClient api,
  ProductContent content, {
  required String message,
  List<String> earlier = const [],
}) async {
  final json = await api.postJson('/api/ai/diagnose', {
    'item': content.productId,
    'message': message,
    if (earlier.isNotEmpty) 'earlier': earlier,
  });
  return _fromJson(json, content);
}

/// Geçmişteki bir teşhisi aynen açar (`GET /api/ai/diagnoses/<id>`).
Future<Diagnosis> loadDiagnosis(
  ApiClient api,
  ProductContent content,
  int id,
) async => _fromJson(await api.getJson('/api/ai/diagnoses/$id'), content);

/// Geçmiş listesindeki bir satır.
class DiagnosisEntry {
  const DiagnosisEntry({required this.diagnosis, required this.createdAt});
  final Diagnosis diagnosis;
  final DateTime createdAt;
}

/// Ürünün teşhis geçmişi, en yeni önce. Parça adları ürünün içeriğinden
/// geldiği için içerik yüklenmeden liste istenmez.
final diagnosisHistoryProvider = FutureProvider.autoDispose
    .family<List<DiagnosisEntry>, ProductContent>((ref, content) async {
      // Giriş, çıkış ya da hesap değişince yeniden sorulur.
      ref.watch(sessionProvider.select((s) => s.value?.id));
      final json = await ref
          .watch(apiClientProvider)
          .getJson(
            '/api/ai/diagnoses?item='
            '${Uri.encodeQueryComponent(content.productId)}',
          );
      return [
        for (final d in json['diagnoses'] as List<Object?>? ?? const [])
          if (d is Map<String, Object?>)
            DiagnosisEntry(
              diagnosis: _fromJson(d, content),
              createdAt:
                  DateTime.tryParse(d['createdAt'] as String? ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
            ),
      ];
    }, retry: (_, _) => null);

Diagnosis _fromJson(Map<String, Object?> json, ProductContent content) =>
    Diagnosis.fromJson(
      json,
      nameOf: (id) => content.part(id)?.name ?? id,
      faultCauseOf: (id) => content.fault(id)?.cause,
    );

/// Teşhiste hangi model düğümünün ne kadar parlayacağı. Parçanın bütün
/// düğümleri aynı ağırlığı alır; bir düğüm birden çok adayda varsa
/// büyüğü kalır.
///
/// - Net sonuçta en olası parça tam parlar, diğerleri olasılığıyla orantılı.
/// - Yakın iki adayda ikisi de tam parlar.
/// - Belirsiz sonuçta ilk üç aday soluk parlar; kamera yaklaşmaz.
Map<String, double> scanWeights(Diagnosis diagnosis, ProductContent content) {
  final candidates = diagnosis.candidates;
  if (candidates.isEmpty) return _systemWeights(diagnosis, content);
  final top = candidates.first.probability;
  final weights = <String, double>{};
  for (final (i, c) in candidates.indexed) {
    final double weight;
    switch (diagnosis.decision) {
      case DiagnosisDecision.ambiguous:
        weight = i < 2 ? 1 : 0;
      case DiagnosisDecision.uncertain:
        weight = i < 3 ? 0.35 * c.probability / top : 0;
      default:
        weight = c.probability / top;
    }
    if (weight <= 0) continue;
    for (final node in content.part(c.partId)?.meshNodes ?? const <String>[]) {
      final current = weights[node] ?? 0;
      if (weight > current) weights[node] = weight;
    }
  }
  return weights;
}

/// Parça seçilemedi ama sistem tahmini var: en olası bir iki sistemin
/// bütün parçaları soluk parlar, kullanıcı yapay zekânın nereye baktığını
/// görür. Sistem de yoksa (konu dışı ya da bilgi yetersiz) vurgu yok.
Map<String, double> _systemWeights(
  Diagnosis diagnosis,
  ProductContent content,
) {
  final systems = diagnosis.systems;
  if (systems.isEmpty || diagnosis.decision == DiagnosisDecision.notDiagnosis) {
    return const {};
  }
  final top = systems.first.probability;
  if (top <= 0) return const {};
  final weights = <String, double>{};
  for (final s in systems.take(2)) {
    if (s.probability < 0.25) continue;
    final weight = 0.35 * s.probability / top;
    for (final part in content.parts.parts) {
      final path = content.pathTo(part.id);
      if (path.isEmpty || path.first.id != s.id) continue;
      for (final node in part.meshNodes) {
        if (weight > (weights[node] ?? 0)) weights[node] = weight;
      }
    }
  }
  return weights;
}
