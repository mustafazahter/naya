/// Parça kartında gösterilen bilgiler.
class PartDetail {
  const PartDetail({
    required this.id,
    required this.name,
    required this.system,
    required this.sns,
    required this.function,
    required this.faults,
    required this.procedures,
    required this.ipd,
  });

  final String id;
  final String name;

  /// Bağlı olduğu montaj, örneğin "Aktarma organları".
  final String system;
  final String sns;
  final String function;
  final List<PartFault> faults;
  final List<Procedure> procedures;
  final String ipd;
}

class PartFault {
  const PartFault({
    required this.title,
    required this.cause,
    required this.severity,
  });

  final String title;
  final String cause;
  final int severity;
}

class Procedure {
  const Procedure({
    required this.title,
    required this.dmc,
    required this.minutes,
  });

  final String title;
  final String dmc;
  final int minutes;
}

/// Taslak için örnek parça; değerler bisiklet şablonundaki
/// `map/parts.json` ve `map/faults.json` ile aynı.
const sampleChain = PartDetail(
  id: 'drive.chain',
  name: 'Zincir',
  system: 'Aktarma organları',
  sns: 'DA1-10',
  function: 'Aynakoldaki gücü arka dişliye taşır.',
  faults: [
    PartFault(
      title: 'Aşınma ve uzama',
      cause: 'Zincir aşınıp uzamış; dişlilere tam oturmuyor.',
      severity: 2,
    ),
    PartFault(
      title: 'Sıkışmış bakla',
      cause: 'Bir bakla sıkışmış; makaralardan geçerken atlıyor.',
      severity: 2,
    ),
    PartFault(
      title: 'Kuru ya da kirli',
      cause: 'Zincir kurumuş ya da kirlenmiş.',
      severity: 1,
    ),
  ],
  procedures: [
    Procedure(
      title: 'Aşınmayı ölç',
      dmc: 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-361A-A',
      minutes: 5,
    ),
    Procedure(
      title: 'Temizle ve yağla',
      dmc: 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-241A-A',
      minutes: 10,
    ),
    Procedure(
      title: 'Sök',
      dmc: 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A',
      minutes: 15,
    ),
    Procedure(
      title: 'Tak',
      dmc: 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-720A-A',
      minutes: 20,
    ),
  ],
  ipd: 'DMC-NAYABIKE-AAA-D00-00-00-01AA-941A-A · Şekil 01 · No 013',
);

/// Bisiklet modelindeki düğüm adlarının Türkçe karşılıkları. Gerçek veride
/// bunlar `map/parts.json` içindeki `name` alanından gelecek.
const bicyclePartNames = {
  'frame': 'Kadro',
  'fork': 'Çatal',
  'handlebar': 'Gidon',
  'saddle': 'Sele',
  'seatpost': 'Sele borusu',
  'drive_chain': 'Zincir',
  'drive_crankset': 'Aynakol',
  'drive_pedals': 'Pedallar',
  'drive_cassette': 'Kaset',
  'drive_derailleur': 'Arka vites değiştirici',
  'brakes_front': 'Ön fren',
  'brakes_rear': 'Arka fren',
  'wheel_front_tire': 'Ön lastik',
  'wheel_front_rim': 'Ön jant',
  'wheel_front_spokes': 'Ön teller',
  'wheel_front_hub': 'Ön göbek',
  'wheel_rear_tire': 'Arka lastik',
  'wheel_rear_rim': 'Arka jant',
  'wheel_rear_spokes': 'Arka teller',
  'wheel_rear_hub': 'Arka göbek',
};
