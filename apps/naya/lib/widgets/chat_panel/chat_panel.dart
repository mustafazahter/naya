import 'package:flutter/material.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import 'procedure_preview.dart';

/// Çalışma alanının alt yarısı: yapay zekâ ile sohbet ve teşhis sonucu.
///
/// Teşhis yokken (sohbet henüz başlamadı) ürünün kayıtlı belirtilerini
/// öneri olarak gösterir. Teşhis sürerken yazılan mesaj ve "taranıyor"
/// görünür; hata olursa mesajı.
class ChatPanel extends StatelessWidget {
  const ChatPanel({
    super.key,
    required this.onCandidateTap,
    required this.onSend,
    this.onOpenModule,
    this.productId,
    this.diagnosis,
    this.pending,
    this.error,
    this.canSend = true,
    this.suggestions = const [],
  });

  final Diagnosis? diagnosis;

  /// Teşhisi süren mesaj.
  final String? pending;

  /// Teşhis başarısız olduysa gösterilecek mesaj.
  final String? error;
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final diagnosis = this.diagnosis;
    final pending = this.pending;
    final error = this.error;
    final List<Widget> children;
    if (pending != null) {
      children = [
        _UserMessage(pending),
        const SizedBox(height: NayaSpace.lg),
        const _Thinking(),
      ];
    } else if (diagnosis != null) {
      children = [
        _UserMessage(diagnosis.symptom),
        const SizedBox(height: NayaSpace.lg),
        _AssistantMessage(
          diagnosis: diagnosis,
          productId: productId,
          onCandidateTap: onCandidateTap,
          onOpenModule: onOpenModule,
        ),
        if (error != null) ...[
          const SizedBox(height: NayaSpace.lg),
          _ErrorMessage(error),
        ],
      ];
    } else if (error != null) {
      children = [_ErrorMessage(error)];
    } else {
      children = [_Intro(suggestions: suggestions, onSend: onSend)];
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                NayaSpace.gutter,
                NayaSpace.lg,
                NayaSpace.gutter,
                NayaSpace.lg,
              ),
              children: children,
            ),
          ),
          _Composer(onSend: onSend, enabled: canSend && pending == null),
        ],
      ),
    );
  }
}

/// Teşhis sürerken: model taranıyor.
class _Thinking extends StatelessWidget {
  const _Thinking();

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
        Text(
          'Sistemler taranıyor…',
          style: context.text.body.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.all(NayaSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: c.textMuted),
          const SizedBox(width: NayaSpace.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.body.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
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
        const TechLabel('Yapay zekâ'),
        const SizedBox(height: NayaSpace.sm),
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
        Text(
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
  const _Composer({required this.onSend, this.enabled = true});

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
                    hintText: 'Sorunu anlat ya da parça sor…',
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
