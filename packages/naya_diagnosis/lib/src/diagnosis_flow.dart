import 'package:naya_format/naya_format.dart';

import 'catalog.dart';
import 'decider.dart';
import 'diagnosis_result.dart';

/// Kullanıcının mesajından teşhise giden yol.
///
/// 1. Niyet ve yeterlilik (tek istekte): teşhis mi isteniyor, belirtiler
///    bir parça seçmeye yetiyor mu?
/// 2. Sistem turu: kök sistemler ve "hiçbiri".
/// 3. Parça turu: toplamı %80'i geçene kadar en fazla 3 sistemin
///    parçaları, her sistem ayrı soru (tek istekte).
///    P(parça) = P(sistem) × P(parça | sistem).
/// 4. Arıza ve güvenlik (tek istekte): en olası parçanın hangi arızası,
///    kullanmaya devam etmek tehlikeli mi?
///
/// Karar kuralları raporun 8. bölümündeki tablodan.
class DiagnosisFlow {
  DiagnosisFlow({required this.catalog, required this.decider});

  final DiagnosisCatalog catalog;
  final Decider decider;

  /// Kamera bu olasılığın altındaki parçaya gitmez.
  static const focusThreshold = 0.35;

  /// İlk iki parça bundan yakınsa ikisi birlikte gösterilir.
  static const ambiguityGap = 0.10;

  /// Parça turuna alınan sistemlerin toplam olasılığı.
  static const systemCoverage = 0.80;
  static const maxSystems = 3;

  /// "Belirtiler yeterli mi?" bunun altındaysa önce soru sorulur.
  static const sufficiencyThreshold = 0.5;

  /// Sonuçta tutulan aday sayısı.
  static const keptCandidates = 10;

  /// "Hiçbiri" seçeneğinin anahtarı.
  static const none = 'none';

  Future<DiagnosisResult> run(
    String message, {
    List<String> earlierMessages = const [],
  }) async {
    final state = _state(message, earlierMessages);
    final models = <String>[];

    // 1. Niyet ve yeterlilik
    final first = await decider.ask(state, {
      'intent': const ChoiceQuestion('Kullanıcı son mesajında ne istiyor?', {
        'diagnose':
            'Bir sorun, ses ya da arıza anlatıyor; kaynağını bulmak istiyor.',
        'repair':
            'Bir şeyin nasıl sökülüp takılacağını ya da '
            'tamir edileceğini soruyor.',
        'partInfo':
            'Bir parçanın ne olduğunu ya da ne işe yaradığını '
            'soruyor.',
        'general':
            'Ürünle ilgili genel bir soru soruyor ya da sohbet '
            'ediyor.',
      }),
      'sufficient': const YesNoQuestion(
        'Anlatılanlar, sorunun hangi parçadan kaynaklandığını tahmin etmeye '
        'yetecek kadar belirti içeriyor mu?',
      ),
    });
    models.add(first.model);
    final intent = _intentOf(first.choices['intent'] ?? const {});
    final sufficiency = first.yes['sufficient'];
    if (intent != DiagnosisIntent.diagnose) {
      return DiagnosisResult(
        intent: intent,
        decision: DiagnosisDecision.notDiagnosis,
        sufficiency: sufficiency,
        model: _modelOf(models),
      );
    }
    if (sufficiency != null && sufficiency < sufficiencyThreshold) {
      return DiagnosisResult(
        intent: intent,
        decision: DiagnosisDecision.needsInfo,
        sufficiency: sufficiency,
        model: _modelOf(models),
      );
    }

    // 2. Sistem turu
    final systems = catalog.systems;
    final systemAnswer = await decider.ask(state, {
      'system': ChoiceQuestion(
        'Belirtilere göre arıza en olası hangi sistemde?',
        {
          for (final s in systems) s.id: catalog.describeSystem(s),
          none: 'Hiçbiri: bu sistemlerin hiçbiri belirtileri açıklamıyor.',
        },
      ),
    });
    models.add(systemAnswer.model);
    final systemScores = _sorted(systemAnswer.choices['system'] ?? const {});
    if (systemScores.isEmpty || systemScores.first.id == none) {
      return DiagnosisResult(
        intent: intent,
        decision: DiagnosisDecision.uncertain,
        sufficiency: sufficiency,
        systems: systemScores,
        model: _modelOf(models),
      );
    }

    // 3. Parça turu
    final chosen = _coveringSystems(systemScores);
    final partAnswer = await decider.ask(
      '$state\nSeçilen sistemler: '
      '${chosen.map((s) => catalog.part(s.id)?.name ?? s.id).join(', ')}',
      {
        for (final s in chosen)
          'part:${s.id}': ChoiceQuestion(
            'Belirtilerin kaynağı olan parça hangisi?',
            {
              for (final p
                  in catalog.partsOf(s.id).take(ChoiceQuestion.maxOptions - 1))
                p.id: catalog.describePart(p),
              none: 'Hiçbiri: bu sistemdeki parçalar belirtiyi açıklamıyor.',
            },
          ),
      },
    );
    models.add(partAnswer.model);
    final candidates = <PartCandidate>[];
    for (final s in chosen) {
      final parts = partAnswer.choices['part:${s.id}'] ?? const {};
      parts.forEach((partId, p) {
        if (partId == none) return;
        candidates.add(
          PartCandidate(
            partId: partId,
            systemId: s.id,
            probability: s.probability * p,
          ),
        );
      });
    }
    candidates.sort((a, b) => b.probability.compareTo(a.probability));
    final kept = candidates.take(keptCandidates).toList();
    final top = kept.isEmpty ? null : kept.first;

    // 4. Arıza ve güvenlik
    final faults = top == null ? <Fault>[] : catalog.faultsOf(top.partId);
    final lastAnswer = await decider.ask(
      top == null
          ? state
          : '$state\nEn olası parça: ${catalog.part(top.partId)?.name}',
      {
        if (faults.isNotEmpty)
          'fault': ChoiceQuestion('Bu parçadaki arıza hangisi?', {
            for (final f in faults) f.id: catalog.describeFault(f),
            none: 'Hiçbiri: bilinen arızaların hiçbiri belirtilere uymuyor.',
          }),
        'danger': const YesNoQuestion(
          'Bu belirtilerle ürünü kullanmaya devam etmek tehlikeli mi?',
        ),
      },
    );
    models.add(lastAnswer.model);
    final faultScores = _sorted(lastAnswer.choices['fault'] ?? const {});
    final fault = faultScores.isEmpty || faultScores.first.id == none
        ? null
        : faultScores.first;

    return DiagnosisResult(
      intent: intent,
      decision: _decide(kept),
      sufficiency: sufficiency,
      systems: systemScores,
      candidates: kept,
      fault: fault,
      procedure: _procedure(top, faults, fault),
      danger: lastAnswer.yes['danger'],
      model: _modelOf(models),
    );
  }

  /// Karar kuralları: eşik, fark ve belirsizlik.
  static DiagnosisDecision _decide(List<PartCandidate> candidates) {
    if (candidates.isEmpty) return DiagnosisDecision.uncertain;
    final top = candidates.first.probability;
    if (top < focusThreshold) return DiagnosisDecision.uncertain;
    if (candidates.length > 1 &&
        top - candidates[1].probability < ambiguityGap) {
      return DiagnosisDecision.ambiguous;
    }
    return DiagnosisDecision.focus;
  }

  /// Arıza netse tamir prosedürü; değilse en ciddi arızanın arıza bulma
  /// prosedürü; o da yoksa parçanın muayene prosedürü.
  String? _procedure(PartCandidate? top, List<Fault> faults, Scored? fault) {
    if (top == null) return null;
    if (fault != null && fault.probability >= focusThreshold) {
      final chosen = catalog.fault(fault.id);
      final dm = chosen?.repair ?? chosen?.isolation;
      if (dm != null) return dm;
    }
    final bySeverity = [...faults]
      ..sort((a, b) => b.severity.compareTo(a.severity));
    for (final f in bySeverity) {
      if (f.isolation != null) return f.isolation;
    }
    final procedures = catalog.part(top.partId)?.procedures ?? const {};
    return procedures['inspect'] ?? procedures.values.firstOrNull;
  }

  /// Toplamı [systemCoverage]'ı geçene kadar en olası sistemler, en fazla
  /// [maxSystems]. "Hiçbiri" alınmaz.
  static List<Scored> _coveringSystems(List<Scored> scores) {
    final chosen = <Scored>[];
    var total = 0.0;
    for (final s in scores) {
      if (s.id == none) continue;
      chosen.add(s);
      total += s.probability;
      if (total >= systemCoverage || chosen.length == maxSystems) break;
    }
    return chosen;
  }

  String _state(String message, List<String> earlier) => [
    'Ürün: ${catalog.productTitle}',
    for (final m in earlier) 'Kullanıcının önceki mesajı: $m',
    'Kullanıcının son mesajı: $message',
  ].join('\n');

  static DiagnosisIntent _intentOf(Map<String, double> scores) {
    final best = _sorted(scores).firstOrNull?.id;
    for (final intent in DiagnosisIntent.values) {
      if (intent.name == best) return intent;
    }
    return DiagnosisIntent.diagnose;
  }

  static List<Scored> _sorted(Map<String, double> scores) {
    final list = [for (final e in scores.entries) Scored(e.key, e.value)];
    list.sort((a, b) => b.probability.compareTo(a.probability));
    return list;
  }

  /// Bütün istekler aynı modelle yapılır; ilk boş olmayan sürüm yeterli.
  static String _modelOf(List<String> models) =>
      models.firstWhere((m) => m.isNotEmpty, orElse: () => '');
}
