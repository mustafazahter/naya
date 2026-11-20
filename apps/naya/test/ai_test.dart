import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:naya/app/app.dart';
import 'package:naya/app/router.dart';
import 'package:naya/features/ask_ai/ask_ai.dart';
import 'package:naya/shared/api/api_client.dart';
import 'package:naya/shared/api/sse.dart';
import 'package:naya/shared/api/token_store.dart';
import 'package:naya/shared/ui/theme.dart';

import 'fake_api.dart';

const _repair = 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A';

/// Sunucunun zincir için döndürdüğü net teşhis.
Map<String, Object?> _chainRecord({int id = 7}) => {
  'id': id,
  'item': 'bisiklet',
  'message': 'Zincir atlıyor.',
  'result': {
    'intent': 'diagnose',
    'decision': 'focus',
    'systems': [
      {'id': 'drive', 'probability': 0.9},
      {'id': 'none', 'probability': 0.1},
    ],
    'candidates': [
      {'part': 'drive.chain', 'system': 'drive', 'probability': 0.7},
      {'part': 'drive.cassette', 'system': 'drive', 'probability': 0.1},
    ],
    'fault': {'id': 'f.chain.worn', 'probability': 0.75},
    'procedure': _repair,
    'danger': 0.1,
    'model': 'jev-test',
  },
  'explanation': 'Zincir aşınmış, değiştirin.',
  'sources': [_repair],
  'createdAt': '2026-11-20T10:00:00Z',
};

const _user = {'id': 1, 'email': 'enes@ornek.com', 'role': 'admin'};

http.Response _signedIn(http.Request _) => jsonResponse({'user': _user});

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  ApiClient api, {
  String at = '/',
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = buildRouter(initialLocation: at);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        apiClientProvider.overrideWithValue(api),
        tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      ],
      child: const NayaApp(),
    ),
  );
  await _settle(tester);
}

void main() {
  NayaFonts.useGoogleFonts = false;

  group('SSE', () {
    test('parçalara bölünmüş akıştan olaylar çıkar', () async {
      const text =
          ': canlı tut\n'
          'event: delta\ndata: {"text":"Mer"}\n\n'
          'event: delta\ndata: {"text":"haba"}\n\n'
          'data: satır bir\ndata: satır iki\n\n'
          'event: done\ndata: {"conversation":3}';
      final bytes = utf8.encode(text);
      // Paketler satırın ortasından bölünse de olaylar bozulmaz.
      final chunks = [
        for (var i = 0; i < bytes.length; i += 7)
          bytes.sublist(i, i + 7 > bytes.length ? bytes.length : i + 7),
      ];
      final events = await parseSse(Stream.fromIterable(chunks)).toList();
      expect(
        [for (final e in events) e.name],
        ['delta', 'delta', 'message', 'done'],
      );
      expect(events[1].json['text'], 'haba');
      expect(events[2].data, 'satır bir\nsatır iki');
      expect(events.last.json['conversation'], 3);
    });

    test('cevap akar, sonda sohbet kimliği ve kaynaklar gelir', () async {
      Map<String, Object?>? sent;
      final api = fakeApi(
        routes: {
          'POST /api/ai/chat': (request) {
            sent = jsonDecode(request.body) as Map<String, Object?>;
            return sseResponse(
              ['Zinciri ', 'yağlayın.'],
              conversation: 4,
              sources: [_repair],
            );
          },
        },
      );
      final events = await askAi(
        api,
        item: 'bisiklet',
        message: 'Nasıl bakım yapılır?',
        part: 'drive.chain',
      ).toList();
      expect(sent, {
        'item': 'bisiklet',
        'message': 'Nasıl bakım yapılır?',
        'part': 'drive.chain',
      });
      expect(
        [for (final e in events.whereType<AnswerDelta>()) e.text].join(),
        'Zinciri yağlayın.',
      );
      final done = events.last as AnswerDone;
      expect(done.conversation, 4);
      expect(done.sources, [_repair]);
    });

    test('akış içindeki hata ApiException olur', () async {
      final api = fakeApi(
        routes: {
          'POST /api/ai/chat': (_) => http.Response(
            'event: error\ndata: {"code":"upstream","message":"Model cevap vermedi."}\n\n',
            200,
          ),
        },
      );
      expect(
        askAi(api, item: 'bisiklet', message: 'Merhaba').toList(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Model cevap vermedi.',
          ),
        ),
      );
    });

    test('anahtar yoksa akış başlamadan hata', () async {
      final api = fakeApi(
        routes: {
          'POST /api/ai/chat': (_) => errorResponse(
            409,
            'no_key',
            'Yapay zekâ için önce ayarlardan OpenRouter anahtarınızı girin.',
          ),
        },
      );
      expect(
        askAi(api, item: 'bisiklet', message: 'Merhaba').toList(),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'no_key')),
      );
    });
  });

  group('çalışma alanında sohbet', () {
    Future<void> send(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();
      await _settle(tester, 4);
    }

    testWidgets('net teşhisten sonra sorular parça sohbetine gider', (
      tester,
    ) async {
      final chats = <Map<String, Object?>>[];
      await _pumpApp(
        tester,
        fakeApi(
          diagnose: (_) => jsonResponse(_chainRecord(), status: 201),
          routes: {
            'POST /api/ai/chat': (request) {
              chats.add(jsonDecode(request.body) as Map<String, Object?>);
              return sseResponse(
                ['Zinciri ', 'ölçün.'],
                conversation: 9,
                sources: [_repair],
              );
            },
          },
        ),
        at: '/urun/bisiklet',
      );
      await send(tester, 'Zincir atlıyor.');
      expect(find.text('ZİNCİR HAKKINDA'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
        'Zincir hakkında sor…',
      );

      await send(tester, 'Ne kadar uzamışsa değişmeli?');
      expect(chats.single, {
        'item': 'bisiklet',
        'message': 'Ne kadar uzamışsa değişmeli?',
        'part': 'drive.chain',
      });
      expect(find.text('Zinciri ölçün.'), findsOneWidget);
      expect(find.text('CEVAP'), findsOneWidget);

      // Sıradaki soru aynı sohbete devam eder.
      await send(tester, 'Hangi alet?');
      expect(chats.last['conversation'], 9);

      // Yeni konu: sohbet temizlenir, sıradaki mesaj yine teşhise gider.
      await tester.tap(find.byTooltip('Yeni konu'));
      await tester.pump();
      expect(find.text('Ne sorun var?'), findsOneWidget);
    });

    testWidgets('anahtar yoksa ayarlara yönlendirilir', (tester) async {
      await _pumpApp(
        tester,
        fakeApi(
          routes: {
            'GET /api/auth/me': _signedIn,
            'POST /api/ai/diagnose': (_) => errorResponse(
              409,
              'no_key',
              'Yapay zekâ için önce ayarlardan OpenRouter anahtarınızı girin.',
            ),
          },
        ),
        at: '/urun/bisiklet',
      );
      await send(tester, 'Zincir atlıyor.');
      expect(
        find.textContaining('OpenRouter anahtarınızı girin'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Ayarlara git'),
        findsOneWidget,
      );
    });
  });

  group('geçmiş', () {
    testWidgets('eski teşhis açılınca çalışma alanında yeniden görünür', (
      tester,
    ) async {
      final opened = <String>[];
      await _pumpApp(
        tester,
        fakeApi(
          routes: {
            'GET /api/ai/diagnoses': (_) => jsonResponse({
              'diagnoses': [_chainRecord()],
            }),
            'GET /api/ai/conversations': (_) => jsonResponse({
              'conversations': [
                {
                  'id': 3,
                  'item': 'bisiklet',
                  'part': 'drive.chain',
                  'title': 'Zincir ne zaman değişir?',
                  'createdAt': '2026-11-19T09:00:00Z',
                  'updatedAt': '2026-11-19T09:05:00Z',
                },
              ],
            }),
            'GET /api/ai/diagnoses/7': (request) {
              opened.add(request.url.path);
              return jsonResponse(_chainRecord());
            },
          },
        ),
        at: '/urun/bisiklet/gecmis',
      );
      expect(find.text('Zincir atlıyor.'), findsOneWidget);
      expect(find.text('Zincir · %70'), findsOneWidget);
      expect(find.text('Zincir ne zaman değişir?'), findsOneWidget);

      await tester.tap(find.text('Zincir atlıyor.'));
      await _settle(tester);
      expect(opened, ['/api/ai/diagnoses/7']);
      // Teşhis sohbette; sıradaki soru parça sohbetine gider.
      expect(find.text('Zincir atlıyor.'), findsOneWidget);
      expect(find.text('ZİNCİR HAKKINDA'), findsOneWidget);
    });

    testWidgets('giriş yoksa geçmiş yerine giriş istenir', (tester) async {
      await _pumpApp(tester, fakeApi(), at: '/urun/bisiklet/gecmis');
      expect(find.text('Giriş gerekiyor'), findsOneWidget);
    });

    testWidgets('kayıtlı sohbet mesajlarıyla açılır', (tester) async {
      await _pumpApp(
        tester,
        fakeApi(
          routes: {
            'GET /api/ai/conversations/3': (_) => jsonResponse({
              'id': 3,
              'item': 'bisiklet',
              'part': 'drive.chain',
              'title': 'Zincir',
              'createdAt': '2026-11-19T09:00:00Z',
              'updatedAt': '2026-11-19T09:05:00Z',
              'messages': [
                {
                  'role': 'user',
                  'content': 'Ne zaman değişir?',
                  'sources': <String>[],
                },
                {
                  'role': 'assistant',
                  'content': 'Uzama %0,5 olunca.',
                  'sources': [_repair],
                },
              ],
            }),
          },
        ),
        at: '/urun/bisiklet?sohbet=3',
      );
      expect(find.text('Ne zaman değişir?'), findsOneWidget);
      expect(find.text('Uzama %0,5 olunca.'), findsOneWidget);
      expect(find.text('ZİNCİR HAKKINDA'), findsOneWidget);
    });
  });

  group('ayarlar', () {
    testWidgets('misafire giriş önerilir', (tester) async {
      await _pumpApp(tester, fakeApi(), at: '/ayarlar');
      expect(find.textContaining('Misafir olarak geziyorsun'), findsOneWidget);
      expect(find.text('OpenRouter anahtarı'), findsNothing);
    });

    testWidgets('anahtar kaydedilir, modeller görevlerine göre görünür', (
      tester,
    ) async {
      Map<String, Object?>? savedKey;
      var hasKey = false;
      await _pumpApp(
        tester,
        fakeApi(
          routes: {
            'GET /api/auth/me': _signedIn,
            'GET /api/ai/key': (_) => jsonResponse({
              'configured': true,
              'hasKey': hasKey,
              if (hasKey) 'hint': '…a1b2',
            }),
            'PUT /api/ai/key': (request) {
              savedKey = jsonDecode(request.body) as Map<String, Object?>;
              hasKey = true;
              return jsonResponse({
                'configured': true,
                'hasKey': true,
                'hint': '…a1b2',
              });
            },
            'GET /api/ai/roles': (_) => jsonResponse({
              'roles': {
                'chat': 'deepseek/deepseek-v4.1-flash',
                'decision': '~typesafe/jev-latest',
              },
            }),
            'GET /api/ai/models': (_) => jsonResponse({
              'models': [
                {
                  'id': 'deepseek/deepseek-v4.1-flash',
                  'name': 'DeepSeek V4.1 Flash',
                  'kind': 'chat',
                },
                {
                  'id': '~typesafe/jev-latest',
                  'name': 'Jev',
                  'kind': 'decision',
                },
              ],
            }),
          },
        ),
        at: '/ayarlar',
      );
      expect(find.text('enes@ornek.com'), findsOneWidget);
      expect(find.text('Henüz anahtar yok.'), findsOneWidget);
      expect(find.text('DeepSeek V4.1 Flash'), findsOneWidget);
      expect(find.text('Jev'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'sk-or-v1-…'),
        ' sk-or-v1-test ',
      );
      await tester.tap(find.text('Kaydet'));
      await _settle(tester);
      expect(savedKey, {'key': 'sk-or-v1-test'});
      expect(find.textContaining('Kayıtlı anahtar …a1b2'), findsOneWidget);
    });
  });

  group('giriş', () {
    testWidgets('giriş yapınca geri dönülür, avatar harfi görünür', (
      tester,
    ) async {
      Map<String, Object?>? sent;
      final completer = Completer<void>();
      await _pumpApp(
        tester,
        fakeApi(
          routes: {
            'POST /api/auth/login': (request) {
              sent = jsonDecode(request.body) as Map<String, Object?>;
              if (!completer.isCompleted) completer.complete();
              return jsonResponse({'user': _user, 'token': 'tkn'});
            },
          },
        ),
      );
      await tester.tap(find.byTooltip('Giriş yap'));
      await _settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'ad@ornek.com'),
        'enes@ornek.com',
      );
      await tester.enterText(find.byType(TextField).last, 'gizli-sifre');
      await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
      await _settle(tester);
      expect(sent, {'email': 'enes@ornek.com', 'password': 'gizli-sifre'});
      expect(find.text('E'), findsOneWidget);
      expect(find.text('Hazır şablonlar'), findsOneWidget);
    });

    testWidgets('hatalı şifrede sunucunun mesajı görünür', (tester) async {
      await _pumpApp(
        tester,
        fakeApi(
          routes: {
            'POST /api/auth/login': (_) => errorResponse(
              401,
              'invalid_credentials',
              'E-posta ya da şifre yanlış.',
            ),
          },
        ),
        at: '/giris',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'ad@ornek.com'),
        'enes@ornek.com',
      );
      await tester.enterText(find.byType(TextField).last, 'yanlis');
      await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
      await _settle(tester);
      expect(find.text('E-posta ya da şifre yanlış.'), findsOneWidget);
    });
  });
}
