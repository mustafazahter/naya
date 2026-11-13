import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:naya_api/server.dart';
import 'package:naya_diagnosis/naya_diagnosis.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'ai_support.dart';
import 'support.dart';

void main() {
  late TestServer server;
  late FakeAi ai;
  late String token;

  Future<TestServer> start({bool masterKey = true}) async {
    ai = FakeAi();
    final s = await TestServer.start(
      ai: ai,
      env: {if (masterKey) 'NAYA_MASTER_KEY': testMasterKey},
    );
    token = await s.register('enes@ornek.com');
    return s;
  }

  tearDown(() => server.close());

  Future<String> bicycleId() async {
    await server.addTemplate(bicycleNaya, name: 'bisiklet');
    final list = await readJson(await server.send('GET', '/api/library/'));
    final templates = list['templates']! as List<Object?>;
    return (templates.single! as Map<String, Object?>)['id']! as String;
  }

  Future<Response> putKey(String key) =>
      server.send('PUT', '/api/ai/key', json: {'key': key}, token: token);

  group('anahtar', () {
    setUp(() async => server = await start());

    test('doğrulanır, şifreli saklanır, yalnız son 4 hane döner', () async {
      final response = await putKey(FakeAi.goodKey);
      expect(response.statusCode, 200);
      final body = await readJson(response);
      expect(body, containsPair('hasKey', true));
      expect(body, containsPair('hint', '…1234'));
      expect(jsonEncode(body), isNot(contains(FakeAi.goodKey)));
      expect(ai.checkedKeys, [FakeAi.goodKey]);

      final row = await server.api.aiSettings.keyRow(1);
      expect(
        utf8.decode(row!.secret, allowMalformed: true),
        isNot(contains('dogru-anahtar')),
      );
      expect(await server.api.aiSettings.apiKeyOf(1), FakeAi.goodKey);
    });

    test('geçersiz anahtar kaydedilmez', () async {
      final response = await putKey('sk-or-v1-yanlis-anahtar');
      expect(response.statusCode, 400);
      expect(
        (await readJson(response))['error'],
        containsPair('code', 'invalid_key'),
      );
      final status = await readJson(
        await server.send('GET', '/api/ai/key', token: token),
      );
      expect(status, containsPair('hasKey', false));
    });

    test('silinince yapay zekâ anahtar ister', () async {
      await putKey(FakeAi.goodKey);
      await server.send('DELETE', '/api/ai/key', token: token);
      final response = await server.send(
        'POST',
        '/api/ai/diagnose',
        json: {'item': await bicycleId(), 'message': 'Zincir atlıyor.'},
        token: token,
      );
      expect(response.statusCode, 409);
      expect(
        (await readJson(response))['error'],
        containsPair('code', 'no_key'),
      );
    });

    test('misafir yapay zekâ uçlarını kullanamaz', () async {
      final response = await server.send('GET', '/api/ai/key');
      expect(response.statusCode, 401);
    });
  });

  test('NAYA_MASTER_KEY yoksa anahtar saklanmaz', () async {
    server = await start(masterKey: false);
    final response = await putKey(FakeAi.goodKey);
    expect(response.statusCode, 503);
    expect(ai.checkedKeys, isEmpty);
  });

  group('roller ve modeller', () {
    setUp(() async => server = await start());

    test('varsayılanlar ve seçim', () async {
      var roles = await readJson(
        await server.send('GET', '/api/ai/roles', token: token),
      );
      expect(roles['roles'], containsPair('decision', '~typesafe/jev-latest'));
      final response = await server.send(
        'PUT',
        '/api/ai/roles',
        json: {'chat': 'deepseek/deepseek-v4-flash'},
        token: token,
      );
      roles = await readJson(response);
      expect(
        roles['roles'],
        containsPair('chat', 'deepseek/deepseek-v4-flash'),
      );

      final bad = await server.send(
        'PUT',
        '/api/ai/roles',
        json: {'decision': 'baska/model', 'vision': 'x'},
        token: token,
      );
      expect(bad.statusCode, 400);
      // Yanlış giriş varsa doğru olanı da kaydedilmez.
      roles = await readJson(
        await server.send('GET', '/api/ai/roles', token: token),
      );
      expect(roles['roles'], containsPair('decision', '~typesafe/jev-latest'));
    });

    test('model listesi 24 saat önbellekte', () async {
      for (var i = 0; i < 2; i++) {
        final body = await readJson(
          await server.send('GET', '/api/ai/models', token: token),
        );
        expect(body['models'], hasLength(2));
      }
      expect(ai.modelCalls, 1);
      server.clock.advance(const Duration(hours: 25));
      await server.send('GET', '/api/ai/models', token: token);
      expect(ai.modelCalls, 2);
    });
  });

  group('teşhis', () {
    late String item;

    setUp(() async {
      server = await start();
      await putKey(FakeAi.goodKey);
      item = await bicycleId();
    });

    Future<Map<String, Object?>> diagnose(String message) async {
      final response = await server.send(
        'POST',
        '/api/ai/diagnose',
        json: {'item': item, 'message': message},
        token: token,
      );
      final text = await response.readAsString();
      expect(response.statusCode, 201, reason: text);
      return jsonDecode(text) as Map<String, Object?>;
    }

    test('olasılıklar, arıza, prosedür ve kaynak', () async {
      final record = await diagnose('Pedala yüklenince zincir atlıyor.');
      final result = record['result']! as Map<String, Object?>;
      expect(result['decision'], 'focus');
      final top = (result['candidates']! as List).first as Map;
      expect(top['part'], 'drive.chain');
      expect(top['probability'], closeTo(0.68, 1e-9));
      expect(result['fault'], containsPair('id', 'f.chain.worn'));
      expect(result['procedure'], 'DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A');
      expect(result['model'], 'jev-1.14-test');
      expect(record['sources'], contains(result['procedure']));
      expect(record['explanation'], startsWith('Zincir aşınmış.'));

      // Açıklamaya giden bağlamda prosedürün metni var.
      final context = ai.chats.single.map((m) => m.content).join('\n');
      expect(context, contains('DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A'));
      expect(context, contains('%68'));
    });

    test('kaydedilir ve geçmişten açılır', () async {
      final record = await diagnose('Zincir atlıyor.');
      final list = await readJson(
        await server.send('GET', '/api/ai/diagnoses?item=$item', token: token),
      );
      expect(list['diagnoses'], hasLength(1));
      final one = await readJson(
        await server.send(
          'GET',
          '/api/ai/diagnoses/${record['id']}',
          token: token,
        ),
      );
      expect(one['result'], record['result']);

      final other = await server.register('mustafa@ornek.com');
      final hidden = await server.send(
        'GET',
        '/api/ai/diagnoses/${record['id']}',
        token: other,
      );
      expect(hidden.statusCode, 404);
    });

    test('belirti yetmezse parça seçilmez, soru sorulur', () async {
      ai.vague = true;
      final record = await diagnose('Bisiklet garip.');
      final result = record['result']! as Map<String, Object?>;
      expect(result['decision'], 'needsInfo');
      expect(result['candidates'], isEmpty);
      expect(ai.decisions, hasLength(1));
      final prompt = ai.chats.single.last.content;
      expect(prompt, contains('tek bir soru'));
    });

    test('Jev\'e giden sistem sorusunda "hiçbiri" var', () async {
      await diagnose('Zincir atlıyor.');
      final system = ai.decisions[1]['system']! as ChoiceQuestion;
      expect(system.options.keys, containsAll(['drive', 'brakes', 'none']));
      expect(system.options['drive'], contains('Zincir'));
    });
  });

  group('sohbet', () {
    late String item;

    setUp(() async {
      server = await start();
      await putKey(FakeAi.goodKey);
      item = await bicycleId();
    });

    test('cevap SSE ile akar, kaydedilir ve devam edilir', () async {
      final response = await server.send(
        'POST',
        '/api/ai/chat',
        json: {'item': item, 'message': 'Zincir nasıl sökülür?'},
        token: token,
      );
      expect(response.headers['content-type'], startsWith('text/event-stream'));
      final text = await response.readAsString();
      final events = [
        for (final block in text.trim().split('\n\n'))
          (
            block.split('\n').first.substring('event: '.length),
            jsonDecode(block.split('\n')[1].substring('data: '.length)),
          ),
      ];
      expect(events.first.$1, 'delta');
      expect(events.last.$1, 'done');
      final done = events.last.$2 as Map<String, Object?>;
      expect(done['sources'], ['DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A']);

      // Arama dizininden ilgili DM metni bağlama girdi.
      final context = ai.chats.single.map((m) => m.content).join('\n');
      expect(context, contains('[DMC-NAYABIKE-'));

      final conversation = await readJson(
        await server.send(
          'GET',
          '/api/ai/conversations/${done['conversation']}',
          token: token,
        ),
      );
      final messages = conversation['messages']! as List<Object?>;
      expect(messages.map((m) => (m! as Map)['role']), ['user', 'assistant']);

      await server
          .send(
            'POST',
            '/api/ai/chat',
            json: {
              'item': item,
              'message': 'Peki takarken?',
              'conversation': done['conversation'],
            },
            token: token,
          )
          .then((r) => r.readAsString());
      final second = ai.chats.last.map((m) => m.content).toList();
      expect(second, contains('Zincir nasıl sökülür?'));
    });

    test('parça sohbetinde parçanın bilgisi bağlamda', () async {
      final response = await server.send(
        'POST',
        '/api/ai/chat',
        json: {
          'item': item,
          'message': 'Bu ne işe yarar?',
          'part': 'drive.chain',
        },
        token: token,
      );
      await response.readAsString();
      final context = ai.chats.single.map((m) => m.content).join('\n');
      expect(context, contains('Konuşulan parça: Zincir.'));
    });

    test('başkasının sohbeti akış başlamadan 404', () async {
      final first = await server.send(
        'POST',
        '/api/ai/chat',
        json: {'item': item, 'message': 'Zincir nasıl sökülür?'},
        token: token,
      );
      final text = await first.readAsString();
      final done = jsonDecode(
        text.trim().split('\n').last.substring('data: '.length),
      ) as Map<String, Object?>;

      final other = await server.register('mustafa@ornek.com');
      final read = await server.send(
        'GET',
        '/api/ai/conversations/${done['conversation']}',
        token: other,
      );
      expect(read.statusCode, 404);

      // Şablon herkese açık ve anahtar da var; 404'ün sebebi sohbetin sahibi.
      await server.send(
        'PUT',
        '/api/ai/key',
        json: {'key': FakeAi.goodKey},
        token: other,
      );
      final response = await server.send(
        'POST',
        '/api/ai/chat',
        json: {
          'item': item,
          'message': 'Devam',
          'conversation': done['conversation'],
        },
        token: other,
      );
      expect(response.statusCode, 404);
    });

    test(
      'model yarıda hata verirse error olayı gelir, soru kaydedilmez',
      () async {
        ai.chatFailure = const AiException('unavailable', 'Sağlayıcı düştü');
        final response = await server.send(
          'POST',
          '/api/ai/chat',
          json: {'item': item, 'message': 'Zincir nasıl sökülür?'},
          token: token,
        );
        expect(response.statusCode, 200);
        final text = await response.readAsString();
        expect(text, contains('event: error'));
        expect(text, isNot(contains('event: done')));

        final list = await readJson(
          await server.send('GET', '/api/ai/conversations', token: token),
        );
        final conversations = list['conversations']! as List<Object?>;
        for (final c in conversations) {
          final one = await readJson(
            await server.send(
              'GET',
              '/api/ai/conversations/${(c! as Map)['id']}',
              token: token,
            ),
          );
          expect(one['messages'], isEmpty);
        }
      },
    );

    test('anahtar yoksa akış başlamadan JSON hatası', () async {
      await server.send('DELETE', '/api/ai/key', token: token);
      final response = await server.send(
        'POST',
        '/api/ai/chat',
        json: {'item': item, 'message': 'Merhaba'},
        token: token,
      );
      expect(response.statusCode, 409);
    });
  });

  group('arama dizini', () {
    setUp(() async => server = await start());

    test('şablon eklenince DM\'ler dizine girer, silinince çıkar', () async {
      final id = await bicycleId();
      final hits = await server.api.search.search(id, 'zincir sökme');
      expect(hits, isNotEmpty);
      expect(hits.first.dmc, startsWith('DMC-NAYABIKE-'));

      await server.api.library.delete(
        (await server.api.library.find(id, null))!,
      );
      final rows = await server.api.db
          .customSelect(
            'SELECT count(*) AS n FROM dm_chunks WHERE library_item_id = ?',
            variables: [Variable.withString(id)],
          )
          .getSingle();
      expect(rows.read<int>('n'), 0);
    });

    test('FTS5 işaretleri sorguyu bozmaz', () {
      expect(
        DmSearch.ftsQuery('zincir* AND "fren" ve'),
        '"zincir" OR "and" OR "fren"',
      );
      expect(DmSearch.ftsQuery('?!'), isNull);
    });
  });
}
