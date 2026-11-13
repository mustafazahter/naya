import 'package:naya_diagnosis/naya_diagnosis.dart';

export 'package:naya_diagnosis/naya_diagnosis.dart' show DiagnosisDecision;

/// Teşhiste bir aday parça ve olasılığı.
class Candidate {
  const Candidate({
    required this.partId,
    required this.name,
    required this.system,
    required this.probability,
  });

  final String partId;
  final String name;
  final String system;

  /// 0..1 arası, P(sistem) × P(parça | sistem).
  final double probability;
}

/// Sunucunun döndürdüğü teşhis, ekranda gösterilecek haliyle.
class Diagnosis {
  const Diagnosis({
    required this.symptom,
    required this.candidates,
    required this.systemsScanned,
    this.decision = DiagnosisDecision.focus,
    this.danger,
    this.faultCause,
    this.procedure,
    this.explanation = '',
    this.sources = const [],
    this.id,
  });

  /// `/api/ai/diagnose` cevabından. Parça ve sistem adları ürünün parça
  /// haritasından gelir; adı bulunamayan kimliğiyle görünür.
  factory Diagnosis.fromJson(
    Map<String, Object?> json, {
    required String Function(String partId) nameOf,
    String? Function(String faultId)? faultCauseOf,
  }) {
    final result = DiagnosisResult.fromJson(
      json['result']! as Map<String, Object?>,
    );
    final fault = result.fault;
    return Diagnosis(
      id: json['id'] as int?,
      symptom: json['message'] as String? ?? '',
      candidates: [
        for (final c in result.candidates.take(5))
          Candidate(
            partId: c.partId,
            name: nameOf(c.partId),
            system: nameOf(c.systemId),
            probability: c.probability,
          ),
      ],
      systemsScanned: result.systems.where((s) => s.id != 'none').length,
      decision: result.decision,
      danger: result.danger,
      faultCause: fault == null ? null : faultCauseOf?.call(fault.id),
      procedure: result.procedure,
      explanation: json['explanation'] as String? ?? '',
      sources: [
        for (final s in (json['sources'] as List<Object?>?) ?? const [])
          if (s is String) s,
      ],
    );
  }

  /// Teşhis geçmişindeki kimliği; örnek veride yok.
  final int? id;
  final String symptom;

  /// Olasılığa göre azalan sırada.
  final List<Candidate> candidates;
  final int systemsScanned;
  final DiagnosisDecision decision;

  /// "Kullanmaya devam etmek tehlikeli mi?" sorusunda "evet" olasılığı.
  final double? danger;

  /// En olası arızanın nedeni, arıza netse.
  final String? faultCause;

  /// Önerilen prosedürün DMC'si.
  final String? procedure;

  /// Sohbet modelinin açıklaması ya da sorusu.
  final String explanation;

  /// Cevabın dayandığı DM'ler.
  final List<String> sources;

  Candidate get top => candidates.first;

  /// Kamera bulunan parçaya gider mi? En yüksek olasılık %35'in altındaysa
  /// ya da ilk iki aday çok yakınsa gitmez.
  bool get isConfident => decision == DiagnosisDecision.focus;

  /// Tehlike olasılığı yarıyı geçiyorsa uyarı gösterilir.
  bool get isDangerous => (danger ?? 0) >= 0.5;
}

/// Masaüstündeki şematik görünüm ve testler için örnek teşhis.
const sampleDiagnosis = Diagnosis(
  symptom: 'Pedala yüklenince zincir boşa atlıyor, cızırtı da geliyor.',
  candidates: [
    Candidate(
      partId: 'drive.chain',
      name: 'Zincir',
      system: 'Aktarma organları',
      probability: 0.62,
    ),
    Candidate(
      partId: 'drive.rear_derailleur',
      name: 'Arka vites değiştirici',
      system: 'Aktarma organları',
      probability: 0.21,
    ),
    Candidate(
      partId: 'drive.cassette',
      name: 'Kaset',
      system: 'Aktarma organları',
      probability: 0.09,
    ),
  ],
  systemsScanned: 4,
  danger: 0.22,
  faultCause: 'Zincir aşınıp uzamış; dişlilere tam oturmuyor.',
  procedure: 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A',
  explanation:
      'En olası neden zincirin aşınıp uzaması. Zincir kontrol aleti ile '
      'ölçün; sınırı geçtiyse değiştirin.',
  sources: ['DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A'],
);
