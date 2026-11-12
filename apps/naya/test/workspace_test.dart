import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naya/app/app.dart';
import 'package:naya/app/router.dart';
import 'package:naya/entities/product/product_content.dart';
import 'package:naya/pages/data_module/data_module_page.dart';
import 'package:naya/shared/api/api_client.dart';
import 'package:naya/shared/ui/theme.dart';
import 'package:naya/widgets/part_sheet/part_sheet.dart';

import 'fake_api.dart';

const _remove = 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A';
const _brakeIsolation = 'DMC-NAYABIKE-AAA-DA2-00-00-00AA-421A-A';

Future<ProductContent> _loadContent() async {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(fakeApi())],
  );
  addTearDown(container.dispose);
  return container.read(productContentProvider('bisiklet').future);
}

void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Uygulamayı adresten açar ve DM'ler gelene kadar bekler.
Future<void> _pumpAt(WidgetTester tester, String location) async {
  final router = buildRouter(initialLocation: location);
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
  // MockClient ve dosya okuma gerçek zamanlı; runAsync içinde beklenir.
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// AnimatedSwitcher'ın geçişi dokunuştan sonraki karede başlar; eski kart
/// geçiş bitince kalkar.
Future<void> settleSwitch(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  NayaFonts.useGoogleFonts = false;

  group('ProductContent', () {
    test('her model düğümü doğru parçanın kartını açar', () async {
      final content = await _loadContent();
      const expected = {
        'frame': 'frame',
        'fork': 'fork',
        'handlebar': 'cockpit',
        'saddle': 'seat.saddle',
        'seatpost': 'seat.post',
        'drive_chain': 'drive.chain',
        'drive_crankset': 'drive.crankset',
        'drive_pedals': 'drive.pedals',
        'drive_cassette': 'drive.cassette',
        'drive_derailleur': 'drive.rear_derailleur',
        'drive_front_derailleur': 'drive.front_derailleur',
        'brakes_front': 'brakes.front',
        'brakes_rear': 'brakes.rear',
        'wheel_front_tire': 'wheel.front.tire',
        'wheel_front_rim': 'wheel.front.rim',
        'wheel_front_spokes': 'wheel.front.spokes',
        'wheel_front_hub': 'wheel.front.hub',
        'wheel_rear_tire': 'wheel.rear.tire',
        'wheel_rear_rim': 'wheel.rear.rim',
        'wheel_rear_spokes': 'wheel.rear.spokes',
        'wheel_rear_hub': 'wheel.rear.hub',
      };
      for (final MapEntry(key: node, value: part) in expected.entries) {
        expect(content.partForNode(node)?.id, part, reason: node);
      }
      expect(content.partForNode('yok'), isNull);
    });

    test(
      'ön frenin arızalarına balata ve disk de girer, ciddisi önce',
      () async {
        final content = await _loadContent();
        final faults = content.faultsFor('brakes.front');
        final parts = faults.map((f) => f.part).toSet();
        expect(parts, containsAll(['brakes.front.pads', 'brakes.front.rotor']));
        final severities = faults.map((f) => f.severity).toList();
        expect(severities, [...severities]..sort((a, b) => b.compareTo(a)));
      },
    );

    test('DM ve çizim yolları koddan bulunur', () async {
      final content = await _loadContent();
      expect(content.dmPath(_remove), endsWith('520A-A_001-00_TR-TR.XML'));
      expect(content.dmPath(_remove.substring(4)), isNotNull);
      expect(content.dmPath('DMC-YOK-AAA-D00-00-00-00AA-040A-A'), isNull);
      expect(
        content.icnPath('ICN-NAYABIKE-AAA-D000000-0-NAYA0-00002-A-001-01'),
        endsWith('.JPG'),
      );
    });

    test('parçanın yolu kökten başlar', () async {
      final content = await _loadContent();
      expect(content.pathTo('brakes.front.pads').map((p) => p.id), [
        'brakes',
        'brakes.front',
        'brakes.front.pads',
      ]);
    });
  });

  group('parça kartı', () {
    Future<List<String>> pumpSheet(
      WidgetTester tester, {
      required String part,
      String? node,
    }) async {
      _useTallScreen(tester);
      final content = (await tester.runAsync(_loadContent))!;
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Scaffold(
            body: PartSheet(
              content: content,
              part: content.part(part)!,
              node: node,
              onOpenModule: opened.add,
              onSelectPart: opened.add,
            ),
          ),
        ),
      );
      return opened;
    }

    testWidgets('zincirin gerçek arıza ve prosedürleri görünür', (
      tester,
    ) async {
      final opened = await pumpSheet(tester, part: 'drive.chain');
      expect(find.text('Zincir'), findsOneWidget);
      expect(find.text('AKTARMA ORGANLARI'), findsOneWidget);
      expect(
        find.text('Zincir aşınıp uzamış; dişlilere tam oturmuyor.'),
        findsOneWidget,
      );
      expect(find.text('Pedala yüklenince zincir boşa atlıyor'), findsWidgets);
      expect(find.text('Sökme'), findsOneWidget);
      expect(find.text('Parça kataloğu'), findsOneWidget);

      await tester.tap(find.text('Sökme'));
      expect(opened, [_remove]);
    });

    testWidgets('aynı düğümdeki parçalar arasında geçilir', (tester) async {
      final opened = await pumpSheet(
        tester,
        part: 'cockpit',
        node: 'handlebar',
      );
      expect(find.text('Gidon ve kumanda'), findsOneWidget);
      await tester.tap(find.text('Vites kolları'));
      expect(opened, ['cockpit.shifters']);
    });
  });

  group('DM okuyucu', () {
    testWidgets('prosedür: hazırlık, adımlar ve işaretleme', (tester) async {
      _useTallScreen(tester);
      await _pumpAt(tester, AppRoutes.module('bisiklet', _remove));
      expect(find.byType(DataModulePage), findsOneWidget);
      expect(find.text('Zincir'), findsOneWidget);
      expect(find.text('Sökme'), findsOneWidget);
      expect(find.text('Başlamadan önce'), findsOneWidget);
      expect(
        find.text('Zincir kenarları keskin olabilir; eldiven takın.'),
        findsOneWidget,
      );
      expect(find.text('Zincir sökme aparatı'), findsOneWidget);
      expect(find.text('Pimi çıkarın'), findsOneWidget);
      expect(find.text('0 / 3 ADIM'), findsOneWidget);

      await tester.tap(find.text('01'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 / 3 ADIM'), findsOneWidget);

      // Sonraki işlem bağlantısı hedef DM'in başlığıyla yazılır.
      expect(find.text('Zincir · Takma'), findsOneWidget);
    });

    testWidgets('arıza bulma: cevaplara göre sonuca gider', (tester) async {
      _useTallScreen(tester);
      await _pumpAt(tester, AppRoutes.module('bisiklet', _brakeIsolation));
      expect(
        find.text("Balata sürtünme malzemesi 0,5 mm'den ince mi?"),
        findsOneWidget,
      );

      await tester.tap(find.text('Hayır'));
      await settleSwitch(tester);
      expect(find.text('Disk ya da balata yağlanmış mı?'), findsOneWidget);

      await tester.tap(find.text('Evet'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        find.textContaining('Diski izopropil alkolle temizleyin.'),
        findsOneWidget,
      );
      expect(find.text('Fren balatası · Değiştirme'), findsOneWidget);

      await tester.tap(find.text('Baştan başla'));
      await settleSwitch(tester);
      expect(
        find.text("Balata sürtünme malzemesi 0,5 mm'den ince mi?"),
        findsOneWidget,
      );
    });

    testWidgets('parça kataloğu satırları', (tester) async {
      _useTallScreen(tester);
      await _pumpAt(
        tester,
        AppRoutes.module('bisiklet', 'DMC-NAYABIKE-AAA-D00-00-00-01AA-941A-A'),
      );
      expect(find.text('Kadro, alüminyum'), findsOneWidget);
      expect(find.text('NB-FR-100'), findsOneWidget);
    });

    testWidgets('olmayan DM açıklamayla hata verir', (tester) async {
      _useTallScreen(tester);
      await _pumpAt(
        tester,
        AppRoutes.module('bisiklet', 'DMC-NAYABIKE-AAA-D00-00-00-00AA-999A-A'),
      );
      expect(find.text('DM açılamadı'), findsOneWidget);
    });
  });
}
