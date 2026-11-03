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

  /// 0..1 arası, Jev'den gelen kalibre olasılık.
  final double probability;
}

class Diagnosis {
  const Diagnosis({
    required this.symptom,
    required this.candidates,
    required this.systemsScanned,
    required this.safeToUse,
    required this.source,
  });

  final String symptom;

  /// Olasılığa göre azalan sırada.
  final List<Candidate> candidates;
  final int systemsScanned;

  /// "Kullanmaya devam etmek güvenli mi?" sorusunun olasılığı.
  final double safeToUse;
  final String source;

  Candidate get top => candidates.first;

  /// En yüksek olasılık %35'in altındaysa parça gösterilmez, soru sorulur.
  bool get isConfident => top.probability >= 0.35;
}

const sampleDiagnosis = Diagnosis(
  symptom: 'Pedal çevirince tıkırtı geliyor, bazen zincir atlıyor.',
  candidates: [
    Candidate(
      partId: 'drive.chain',
      name: 'Zincir',
      system: 'Aktarma organları',
      probability: 0.62,
    ),
    Candidate(
      partId: 'drive.derailleur',
      name: 'Arka vites değiştirici',
      system: 'Aktarma organları',
      probability: 0.21,
    ),
    Candidate(
      partId: 'drive.crank',
      name: 'Pedal kolu ve yatağı',
      system: 'Aktarma organları',
      probability: 0.09,
    ),
  ],
  systemsScanned: 4,
  safeToUse: 0.78,
  source: 'DMC-NAYABIKE-AAA-D00-00-00-00AA-421A-A',
);
