import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/product/product_content.dart';
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
  return Diagnosis.fromJson(
    json,
    nameOf: (id) => content.part(id)?.name ?? id,
    faultCauseOf: (id) => content.fault(id)?.cause,
  );
}

/// Teşhiste hangi model düğümünün ne kadar parlayacağı. Parçanın bütün
/// düğümleri aynı ağırlığı alır; bir düğüm birden çok adayda varsa
/// büyüğü kalır.
///
/// - Net sonuçta en olası parça tam parlar, diğerleri olasılığıyla orantılı.
/// - Yakın iki adayda ikisi de tam parlar.
/// - Belirsiz sonuçta ilk üç aday soluk parlar; kamera yaklaşmaz.
Map<String, double> scanWeights(Diagnosis diagnosis, ProductContent content) {
  final candidates = diagnosis.candidates;
  if (candidates.isEmpty) return const {};
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
