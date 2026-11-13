import 'dart:convert';
import 'dart:io';

import 'package:naya_diagnosis/naya_diagnosis.dart';
import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

/// Repodaki gerçek bisiklet şablonunun parça ve arıza dosyaları.
DiagnosisCatalog _bicycle() {
  Map<String, Object?> read(String name) => jsonDecode(
    File('../../templates/src/bisiklet/map/$name').readAsStringSync(),
  ) as Map<String, Object?>;
  return DiagnosisCatalog(
    productTitle: 'Dağ bisikleti',
    parts: PartsFile.fromJson(read('parts.json')),
    faults: FaultsFile.fromJson(read('faults.json')),
  );
}

/// Sorulara sırayla verilecek cevaplar; sorulanları da saklar.
class _ScriptedDecider implements Decider {
  _ScriptedDecider(this.script);

  final List<DecisionAnswers> script;
  final asked = <Map<String, DecisionQuestion>>[];

  @override
  Future<DecisionAnswers> ask(
    String state,
    Map<String, DecisionQuestion> questions,
  ) async {
    asked.add(questions);
    return script[asked.length - 1];
  }
}

const _diagnose = DecisionAnswers(
  choices: {
    'intent': {
      'diagnose': 0.9,
      'repair': 0.05,
      'partInfo': 0.03,
      'general': 0.02,
    },
  },
  yes: {'sufficient': 0.85},
  model: 'jev-test',
);

void main() {
  final catalog = _bicycle();

  group('katalog', () {
    test('sistemler ağacın kökü', () {
      expect(catalog.systems.map((s) => s.id), [
        'frame',
        'fork',
        'cockpit',
        'seat',
        'drive',
        'brakes',
        'wheel.front',
        'wheel.rear',
      ]);
    });

    test('altında parça olmayan sistem kendisi aday', () {
      expect(catalog.partsOf('frame').map((p) => p.id), ['frame']);
      expect(
        catalog.partsOf('drive').map((p) => p.id),
        containsAll(['drive.chain', 'drive.rear_derailleur', 'drive.cassette']),
      );
      expect(catalog.systemOf('brakes.front.pads'), 'brakes');
    });

    test('açıklamalarda bilinen belirtiler var', () {
      final chain = catalog.part('drive.chain')!;
      expect(
        catalog.describePart(chain),
        contains('Pedala yüklenince zincir boşa atlıyor'),
      );
    });
  });

  group('akış', () {
    test('net teşhis: zincir, arızası ve tamir prosedürü', () async {
      final decider = _ScriptedDecider([
        _diagnose,
        const DecisionAnswers(
          choices: {
            'system': {
              'drive': 0.7,
              'brakes': 0.15,
              'wheel.rear': 0.1,
              'none': 0.05,
            },
          },
        ),
        const DecisionAnswers(
          choices: {
            'part:drive': {
              'drive.chain': 0.8,
              'drive.rear_derailleur': 0.15,
              'none': 0.05,
            },
            'part:brakes': {'brakes.rear': 0.6, 'none': 0.4},
          },
        ),
        const DecisionAnswers(
          choices: {
            'fault': {'f.chain.worn': 0.7, 'none': 0.3},
          },
          yes: {'danger': 0.2},
        ),
      ]);
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: decider,
      ).run('Pedala yüklenince zincir atlıyor.');

      expect(result.decision, DiagnosisDecision.focus);
      expect(result.top!.partId, 'drive.chain');
      expect(result.top!.probability, closeTo(0.56, 1e-9));
      expect(result.fault!.id, 'f.chain.worn');
      expect(result.procedure, 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A');
      expect(result.danger, 0.2);
      expect(result.model, 'jev-test');

      // drive + brakes = 0.85: iki sistemin parçaları soruldu.
      expect(decider.asked[2].keys, ['part:drive', 'part:brakes']);
      final systemQuestion = decider.asked[1]['system']! as ChoiceQuestion;
      expect(systemQuestion.options.keys, contains('none'));
    });

    test('belirti yetmiyorsa önce soru', () async {
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: _ScriptedDecider([
          const DecisionAnswers(
            choices: {
              'intent': {'diagnose': 0.8, 'general': 0.2},
            },
            yes: {'sufficient': 0.2},
          ),
        ]),
      ).run('Bisiklet garip.');
      expect(result.decision, DiagnosisDecision.needsInfo);
      expect(result.candidates, isEmpty);
    });

    test('teşhis istenmiyorsa durur', () async {
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: _ScriptedDecider([
          const DecisionAnswers(
            choices: {
              'intent': {'repair': 0.9, 'diagnose': 0.1},
            },
            yes: {'sufficient': 0.9},
          ),
        ]),
      ).run('Zincir nasıl sökülür?');
      expect(result.intent, DiagnosisIntent.repair);
      expect(result.decision, DiagnosisDecision.notDiagnosis);
    });

    test('sistem turunda "hiçbiri" öndeyse parça seçilmez', () async {
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: _ScriptedDecider([
          _diagnose,
          const DecisionAnswers(
            choices: {
              'system': {'none': 0.6, 'drive': 0.3, 'brakes': 0.1},
            },
          ),
        ]),
      ).run('Rengi soldu.');
      expect(result.decision, DiagnosisDecision.uncertain);
      expect(result.candidates, isEmpty);
    });

    Future<DiagnosisResult> withParts(Map<String, double> parts) =>
        DiagnosisFlow(
          catalog: catalog,
          decider: _ScriptedDecider([
            _diagnose,
            const DecisionAnswers(
              choices: {
                'system': {'brakes': 0.9, 'none': 0.1},
              },
            ),
            DecisionAnswers(choices: {'part:brakes': parts}),
            const DecisionAnswers(yes: {'danger': 0.7}),
          ]),
        ).run('Fren sesi var.');

    test('ilk iki parça yakınsa ikisi birlikte', () async {
      final result = await withParts({
        'brakes.front.pads': 0.42,
        'brakes.front.rotor': 0.38,
        'none': 0.2,
      });
      expect(result.decision, DiagnosisDecision.ambiguous);
    });

    test('en olası parça eşiğin altındaysa belirsiz', () async {
      final result = await withParts({
        'brakes.front.pads': 0.3,
        'brakes.front.rotor': 0.1,
        'none': 0.6,
      });
      expect(result.decision, DiagnosisDecision.uncertain);
      expect(result.candidates.first.partId, 'brakes.front.pads');
    });

    test('arıza net değilse arıza bulma prosedürü önerilir', () async {
      final result = await withParts({'brakes.front.pads': 0.9, 'none': 0.1});
      expect(result.fault, isNull);
      expect(result.procedure, isNotNull);
      final isolations = catalog
          .faultsOf('brakes.front.pads')
          .map((f) => f.isolation);
      expect(isolations, contains(result.procedure));
    });
  });

  test('sonuç JSON ile gidip gelir', () {
    const result = DiagnosisResult(
      intent: DiagnosisIntent.diagnose,
      decision: DiagnosisDecision.focus,
      sufficiency: 0.8,
      systems: [Scored('drive', 0.7), Scored('none', 0.3)],
      candidates: [
        PartCandidate(
          partId: 'drive.chain',
          systemId: 'drive',
          probability: 0.56,
        ),
      ],
      fault: Scored('f.chain.worn', 0.7),
      procedure: 'DMC-X',
      danger: 0.2,
      model: 'jev',
    );
    final copy = DiagnosisResult.fromJson(
      jsonDecode(jsonEncode(result.toJson())) as Map<String, Object?>,
    );
    expect(copy.toJson(), result.toJson());
  });
}
