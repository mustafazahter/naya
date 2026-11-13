/// Kullanıcının mesajla ne istediği.
enum DiagnosisIntent {
  /// Bir sorun anlatıyor, kaynağını arıyor.
  diagnose,

  /// Bir şeyin nasıl tamir edileceğini soruyor.
  repair,

  /// Bir parça hakkında bilgi istiyor.
  partInfo,

  /// Ürünle ilgili genel bir soru.
  general,
}

/// Teşhisin sonunda ne yapılacağı. Arayüz ve animasyon buna göre davranır.
enum DiagnosisDecision {
  /// En olası parça yeterince olası ve ikinciden belirgin önde: kamera
  /// ona gider.
  focus,

  /// İlk iki parça birbirine çok yakın: ikisi birlikte parlar, soru sorulur.
  ambiguous,

  /// En olası parça bile eşiğin altında ya da "hiçbiri" önde: ilk adaylar
  /// soluk gösterilir, soru sorulur.
  uncertain,

  /// Belirtiler bir parça seçmeye yetmiyor: önce netleştirici soru.
  needsInfo,

  /// Mesaj bir arıza anlatmıyor; teşhis yapılmadı.
  notDiagnosis,
}

/// Olasılığı olan bir seçenek: sistem ya da arıza.
class Scored {
  const Scored(this.id, this.probability);

  factory Scored.fromJson(Map<String, Object?> json) =>
      Scored(json['id']! as String, (json['probability']! as num).toDouble());

  final String id;
  final double probability;

  Map<String, Object?> toJson() => {'id': id, 'probability': probability};
}

/// Aday parça. [probability] iki turun çarpımıdır:
/// P(parça) = P(sistem) × P(parça | sistem).
class PartCandidate {
  const PartCandidate({
    required this.partId,
    required this.systemId,
    required this.probability,
  });

  factory PartCandidate.fromJson(Map<String, Object?> json) => PartCandidate(
    partId: json['part']! as String,
    systemId: json['system']! as String,
    probability: (json['probability']! as num).toDouble(),
  );

  final String partId;
  final String systemId;
  final double probability;

  Map<String, Object?> toJson() => {
    'part': partId,
    'system': systemId,
    'probability': probability,
  };
}

/// Teşhisin sonucu. Olasılıkların tamamı kaydedilir; eşikler ileride bu
/// kayıtlarla ayarlanabilir.
class DiagnosisResult {
  const DiagnosisResult({
    required this.intent,
    required this.decision,
    this.sufficiency,
    this.systems = const [],
    this.candidates = const [],
    this.fault,
    this.procedure,
    this.danger,
    this.model = '',
  });

  factory DiagnosisResult.fromJson(Map<String, Object?> json) {
    List<Map<String, Object?>> list(String key) => [
      for (final e in (json[key] as List<Object?>?) ?? const [])
        e! as Map<String, Object?>,
    ];
    final fault = json['fault'] as Map<String, Object?>?;
    return DiagnosisResult(
      intent: DiagnosisIntent.values.byName(json['intent']! as String),
      decision: DiagnosisDecision.values.byName(json['decision']! as String),
      sufficiency: (json['sufficiency'] as num?)?.toDouble(),
      systems: [for (final s in list('systems')) Scored.fromJson(s)],
      candidates: [
        for (final c in list('candidates')) PartCandidate.fromJson(c),
      ],
      fault: fault == null ? null : Scored.fromJson(fault),
      procedure: json['procedure'] as String?,
      danger: (json['danger'] as num?)?.toDouble(),
      model: json['model'] as String? ?? '',
    );
  }

  final DiagnosisIntent intent;
  final DiagnosisDecision decision;

  /// "Belirtiler yeterli mi?" sorusunda "evet" olasılığı.
  final double? sufficiency;

  /// Sistem turu, "hiçbiri" (`none`) dahil, en olası önce.
  final List<Scored> systems;

  /// Birleşik olasılığa göre sıralı aday parçalar.
  final List<PartCandidate> candidates;

  /// En olası parçanın en olası arızası.
  final Scored? fault;

  /// Önerilen prosedürün DMC'si: arıza netse tamir, değilse arıza bulma.
  final String? procedure;

  /// "Kullanmaya devam etmek tehlikeli mi?" sorusunda "evet" olasılığı.
  final double? danger;

  /// Cevapları veren karar modelinin sürümü.
  final String model;

  PartCandidate? get top => candidates.isEmpty ? null : candidates.first;

  Map<String, Object?> toJson() => {
    'intent': intent.name,
    'decision': decision.name,
    if (sufficiency != null) 'sufficiency': sufficiency,
    'systems': [for (final s in systems) s.toJson()],
    'candidates': [for (final c in candidates) c.toJson()],
    if (fault != null) 'fault': fault!.toJson(),
    if (procedure != null) 'procedure': procedure,
    if (danger != null) 'danger': danger,
    'model': model,
  };
}
