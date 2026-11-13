import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:naya_api/server.dart';
import 'package:naya_cli/naya_cli.dart';
import 'package:naya_diagnosis/naya_diagnosis.dart';

/// Testlerde kullanılan ana anahtar (32 sıfır bayt).
final testMasterKey = base64.encode(List.filled(32, 0));

/// Repodaki bisiklet şablonu, paketlenmiş hali. Model dahil (~8 MB) olduğu
/// için bir kez paketlenir.
final Uint8List bicycleNaya = packFolder(
  Directory('../../templates/src/bisiklet'),
).encode();

/// OpenRouter yerine: anahtarı kontrol eder, Jev sorularına soru
/// anahtarına göre sabit cevap verir, sohbette hazır metin akıtır.
class FakeAi implements AiProvider {
  FakeAi({
    this.chatText = 'Zincir aşınmış. [DMC-NAYABIKE-AAA-DA1-10-00-00AA-520A-A]',
  });

  String chatText;

  /// Verilirse sohbet cevabı yarıda bu hatayla kesilir.
  Object? chatFailure;

  /// Geçerli sayılan anahtar.
  static const goodKey = 'sk-or-v1-dogru-anahtar-1234';

  final checkedKeys = <String>[];
  final decisions = <Map<String, DecisionQuestion>>[];
  final chats = <List<ChatMessage>>[];
  int modelCalls = 0;

  /// Belirtiler yetmiyor mu?
  bool vague = false;

  @override
  Future<void> checkKey(String apiKey) async {
    checkedKeys.add(apiKey);
    if (apiKey != goodKey) {
      throw const AiException('invalid_key', 'Geçersiz.', status: 400);
    }
  }

  @override
  Future<List<AiModel>> listModels() async {
    modelCalls++;
    return const [
      AiModel(id: '~typesafe/jev-latest', name: 'Jev', kind: 'decision'),
      AiModel(
        id: 'deepseek/deepseek-v4.1-flash',
        name: 'DeepSeek',
        kind: 'chat',
      ),
    ];
  }

  @override
  Future<DecisionAnswers> decide({
    required String apiKey,
    required String model,
    required String state,
    required Map<String, DecisionQuestion> questions,
  }) async {
    decisions.add(questions);
    final choices = <String, Map<String, double>>{};
    final yes = <String, double>{};
    for (final key in questions.keys) {
      switch (key) {
        case 'intent':
          choices[key] = {'diagnose': 0.9, 'general': 0.1};
        case 'sufficient':
          yes[key] = vague ? 0.1 : 0.9;
        case 'system':
          choices[key] = {'drive': 0.85, 'brakes': 0.1, 'none': 0.05};
        case 'part:drive':
          choices[key] = {
            'drive.chain': 0.8,
            'drive.cassette': 0.15,
            'none': 0.05,
          };
        case 'fault':
          choices[key] = {'f.chain.worn': 0.75, 'none': 0.25};
        case 'danger':
          yes[key] = 0.1;
        default:
          choices[key] = {'none': 1};
      }
    }
    return DecisionAnswers(choices: choices, yes: yes, model: 'jev-1.14-test');
  }

  @override
  Stream<String> chat({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async* {
    chats.add(messages);
    for (final word in chatText.split(' ')) {
      yield '$word ';
    }
    final failure = chatFailure;
    if (failure != null) throw failure;
  }
}
