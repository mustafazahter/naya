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

/// Taslak için örnek parça.
const sampleChain = PartDetail(
  id: 'drive.chain',
  name: 'Zincir',
  system: 'Aktarma organları',
  sns: '41-20',
  function: 'Pedal dişlisindeki gücü arka tekerleğe aktarır.',
  faults: [
    PartFault(
      title: 'Aşınma ve uzama',
      cause: 'Baklalar aşınmış, zincir dişliye tam oturmuyor.',
      severity: 2,
    ),
    PartFault(
      title: 'Kırık bakla',
      cause: 'Ani yükte bakla pimi çıkmış ya da kırılmış.',
      severity: 4,
    ),
    PartFault(
      title: 'Yağsız ve paslı',
      cause: 'Uzun süre bakımsız kalmış, sürtünme artmış.',
      severity: 1,
    ),
  ],
  procedures: [
    Procedure(
      title: 'Kontrol et',
      dmc: 'DMC-NAYABIKE-AAA-D00-00-00-00AA-310A-A',
      minutes: 5,
    ),
    Procedure(
      title: 'Sök',
      dmc: 'DMC-NAYABIKE-AAA-D00-00-00-00AA-520A-A',
      minutes: 15,
    ),
    Procedure(
      title: 'Tak',
      dmc: 'DMC-NAYABIKE-AAA-D00-00-00-00AA-720A-A',
      minutes: 20,
    ),
  ],
  ipd: 'DMC-NAYABIKE-AAA-D00-00-00-00AA-941A-A · Şekil 1 · No 12',
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
  'drive_cassette': 'Arka dişli',
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
