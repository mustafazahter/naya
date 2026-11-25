import 'dart:convert';
import 'dart:io';

import 'package:naya_diagnosis/naya_diagnosis.dart';
import 'package:naya_format/naya_format.dart';
import 'package:test/test.dart';

/// Repodaki gerçek bir şablonun parça ve arıza dosyaları.
DiagnosisCatalog _template(String folder, String title) {
  Map<String, Object?> read(String name) => jsonDecode(
    File('../../templates/src/$folder/map/$name').readAsStringSync(),
  ) as Map<String, Object?>;
  return DiagnosisCatalog(
    productTitle: title,
    parts: PartsFile.fromJson(read('parts.json')),
    faults: FaultsFile.fromJson(read('faults.json')),
  );
}

DiagnosisCatalog _bicycle() => _template('bisiklet', 'Dağ bisikleti');

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

    _faultPartsSelectable(catalog, 'bisiklet');

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

    test('belirti yetmiyorsa önce soru, sistem tahmini yine gelir', () async {
      final decider = _ScriptedDecider([
        const DecisionAnswers(
          choices: {
            'intent': {'diagnose': 0.8, 'general': 0.2},
          },
          yes: {'sufficient': 0.2},
        ),
        const DecisionAnswers(
          choices: {
            'system': {'drive': 0.6, 'brakes': 0.3, 'none': 0.1},
          },
        ),
      ]);
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: decider,
      ).run('Bisiklet garip.');
      expect(result.decision, DiagnosisDecision.needsInfo);
      expect(result.candidates, isEmpty);
      // Modelde nereye bakıldığı görünsün diye sistemler döner.
      expect(result.systems.first.id, 'drive');
      expect(decider.asked, hasLength(2));
    });

    test(
      'soru cevaplandıysa yeterlilik düşük olsa da parçaya geçilir',
      () async {
        final decider = _ScriptedDecider([
          const DecisionAnswers(
            choices: {
              'intent': {'diagnose': 0.8, 'general': 0.2},
            },
            yes: {'sufficient': 0.3},
          ),
          const DecisionAnswers(
            choices: {
              'system': {'drive': 0.8, 'none': 0.2},
            },
          ),
          const DecisionAnswers(
            choices: {
              'part:drive': {'drive.chain': 0.9, 'none': 0.1},
            },
          ),
          const DecisionAnswers(choices: {}),
        ]);
        final result = await DiagnosisFlow(
          catalog: catalog,
          decider: decider,
        ).run('Zincir sesi geliyor.', earlierMessages: ['Bisiklet garip.']);
        expect(result.decision, isNot(DiagnosisDecision.needsInfo));
        expect(result.candidates.first.partId, 'drive.chain');
      },
    );

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

    test('başka ürünün parçası anlatılıyorsa parça aranmaz', () async {
      final decider = _ScriptedDecider([
        const DecisionAnswers(
          choices: {
            'intent': {'diagnose': 0.9, 'general': 0.1},
          },
          yes: {'sufficient': 0.7, 'fits': 0.1},
        ),
      ]);
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: decider,
      ).run('Paletin gergisi gevşedi, kule dönmüyor.');
      expect(result.decision, DiagnosisDecision.uncertain);
      expect(result.relevance, 0.1);
      expect(result.systems, isEmpty);
      expect(result.candidates, isEmpty);
      // Sistem turu sorulmaz.
      expect(decider.asked, hasLength(1));
      expect(decider.asked.first.keys, contains('fits'));
      final again = DiagnosisResult.fromJson(result.toJson());
      expect(again.relevance, 0.1);
    });

    test('ürüne uygunluk eşiğin üstündeyse akış sürer', () async {
      final decider = _ScriptedDecider([
        const DecisionAnswers(
          choices: {
            'intent': {'diagnose': 0.9, 'general': 0.1},
          },
          yes: {'sufficient': 0.8, 'fits': 0.6},
        ),
        const DecisionAnswers(
          choices: {
            'system': {'drive': 0.9, 'none': 0.1},
          },
        ),
        const DecisionAnswers(
          choices: {
            'part:drive': {'drive.chain': 0.9, 'none': 0.1},
          },
        ),
        const DecisionAnswers(choices: {}),
      ]);
      final result = await DiagnosisFlow(
        catalog: catalog,
        decider: decider,
      ).run('Zincir sesi geliyor.');
      expect(result.candidates.first.partId, 'drive.chain');
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

  group('Corolla kataloğu', () {
    final corolla = _template('corolla', 'Toyota Corolla 1996');

    test('sistemler', () {
      expect(corolla.systems.map((s) => s.id), [
        'body',
        'interior',
        'engine',
        'cooling',
        'fuel',
        'exhaust',
        'ignition',
        'engine_control',
        'electrical',
        'lighting',
        'hvac',
        'drivetrain',
        'brakes',
        'chassis',
        'wheels',
      ]);
    });

    _faultPartsSelectable(corolla, 'corolla');

    test('fren tutmuyor: balatalar ve değişim prosedürü', () async {
      final result = await DiagnosisFlow(
        catalog: corolla,
        decider: _ScriptedDecider([
          _diagnose,
          const DecisionAnswers(
            choices: {
              'system': {'brakes': 0.8, 'chassis': 0.1, 'none': 0.1},
            },
          ),
          const DecisionAnswers(
            choices: {
              'part:brakes': {
                'brakes.front.pads': 0.7,
                'brakes.booster': 0.2,
                'none': 0.1,
              },
            },
          ),
          const DecisionAnswers(
            choices: {
              'fault': {'f.pads.worn': 0.8, 'none': 0.2},
            },
            yes: {'danger': 0.6},
          ),
        ]),
      ).run('Frene basınca araç geç duruyor, önden ciyaklama geliyor.');

      expect(result.decision, DiagnosisDecision.focus);
      expect(result.top!.partId, 'brakes.front.pads');
      expect(result.fault!.id, 'f.pads.worn');
      expect(result.procedure, 'DMC-NAYACAR-AAA-DA3-10-00-00AA-921A-A');
    });

    test('trafikte hararet: radyatör fanı ve fan değişimi', () async {
      final result = await DiagnosisFlow(
        catalog: corolla,
        decider: _ScriptedDecider([
          _diagnose,
          const DecisionAnswers(
            choices: {
              'system': {'cooling': 0.8, 'engine': 0.1, 'none': 0.1},
            },
          ),
          const DecisionAnswers(
            choices: {
              'part:cooling': {
                'cooling.fan': 0.7,
                'cooling.thermostat': 0.2,
                'none': 0.1,
              },
            },
          ),
          const DecisionAnswers(
            choices: {
              'fault': {'f.fan.inoperative': 0.8, 'none': 0.2},
            },
            yes: {'danger': 0.6},
          ),
        ]),
      ).run('Trafikte hararet yükseliyor, yolda düzeliyor.');

      expect(result.decision, DiagnosisDecision.focus);
      expect(result.top!.partId, 'cooling.fan');
      expect(result.fault!.id, 'f.fan.inoperative');
      expect(result.procedure, 'DMC-NAYACAR-AAA-DA1-40-00-05AA-920A-A');
    });
  });
  group('Leopard 2A6 kataloğu', () {
    final tank = _template('leopard2', 'Leopard 2A6');

    test('sistemler', () {
      expect(tank.systems.map((s) => s.id), [
        'hull',
        'turret',
        'powerpack',
        'fuel',
        'running_gear',
        'electrical',
        'hydraulics',
        'crew_systems',
        'equipment',
      ]);
    });

    _faultPartsSelectable(tank, 'leopard2');

    test('güç paketinin parçaları soğutmayı ve fan tahrikini kapsar', () {
      expect(
        tank.partsOf('powerpack').map((p) => p.id),
        containsAll(['cooling.radiators', 'cooling.fans', 'cooling.fan_drive']),
      );
      expect(tank.systemOf('hull.engine_deck.grilles'), 'hull');
    });

    test('havalandırma zayıf: NBC filtresi değişimi', () async {
      final result =
          await DiagnosisFlow(
            catalog: tank,
            decider: _ScriptedDecider([
              _diagnose,
              const DecisionAnswers(
                choices: {
                  'system': {
                    'crew_systems': 0.8,
                    'electrical': 0.1,
                    'none': 0.1,
                  },
                },
              ),
              const DecisionAnswers(
                choices: {
                  'part:crew_systems': {
                    'crew.nbc_filter': 0.75,
                    'crew.nbc': 0.15,
                    'none': 0.1,
                  },
                },
              ),
              const DecisionAnswers(
                choices: {
                  'fault': {'f.nbc.filter': 0.85, 'none': 0.15},
                },
                yes: {'danger': 0.2},
              ),
            ]),
          ).run(
            'Kapaklar kapalıyken içerisi havasız, filtre göstergesi kırmızıda.',
          );

      expect(result.decision, DiagnosisDecision.focus);
      expect(result.top!.partId, 'crew.nbc_filter');
      expect(result.fault!.id, 'f.nbc.filter');
      expect(result.procedure, 'DMC-NAYATANK-AAA-DA7-10-00-00AA-920A-A');
    });

    test('motor ısınıyor: radyatör temizliği', () async {
      final result = await DiagnosisFlow(
        catalog: tank,
        decider: _ScriptedDecider([
          _diagnose,
          const DecisionAnswers(
            choices: {
              'system': {'powerpack': 0.8, 'hull': 0.1, 'none': 0.1},
            },
          ),
          const DecisionAnswers(
            choices: {
              'part:powerpack': {
                'cooling.radiators': 0.7,
                'cooling.fans': 0.2,
                'none': 0.1,
              },
            },
          ),
          const DecisionAnswers(
            choices: {
              'fault': {'f.radiator.dirty': 0.8, 'none': 0.2},
            },
            yes: {'danger': 0.3},
          ),
        ]),
      ).run('Tozlu arazide motor sıcaklığı sürekli yükseliyor.');

      expect(result.decision, DiagnosisDecision.focus);
      expect(result.top!.partId, 'cooling.radiators');
      expect(result.fault!.id, 'f.radiator.dirty');
      expect(result.procedure, 'DMC-NAYATANK-AAA-DA1-30-00-00AA-250A-A');
    });
  });

  group('F-16F kataloğu', () {
    final jet = _template('f16', 'F-16F Block 60');

    test('sistemler', () {
      expect(jet.systems.map((s) => s.id), [
        'airframe',
        'cockpit',
        'wings',
        'empennage',
        'flight_controls',
        'fuel',
        'hydraulics',
        'landing_gear',
        'tail_hook',
        'engine',
        'ecs',
        'electrical',
        'lights',
        'air_data',
        'oxygen',
        'fire',
        'jfs',
      ]);
    });

    _faultPartsSelectable(jet, 'f16');

    test('frenler zayıf: aşınmış fren değiştirilir', () async {
      final result = await DiagnosisFlow(
        catalog: jet,
        decider: _ScriptedDecider([
          _diagnose,
          const DecisionAnswers(
            choices: {
              'system': {'landing_gear': 0.8, 'hydraulics': 0.1, 'none': 0.1},
            },
          ),
          const DecisionAnswers(
            choices: {
              'part:landing_gear': {
                'gear.brakes': 0.7,
                'gear.wheels': 0.2,
                'none': 0.1,
              },
            },
          ),
          const DecisionAnswers(
            choices: {
              'fault': {'f.brakes.worn': 0.8, 'none': 0.2},
            },
            yes: {'danger': 0.7},
          ),
        ]),
      ).run('Taksi sırasında frenler zayıf tutuyor, aşınma pimi görünmüyor.');

      expect(result.decision, DiagnosisDecision.focus);
      expect(result.top!.partId, 'gear.brakes');
      expect(result.fault!.id, 'f.brakes.worn');
      expect(result.procedure, 'DMC-NAYAJET-AAA-32-40-00-01AA-920A-A');
    });

    test('jeneratör uyarısı: belirsiz arızada arıza bulma DM\'i', () async {
      final result = await DiagnosisFlow(
        catalog: jet,
        decider: _ScriptedDecider([
          _diagnose,
          const DecisionAnswers(
            choices: {
              'system': {'electrical': 0.8, 'engine': 0.1, 'none': 0.1},
            },
          ),
          const DecisionAnswers(
            choices: {
              'part:electrical': {
                'electrical.generator': 0.6,
                'electrical.standby': 0.3,
                'none': 0.1,
              },
            },
          ),
          const DecisionAnswers(
            choices: {
              'fault': {'f.gen.main': 0.2, 'none': 0.8},
            },
            yes: {'danger': 0.4},
          ),
        ]),
      ).run('Motor çalışırken jeneratör uyarı ışığı yanıyor.');

      expect(result.top!.partId, 'electrical.generator');
      expect(result.procedure, 'DMC-NAYAJET-AAA-24-00-00-00AA-421A-A');
    });
  });
}

/// Parça turunda modele yalnız seçilen sistemin parçaları sunulur; her
/// arızanın parçası o listede olmalı, yoksa teşhis onu hiç bulamaz.
void _faultPartsSelectable(DiagnosisCatalog catalog, String folder) {
  test('her arızanın parçası teşhiste seçilebilir', () {
    final file = jsonDecode(
      File('../../templates/src/$folder/map/faults.json').readAsStringSync(),
    ) as Map<String, Object?>;
    for (final fault in FaultsFile.fromJson(file).faults) {
      final system = catalog.systemOf(fault.part);
      expect(
        catalog.partsOf(system).map((p) => p.id),
        contains(fault.part),
        reason: fault.id,
      );
      expect(
        catalog.faultsOf(fault.part).map((f) => f.id),
        contains(fault.id),
        reason: fault.id,
      );
    }
  });
}
