/// Karar modeline (Jev) sorulan soru. Model metin üretmez; her seçeneğe
/// kalibre bir olasılık verir.
sealed class DecisionQuestion {
  const DecisionQuestion(this.instructions);

  /// Modele ne sorulduğu, tek cümle.
  final String instructions;
}

/// Seçeneklerden biri (en fazla [maxOptions]). Anahtar seçeneğin kimliği,
/// değer modelin okuyacağı açıklama.
class ChoiceQuestion extends DecisionQuestion {
  const ChoiceQuestion(super.instructions, this.options);

  final Map<String, String> options;

  static const maxOptions = 255;
}

/// Evet/hayır. Cevap "evet" olasılığıdır.
class YesNoQuestion extends DecisionQuestion {
  const YesNoQuestion(super.instructions);
}

/// Bir istekteki bütün soruların cevapları.
class DecisionAnswers {
  const DecisionAnswers({
    this.choices = const {},
    this.yes = const {},
    this.model = '',
  });

  /// Seçmeli sorular: soru anahtarı → seçenek → olasılık.
  final Map<String, Map<String, double>> choices;

  /// Evet/hayır soruları: soru anahtarı → "evet" olasılığı.
  final Map<String, double> yes;

  /// Cevabı veren modelin sürümü; teşhis kaydına yazılır.
  final String model;
}

/// Soruları karar modeline soran taraf. Sunucuda OpenRouter üzerinden
/// Jev'e gider; testlerde sabit cevaplar verir.
abstract interface class Decider {
  /// [state] durumu (ürün, kullanıcının anlattığı) anlatır; bir istekte
  /// birden çok soru sorulabilir.
  Future<DecisionAnswers> ask(
    String state,
    Map<String, DecisionQuestion> questions,
  );
}
