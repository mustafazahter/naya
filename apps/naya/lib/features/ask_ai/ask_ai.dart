import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_client.dart';
import '../../shared/api/sse.dart';

/// Sohbet akışında istemcinin gördüğü olaylar.
sealed class AnswerEvent {
  const AnswerEvent();
}

/// Cevabın yeni gelen parçası; ekrandaki metnin sonuna eklenir.
class AnswerDelta extends AnswerEvent {
  const AnswerDelta(this.text);
  final String text;
}

/// Cevap bitti ve kaydedildi. Sonraki mesaj aynı [conversation]'a gider.
class AnswerDone extends AnswerEvent {
  const AnswerDone({required this.conversation, required this.sources});
  final int conversation;

  /// Cevabın dayandığı DM'ler.
  final List<String> sources;
}

/// Sohbet modeline soru sorar; cevap kelime kelime akar
/// (`POST /api/ai/chat`, SSE).
///
/// [part] verilirse parçanın kartı ve DM'leri sabit bağlam olur.
/// [conversation] verilirse önceki mesajlar da bağlama girer. Akış
/// başlamadan ya da ortasında gelen hata [ApiException] olarak fırlar.
Stream<AnswerEvent> askAi(
  ApiClient api, {
  required String item,
  required String message,
  int? conversation,
  String? part,
}) async* {
  final bytes = await api.postStream('/api/ai/chat', {
    'item': item,
    'message': message,
    'conversation': ?conversation,
    'part': ?part,
  });
  await for (final event in parseSse(bytes)) {
    final json = event.json;
    switch (event.name) {
      case 'delta':
        final text = json['text'];
        if (text is String && text.isNotEmpty) yield AnswerDelta(text);
      case 'done':
        yield AnswerDone(
          conversation: json['conversation']! as int,
          sources: _strings(json['sources']),
        );
        return;
      case 'error':
        throw ApiException(
          200,
          json['code'] as String? ?? 'error',
          json['message'] as String? ?? 'Cevap üretilirken bir sorun oluştu.',
        );
    }
  }
  // `done` gelmeden bağlantı koptu.
  throw const ApiException(0, 'offline', 'Bağlantı koptu, cevap yarım kaldı.');
}

/// Kayıtlı bir sohbet: başlığı ve hangi parça hakkında olduğu.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.part,
  });

  factory ConversationSummary.fromJson(Map<String, Object?> json) =>
      ConversationSummary(
        id: json['id']! as int,
        title: json['title'] as String? ?? '',
        part: json['part'] as String?,
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );

  final int id;
  final String title;
  final String? part;
  final DateTime updatedAt;
}

/// Sohbetteki tek mesaj.
class ConversationMessage {
  const ConversationMessage({
    required this.fromUser,
    required this.text,
    this.sources = const [],
  });

  final bool fromUser;
  final String text;
  final List<String> sources;
}

/// Ürünün sohbetleri, en yeni önce.
final conversationsProvider = FutureProvider.autoDispose
    .family<List<ConversationSummary>, String>((ref, item) async {
      final json = await ref
          .watch(apiClientProvider)
          .getJson(
            '/api/ai/conversations?item=${Uri.encodeQueryComponent(item)}',
          );
      final list = [
        for (final c in json['conversations'] as List<Object?>? ?? const [])
          if (c is Map<String, Object?>) ConversationSummary.fromJson(c),
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    }, retry: (_, _) => null);

/// Kayıtlı sohbeti mesajlarıyla açar.
Future<(ConversationSummary, List<ConversationMessage>)> loadConversation(
  ApiClient api,
  int id,
) async {
  final json = await api.getJson('/api/ai/conversations/$id');
  return (
    ConversationSummary.fromJson(json),
    [
      for (final m in json['messages'] as List<Object?>? ?? const [])
        if (m is Map<String, Object?>)
          ConversationMessage(
            fromUser: m['role'] == 'user',
            text: m['content'] as String? ?? '',
            sources: _strings(m['sources']),
          ),
    ],
  );
}

List<String> _strings(Object? value) => [
  if (value is List)
    for (final s in value)
      if (s is String) s,
];
