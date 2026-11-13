import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya/app/app.dart';
import 'package:naya/app/router.dart';
import 'package:naya/entities/diagnosis/diagnosis.dart';
import 'package:naya/entities/product/product_content.dart';
import 'package:naya/features/diagnose/request_diagnosis.dart';
import 'package:naya/pages/data_module/data_module_page.dart';
import 'package:naya/shared/api/api_client.dart';
import 'package:naya/shared/ui/theme.dart';

import 'fake_api.dart';

const _repair = 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A';

/// Sunucunun zincir için döndürdüğü teşhis.
Map<String, Object?> _chainRecord({
  String decision = 'focus',
  double chain = 0.68,
  double cassette = 0.13,
  double danger = 0.1,
}) => {
  'id': 7,
  'item': 'bisiklet',
  'message': 'Zincir atlıyor.',
  'result': {
    'intent': 'diagnose',
    'decision': decision,
    'systems': [
      {'id': 'drive', 'probability': 0.85},
      {'id': 'brakes', 'probability': 0.1},
      {'id': 'none', 'probability': 0.05},
    ],
    'candidates': [
      {'part': 'drive.chain', 'system': 'drive', 'probability': chain},
      {'part': 'drive.cassette', 'system': 'drive', 'probability': cassette},
      {'part': 'drive.rear_derailleur', 'system': 'drive', 'probability': 0.04},
    ],
    'fault': {'id': 'f.chain.worn', 'probability': 0.75},
    'procedure': _repair,
    'danger': danger,
    'model': 'jev-test',
  },
  'explanation': 'Zincir aşınmış, değiştirin. [$_repair]',
  'sources': [_repair],
  'createdAt': '2026-11-13T10:00:00Z',
};

Future<ProductContent> _content(ApiClient api) async {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  return container.read(productContentProvider('bisiklet').future);
}

void main() {
  NayaFonts.useGoogleFonts = false;

  group('teşhis isteği', () {
    test('cevap parça adlarıyla okunur, istek ürünü ve mesajı taşır', () async {
      late Map<String, Object?> sent;
      final api = fakeApi(
        diagnose: (body) {
          sent = body;
          return jsonResponse(_chainRecord(), status: 201);
        },
      );
      final content = await _content(api);
      final diagnosis = await requestDiagnosis(
        api,
        content,
        message: 'Zincir atlıyor.',
        earlier: ['Pedal çevirince tıkırtı var.'],
      );
      expect(sent, {
        'item': 'bisiklet',
        'message': 'Zincir atlıyor.',
        'earlier': ['Pedal çevirince tıkırtı var.'],
      });
      expect(diagnosis.top.name, 'Zincir');
      expect(diagnosis.top.system, 'Aktarma organları');
      expect(diagnosis.isConfident, isTrue);
      expect(diagnosis.faultCause, contains('aşınıp'));
      expect(diagnosis.systemsScanned, 2);
    });

    test('girişsiz istek açıklamalı hata verir', () async {
      final api = fakeApi();
      final content = await _content(api);
      expect(
        requestDiagnosis(api, content, message: 'x'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });
  });

  group('parlama ağırlıkları', () {
    Future<Map<String, double>> weightsFor(
      String decision,
      double chain,
    ) async {
      final api = fakeApi(
        diagnose: (_) => jsonResponse(
          _chainRecord(decision: decision, chain: chain),
          status: 201,
        ),
      );
      final content = await _content(api);
      final diagnosis = await requestDiagnosis(api, content, message: 'x');
      return scanWeights(diagnosis, content);
    }

    test('net sonuçta en olası tam, diğerleri orantılı', () async {
      final weights = await weightsFor('focus', 0.68);
      expect(weights['drive_chain'], 1);
      expect(weights['drive_cassette'], closeTo(0.13 / 0.68, 1e-9));
    });

    test('yakın iki aday ikisi de tam parlar', () async {
      final weights = await weightsFor('ambiguous', 0.2);
      expect(weights['drive_chain'], 1);
      expect(weights['drive_cassette'], 1);
      expect(weights.containsKey('drive_derailleur'), isFalse);
    });

    test('belirsiz sonuçta ilk üç aday soluk', () async {
      final weights = await weightsFor('uncertain', 0.3);
      expect(weights['drive_chain'], closeTo(0.35, 1e-9));
      expect(weights.values.every((w) => w <= 0.35), isTrue);
      expect(weights, hasLength(3));
    });
  });

  group('çalışma alanında', () {
    Future<void> pump(WidgetTester tester, ApiClient api) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = buildRouter(initialLocation: '/urun/bisiklet');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            apiClientProvider.overrideWithValue(api),
          ],
          child: const NayaApp(),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<void> ask(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('yazılan belirti teşhis edilir, sonuç ve kaynak görünür', (
      tester,
    ) async {
      final asked = <Map<String, Object?>>[];
      await pump(
        tester,
        fakeApi(
          diagnose: (body) {
            asked.add(body);
            return jsonResponse(_chainRecord(), status: 201);
          },
        ),
      );
      await ask(tester, 'Zincir atlıyor.');

      expect(asked.single['message'], 'Zincir atlıyor.');
      expect(find.text('Zincir aşınmış, değiştirin.'), findsOneWidget);
      expect(find.text('%68'), findsOneWidget);
      expect(find.text('TEŞHİS'), findsOneWidget);

      // Önerilen DM koda basmadan sohbette açılmış görünür.
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('SÖKME'), findsOneWidget);
      expect(find.text('Adım adım aç'), findsOneWidget);
      expect(find.text('Parça kartı'), findsOneWidget);
      expect(find.textContaining('ADIM'), findsWidgets);
      expect(find.text(_repair), findsOneWidget);

      await tester.tap(find.text('Adım adım aç'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(DataModulePage), findsOneWidget);
    });

    testWidgets('soru sorulduysa cevap önceki mesajla gider', (tester) async {
      final asked = <Map<String, Object?>>[];
      await pump(
        tester,
        fakeApi(
          diagnose: (body) {
            asked.add(body);
            return jsonResponse(
              _chainRecord(decision: asked.length == 1 ? 'needsInfo' : 'focus'),
              status: 201,
            );
          },
        ),
      );
      await ask(tester, 'Bisiklet garip.');
      expect(find.text('BİRAZ DAHA ANLAT'), findsOneWidget);
      await ask(tester, 'Pedal çevirince zincir atlıyor.');
      expect(asked.last['earlier'], ['Bisiklet garip.']);
    });

    testWidgets('tehlike yüksekse uyarı bandı', (tester) async {
      await pump(
        tester,
        fakeApi(
          diagnose: (_) => jsonResponse(_chainRecord(danger: 0.8), status: 201),
        ),
      );
      await ask(tester, 'Fren tutmuyor.');
      expect(find.textContaining('Onarmadan kullanmayın'), findsOneWidget);
    });

    testWidgets('giriş yoksa ne yapılacağı söylenir', (tester) async {
      await pump(tester, fakeApi());
      await ask(tester, 'Zincir atlıyor.');
      expect(
        find.text('Teşhis için giriş yapmanız gerekiyor.'),
        findsOneWidget,
      );
    });
  });

  test('örnek teşhis karar kuralına uyar', () {
    expect(sampleDiagnosis.isConfident, isTrue);
    expect(sampleDiagnosis.isDangerous, isFalse);
  });
}
