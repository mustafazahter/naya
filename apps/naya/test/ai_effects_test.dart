import 'package:flutter_test/flutter_test.dart';
import 'package:naya/entities/diagnosis/diagnosis.dart';
import 'package:naya/entities/product/product_content.dart';
import 'package:naya/features/diagnose/request_diagnosis.dart';
import 'package:naya_diagnosis/naya_diagnosis.dart';
import 'package:naya_format/naya_format.dart';

const _ipd = {'dmc': 'DMC-NAYACAR-AAA-D00-00-00-01AA-941A-A', 'figure': '01'};

Map<String, Object?> _part(
  String id,
  String name,
  List<String> nodes, {
  String? parent,
  Map<String, String> procedures = const {},
}) => {
  'id': id,
  'name': name,
  'parent': ?parent,
  'meshNodes': nodes,
  'procedures': procedures,
  'ipd': {..._ipd, 'item': '001'},
};

/// Kapılar tek düğüm; kilit ve fitil dört kapıyı kapsayan grup parçaları.
ProductContent _car() => ProductContent(
  productId: 'araba',
  parts: PartsFile.fromJson({
    'parts': [
      _part('body', 'Gövde', ['shell']),
      _part('body.door_fl', 'Sol ön kapı', ['door_fl'], parent: 'body'),
      _part('body.door_fr', 'Sağ ön kapı', ['door_fr'], parent: 'body'),
      _part(
        'body.door_locks',
        'Kapı kilitleri',
        ['door_fl', 'door_fr'],
        parent: 'body',
        procedures: {'replace': 'DMC-NAYACAR-AAA-DA0-40-00-00AA-920A-A'},
      ),
      _part('body.door_seals', 'Kapı fitilleri', [
        'door_fl',
        'door_fr',
      ], parent: 'body'),
      _part('engine', 'Motor', ['engine_block']),
      _part('engine.coils', 'Bobinler', ['coils'], parent: 'engine'),
    ],
  }),
  faults: FaultsFile.fromJson({
    'symptoms': [
      {'id': 'sym.lock', 'text': 'Kapı kilitlenmiyor'},
      {'id': 'sym.leak', 'text': 'Kapıdan su giriyor'},
      {'id': 'sym.misfire', 'text': 'Motor tekliyor'},
    ],
    'faults': [
      {
        'id': 'f.lock',
        'part': 'body.door_locks',
        'symptoms': ['sym.lock'],
        'cause': 'Kilit motoru arızalı.',
        'severity': 1,
        'isolation': 'DMC-NAYACAR-AAA-DA0-40-00-00AA-421A-A',
      },
      {
        'id': 'f.seal',
        'part': 'body.door_seals',
        'symptoms': ['sym.leak'],
        'cause': 'Fitil yırtık.',
        'severity': 2,
      },
      {
        'id': 'f.coil',
        'part': 'engine.coils',
        'symptoms': ['sym.misfire'],
        'cause': 'Bobin arızalı.',
        'severity': 2,
        'repair': 'DMC-NAYACAR-AAA-DA1-50-00-00AA-920A-A',
      },
    ],
  }),
);

void main() {
  group('parça kartı', () {
    test('kapı kartında kapsayan kilit ve fitil arızaları görünür', () {
      final content = _car();
      expect(content.faultsFor('body.door_fl'), isEmpty);
      expect(content.groupsCovering('body.door_fl').map((p) => p.id), [
        'body.door_locks',
        'body.door_seals',
      ]);
      // En ciddisi önce.
      expect(content.cardFaults('body.door_fl').map((f) => f.id), [
        'f.seal',
        'f.lock',
      ]);
    });

    test('üst montaj ve alt parça kapsayan grup sayılmaz', () {
      final content = _car();
      expect(content.groupsCovering('body'), isEmpty);
      expect(content.groupsCovering('engine.coils'), isEmpty);
      expect(content.cardFaults('engine').map((f) => f.id), ['f.coil']);
    });
  });

  test('sohbet kaynaklarından parçalar bulunur, IPD sayılmaz', () {
    final content = _car();
    expect(
      content
          .partsForModules([
            'DMC-NAYACAR-AAA-DA0-40-00-00AA-920A-A',
            'DMC-NAYACAR-AAA-DA1-50-00-00AA-920A-A_001-00_TR-TR',
            'DMC-NAYACAR-AAA-D00-00-00-01AA-941A-A',
          ])
          .map((p) => p.id),
      ['body.door_locks', 'engine.coils'],
    );
  });

  test('başka daldaki büyük grup kapsayan grup sayılmaz', () {
    final content = ProductContent(
      productId: 'araba',
      parts: PartsFile.fromJson({
        'parts': [
          _part('engine', 'Motor', ['block', 'pump']),
          _part('engine.water_pump', 'Su pompası', ['pump'], parent: 'engine'),
          _part('cooling', 'Soğutma', ['radiator']),
          // Soğutma dalında ama su pompasının düğümünü de kapsıyor.
          _part('cooling.hoses', 'Hortumlar', [
            'radiator',
            'pump',
          ], parent: 'cooling'),
        ],
      }),
    );
    expect(content.groupsCovering('engine.water_pump'), isEmpty);
  });

  group('teşhis vurgusu', () {
    Diagnosis diagnosis(DiagnosisDecision decision, List<Scored> systems) =>
        Diagnosis(
          symptom: 'Motor tekliyor',
          candidates: const [],
          systemsScanned: systems.length,
          systems: systems,
          decision: decision,
        );

    test('parça seçilemezse en olası sistemin parçaları soluk parlar', () {
      final weights = scanWeights(
        diagnosis(DiagnosisDecision.uncertain, const [
          Scored('engine', 0.8),
          Scored('body', 0.1),
        ]),
        _car(),
      );
      expect(weights.keys, unorderedEquals(['engine_block', 'coils']));
      expect(weights['coils'], closeTo(0.35, 1e-9));
    });

    test('yapay zekâ "hiçbiri" dediyse sistem parlamaz', () {
      final d = Diagnosis(
        symptom: 'Garip bir koku var',
        candidates: const [],
        systemsScanned: 1,
        systems: const [Scored('engine', 0.4)],
        noSystemFits: true,
        decision: DiagnosisDecision.uncertain,
      );
      expect(scanWeights(d, _car()), isEmpty);
    });

    test('konu dışı mesajda ve sistem yokken vurgu yok', () {
      expect(
        scanWeights(diagnosis(DiagnosisDecision.needsInfo, const []), _car()),
        isEmpty,
      );
      expect(
        scanWeights(
          diagnosis(DiagnosisDecision.notDiagnosis, const [
            Scored('engine', 0.9),
          ]),
          _car(),
        ),
        isEmpty,
      );
    });
  });
}
