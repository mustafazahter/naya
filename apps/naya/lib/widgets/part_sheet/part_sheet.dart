import 'package:flutter/material.dart';

import '../../entities/part/part.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Parça kartı: ne işe yarar, nasıl bozulur, nasıl tamir edilir.
///
/// Telefonda alttan açılan sayfa, geniş ekranda sağda bir panel olarak
/// gösterilir; içerik aynı.
class PartSheet extends StatelessWidget {
  const PartSheet({super.key, required this.part, this.controller});

  final PartDetail part;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        NayaSpace.gutter,
        NayaSpace.md,
        NayaSpace.gutter,
        NayaSpace.xxl,
      ),
      children: [
        // Tutamaç yalnız alttan açılan sayfada; yan panelde anlamı yok.
        if (controller != null)
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.lineStrong,
                borderRadius: const BorderRadius.all(NayaRadius.pill),
              ),
            ),
          ),
        const SizedBox(height: NayaSpace.xl),
        Row(
          children: [
            TechLabel('SNS ${part.sns}'),
            const SizedBox(width: NayaSpace.md),
            Expanded(child: TechLabel(part.system)),
          ],
        ),
        const SizedBox(height: NayaSpace.sm),
        Text(part.name, style: context.text.display),
        const SizedBox(height: NayaSpace.sm),
        Text(part.function, style: context.text.body),
        const SizedBox(height: NayaSpace.xl),
        _MediaStrip(),
        const SizedBox(height: NayaSpace.xxl),
        const SectionHeader(label: 'Arızalar', title: 'Nasıl bozulur'),
        const SizedBox(height: NayaSpace.md),
        for (final fault in part.faults) _FaultTile(fault),
        const SizedBox(height: NayaSpace.xxl),
        const SectionHeader(label: 'Prosedürler', title: 'Nasıl yapılır'),
        const SizedBox(height: NayaSpace.md),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, procedure) in part.procedures.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                _ProcedureTile(procedure),
              ],
            ],
          ),
        ),
        const SizedBox(height: NayaSpace.lg),
        Text('Parça kataloğu', style: context.text.small),
        const SizedBox(height: 2),
        Text(part.ipd, style: context.text.mono.copyWith(fontSize: 11)),
        const SizedBox(height: NayaSpace.xxl),
        PrimaryButton(
          label: '${part.name} hakkında sor',
          icon: Icons.chat_bubble_outline,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

/// Görsellerin yeri. Gerçek fotoğraflar `media/` klasöründen gelecek.
class _MediaStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 112,
      child: Row(
        children: [
          for (final (i, caption) in const [
            'Genel görünüm',
            'Ölçüm',
            'Takma yönü',
          ].indexed) ...[
            if (i > 0) const SizedBox(width: NayaSpace.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(NayaSpace.sm),
                alignment: Alignment.bottomLeft,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(NayaRadius.md),
                  border: Border.all(color: c.line),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.viewportTop, c.surfaceRaised],
                  ),
                ),
                child: TechLabel(caption),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaultTile extends StatelessWidget {
  const _FaultTile(this.fault);

  final PartFault fault;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NayaSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SeverityMeter(fault.severity),
          ),
          const SizedBox(width: NayaSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fault.title,
                  style: context.text.body.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(fault.cause, style: context.text.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcedureTile extends StatelessWidget {
  const _ProcedureTile(this.procedure);

  final Procedure procedure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(NayaSpace.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    procedure.title,
                    style: context.text.body.copyWith(color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    procedure.dmc,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.mono.copyWith(
                      fontSize: 11,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NayaSpace.md),
            TechLabel('${procedure.minutes} dk'),
            const SizedBox(width: NayaSpace.xs),
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
