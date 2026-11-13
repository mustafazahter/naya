import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import 'product_content.dart';

/// Bir prosedür DM'i açılmış haliyle (teşhiste sohbette, parça
/// sayfasında arızanın altında): ne işlemi
/// olduğu, kaç adım sürdüğü, gereken aletler, uyarılar ve ilk adımlar.
/// Kullanıcı koda basmadan ne yapacağını görür; ayrıntı için okuyucuyu
/// ya da parçanın kartını açar.
class ProcedurePreview extends ConsumerWidget {
  const ProcedurePreview({
    super.key,
    required this.productId,
    required this.dmc,
    required this.onOpen,
    this.onOpenPart,
  });

  final String productId;
  final String dmc;

  /// DM okuyucuyu açar.
  final VoidCallback onOpen;

  /// Bulunan parçanın kartını açar; parça yoksa düğme görünmez.
  final VoidCallback? onOpenPart;

  /// Önizlemede gösterilen adım sayısı.
  static const shownSteps = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(
      dataModuleProvider((productId: productId, dmc: dmc)),
    );
    return switch (module) {
      AsyncData(:final value) => _Card(
        doc: value,
        onOpen: onOpen,
        onOpenPart: onOpenPart,
      ),
      // Okunamazsa en azından kodu ve okuyucuya geçiş kalsın.
      AsyncError() => _Card(doc: null, dmc: dmc, onOpen: onOpen),
      _ => const Panel(
        padding: EdgeInsets.all(NayaSpace.lg),
        child: SkeletonBlock(height: 120),
      ),
    };
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.doc,
    required this.onOpen,
    this.onOpenPart,
    this.dmc,
  });

  final DmDocument? doc;
  final String? dmc;
  final VoidCallback onOpen;
  final VoidCallback? onOpenPart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final doc = this.doc;
    final steps = doc == null ? const <String>[] : stepTexts(doc);
    final requirements = doc?.requirements;
    final warning = requirements?.safety
        .where((a) => a.kind != DmAdmonitionKind.note)
        .firstOrNull;
    final tools = [
      for (final item in [
        ...?requirements?.equipment,
        ...?requirements?.supplies,
      ])
        item.name,
    ];

    return Panel(
      raised: true,
      padding: const EdgeInsets.all(NayaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TechLabel(doc == null ? 'Önerilen işlem' : kindOf(doc)),
              const Spacer(),
              if (steps.isNotEmpty)
                TechLabel(
                  doc!.contentType == 'faultIsolation'
                      ? '${steps.length} soru'
                      : '${steps.length} adım',
                ),
            ],
          ),
          const SizedBox(height: NayaSpace.sm),
          if (doc != null) ...[
            Text(
              doc.techName,
              style: context.text.heading.copyWith(color: c.text),
            ),
            if (doc.infoName != null)
              Text(
                doc.infoName!,
                style: context.text.body.copyWith(color: c.textSecondary),
              ),
          ],
          if (warning != null) ...[
            const SizedBox(height: NayaSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: c.danger),
                const SizedBox(width: NayaSpace.sm),
                Expanded(
                  child: Text(
                    warning.paragraphs.join(' '),
                    style: context.text.small.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ],
          if (tools.isNotEmpty) ...[
            const SizedBox(height: NayaSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.handyman_outlined, size: 16, color: c.textMuted),
                const SizedBox(width: NayaSpace.sm),
                Expanded(
                  child: Text(
                    tools.join(', '),
                    style: context.text.small.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (steps.isNotEmpty) ...[
            Divider(height: NayaSpace.xl, color: c.line),
            for (final (i, text)
                in steps.take(ProcedurePreview.shownSteps).indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: NayaSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: context.text.mono.copyWith(
                          fontSize: 12,
                          color: c.accent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.small.copyWith(color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
            if (steps.length > ProcedurePreview.shownSteps)
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  '+${steps.length - ProcedurePreview.shownSteps} adım daha',
                  style: context.text.small.copyWith(color: c.textMuted),
                ),
              ),
          ],
          const SizedBox(height: NayaSpace.lg),
          Wrap(
            spacing: NayaSpace.sm,
            runSpacing: NayaSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Adım adım aç'),
              ),
              if (onOpenPart != null)
                TextButton(
                  onPressed: onOpenPart,
                  child: const Text('Parça kartı'),
                ),
            ],
          ),
          const SizedBox(height: NayaSpace.sm),
          Text(
            doc == null ? dmc ?? '' : '${doc.code}',
            overflow: TextOverflow.ellipsis,
            style: context.text.mono.copyWith(fontSize: 11, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// İşlemin adı, bilgi koduna göre (S1000D bilgi kodları).
String kindOf(DmDocument doc) {
  if (doc.contentType == 'faultIsolation') return 'Arıza bulma';
  final code = doc.code.infoCode;
  return switch (code) {
    '520' => 'Sökme',
    '720' => 'Takma',
    '920' || '921' => 'Değiştirme',
    '241' => 'Yağlama',
    '271' => 'Ayar',
    _ when code.startsWith('3') => 'Kontrol',
    _ => 'Önerilen işlem',
  };
}

/// Ana adımların ya da arıza bulmadaki soruların kısa metni.
List<String> stepTexts(DmDocument doc) {
  final texts = <String>[];
  for (final block in doc.blocks) {
    switch (block) {
      case DmStep(:final title, :final blocks):
        final text = title ?? _firstText(blocks);
        if (text != null && text.isNotEmpty) texts.add(text);
      case DmIsolation(:final blocks):
        for (final step in blocks.whereType<DmIsolationStep>()) {
          final text = step.question.text.isNotEmpty
              ? step.question.text
              : step.action.text;
          if (text.isNotEmpty) texts.add(text);
        }
      default:
        break;
    }
  }
  return texts;
}

String? _firstText(List<DmBlock> blocks) {
  for (final block in blocks) {
    if (block is DmParagraph && block.text.text.isNotEmpty) {
      return block.text.text;
    }
    if (block is DmStep) {
      final inner = block.title ?? _firstText(block.blocks);
      if (inner != null) return inner;
    }
  }
  return null;
}

/// Teşhisin dayandığı diğer DM'ler: kod yerine başlığı.
class SourceLink extends ConsumerWidget {
  const SourceLink({
    super.key,
    required this.productId,
    required this.dmc,
    required this.onTap,
  });

  final String productId;
  final String dmc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final module = ref
        .watch(dataModuleProvider((productId: productId, dmc: dmc)))
        .value;
    final title = module == null
        ? dmc
        : [module.techName, ?module.infoName].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(NayaRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NayaSpace.xs),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 16, color: c.textMuted),
            const SizedBox(width: NayaSpace.sm),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: context.text.small.copyWith(color: c.accent),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
