import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:naya_diagnosis/naya_diagnosis.dart';
import 'package:naya_format/naya_format.dart';

import '../auth/auth_service.dart';
import '../database/database.dart';
import '../library/library_service.dart';
import 'ai_provider.dart';
import 'ai_settings.dart';
import 'dm_search.dart';

/// Kaydedilmiş bir teşhis: sonuç, açıklama ve dayandığı DM'ler.
class DiagnosisRecord {
  const DiagnosisRecord({
    required this.id,
    required this.itemId,
    required this.message,
    required this.result,
    required this.explanation,
    required this.sources,
    required this.createdAt,
  });

  factory DiagnosisRecord.fromRow(DiagnosisRow row) {
    final json = jsonDecode(row.resultJson) as Map<String, Object?>;
    return DiagnosisRecord(
      id: row.id,
      itemId: row.libraryItemId,
      message: row.message,
      result: DiagnosisResult.fromJson(json['result']! as Map<String, Object?>),
      explanation: row.explanation,
      sources: [
        for (final s in json['sources']! as List<Object?>) s! as String,
      ],
      createdAt: row.createdAt,
    );
  }

  final int id;
  final String itemId;
  final String message;
  final DiagnosisResult result;
  final String explanation;
  final List<String> sources;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'item': itemId,
    'message': message,
    'result': result.toJson(),
    'explanation': explanation,
    'sources': sources,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// Sohbet akışında istemciye giden olaylar.
sealed class ChatEvent {
  const ChatEvent();
}

/// Cevabın yeni gelen parçası.
class ChatDelta extends ChatEvent {
  const ChatDelta(this.text);
  final String text;
}

/// Cevap bitti ve kaydedildi.
class ChatDone extends ChatEvent {
  const ChatDone({
    required this.conversationId,
    required this.messageId,
    required this.sources,
  });
  final int conversationId;
  final int messageId;
  final List<String> sources;
}

/// Yapay zekânın ürün hakkında konuştuğu yer: teşhis ve sohbet.
///
/// Bağlam (RAG) iki yerden gelir: kesin bağlantılar (teşhiste bulunan
/// parçanın prosedürü, parça kartından açılan sohbette parçanın DM'leri) ve
/// mesajdaki kelimelerle FTS5 araması. En fazla ~6k token (~24 bin
/// karakter) gider; cevap kullandığı DMC'leri gösterir.
class Assistant {
  Assistant({
    required this._db,
    required this._provider,
    required this._settings,
    required this._library,
    required this._search,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final NayaDatabase _db;
  final AiProvider _provider;
  final AiSettings _settings;
  final LibraryService _library;
  final DmSearch _search;
  final DateTime Function() _clock;

  /// Bağlama giden metnin üst sınırı (~6k token).
  static const maxContextChars = 24000;

  /// Sohbette modele giden önceki mesaj sayısı.
  static const historyLength = 10;

  Future<DiagnosisRecord> diagnose(
    AuthUser user,
    LibraryItemRow item,
    String message, {
    List<String> earlierMessages = const [],
  }) async {
    final apiKey = await _settings.apiKeyOf(user.id);
    final roles = await _settings.roles(user.id);
    final file = await _library.open(item);
    final parts = file.parts;
    if (parts == null) {
      throw const AiException(
        'no_parts',
        'Bu dosyada parça haritası yok; teşhis yapılamaz.',
        status: 422,
      );
    }
    final catalog = DiagnosisCatalog(
      productTitle: file.manifest.title,
      parts: parts,
      faults: file.faults,
    );
    final result = await DiagnosisFlow(
      catalog: catalog,
      decider: ProviderDecider(
        _provider,
        apiKey: apiKey,
        model: roles[AiRole.decision]!,
      ),
    ).run(message, earlierMessages: earlierMessages);

    final passages = <DmPassage>[];
    final procedure = result.procedure;
    if (procedure != null) {
      passages.addAll(await _search.passagesOf(item.id, procedure));
    }
    passages.addAll(await _search.search(item.id, message));
    final context = _contextOf(passages);

    var explanation = '';
    try {
      explanation = await _provider
          .chat(
            apiKey: apiKey,
            model: roles[AiRole.chat]!,
            messages: [
              ChatMessage('system', _systemPrompt(file.manifest.title)),
              ChatMessage(
                'user',
                '${_diagnosisBrief(catalog, result)}\n\n'
                    'Kullanıcının mesajı: $message\n\n'
                    'Doküman parçaları:\n${context.text}',
              ),
            ],
          )
          .join();
    } on AiException catch (e) {
      // Açıklama gelmese de olasılıklar ve animasyon işe yarar.
      stderr.writeln('Teşhis açıklaması alınamadı: $e');
    }

    final sources = _cited(explanation, context.dmcs, procedure);
    final now = _clock();
    final id = await _db
        .into(_db.diagnoses)
        .insert(
          DiagnosesCompanion.insert(
            userId: user.id,
            libraryItemId: item.id,
            message: message,
            resultJson: jsonEncode({
              'result': result.toJson(),
              'sources': sources,
            }),
            explanation: Value(explanation),
            model: result.model,
            createdAt: now,
          ),
        );
    return DiagnosisRecord(
      id: id,
      itemId: item.id,
      message: message,
      result: result,
      explanation: explanation,
      sources: sources,
      createdAt: now,
    );
  }

  /// Kullanıcının teşhisleri, en yeni önce; [itemId] verilirse yalnız o
  /// ürününkiler.
  Future<List<DiagnosisRecord>> diagnoses(
    AuthUser user, {
    String? itemId,
  }) async {
    final query = _db.select(_db.diagnoses)
      ..where((d) => d.userId.equals(user.id))
      ..orderBy([(d) => OrderingTerm.desc(d.id)])
      ..limit(100);
    if (itemId != null) query.where((d) => d.libraryItemId.equals(itemId));
    return [for (final row in await query.get()) DiagnosisRecord.fromRow(row)];
  }

  Future<DiagnosisRecord?> diagnosis(AuthUser user, int id) async {
    final row =
        await (_db.select(_db.diagnoses)
              ..where((d) => d.id.equals(id) & d.userId.equals(user.id)))
            .getSingleOrNull();
    return row == null ? null : DiagnosisRecord.fromRow(row);
  }

  /// Sohbet: cevap parça parça akar, bitince mesajlar kaydedilir.
  /// [conversationId] yoksa yeni sohbet açılır; [partId] verilirse parça
  /// kartı ve DM'leri sabit bağlam olur.
  Stream<ChatEvent> chat(
    AuthUser user,
    LibraryItemRow item,
    String message, {
    int? conversationId,
    String? partId,
  }) async* {
    final apiKey = await _settings.apiKeyOf(user.id);
    final roles = await _settings.roles(user.id);
    final file = await _library.open(item);

    final conversation = await _conversation(
      user,
      item,
      conversationId,
      partId: partId,
      firstMessage: message,
    );
    final history =
        await (_db.select(_db.messages)
              ..where((m) => m.conversationId.equals(conversation.id))
              ..orderBy([(m) => OrderingTerm.desc(m.id)])
              ..limit(historyLength))
            .get();

    final passages = <DmPassage>[];
    final part = conversation.partId == null
        ? null
        : file.parts?[conversation.partId!];
    if (part != null) {
      for (final dmc in part.procedures.values.toSet()) {
        passages.addAll(await _search.passagesOf(item.id, dmc));
      }
    }
    passages.addAll(await _search.search(item.id, message));
    final context = _contextOf(passages);

    final now = _clock();
    await _db
        .into(_db.messages)
        .insert(
          MessagesCompanion.insert(
            conversationId: conversation.id,
            role: 'user',
            content: message,
            createdAt: now,
          ),
        );

    final answer = StringBuffer();
    await for (final delta in _provider.chat(
      apiKey: apiKey,
      model: roles[AiRole.chat]!,
      messages: [
        ChatMessage('system', _systemPrompt(file.manifest.title)),
        ChatMessage(
          'system',
          [
            if (part != null) _partBrief(file, part),
            'Doküman parçaları:\n${context.text}',
          ].join('\n\n'),
        ),
        for (final m in history.reversed) ChatMessage(m.role, m.content),
        ChatMessage('user', message),
      ],
    )) {
      answer.write(delta);
      yield ChatDelta(delta);
    }

    final text = answer.toString();
    final sources = _cited(text, context.dmcs, null);
    final messageId = await _db
        .into(_db.messages)
        .insert(
          MessagesCompanion.insert(
            conversationId: conversation.id,
            role: 'assistant',
            content: text,
            sourcesJson: Value(jsonEncode(sources)),
            createdAt: _clock(),
          ),
        );
    await (_db.update(_db.conversations)
          ..where((c) => c.id.equals(conversation.id)))
        .write(ConversationsCompanion(updatedAt: Value(_clock())));
    yield ChatDone(
      conversationId: conversation.id,
      messageId: messageId,
      sources: sources,
    );
  }

  Future<List<ConversationRow>> conversations(AuthUser user, {String? itemId}) {
    final query = _db.select(_db.conversations)
      ..where((c) => c.userId.equals(user.id))
      ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])
      ..limit(100);
    if (itemId != null) query.where((c) => c.libraryItemId.equals(itemId));
    return query.get();
  }

  /// Sohbet ve mesajları; başkasınınsa `null`.
  Future<(ConversationRow, List<MessageRow>)?> conversation(
    AuthUser user,
    int id,
  ) async {
    final row =
        await (_db.select(_db.conversations)
              ..where((c) => c.id.equals(id) & c.userId.equals(user.id)))
            .getSingleOrNull();
    if (row == null) return null;
    final messages =
        await (_db.select(_db.messages)
              ..where((m) => m.conversationId.equals(id))
              ..orderBy([(m) => OrderingTerm.asc(m.id)]))
            .get();
    return (row, messages);
  }

  Future<ConversationRow> _conversation(
    AuthUser user,
    LibraryItemRow item,
    int? id, {
    required String? partId,
    required String firstMessage,
  }) async {
    if (id != null) {
      final existing =
          await (_db.select(_db.conversations)..where(
                (c) =>
                    c.id.equals(id) &
                    c.userId.equals(user.id) &
                    c.libraryItemId.equals(item.id),
              ))
              .getSingleOrNull();
      if (existing == null) {
        throw const AiException(
          'not_found',
          'Böyle bir sohbet yok.',
          status: 404,
        );
      }
      return existing;
    }
    final now = _clock();
    final title = firstMessage.length > 60
        ? '${firstMessage.substring(0, 60)}…'
        : firstMessage;
    return _db
        .into(_db.conversations)
        .insertReturning(
          ConversationsCompanion.insert(
            userId: user.id,
            libraryItemId: item.id,
            partId: Value(partId),
            title: title,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  static String _systemPrompt(String product) =>
      'Sen NAYA uygulamasının bakım asistanısın. Ürün: $product. '
      'Türkçe, kısa ve açık yaz. Yalnız sana verilen doküman parçalarına ve '
      'teşhis sonucuna dayan; dokümanda olmayan bir adım uydurma, bilmiyorsan '
      'söyle. Bir bilgiyi bir doküman parçasından aldıysan sonuna o parçanın '
      'kodunu köşeli parantezle yaz, örneğin [DMC-...]. Olasılıkları '
      'değiştirme; sana verilen yüzdeleri kullan. Tehlike varsa en başta '
      'söyle.';

  /// Teşhis sonucunu sohbet modeline anlatan özet ve ondan ne istendiği.
  static String _diagnosisBrief(
    DiagnosisCatalog catalog,
    DiagnosisResult result,
  ) {
    String percent(double p) => '%${(p * 100).round()}';
    String name(String partId) => catalog.part(partId)?.name ?? partId;
    final lines = <String>['Teşhis sonucu:'];
    for (final c in result.candidates.take(3)) {
      lines.add('- ${name(c.partId)}: ${percent(c.probability)}');
    }
    final fault = result.fault == null ? null : catalog.fault(result.fault!.id);
    if (fault != null) {
      lines.add(
        'En olası arıza: ${fault.cause} (${percent(result.fault!.probability)})',
      );
    }
    if (result.procedure != null) {
      lines.add('Önerilen prosedür: ${result.procedure}');
    }
    final danger = result.danger;
    if (danger != null && danger >= 0.5) {
      lines.add(
        'Kullanmaya devam etmek tehlikeli olabilir (${percent(danger)}).',
      );
    }
    lines.add('');
    lines.add(switch (result.decision) {
      DiagnosisDecision.focus =>
        'En olası parçayı, nedenini ve ne yapılması gerektiğini birkaç '
            'cümleyle anlat.',
      DiagnosisDecision.ambiguous || DiagnosisDecision.uncertain =>
        'Sonuç kesin değil. Adayları kısaca söyle ve aralarında ayırt etmek '
            'için kullanıcıya tek bir netleştirici soru sor.',
      DiagnosisDecision.needsInfo =>
        'Anlatılanlar teşhis için yetmiyor. Sorunu netleştirmek için '
            'kullanıcıya tek bir soru sor (ne zaman oluyor, nereden ses '
            'geliyor gibi).',
      DiagnosisDecision.notDiagnosis =>
        'Kullanıcı bir arıza anlatmıyor; sorusunu dokümana dayanarak '
            'cevapla.',
    });
    return lines.join('\n');
  }

  static String _partBrief(NayaFile file, Part part) {
    final faults = [
      for (final f in file.faults?.faults ?? const <Fault>[])
        if (f.part == part.id) f.cause,
    ];
    return [
      'Konuşulan parça: ${part.name}.',
      if (part.function != null) 'İşlevi: ${part.function}',
      if (faults.isNotEmpty) 'Bilinen arızaları: ${faults.join('; ')}',
    ].join('\n');
  }

  /// Parçaları sınırı aşmadan, tekrarsız birleştirir.
  static ({String text, List<String> dmcs}) _contextOf(
    List<DmPassage> passages,
  ) {
    final buffer = StringBuffer();
    final seen = <String>{};
    final dmcs = <String>[];
    for (final p in passages) {
      final entry = '[${p.dmc}] ${p.title}\n${p.text}\n\n';
      if (!seen.add(entry)) continue;
      if (buffer.length + entry.length > maxContextChars) break;
      buffer.write(entry);
      if (!dmcs.contains(p.dmc)) dmcs.add(p.dmc);
    }
    return (text: buffer.toString(), dmcs: dmcs);
  }

  /// Cevabın kaynakları: cevapta adı geçen DMC'ler. Model hiçbirini
  /// yazmadıysa bağlama giden ilk birkaç DM; önerilen prosedür hep başta.
  static List<String> _cited(
    String answer,
    List<String> given,
    String? procedure,
  ) {
    final mentioned = [
      for (final dmc in given)
        if (answer.contains(dmc)) dmc,
    ];
    final sources = mentioned.isNotEmpty ? mentioned : given.take(3).toList();
    if (procedure != null) {
      sources.remove(procedure);
      sources.insert(0, procedure);
    }
    return sources;
  }
}
