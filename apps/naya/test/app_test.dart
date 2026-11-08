import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:naya/app/app.dart';
import 'package:naya/app/router.dart';
import 'package:naya/entities/product/product.dart';
import 'package:naya/entities/product/product_library.dart';
import 'package:naya/pages/workspace/workspace_page.dart';
import 'package:naya/shared/ui/components.dart';
import 'package:naya/shared/ui/theme.dart';
import 'package:naya/shared/ui/tokens.dart';
import 'package:naya/shared/utils/turkish_text.dart';

/// Uygulamayı verilen adresten başlatır, veriler gelene kadar bekler.
Future<GoRouter> pumpApp(
  WidgetTester tester, {
  String location = '/',
  List<dynamic> overrides = const [],
}) async {
  final router = buildRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        ...overrides.cast(),
      ],
      child: const NayaApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  return router;
}

void main() {
  // Testte ağdan font indirilmesin.
  NayaFonts.useGoogleFonts = false;

  // Sayfanın tamamı ölçülsün, kaydırmaya gerek kalmasın.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('kütüphane', () {
    testWidgets('şablonlar ve dosyalar görünür', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);
      expect(find.text('Neyi inceliyoruz?'), findsOneWidget);
      expect(find.text('Bisiklet'), findsOneWidget);
      expect(find.text('Jeneratör 5 kVA'), findsOneWidget);
    });

    testWidgets('veri gelene kadar iskelet görünür', (tester) async {
      useTallScreen(tester);
      final pending = Completer<ProductLibrary>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(buildRouter()),
            productLibraryProvider.overrideWith((ref) => pending.future),
          ],
          child: const NayaApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonBlock), findsNWidgets(4));
      expect(find.text('Hazır şablonlar'), findsNothing);
    });

    testWidgets('hata mesajı ve yeniden deneme', (tester) async {
      useTallScreen(tester);
      var calls = 0;
      await pumpApp(
        tester,
        overrides: [
          productLibraryProvider.overrideWith((ref) async {
            calls++;
            if (calls == 1) throw Exception('ağ yok');
            return const ProductLibrary(
              templates: sampleTemplates,
              userFiles: [],
            );
          }),
        ],
      );
      expect(find.text('Kütüphane yüklenemedi'), findsOneWidget);
      await tester.tap(find.text('Yeniden dene'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Bisiklet'), findsOneWidget);
    });

    testWidgets('arama süzer, sonuç yoksa boş durum çıkar', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'bisik');
      await tester.pump();
      expect(find.text('Bisiklet'), findsOneWidget);
      expect(find.text('Tank'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);

      await tester.tap(find.byTooltip('Aramayı temizle'));
      await tester.pump();
      expect(find.text('Tank'), findsOneWidget);
    });

    testWidgets('telefon genişliğinde taşma yok', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('router', () {
    testWidgets('karta dokununca çalışma alanı açılır, adres değişir', (
      tester,
    ) async {
      useTallScreen(tester);
      final router = await pumpApp(tester);
      await tester.tap(find.text('Araba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(WorkspacePage), findsOneWidget);
      expect(router.state.uri.path, '/urun/araba');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('adresten doğrudan açılıp geri dönülür', (tester) async {
      useTallScreen(tester);
      final router = await pumpApp(tester, location: '/urun/araba');
      expect(find.byType(WorkspacePage), findsOneWidget);
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Neyi inceliyoruz?'), findsOneWidget);
    });

    testWidgets('bilinmeyen ürün', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, location: '/urun/yok');
      expect(find.text('Burada bir şey yok'), findsOneWidget);
      await tester.tap(find.text('Kütüphaneye dön'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Neyi inceliyoruz?'), findsOneWidget);
    });

    testWidgets('bilinmeyen adres', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester, location: '/olmayan/adres');
      expect(find.text('Burada bir şey yok'), findsOneWidget);
    });
  });

  group('tema', () {
    Future<Color> backgroundFor(WidgetTester tester, Brightness b) async {
      useTallScreen(tester);
      tester.platformDispatcher.platformBrightnessTestValue = b;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);
      return tester
              .widget<Scaffold>(find.byType(Scaffold).first)
              .backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).first))
              .scaffoldBackgroundColor;
    }

    testWidgets('cihaz koyuysa koyu', (tester) async {
      expect(
        await backgroundFor(tester, Brightness.dark),
        NayaColors.dark.background,
      );
    });

    testWidgets('cihaz açıksa açık', (tester) async {
      expect(
        await backgroundFor(tester, Brightness.light),
        NayaColors.light.background,
      );
    });
  });

  group('Türkçe metin', () {
    test('büyük harf', () {
      expect(turkishUpperCase('Senin dosyaların'), 'SENİN DOSYALARIN');
    });

    test('küçük harf', () {
      expect(turkishLowerCase('ISI İZİ'), 'ısı izi');
    });

    test('ürün araması Türkçe harfleri tanır', () {
      const product = Product(
        id: 'x',
        title: 'Isı Pompası',
        subtitle: 'İç ünite',
        category: ProductCategory.car,
        partCount: 0,
        faultCount: 0,
        moduleCount: 0,
      );
      expect(product.matches('ısı'), isTrue);
      expect(product.matches('iç'), isTrue);
      expect(product.matches('  POMPA '), isTrue);
      expect(product.matches('motor'), isFalse);
      expect(product.matches(''), isTrue);
    });
  });
}
