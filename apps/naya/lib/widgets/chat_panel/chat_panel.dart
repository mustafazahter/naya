import 'package:flutter/material.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Çalışma alanının alt yarısı: yapay zekâ ile sohbet ve teşhis sonucu.
class ChatPanel extends StatelessWidget {
  const ChatPanel({
    super.key,
    required this.diagnosis,
    required this.onCandidateTap,
  });

  final Diagnosis diagnosis;
  final ValueChanged<String> onCandidateTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
              children: [
                _UserMessage(diagnosis.symptom),
                const SizedBox(height: NayaSpace.lg),
                _AssistantMessage(
                  diagnosis: diagnosis,
                  onCandidateTap: onCandidateTap,
                ),
                const SizedBox(height: NayaSpace.lg),
                const Wrap(
                  spacing: NayaSpace.sm,
                  runSpacing: NayaSpace.sm,
                  children: [
                    SuggestionChip('Zinciri nasıl değiştiririm?'),
                    SuggestionChip('Hangi aletler gerekli?'),
                    SuggestionChip('Başka ne olabilir?'),
                  ],
                ),
              ],
            ),
          ),
          const _Composer(),
        ],
      ),
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
  });

  final Diagnosis diagnosis;
  final ValueChanged<String> onCandidateTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = diagnosis.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TechLabel('Teşhis'),
        const SizedBox(height: NayaSpace.sm),
        Text.rich(
          TextSpan(
            style: context.text.body.copyWith(color: c.text),
            children: [
              const TextSpan(text: 'En olası neden '),
              TextSpan(
                text: '${top.name.toLowerCase()} aşınması',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text:
                    '. Tıkırtı ve atlama birlikte görülüyorsa zincir çoğu '
                    'zaman uzamıştır. Ölçüm için zincir kontrol aleti yeterli.',
              ),
            ],
          ),
        ),
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
              for (final (i, candidate) in diagnosis.candidates.indexed)
                _CandidateRow(
                  candidate: candidate,
                  emphasized: i == 0,
                  onTap: () => onCandidateTap(candidate.partId),
                ),
              Divider(height: NayaSpace.xl, color: c.line),
              _SafetyRow(safeToUse: diagnosis.safeToUse),
            ],
          ),
        ),
        const SizedBox(height: NayaSpace.sm),
        Row(
          children: [
            Icon(Icons.description_outlined, size: 14, color: c.textMuted),
            const SizedBox(width: NayaSpace.xs),
            Flexible(
              child: Text(
                diagnosis.source,
                overflow: TextOverflow.ellipsis,
                style: context.text.mono.copyWith(
                  fontSize: 11,
                  color: c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
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
  const _SafetyRow({required this.safeToUse});

  final double safeToUse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final safe = safeToUse >= 0.6;
    return Row(
      children: [
        Icon(
          safe ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          size: 18,
          color: safe ? c.platinum : c.danger,
        ),
        const SizedBox(width: NayaSpace.sm),
        Expanded(
          child: Text(
            safe
                ? 'Kısa mesafe sürülebilir, ilk fırsatta değiştirin.'
                : 'Değiştirmeden kullanmayın.',
            style: context.text.small.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

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
                  onTap: () {},
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
