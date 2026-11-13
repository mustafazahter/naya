import 'package:naya_diagnosis/naya_diagnosis.dart';

/// Yapay zekâ servisinden dönen, kullanıcıya gösterilebilir hata.
class AiException implements Exception {
  const AiException(this.code, this.message, {this.status = 502});

  /// `invalid_key`, `no_credit`, `rate_limited`, `unavailable`...
  final String code;
  final String message;

  /// İstemciye dönecek HTTP durumu.
  final int status;

  @override
  String toString() => '$code: $message';
}

/// Ayarlarda listelenen bir model.
class AiModel {
  const AiModel({
    required this.id,
    required this.name,
    required this.kind,
    this.contextLength,
    this.inputPrice,
    this.outputPrice,
  });

  final String id;
  final String name;

  /// `chat` (metin üreten) ya da `decision` (Jev gibi olasılık dönen).
  final String kind;
  final int? contextLength;

  /// Milyon token başına dolar.
  final double? inputPrice;
  final double? outputPrice;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'contextLength': ?contextLength,
    'inputPrice': ?inputPrice,
    'outputPrice': ?outputPrice,
  };
}

/// Sohbet modeline giden mesaj.
class ChatMessage {
  const ChatMessage(this.role, this.content);

  /// `system`, `user` ya da `assistant`.
  final String role;
  final String content;

  Map<String, Object?> toJson() => {'role': role, 'content': content};
}

/// Yapay zekâ sağlayıcısı. Şimdilik yalnız OpenRouter var; kod bu arayüzü
/// kullandığı için başka bir sağlayıcı eklemek tek sınıf yazmak demek.
abstract interface class AiProvider {
  /// Anahtar geçerli mi? Geçersizse [AiException] (`invalid_key`).
  Future<void> checkKey(String apiKey);

  /// Kullanılabilecek sohbet ve karar modelleri.
  Future<List<AiModel>> listModels();

  /// Karar modeline (Jev) sorular.
  Future<DecisionAnswers> decide({
    required String apiKey,
    required String model,
    required String state,
    required Map<String, DecisionQuestion> questions,
  });

  /// Sohbet modelinin cevabı, parça parça.
  Stream<String> chat({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  });
}

/// [AiProvider] üzerinden Jev'e soran [Decider]; teşhis akışı bunu kullanır.
class ProviderDecider implements Decider {
  ProviderDecider(this.provider, {required this.apiKey, required this.model});

  final AiProvider provider;
  final String apiKey;
  final String model;

  @override
  Future<DecisionAnswers> ask(
    String state,
    Map<String, DecisionQuestion> questions,
  ) => provider.decide(
    apiKey: apiKey,
    model: model,
    state: state,
    questions: questions,
  );
}
