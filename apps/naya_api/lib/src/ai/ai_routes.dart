import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/auth_middleware.dart';
import '../auth/auth_service.dart';
import '../database/database.dart';
import '../http/json_response.dart';
import '../library/library_service.dart';
import 'ai_provider.dart';
import 'ai_settings.dart';
import 'assistant.dart';

/// `/api/ai` uçları. Hepsi giriş ister; misafir yapay zekâ kullanamaz.
///
/// - `GET/PUT/DELETE /key`        OpenRouter anahtarı (yalnız son 4 hane döner)
/// - `GET /models`                sohbet ve karar modelleri (24 saat önbellek)
/// - `GET/PUT /roles`             `chat` ve `decision` için seçilen modeller
/// - `POST /diagnose`             teşhis: olasılıklar, açıklama, kaynaklar
/// - `GET /diagnoses[?item=]`     teşhis geçmişi; `GET /diagnoses/<id>`
/// - `POST /chat`                 sohbet, cevap SSE ile akar
/// - `GET /conversations[?item=]` sohbetler; `GET /conversations/<id>`
class AiRoutes {
  AiRoutes({
    required this._settings,
    required this._assistant,
    required this._library,
  });

  final AiSettings _settings;
  final Assistant _assistant;
  final LibraryService _library;

  /// Teşhis ve sohbet mesajının üst sınırı.
  static const maxMessageLength = 2000;

  Router get router => Router()
    ..get('/key', _signedIn(_getKey))
    ..put('/key', _signedIn(_putKey))
    ..delete('/key', _signedIn(_deleteKey))
    ..get('/models', _signedIn(_models))
    ..get('/roles', _signedIn(_getRoles))
    ..put('/roles', _signedIn(_putRoles))
    ..post('/diagnose', _signedIn(_diagnose))
    ..get('/diagnoses', _signedIn(_diagnoses))
    ..get('/diagnoses/<id>', _signedInWith(_diagnosis))
    ..post('/chat', _signedIn(_chat))
    ..get('/conversations', _signedIn(_conversations))
    ..get('/conversations/<id>', _signedInWith(_conversation));

  Future<Response> _getKey(Request request, AuthUser user) async {
    final row = await _settings.keyRow(user.id);
    return jsonOk({
      'configured': _settings.canStoreKeys,
      'hasKey': row != null,
      if (row != null) 'hint': '…${row.hint}',
      if (row != null) 'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    });
  }

  Future<Response> _putKey(Request request, AuthUser user) async {
    final body = await readJsonObject(request);
    final key = body?['key'];
    if (key is! String) {
      return jsonError(400, 'bad_request', 'Gövdede "key" olmalı.');
    }
    await _settings.saveKey(user.id, key);
    return _getKey(request, user);
  }

  Future<Response> _deleteKey(Request request, AuthUser user) async {
    await _settings.deleteKey(user.id);
    return Response(204);
  }

  Future<Response> _models(Request request, AuthUser user) async {
    final models = await _settings.models();
    return jsonOk({
      'models': [for (final m in models) m.toJson()],
    });
  }

  Future<Response> _getRoles(Request request, AuthUser user) async =>
      jsonOk({'roles': await _settings.roles(user.id)});

  Future<Response> _putRoles(Request request, AuthUser user) async {
    final body = await readJsonObject(request);
    if (body == null) {
      return jsonError(400, 'bad_request', 'Gövde bir JSON nesnesi olmalı.');
    }
    // Önce hepsi denetlenir; biri yanlışsa hiçbiri kaydedilmez.
    for (final entry in body.entries) {
      if (!AiRole.defaults.containsKey(entry.key)) {
        return jsonError(400, 'bad_request', 'Bilinmeyen rol: ${entry.key}');
      }
      if (entry.value is! String) {
        return jsonError(400, 'bad_request', '"${entry.key}" metin olmalı.');
      }
    }
    for (final entry in body.entries) {
      await _settings.setRole(user.id, entry.key, entry.value! as String);
    }
    return _getRoles(request, user);
  }

  Future<Response> _diagnose(Request request, AuthUser user) async {
    final body = await readJsonObject(request);
    final item = await _item(body?['item'], user);
    final message = _message(body?['message']);
    final earlier = body?['earlier'];
    final record = await _assistant.diagnose(
      user,
      item,
      message,
      earlierMessages: [
        if (earlier is List)
          for (final m in earlier.take(5))
            if (m is String) _message(m),
      ],
    );
    return jsonOk(record.toJson(), status: 201);
  }

  Future<Response> _diagnoses(Request request, AuthUser user) async {
    final records = await _assistant.diagnoses(
      user,
      itemId: request.url.queryParameters['item'],
    );
    return jsonOk({
      'diagnoses': [for (final r in records) r.toJson()],
    });
  }

  Future<Response> _diagnosis(Request request, AuthUser user, String id) async {
    final number = int.tryParse(id);
    final record = number == null
        ? null
        : await _assistant.diagnosis(user, number);
    if (record == null) return notFound('Böyle bir teşhis yok.');
    return jsonOk(record.toJson());
  }

  /// Cevap Server-Sent Events olarak akar:
  /// `event: delta` (`{"text"}`), sonunda `event: done`
  /// (`{"conversation", "message", "sources"}`), sorun olursa `event: error`
  /// (`{"code", "message"}`).
  Future<Response> _chat(Request request, AuthUser user) async {
    final body = await readJsonObject(request);
    final item = await _item(body?['item'], user);
    final message = _message(body?['message']);
    final conversation = body?['conversation'];
    final part = body?['part'];
    // Anahtar yoksa ya da sohbet başkasınınsa akış başlamadan JSON hatası
    // dönsün; akış başladıktan sonra durum kodu hep 200'dür.
    await _settings.apiKeyOf(user.id);
    if (conversation is int) {
      final found = await _assistant.conversation(user, conversation);
      if (found == null || found.$1.libraryItemId != item.id) {
        return notFound('Böyle bir sohbet yok.');
      }
    }

    final events = _assistant.chat(
      user,
      item,
      message,
      conversationId: conversation is int ? conversation : null,
      partId: part is String ? part : null,
    );
    return Response.ok(
      _sse(events),
      headers: {
        'content-type': 'text/event-stream; charset=utf-8',
        'cache-control': 'no-cache',
        'x-accel-buffering': 'no',
      },
      context: {'shelf.io.buffer_output': false},
    );
  }

  static Stream<List<int>> _sse(Stream<ChatEvent> events) async* {
    List<int> event(String name, Object data) =>
        utf8.encode('event: $name\ndata: ${jsonEncode(data)}\n\n');
    try {
      await for (final e in events) {
        switch (e) {
          case ChatDelta(:final text):
            yield event('delta', {'text': text});
          case ChatDone(
            :final conversationId,
            :final messageId,
            :final sources,
          ):
            yield event('done', {
              'conversation': conversationId,
              'message': messageId,
              'sources': sources,
            });
        }
      }
    } on AiException catch (e) {
      yield event('error', {'code': e.code, 'message': e.message});
    } on Object catch (e) {
      // Beklenmedik hata da akışı sessizce kesmesin; ayrıntı günlükte.
      stderr.writeln('Sohbet akışı hatası: $e');
      yield event('error', {
        'code': 'internal',
        'message': 'Cevap üretilirken bir sorun oluştu.',
      });
    }
  }

  Future<Response> _conversations(Request request, AuthUser user) async {
    final rows = await _assistant.conversations(
      user,
      itemId: request.url.queryParameters['item'],
    );
    return jsonOk({
      'conversations': [for (final c in rows) _conversationJson(c)],
    });
  }

  Future<Response> _conversation(
    Request request,
    AuthUser user,
    String id,
  ) async {
    final number = int.tryParse(id);
    final found = number == null
        ? null
        : await _assistant.conversation(user, number);
    if (found == null) return notFound('Böyle bir sohbet yok.');
    final (conversation, messages) = found;
    return jsonOk({
      ..._conversationJson(conversation),
      'messages': [
        for (final m in messages)
          {
            'id': m.id,
            'role': m.role,
            'content': m.content,
            'sources': jsonDecode(m.sourcesJson),
            'createdAt': m.createdAt.toUtc().toIso8601String(),
          },
      ],
    });
  }

  static Map<String, Object?> _conversationJson(ConversationRow c) => {
    'id': c.id,
    'item': c.libraryItemId,
    'part': c.partId,
    'title': c.title,
    'createdAt': c.createdAt.toUtc().toIso8601String(),
    'updatedAt': c.updatedAt.toUtc().toIso8601String(),
  };

  Future<LibraryItemRow> _item(Object? id, AuthUser user) async {
    if (id is! String) {
      throw const AiException(
        'bad_request',
        'Gövdede "item" olmalı.',
        status: 400,
      );
    }
    final item = await _library.find(id, user);
    if (item == null) {
      throw const AiException(
        'not_found',
        'Kütüphanede böyle bir dosya yok.',
        status: 404,
      );
    }
    return item;
  }

  static String _message(Object? value) {
    final text = value is String ? value.trim() : '';
    if (text.isEmpty) {
      throw const AiException('bad_request', 'Mesaj boş olamaz.', status: 400);
    }
    if (text.length > maxMessageLength) {
      throw const AiException(
        'bad_request',
        'Mesaj en fazla $maxMessageLength karakter olabilir.',
        status: 400,
      );
    }
    return text;
  }

  /// Giriş yoksa 401; yapay zekâ hataları JSON hatasına çevrilir.
  static Handler _signedIn(
    Future<Response> Function(Request, AuthUser) handler,
  ) => (request) async {
    final user = userOf(request);
    if (user == null) return unauthorized();
    try {
      return await handler(request, user);
    } on AiException catch (e) {
      return jsonError(e.status, e.code, e.message);
    }
  };

  static Function _signedInWith(
    Future<Response> Function(Request, AuthUser, String) handler,
  ) => (Request request, String id) async {
    final user = userOf(request);
    if (user == null) return unauthorized();
    try {
      return await handler(request, user, id);
    } on AiException catch (e) {
      return jsonError(e.status, e.code, e.message);
    }
  };
}
