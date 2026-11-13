import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya/app/app.dart';
import 'package:naya/app/router.dart';
import 'package:naya/pages/data_module/data_module_page.dart';
import 'package:naya/pages/part/part_page.dart';
import 'package:naya/shared/api/api_client.dart';
import 'package:naya/shared/ui/theme.dart';
import 'package:naya/widgets/viewer_panel/model_loader.dart';

import 'fake_api.dart';

void main() {
  NayaFonts.useGoogleFonts = false;

  group('parça sayfası', () {
    Future<void> pump(WidgetTester tester, String part) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = buildRouter(
        initialLocation: AppRoutes.part('bisiklet', part),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            apiClientProvider.overrideWithValue(fakeApi()),
          ],
          child: const NayaApp(),
        ),
      );
      // İçerik, sonra arızaların ve anlatımın DM'leri iner.
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('zincirin her şeyi tek sayfada', (tester) async {
      await pump(tester, 'drive.chain');
      expect(find.byType(PartPage), findsOneWidget);
      expect(find.text('Zincir'), findsWidgets);

      // Bölümler: anlatım, şemalar, arızalar, bakım, katalog.
      for (final label in ['ANLATIM', 'ŞEMALAR', 'ARIZALAR', 'BAKIM']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // Anlatım, aktarma organlarının tanıtım DM'inden.
      expect(find.text('Vitesler'), findsOneWidget);

      // İlk arıza açık gelir; onarımın adımları sayfada görünür.
      expect(find.text('Adım adım aç'), findsOneWidget);
      expect(find.textContaining('Zinciri en küçük aynaya'), findsOneWidget);
    });

    testWidgets('arıza açılıp kapanır, prosedür okuyucuda açılır', (
      tester,
    ) async {
      await pump(tester, 'drive.chain');
      final cards = find.byIcon(Icons.expand_more);
      expect(cards, findsWidgets);

      // İlkini kapat: onarım kartı kalkar.
      await tester.tap(cards.first);
      await tester.pumpAndSettle();
      expect(find.text('Adım adım aç'), findsNothing);

      await tester.tap(cards.first);
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.text('Adım adım aç'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(DataModulePage), findsOneWidget);
    });

    testWidgets('olmayan parça açıklamayla', (tester) async {
      await pump(tester, 'yok.boyle');
      expect(find.text('Böyle bir parça yok'), findsOneWidget);
    });
  });

  group('yükleme ekranı', () {
    Future<List<String>> pump(
      WidgetTester tester, {
      required bool ready,
      bool failed = false,
    }) async {
      final finished = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: ModelLoader(
              title: 'Dağ bisikleti',
              progress: 0.5,
              ready: ready,
              failed: failed,
              onFinished: () => finished.add('bitti'),
            ),
          ),
        ),
      );
      return finished;
    }

    testWidgets('ilerlemeyi gösterir, hazır olunca kapanır', (tester) async {
      final finished = await pump(tester, ready: false);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('GEOMETRİ İNİYOR'), findsOneWidget);
      expect(finished, isEmpty);

      await pump(tester, ready: true);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(find.text('MONTAJ'), findsOneWidget);
    });

    testWidgets('hazır olunca onFinished çağrılır', (tester) async {
      final finished = await pump(tester, ready: true);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 800));
      expect(finished, ['bitti']);
    });

    testWidgets('yüklenemezse sebebi yazar, sayaç gizlenir', (tester) async {
      await pump(tester, ready: false, failed: true);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('MODEL YÜKLENEMEDİ'), findsOneWidget);
      expect(find.text('%'), findsNothing);
    });
  });
}
