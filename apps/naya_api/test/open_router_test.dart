import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naya_api/server.dart';
import 'package:naya_diagnosis/naya_diagnosis.dart';
import 'package:test/test.dart';

void main() {
  group('Jev', () {
    test('istek gövdesi ve cevabın okunması', () async {
      late Map<String, Object?> sent;
      late http.Request request;
      final provider = OpenRouterProvider(
        client: MockClient((r) async {
          request = r;
          sent = jsonDecode(r.body) as Map<String, Object?>;
          return http.Response(
            jsonEncode({
              'model': 'typesafe/jev-1.14-20261014',
              'answers': {
                'system': {
                  'type': 'choice',
                  'choice': 'drive',
                  'confidence': 0.7,
                  'probabilities': {'drive': 0.8, 'none': 0.2},
                },
                'danger': {'type': 'noul', 'noul': 0.12},
                'skipped': {'type': 'refusal'},
              },
              'usage': {'input_tokens': 400, 'output_tokens': 0},
            }),
            200,
          );
        }),
      );
      final answers = await provider.decide(
        apiKey: 'sk-test',
        model: '~typesafe/jev-latest',
        state: 'Ürün: Bisiklet',
        questions: const {
          'system': ChoiceQuestion('Hangi sistem?', {
            'drive': 'Aktarma',
            'none': 'Hiçbiri',
          }),
          'danger': YesNoQuestion('Tehlikeli mi?'),
          'skipped': YesNoQuestion('?'),
        },
      );

      expect(request.url.path, '/api/alpha/decisions');
      expect(request.headers['authorization'], 'Bearer sk-test');
      expect(sent['model'], '~typesafe/jev-latest');
      expect(sent['state'], 'Ürün: Bisiklet');
      final questions = sent['questions']! as Map<String, Object?>;
      expect(questions['system'], {
        'type': 'choice',
        'instructions': 'Hangi sistem?',
        'criteria': {'drive': 'Aktarma', 'none': 'Hiçbiri'},
      });
      expect(questions['danger'], {
        'type': 'noul',
        'instructions': 'Tehlikeli mi?',
      });

      expect(answers.choices['system'], {'drive': 0.8, 'none': 0.2});
      expect(answers.yes['danger'], 0.12);
      expect(answers.yes.containsKey('skipped'), isFalse);
      expect(answers.model, 'typesafe/jev-1.14-20261014');
    });

    test('hata kodları anlaşılır mesaja çevrilir', () async {
      Future<AiException> errorFor(int status) async {
        final provider = OpenRouterProvider(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'error': {'code': status, 'message': 'x'},
              }),
              status,
            ),
          ),
        );
        try {
          await provider.checkKey('k');
        } on AiException catch (e) {
          return e;
        }
        fail('hata bekleniyordu');
      }

      expect((await errorFor(401)).code, 'invalid_key');
      expect((await errorFor(402)).code, 'no_credit');
      expect((await errorFor(429)).code, 'rate_limited');
      expect((await errorFor(503)).code, 'unavailable');
    });
  });

  group('sohbet', () {
    OpenRouterProvider streaming(String body) => OpenRouterProvider(
      client: MockClient.streaming(
        (request, _) async => http.StreamedResponse(
          Stream.value(utf8.encode(body)),
          200,
          headers: {'content-type': 'text/event-stream'},
        ),
      ),
    );

    String chunk(String text) =>
        'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': text},
            },
          ],
        })}\n\n';

    test('SSE parçaları sırayla gelir, yorum satırları atlanır', () async {
      final provider = streaming(
        ': OPENROUTER PROCESSING\n\n'
        '${chunk('Zincir ')}${chunk('aşınmış.')}'
        'data: ${jsonEncode({
          'choices': [
            {'delta': <String, Object?>{}, 'finish_reason': 'stop'},
          ],
          'usage': {'prompt_tokens': 10},
        })}\n\n'
        'data: [DONE]\n\n',
      );
      final parts = await provider
          .chat(apiKey: 'k', model: 'm', messages: const [])
          .toList();
      expect(parts, ['Zincir ', 'aşınmış.']);
    });

    test('akış ortasındaki hata yakalanır', () async {
      final provider = streaming(
        '${chunk('Başla')}'
        'data: ${jsonEncode({
          'error': {'code': 502, 'message': 'Sağlayıcı düştü'},
          'choices': [
            {
              'delta': {'content': ''},
              'finish_reason': 'error',
            },
          ],
        })}\n\n',
      );
      await expectLater(
        provider.chat(apiKey: 'k', model: 'm', messages: const []).toList(),
        throwsA(isA<AiException>()),
      );
    });

    test('akış ortasında kopan bağlantı AiException olur', () async {
      Stream<List<int>> cut() async* {
        yield utf8.encode(chunk('Başla'));
        throw http.ClientException('koptu');
      }

      final provider = OpenRouterProvider(
        client: MockClient.streaming(
          (request, _) async => http.StreamedResponse(cut(), 200),
        ),
      );
      await expectLater(
        provider.chat(apiKey: 'k', model: 'm', messages: const []).toList(),
        throwsA(isA<AiException>()),
      );
    });
  });

  test('olasılıklar 0-1 arasına sıkıştırılır, sayı olmayan atlanır', () async {
    final provider = OpenRouterProvider(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'answers': {
              'system': {
                'type': 'choice',
                'probabilities': {'drive': 1.4, 'brakes': -0.2, 'x': 'a'},
              },
              'danger': {'type': 'noul', 'noul': 2},
            },
          }),
          200,
        ),
      ),
    );
    final answers = await provider.decide(
      apiKey: 'k',
      model: 'm',
      state: 's',
      questions: const {},
    );
    expect(answers.choices['system'], {'drive': 1.0, 'brakes': 0.0});
    expect(answers.yes['danger'], 1.0);
  });

  test('JSON olmayan cevap 500 değil anlaşılır hata olur', () async {
    final provider = OpenRouterProvider(
      client: MockClient((_) async => http.Response('<html>', 200)),
    );
    await expectLater(
      provider.listModels(),
      throwsA(isA<AiException>().having((e) => e.status, 'status', 502)),
    );
  });

  test('model listesi: Jev ayrı istenir, fiyat milyon token başına', () async {
    final urls = <String>[];
    final provider = OpenRouterProvider(
      client: MockClient((r) async {
        urls.add(r.url.toString());
        final decisions =
            r.url.queryParameters['output_modalities'] == 'decisions';
        return http.Response(
          jsonEncode({
            'data': [
              if (decisions)
                {
                  'id': 'typesafe/jev-1.14',
                  'name': 'Jev 1.14',
                  'architecture': {
                    'output_modalities': ['decisions'],
                  },
                  'pricing': {'prompt': '0.000000042', 'completion': '0'},
                }
              else
                {
                  'id': 'deepseek/deepseek-v4.1-flash',
                  'name': 'DeepSeek',
                  'context_length': 128000,
                  'architecture': {
                    'output_modalities': ['text'],
                  },
                  'pricing': {'prompt': '0.0000003', 'completion': '0.0000012'},
                },
            ],
          }),
          200,
        );
      }),
    );
    final models = await provider.listModels();
    expect(urls, hasLength(2));
    expect(models.map((m) => (m.id, m.kind)), [
      ('typesafe/jev-1.14', 'decision'),
      ('deepseek/deepseek-v4.1-flash', 'chat'),
    ]);
    expect(models.first.inputPrice, closeTo(0.042, 1e-9));
    expect(models.last.outputPrice, closeTo(1.2, 1e-9));
  });

  group('KeyVault', () {
    final vault = KeyVault(List.filled(32, 7));

    test('şifreler ve aynı kullanıcı için çözer', () async {
      final secret = await vault.encrypt('sk-or-v1-gizli', userId: 3);
      expect(
        utf8.decode(secret, allowMalformed: true),
        isNot(contains('gizli')),
      );
      expect(await vault.decrypt(secret, userId: 3), 'sk-or-v1-gizli');
    });

    test(
      'başka kullanıcının satırı ya da yanlış ana anahtar çözülmez',
      () async {
        final secret = await vault.encrypt('sk-or-v1-gizli', userId: 3);
        expect(await vault.decrypt(secret, userId: 4), isNull);
        expect(
          await KeyVault(List.filled(32, 8)).decrypt(secret, userId: 3),
          isNull,
        );
      },
    );

    test('ana anahtar 32 bayt base64 olmalı', () {
      expect(KeyVault.fromBase64(null), isNull);
      expect(KeyVault.fromBase64('kısa'), isNull);
      expect(KeyVault.fromBase64(base64.encode(List.filled(16, 1))), isNull);
      expect(KeyVault.fromBase64(base64.encode(List.filled(32, 1))), isNotNull);
    });
  });
}
