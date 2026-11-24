import 'package:flutter_test/flutter_test.dart';
import 'package:naya/features/ai_settings/ai_settings.dart';

void main() {
  test('model satırı bağlamı ve 1M token fiyatını birimiyle yazar', () {
    final model = AiModel.fromJson({
      'id': 'deepseek/deepseek-v4.1-flash',
      'contextLength': 1048576,
      'inputPrice': 0.0507,
      'outputPrice': 0.2028,
    });
    expect(
      model.details,
      'deepseek/deepseek-v4.1-flash · 1M · 1M token: girdi \$0.051, '
      'çıktı \$0.2',
    );
  });

  test('büyük fiyat en çok iki ondalık, bağlam K ile', () {
    final model = AiModel.fromJson({
      'id': 'openai/gpt-5.5',
      'contextLength': 128000,
      'inputPrice': 5,
      'outputPrice': 30,
    });
    expect(
      model.details,
      'openai/gpt-5.5 · 128K · 1M token: girdi \$5, çıktı \$30',
    );
  });

  test('eksi fiyat (yönlendirici) bilinmiyor sayılır, fiyat yazılmaz', () {
    final model = AiModel.fromJson({
      'id': 'openrouter/auto',
      'contextLength': 2000000,
      'inputPrice': -1000000,
      'outputPrice': -1000000,
    });
    expect(model.inputPrice, isNull);
    expect(model.details, 'openrouter/auto · 2M');
  });

  test('ücretsiz model 0 olarak görünür', () {
    final model = AiModel.fromJson({
      'id': 'x/free',
      'inputPrice': 0,
      'outputPrice': 0,
    });
    expect(model.details, 'x/free · 1M token: girdi \$0, çıktı \$0');
  });

  test('çok küçük fiyat üslü sayı olarak değil sınırla yazılır', () {
    final model = AiModel.fromJson({
      'id': 'x/tiny',
      'inputPrice': 0.00000012,
      'outputPrice': 0.0004,
    });
    expect(model.details, 'x/tiny · 1M token: girdi \$<0.0001, çıktı \$0.0004');
  });
}
