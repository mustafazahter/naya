import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/product/product_content.dart';
import '../../features/ask_ai/ask_ai.dart';
import '../../features/diagnose/request_diagnosis.dart';
import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/page_shell.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Bir ürünün teşhis ve sohbet geçmişi. Eski bir teşhis açılınca çalışma
/// alanında modelde yeniden oynatılır; sohbet açılınca kaldığı yerden
/// devam eder.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({
    super.key,
    required this.productId,
    required this.onOpenDiagnosis,
    required this.onOpenConversation,
    required this.onSignIn,
  });

  final String productId;
  final ValueChanged<int> onOpenDiagnosis;
  final ValueChanged<int> onOpenConversation;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(productContentProvider(productId));
    final data = content.value;
    final diagnoses = data == null
        ? null
        : ref.watch(diagnosisHistoryProvider(data));
    final conversations = ref.watch(conversationsProvider(productId));

    // Giriş yoksa iki liste de 401 verir; bir kez söylemek yeter.
    final signedOut = [
      diagnoses?.error,
      conversations.error,
    ].any((e) => e is ApiException && e.statusCode == 401);
    return PageShell(
      label: 'Yapay zekâ',
      title: 'Geçmiş',
      intro:
          'Yaptığın teşhisler ve sohbetler. Açtığında model aynı sonucu '
          'yeniden gösterir.',
      children: [
        if (signedOut)
          EmptyState(
            icon: Icons.lock_outline,
            title: 'Giriş gerekiyor',
            message: 'Geçmiş hesabına kaydediliyor; görmek için giriş yap.',
            actionLabel: 'Giriş yap',
            onAction: onSignIn,
          )
        else ...[
          const SectionHeader(label: 'Yapay zekâ', title: 'Teşhisler'),
          const SizedBox(height: NayaSpace.md),
          switch (diagnoses) {
            AsyncData(:final value) when value.isEmpty => const _Empty(
              'Henüz teşhis yok. Çalışma alanında bir belirti yaz.',
            ),
            AsyncData(:final value) => Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, entry) in value.indexed) ...[
                    if (i > 0) Divider(height: 1, color: context.colors.line),
                    _DiagnosisRow(
                      entry: entry,
                      onTap: () => onOpenDiagnosis(entry.diagnosis.id!),
                    ),
                  ],
                ],
              ),
            ),
            AsyncError(:final error) => _Empty(_message(error)),
            // İçerik inmediyse teşhis listesi hiç istenmez; iskelet sonsuza
            // dek dönmesin.
            _ when content.hasError => _Empty(_message(content.error!)),
            _ => const SkeletonBlock(height: 160),
          },
          const SizedBox(height: NayaSpace.xxl),
          const SectionHeader(label: 'Parçalar hakkında', title: 'Sohbetler'),
          const SizedBox(height: NayaSpace.md),
          switch (conversations) {
            AsyncData(:final value) when value.isEmpty => const _Empty(
              'Henüz sohbet yok. Bir parçanın kartında "hakkında sor"a dokun.',
            ),
            AsyncData(:final value) => Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, c) in value.indexed) ...[
                    if (i > 0) Divider(height: 1, color: context.colors.line),
                    _ConversationRow(
                      summary: c,
                      partName: c.part == null
                          ? null
                          : data?.part(c.part!)?.name,
                      onTap: () => onOpenConversation(c.id),
                    ),
                  ],
                ],
              ),
            ),
            AsyncError(:final error) => _Empty(_message(error)),
            _ => const SkeletonBlock(height: 120),
          },
        ],
      ],
    );
  }

  static String _message(Object error) =>
      error is ApiException ? error.message : 'Geçmiş okunamadı.';
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Panel(child: Text(text, style: context.text.body));
}

class _DiagnosisRow extends StatelessWidget {
  const _DiagnosisRow({required this.entry, required this.onTap});

  final DiagnosisEntry entry;
  final VoidCallback onTap;

  String get _result {
    final d = entry.diagnosis;
    return switch (d.decision) {
      DiagnosisDecision.focus when d.candidates.isNotEmpty =>
        '${d.top.name} · %${(d.top.probability * 100).round()}',
      DiagnosisDecision.ambiguous when d.candidates.length > 1 =>
        '${d.candidates[0].name} ya da ${d.candidates[1].name}',
      DiagnosisDecision.needsInfo => 'Ek bilgi istendi',
      DiagnosisDecision.notDiagnosis => 'Soru cevaplandı',
      _ => 'Kesin sonuç yok',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = entry.diagnosis;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(NayaSpace.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.symptom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.body.copyWith(color: c.text),
                  ),
                  const SizedBox(height: NayaSpace.xs),
                  Row(
                    children: [
                      if (d.isDangerous) ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: c.danger,
                        ),
                        const SizedBox(width: NayaSpace.xs),
                      ],
                      Flexible(
                        child: Text(
                          _result,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.small.copyWith(
                            color: d.isConfident ? c.accent : c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: NayaSpace.md),
            TechLabel(_when(entry.createdAt)),
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.summary,
    required this.partName,
    required this.onTap,
  });

  final ConversationSummary summary;
  final String? partName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(NayaSpace.lg),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 18, color: c.textMuted),
            const SizedBox(width: NayaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.title.isEmpty ? 'Sohbet' : summary.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.body.copyWith(color: c.text),
                  ),
                  if (partName != null) ...[
                    const SizedBox(height: NayaSpace.xs),
                    Text(
                      partName!,
                      style: context.text.small.copyWith(color: c.accent),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: NayaSpace.md),
            TechLabel(_when(summary.updatedAt)),
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

/// "14:05", "Dün", "18 Kas"
String _when(DateTime t) {
  const months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
  if (diff == 1) return 'Dün';
  return '${t.day} ${months[t.month - 1]}';
}
