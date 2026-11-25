import 'package:flutter/material.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/product/procedure_preview.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/rich_message.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Sohbetteki bir adım: kullanıcının mesajı, teşhis ya da akan cevap.
sealed class ChatTurn {
  const ChatTurn();
}

class UserTurn extends ChatTurn {
  const UserTurn(this.text);
  final String text;
}

/// Teşhis sonucu: adaylar, olasılıklar, önerilen prosedür.
class DiagnosisTurn extends ChatTurn {
  const DiagnosisTurn(this.diagnosis);
  final Diagnosis diagnosis;
}

/// Sohbet modelinin cevabı. [streaming] iken metin hâlâ akıyor; kaynaklar
/// cevap bitince gelir.
class AnswerTurn extends ChatTurn {
  const AnswerTurn(
    this.text, {
    this.sources = const [],
    this.streaming = false,
  });
  final String text;
  final List<String> sources;
  final bool streaming;
}

/// Sohbetin altında gösterilen uyarı (giriş yok, anahtar yok, ağ hatası)
/// ve varsa çözümü.
class ChatNotice {
  const ChatNotice(this.message, {this.actionLabel, this.onAction});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// Çalışma alanının alt yarısı: yapay zekâ ile sohbet ve teşhis sonucu.
///
/// Sohbet boşken ürünün kayıtlı belirtilerini öneri olarak gösterir.
/// İlk mesaj teşhise gider; sonuç netse sonraki sorular bulunan parça
/// hakkında sohbete döner ([topic]). En yeni mesaj hep altta görünür.
class ChatPanel extends StatelessWidget {
  const ChatPanel({
    super.key,
    required this.onCandidateTap,
    required this.onSend,
    this.turns = const [],
    this.diagnosing = false,
    this.notice,
    this.topic,
    this.onNewTopic,
    this.onOpenHistory,
    this.onOpenModule,
    this.productId,
    this.canSend = true,
    this.suggestions = const [],
  });

  final List<ChatTurn> turns;

  /// Teşhis sürüyor: model taranıyor.
  final bool diagnosing;
  final ChatNotice? notice;

  /// Sohbet bir parça hakkındaysa adı ("Zincir").
  final String? topic;

  /// Sohbeti temizleyip yeni bir soruna başlar.
  final VoidCallback? onNewTopic;
  final VoidCallback? onOpenHistory;
  final ValueChanged<String> onCandidateTap;

  /// Yazılan ya da seçilen öneri metni.
  final ValueChanged<String> onSend;

  /// Ürünün içeriği yüklenmeden mesaj gönderilemez; yazılan kaybolmasın.
  final bool canSend;

  /// Kaynak DM'e dokunuldu.
  final ValueChanged<String>? onOpenModule;

  /// Verilirse önerilen DM sohbette açılmış haliyle görünür.
  final String? productId;
  final List<String> suggestions;

  bool get _busy =>
      diagnosing || turns.any((t) => t is AnswerTurn && t.streaming);

  /// Parça sohbetinde boşken önerilen sorular.
  static const _partQuestions = [
    'Nasıl bakım yapılır?',
    'Ne zaman değiştirilmeli?',
    'Hangi aletler gerekir?',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final topic = this.topic;
    final notice = this.notice;
    final children = <Widget>[
      if (turns.isEmpty && !diagnosing)
        topic == null
            ? _Intro(suggestions: suggestions, onSend: onSend)
            : _PartIntro(
                part: topic,
                suggestions: _partQuestions,
                onSend: onSend,
              ),
      for (final (i, turn) in turns.indexed) ...[
        if (i > 0) const SizedBox(height: NayaSpace.lg),
        switch (turn) {
          UserTurn(:final text) => _UserMessage(text),
          DiagnosisTurn(:final diagnosis) => _AssistantMessage(
            diagnosis: diagnosis,
            productId: productId,
            onCandidateTap: onCandidateTap,
            onOpenModule: onOpenModule,
          ),
          AnswerTurn() => _Answer(
            turn: turn,
            productId: productId,
            onOpenModule: onOpenModule,
          ),
        },
      ],
      if (diagnosing) ...[
        const SizedBox(height: NayaSpace.lg),
        const _Thinking('Sistemler taranıyor…'),
      ],
      if (notice != null) ...[
        const SizedBox(height: NayaSpace.lg),
        _ErrorMessage(notice),
      ],
    ];
    final hint = topic == null
        ? 'Sorunu anlat ya da parça sor…'
        : '${topic.trim()} hakkında sor…';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        children: [
          if (turns.isNotEmpty || onOpenHistory != null)
            _Toolbar(
              title: topic == null ? 'Yapay zekâ' : '$topic hakkında',
              onNewTopic: turns.isEmpty || _busy ? null : onNewTopic,
              onOpenHistory: onOpenHistory,
            ),
          Expanded(
            // Ters liste: yeni mesaj ve akan cevap hep altta görünür;
            // kullanıcı yukarı kaydırmadıkça ekran kendiliğinden takip eder.
            // Sohbet boşken giriş metni baştan okunsun diye düz liste.
            child: ListView(
              reverse: turns.isNotEmpty || diagnosing || notice != null,
              padding: const EdgeInsets.fromLTRB(
                NayaSpace.gutter,
                NayaSpace.lg,
                NayaSpace.gutter,
                NayaSpace.lg,
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ],
            ),
          ),
          _Composer(onSend: onSend, hint: hint, enabled: canSend && !_busy),
        ],
      ),
    );
  }
}

/// Sohbetin üstü: konu, geçmiş ve yeni konu.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.title, this.onNewTopic, this.onOpenHistory});

  final String title;
  final VoidCallback? onNewTopic;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NayaSpace.gutter,
        NayaSpace.sm,
        NayaSpace.sm,
        0,
      ),
      child: Row(
        children: [
          Expanded(child: TechLabel(title)),
          if (onOpenHistory != null)
            IconButton(
              tooltip: 'Geçmiş',
              onPressed: onOpenHistory,
              icon: Icon(Icons.history, size: 20, color: c.textSecondary),
            ),
          if (onNewTopic != null)
            IconButton(
              tooltip: 'Yeni konu',
              onPressed: onNewTopic,
              icon: Icon(Icons.add_comment_outlined, size: 20, color: c.text),
            ),
        ],
      ),
    );
  }
}

/// Teşhis ya da cevap beklenirken.
class _Thinking extends StatelessWidget {
  const _Thinking(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
        ),
        const SizedBox(width: NayaSpace.md),
        Text(label, style: context.text.body.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.notice);

  final ChatNotice notice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final action = notice.onAction;
    return Panel(
      padding: const EdgeInsets.all(NayaSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: c.textMuted),
          const SizedBox(width: NayaSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.message,
                  style: context.text.body.copyWith(color: c.textSecondary),
                ),
                if (action != null && notice.actionLabel != null) ...[
                  const SizedBox(height: NayaSpace.sm),
                  OutlinedButton(
                    onPressed: action,
                    child: Text(notice.actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sohbet modelinin cevabı. Metindeki `[DMC-…]` atıfları ayıklanır;
/// kaynaklar cevap bitince altta bağlantı olarak görünür.
class _Answer extends StatelessWidget {
  const _Answer({required this.turn, this.productId, this.onOpenModule});

  final AnswerTurn turn;
  final String? productId;
  final ValueChanged<String>? onOpenModule;

  static final _citation = RegExp(r'\s*\[DMC-[^\]]+\]');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = turn.text.replaceAll(_citation, '').trim();
    final productId = this.productId;
    final open = onOpenModule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TechLabel('Cevap'),
        const SizedBox(height: NayaSpace.sm),
        if (text.isEmpty && turn.streaming)
          const _Thinking('Yazıyor…')
        else
          RichMessage(
            text,
            style: context.text.body.copyWith(color: c.text),
            // Akış sürerken metnin sonunda yanıp sönmeyen ince imleç.
            trailing: turn.streaming
                ? TextSpan(
                    text: ' ▍',
                    style: TextStyle(color: c.accent),
                  )
                : null,
          ),
        if (turn.sources.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.md),
          const TechLabel('Kaynaklar'),
          const SizedBox(height: NayaSpace.xs),
          if (productId != null && open != null)
            for (final dmc in turn.sources)
              SourceLink(productId: productId, dmc: dmc, onTap: () => open(dmc))
          else
            Wrap(
              spacing: NayaSpace.xs,
              runSpacing: NayaSpace.xs,
              children: [for (final dmc in turn.sources) _SourceTag(dmc)],
            ),
        ],
      ],
    );
  }
}

/// Parça sohbeti boşken.
class _PartIntro extends StatelessWidget {
  const _PartIntro({
    required this.part,
    required this.suggestions,
    required this.onSend,
  });

  final String part;
  final List<String> suggestions;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$part hakkında ne bilmek istersin?', style: context.text.title),
        const SizedBox(height: NayaSpace.sm),
        Text(
          'Cevaplar bu parçanın kartına ve bakım dokümanlarına dayanır; '
          'kaynağa dokununca doküman açılır.',
          style: context.text.body,
        ),
        const SizedBox(height: NayaSpace.xl),
        Wrap(
          spacing: NayaSpace.sm,
          runSpacing: NayaSpace.sm,
          children: [
            for (final text in suggestions)
              SuggestionChip(text, onTap: () => onSend(text)),
          ],
        ),
      ],
    );
  }
}

/// Sohbet boşken: ne yapılabileceği ve ürünün kayıtlı belirtileri.
class _Intro extends StatelessWidget {
  const _Intro({required this.suggestions, required this.onSend});

  final List<String> suggestions;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ne sorun var?', style: context.text.title),
        const SizedBox(height: NayaSpace.sm),
        Text(
          'Belirtiyi yaz; olası parçaları modelde tarayıp en olasısını '
          'gösteririm. Parçaya dokunursan kartı ve tamir adımları açılır.',
          style: context.text.body,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.xl),
          const TechLabel('Sık görülen belirtiler'),
          const SizedBox(height: NayaSpace.md),
          Wrap(
            spacing: NayaSpace.sm,
            runSpacing: NayaSpace.sm,
            children: [
              for (final text in suggestions)
                SuggestionChip(text, onTap: () => onSend(text)),
            ],
          ),
        ],
      ],
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: NayaSpace.lg,
            vertical: NayaSpace.md,
          ),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.only(
              topLeft: NayaRadius.lg,
              topRight: NayaRadius.lg,
              bottomLeft: NayaRadius.lg,
              bottomRight: NayaRadius.sm,
            ),
          ),
          child: Text(text, style: context.text.body.copyWith(color: c.text)),
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({
    required this.diagnosis,
    required this.onCandidateTap,
    this.productId,
    this.onOpenModule,
  });

  final Diagnosis diagnosis;
  final String? productId;
  final ValueChanged<String> onCandidateTap;
  final ValueChanged<String>? onOpenModule;

  /// Açıklamadaki `[DMC-…]` atıfları metinden çıkar; kaynaklar ayrıca
  /// etiket olarak görünüyor.
  static final _citation = RegExp(r'\s*\[DMC-[^\]]+\]');

  String get _label => switch (diagnosis.decision) {
    DiagnosisDecision.focus => 'Teşhis',
    DiagnosisDecision.ambiguous => 'İki olasılık',
    DiagnosisDecision.uncertain => 'Emin değilim',
    DiagnosisDecision.needsInfo => 'Biraz daha anlat',
    DiagnosisDecision.notDiagnosis => 'Cevap',
  };

  /// Açıklama gelmediyse karara göre kısa bir metin.
  String get _fallback => switch (diagnosis.decision) {
    DiagnosisDecision.focus when diagnosis.candidates.isNotEmpty =>
      'En olası parça ${diagnosis.top.name.toLowerCase()}.',
    DiagnosisDecision.needsInfo =>
      'Teşhis için biraz daha bilgi lazım: ne zaman oluyor, ses nereden '
          'geliyor?',
    _ =>
      'Sonuç kesin değil. Belirtiyi biraz daha anlatırsan adayları '
          'daraltabilirim.',
  };

  /// Önerilen DM'in açılmış hali ve diğer kaynaklar. Ürün bilinmiyorsa
  /// (örnek veri) yalnız kodlar.
  List<Widget> _details() {
    final productId = this.productId;
    final open = onOpenModule;
    final procedure = diagnosis.procedure;
    final others = [
      for (final dmc in diagnosis.sources)
        if (dmc != procedure) dmc,
    ];
    if (productId == null || open == null) {
      return [
        if (diagnosis.sources.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.sm),
          Wrap(
            spacing: NayaSpace.xs,
            runSpacing: NayaSpace.xs,
            children: [for (final dmc in diagnosis.sources) _SourceTag(dmc)],
          ),
        ],
      ];
    }
    final top = diagnosis.candidates.isEmpty ? null : diagnosis.top;
    return [
      if (procedure != null) ...[
        const SizedBox(height: NayaSpace.md),
        ProcedurePreview(
          productId: productId,
          dmc: procedure,
          onOpen: () => open(procedure),
          onOpenPart: top == null ? null : () => onCandidateTap(top.partId),
        ),
      ],
      if (others.isNotEmpty) ...[
        const SizedBox(height: NayaSpace.md),
        const TechLabel('Kaynaklar'),
        const SizedBox(height: NayaSpace.xs),
        for (final dmc in others)
          SourceLink(productId: productId, dmc: dmc, onTap: () => open(dmc)),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = diagnosis.explanation.replaceAll(_citation, '').trim();
    final danger = diagnosis.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TechLabel(_label),
        const SizedBox(height: NayaSpace.sm),
        if (diagnosis.isDangerous) ...[
          _DangerBanner(danger: danger!),
          const SizedBox(height: NayaSpace.md),
        ],
        RichMessage(
          text.isEmpty ? _fallback : text,
          style: context.text.body.copyWith(color: c.text),
        ),
        if (diagnosis.candidates.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.md),
          Panel(
            padding: const EdgeInsets.all(NayaSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TechLabel('${diagnosis.systemsScanned} sistem tarandı'),
                    const Spacer(),
                    const TechLabel('Olasılık'),
                  ],
                ),
                const SizedBox(height: NayaSpace.sm),
                for (final (i, candidate)
                    in diagnosis.candidates.take(3).indexed)
                  _CandidateRow(
                    candidate: candidate,
                    emphasized: i == 0 && diagnosis.isConfident,
                    onTap: () => onCandidateTap(candidate.partId),
                  ),
                if (diagnosis.faultCause != null) ...[
                  Divider(height: NayaSpace.xl, color: c.line),
                  Text(
                    diagnosis.faultCause!,
                    style: context.text.small.copyWith(color: c.textSecondary),
                  ),
                ],
                if (danger != null && !diagnosis.isDangerous) ...[
                  Divider(height: NayaSpace.xl, color: c.line),
                  _SafetyRow(danger: danger),
                ],
              ],
            ),
          ),
        ],
        ..._details(),
      ],
    );
  }
}

/// Ürün bilinmediğinde kaynak DM'in kodu.
class _SourceTag extends StatelessWidget {
  const _SourceTag(this.dmc);

  final String dmc;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.description_outlined, size: 14, color: c.textMuted),
        const SizedBox(width: NayaSpace.xs),
        Flexible(
          child: Text(
            dmc,
            overflow: TextOverflow.ellipsis,
            style: context.text.mono.copyWith(fontSize: 11, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Kullanmaya devam etmek tehlikeliyse en üstte.
class _DangerBanner extends StatelessWidget {
  const _DangerBanner({required this.danger});

  final double danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(NayaSpace.md),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(NayaRadius.md),
        border: Border.all(color: c.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: c.danger),
          const SizedBox(width: NayaSpace.sm),
          Expanded(
            child: Text(
              'Onarmadan kullanmayın (tehlike olasılığı '
              '%${(danger * 100).round()}).',
              style: context.text.small.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.emphasized,
    required this.onTap,
  });

  final Candidate candidate;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final percent = (candidate.probability * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(NayaRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NayaSpace.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.name,
                    style: context.text.body.copyWith(
                      color: emphasized ? c.text : c.textSecondary,
                      fontWeight: emphasized ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                Text(
                  '%$percent',
                  style: context.text.mono.copyWith(
                    color: emphasized ? c.accent : c.textMuted,
                  ),
                ),
                // Satıra dokununca parçanın kartı açılır.
                Icon(Icons.chevron_right, size: 16, color: c.textMuted),
              ],
            ),
            const SizedBox(height: NayaSpace.xs + 2),
            ProbabilityBar(
              value: candidate.probability,
              emphasized: emphasized,
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({required this.danger});

  /// "Kullanmak tehlikeli mi?" sorusunda "evet" olasılığı; burada yarının
  /// altında, uyarı bandı gösterilmiyor.
  final double danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: c.platinum),
        const SizedBox(width: NayaSpace.sm),
        Expanded(
          child: Text(
            'Kısa süre kullanılabilir, ilk fırsatta onarın.',
            style: context.text.small.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.onSend,
    required this.hint,
    this.enabled = true,
  });

  final String hint;

  final ValueChanged<String> onSend;

  /// Teşhis sürerken yeni mesaj gönderilmez.
  final bool enabled;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NayaSpace.md,
          NayaSpace.sm,
          NayaSpace.md,
          NayaSpace.md,
        ),
        child: Container(
          padding: const EdgeInsets.only(left: NayaSpace.lg, right: 6),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.all(NayaRadius.pill),
            border: Border.all(color: c.lineStrong),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: context.text.body.copyWith(color: c.text),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: context.text.body.copyWith(color: c.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Material(
                color: c.accent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _send,
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: c.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
