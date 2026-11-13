import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:naya_diagnosis/naya_diagnosis.dart';

import 'ai_provider.dart';

/// OpenRouter üzerinden sohbet ve karar modelleri.
///
/// - Sohbet: `POST /api/v1/chat/completions`, `stream: true` ile SSE.
/// - Jev: `POST /api/alpha/decisions`. Gövdede `model`, `state` ve
///   `questions` en üst seviyede; cevap `answers` içinde soru soru gelir.
///   Uç "alpha" olduğu için biçimi değişebilir; okuma tek yerde.
/// - Anahtar kontrolü: `GET /api/v1/key`.
/// - Model listesi: `GET /api/v1/models`. Jev varsayılan listede yok,
///   `output_modalities=decisions` ile ayrıca isteniyor.
class OpenRouterProvider implements AiProvider {
  OpenRouterProvider({
    http.Client? client,
    this.baseUrl = 'https://openrouter.ai',
  }) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  static const _decisionTimeout = Duration(seconds: 30);
  static const _chatTimeout = Duration(seconds: 90);

  /// Bir cevabın en uzun süresi; parça parça gelen yavaş bir akış
  /// bağlantıyı sonsuza dek açık tutmasın.
  static const _chatDeadline = Duration(minutes: 3);

  /// Bir cevabın en fazla token'ı; geçmişte tekrar gönderildiği için
  /// bağlam şişmesin.
  static const maxAnswerTokens = 1500;

  @override
  Future<void> checkKey(String apiKey) async {
    final response = await _send(
      () => _http
          .get(Uri.parse('$baseUrl/api/v1/key'), headers: _headers(apiKey))
          .timeout(_decisionTimeout),
    );
    if (response.statusCode != 200) throw _errorOf(response);
  }

  @override
  Future<List<AiModel>> listModels() async {
    final chat = await _models('$baseUrl/api/v1/models');
    final decision = await _models(
      '$baseUrl/api/v1/models?output_modalities=decisions',
    );
    final seen = <String>{};
    return [
      for (final m in [...decision, ...chat])
        if (seen.add(m.id)) m,
    ];
  }

  Future<List<AiModel>> _models(String url) async {
    final response = await _send(
      () => _http.get(Uri.parse(url)).timeout(_decisionTimeout),
    );
    if (response.statusCode != 200) throw _errorOf(response);
    final body = _decode(response);
    final data = body is Map ? body['data'] : null;
    if (data is! List) return const [];
    final models = <AiModel>[];
    for (final item in data) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! String) continue;
      final architecture = item['architecture'];
      final outputs = architecture is Map
          ? architecture['output_modalities']
          : null;
      final String kind;
      if (outputs is List && outputs.contains('decisions')) {
        kind = 'decision';
      } else if (outputs is List && outputs.contains('text')) {
        kind = 'chat';
      } else {
        continue;
      }
      final pricing = item['pricing'];
      final name = item['name'];
      final context = item['context_length'];
      models.add(
        AiModel(
          id: id,
          name: name is String ? name : id,
          kind: kind,
          contextLength: context is num ? context.toInt() : null,
          inputPrice: _perMillion(pricing is Map ? pricing['prompt'] : null),
          outputPrice: _perMillion(
            pricing is Map ? pricing['completion'] : null,
          ),
        ),
      );
    }
    return models;
  }

  @override
  Future<DecisionAnswers> decide({
    required String apiKey,
    required String model,
    required String state,
    required Map<String, DecisionQuestion> questions,
  }) async {
    final response = await _send(
      () => _http
          .post(
            Uri.parse('$baseUrl/api/alpha/decisions'),
            headers: {..._headers(apiKey), 'content-type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'state': state,
              'questions': {
                for (final e in questions.entries) e.key: _question(e.value),
              },
            }),
          )
          .timeout(_decisionTimeout),
    );
    if (response.statusCode != 200) throw _errorOf(response);
    final body = _decode(response);
    if (body is! Map) throw _unexpected;
    final answers = body['answers'];
    if (answers is! Map) throw _unexpected;

    final choices = <String, Map<String, double>>{};
    final yes = <String, double>{};
    answers.forEach((key, answer) {
      if (key is! String || answer is! Map) return;
      // Sağlayıcının cevaplamadığı soru `{"type": "refusal"}` döner;
      // yokmuş gibi davranılır, akış eksik cevabı "belirsiz" sayar.
      switch (answer['type']) {
        case 'choice':
          final probabilities = answer['probabilities'];
          if (probabilities is Map) {
            choices[key] = {
              for (final p in probabilities.entries)
                if (p.key is String && _probability(p.value) != null)
                  p.key as String: _probability(p.value)!,
            };
          }
        case 'noul':
          final value = _probability(answer['noul']);
          if (value != null) yes[key] = value;
      }
    });
    final answeredBy = body['model'];
    return DecisionAnswers(
      choices: choices,
      yes: yes,
      model: answeredBy is String ? answeredBy : model,
    );
  }

  /// Olasılık 0-1 arasında bir sayı olmalı; değilse yok sayılır.
  static double? _probability(Object? value) {
    if (value is! num || !value.isFinite) return null;
    return value.toDouble().clamp(0.0, 1.0);
  }

  static Map<String, Object?> _question(DecisionQuestion question) =>
      switch (question) {
        ChoiceQuestion(:final instructions, :final options) => {
          'type': 'choice',
          'instructions': instructions,
          'criteria': options,
        },
        YesNoQuestion(:final instructions) => {
          'type': 'noul',
          'instructions': instructions,
        },
      };

  @override
  Stream<String> chat({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async* {
    final request =
        http.Request('POST', Uri.parse('$baseUrl/api/v1/chat/completions'))
          ..headers.addAll({
            ..._headers(apiKey),
            'content-type': 'application/json',
          })
          ..body = jsonEncode({
            'model': model,
            'stream': true,
            'max_tokens': maxAnswerTokens,
            'messages': [for (final m in messages) m.toJson()],
          });
    final http.StreamedResponse response;
    try {
      response = await _http.send(request).timeout(_chatTimeout);
    } on TimeoutException {
      throw _timeout;
    } on http.ClientException {
      throw _offline;
    }
    if (response.statusCode != 200) {
      throw _errorOf(await http.Response.fromStream(response));
    }

    // SSE: her olay "data: {...}" satırı; ":" ile başlayan satırlar
    // bağlantıyı açık tutan yorumlar.
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(_chatTimeout);
    final started = DateTime.now();
    try {
      await for (final line in lines) {
        if (DateTime.now().difference(started) > _chatDeadline) {
          throw _timeout;
        }
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data == '[DONE]') break;
        final Object? chunk;
        try {
          chunk = jsonDecode(data);
        } on FormatException {
          continue;
        }
        if (chunk is! Map) continue;
        // Akış başladıktan sonraki hata da 200 ile ama `error` alanıyla gelir.
        final error = chunk['error'];
        if (error is Map) {
          throw AiException(
            'unavailable',
            'Sohbet modeli cevap verirken hata oluştu: '
                '${error['message'] ?? 'bilinmeyen hata'}',
          );
        }
        final choices = chunk['choices'];
        if (choices is! List || choices.isEmpty) continue;
        final first = choices.first;
        final delta = first is Map ? first['delta'] : null;
        final content = delta is Map ? delta['content'] : null;
        if (content is String && content.isNotEmpty) yield content;
      }
    } on TimeoutException {
      throw _timeout;
    } on http.ClientException {
      // Akış ortasında bağlantı koptu.
      throw _offline;
    }
  }

  void close() => _http.close();

  Map<String, String> _headers(String apiKey) => {
    'authorization': 'Bearer $apiKey',
    'x-openrouter-title': 'NAYA',
  };

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      throw _timeout;
    } on http.ClientException {
      throw _offline;
    }
  }

  /// OpenRouter hataları `{"error": {"code", "message"}}`; durum koduna
  /// göre kullanıcıya anlaşılır bir mesaj seçilir.
  static AiException _errorOf(http.Response response) {
    var detail = '';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body is Map ? body['error'] : null;
      if (error is Map && error['message'] is String) {
        detail = error['message'] as String;
      }
    } on FormatException {
      // Aşağıdaki genel mesaj yeterli.
    }
    return switch (response.statusCode) {
      401 || 403 => const AiException(
        'invalid_key',
        'OpenRouter anahtarı geçersiz.',
        status: 400,
      ),
      402 => const AiException(
        'no_credit',
        'OpenRouter hesabında kredi kalmamış.',
        status: 402,
      ),
      429 => const AiException(
        'rate_limited',
        'OpenRouter çok fazla istek dedi; biraz sonra tekrar deneyin.',
        status: 429,
      ),
      400 || 413 || 422 => AiException(
        'bad_request',
        'Yapay zekâ isteği reddedildi${detail.isEmpty ? '' : ': $detail'}',
        status: 400,
      ),
      _ => AiException(
        'unavailable',
        'Yapay zekâ servisi şu an cevap vermiyor '
            '(${response.statusCode}).',
      ),
    };
  }

  /// Gövde JSON değilse sağlayıcıdan beklenmedik cevap gelmiştir.
  static Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw _unexpected;
    }
  }

  static double? _perMillion(Object? perToken) {
    final value = perToken is String ? double.tryParse(perToken) : null;
    return value == null ? null : value * 1000000;
  }

  static const _unexpected = AiException(
    'unavailable',
    'Yapay zekâ servisinden beklenmedik cevap geldi.',
  );
  static const _timeout = AiException(
    'unavailable',
    'Yapay zekâ servisi zamanında cevap vermedi.',
    status: 504,
  );
  static const _offline = AiException(
    'unavailable',
    'Yapay zekâ servisine ulaşılamadı.',
  );
}
