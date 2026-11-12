import 'package:flutter/material.dart';
import 'package:naya_format/naya_format.dart';

import '../../entities/product/product_content.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Parça kartı: ne işe yarar, nasıl bozulur, nasıl tamir edilir.
///
/// Telefonda alttan açılan sayfa, geniş ekranda sağda bir panel olarak
/// gösterilir; içerik aynı. Veriler `.naya`'daki `map/parts.json` ve
/// `map/faults.json`'dan gelir; prosedürler DM okuyucuda açılır.
class PartSheet extends StatelessWidget {
  const PartSheet({
    super.key,
    required this.content,
    required this.part,
    required this.onOpenModule,
    required this.onSelectPart,
    this.node,
    this.onAsk,
    this.controller,
  });

  final ProductContent content;
  final Part part;

  /// Dokunulan model düğümü; aynı düğümdeki diğer parçaları göstermek için.
  final String? node;

  /// DM okuyucuyu açar (DMC ile).
  final ValueChanged<String> onOpenModule;

  /// Kartta başka bir parçaya geçer (alt parça, aynı düğümdeki parça).
  final ValueChanged<String> onSelectPart;
  final VoidCallback? onAsk;
  final ScrollController? controller;

  /// Prosedürlerin karttaki sırası: önce bul ve bak, sonra ayarla, sonra
  /// sök-tak.
  static const _procedureOrder = [
    'isolate',
    'inspect',
    'measure',
    'adjust',
    'lubricate',
    'remove',
    'install',
    'replace',
  ];

  static const _procedureLabels = {
    'isolate': 'Arıza bulma',
    'inspect': 'Muayene',
    'measure': 'Ölçüm',
    'adjust': 'Ayar',
    'lubricate': 'Yağlama',
    'remove': 'Sökme',
    'install': 'Takma',
    'replace': 'Değiştirme',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = content.pathTo(part.id);
    final related = <Part>[
      ...content.childrenOf(part.id),
      if (node != null)
        for (final p in content.siblingsOnNode(node!, part))
          if (p.parent != part.id) p,
    ];
    final faults = content.faultsFor(part.id);
    final procedures = part.procedures.entries.toList()
      ..sort((a, b) => _rank(a.key).compareTo(_rank(b.key)));

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
        Wrap(
          spacing: NayaSpace.md,
          runSpacing: NayaSpace.xs,
          children: [
            if (part.sns != null) TechLabel('SNS ${part.sns}'),
            if (path.length > 1)
              TechLabel(
                path.take(path.length - 1).map((p) => p.name).join(' › '),
              ),
          ],
        ),
        const SizedBox(height: NayaSpace.sm),
        Text(part.name, style: context.text.display),
        if (part.function != null) ...[
          const SizedBox(height: NayaSpace.sm),
          Text(part.function!, style: context.text.body),
        ],
        if (related.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.lg),
          Wrap(
            spacing: NayaSpace.sm,
            runSpacing: NayaSpace.sm,
            children: [
              for (final p in related)
                SuggestionChip(p.name, onTap: () => onSelectPart(p.id)),
            ],
          ),
        ],
        const SizedBox(height: NayaSpace.xxl),
        SectionHeader(
          label: 'Arızalar',
          title: 'Nasıl bozulur',
          trailing: faults.isEmpty ? null : TechLabel('${faults.length}'),
        ),
        const SizedBox(height: NayaSpace.sm),
        if (faults.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: NayaSpace.md),
            child: Text(
              'Bu parça için kayıtlı arıza yok.',
              style: context.text.small,
            ),
          ),
        for (final fault in faults)
          _FaultTile(
            fault: fault,
            partName: fault.part == part.id
                ? null
                : content.part(fault.part)?.name,
            symptoms: [for (final s in fault.symptoms) content.symptomText(s)],
            onOpenModule: onOpenModule,
          ),
        if (procedures.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.xxl),
          const SectionHeader(label: 'Prosedürler', title: 'Nasıl yapılır'),
          const SizedBox(height: NayaSpace.md),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, entry) in procedures.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  _ModuleTile(
                    title: _procedureLabels[entry.key] ?? entry.key,
                    dmc: entry.value,
                    onTap: () => onOpenModule(entry.value),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (part.ipd case final ipd?) ...[
          const SizedBox(height: NayaSpace.lg),
          Panel(
            padding: EdgeInsets.zero,
            child: _ModuleTile(
              title: 'Parça kataloğu',
              subtitle: 'Şekil ${ipd.figure} · Öğe ${ipd.item}',
              dmc: ipd.dmc,
              onTap: () => onOpenModule(ipd.dmc),
            ),
          ),
        ],
        if (onAsk != null) ...[
          const SizedBox(height: NayaSpace.xxl),
          PrimaryButton(
            label: '${part.name} hakkında sor',
            icon: Icons.chat_bubble_outline,
            onPressed: onAsk,
          ),
        ],
      ],
    );
  }

  static int _rank(String kind) {
    final i = _procedureOrder.indexOf(kind);
    return i < 0 ? _procedureOrder.length : i;
  }
}

class _FaultTile extends StatelessWidget {
  const _FaultTile({
    required this.fault,
    required this.symptoms,
    required this.onOpenModule,
    this.partName,
  });

  final Fault fault;
  final List<String> symptoms;

  /// Arıza bir alt parçadaysa onun adı ("Balata").
  final String? partName;
  final ValueChanged<String> onOpenModule;

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
                if (partName != null) ...[
                  TechLabel(partName!),
                  const SizedBox(height: 2),
                ],
                Text(
                  fault.cause,
                  style: context.text.body.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final symptom in symptoms) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7, right: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Text(symptom, style: context.text.small)),
                    ],
                  ),
                ],
                if (fault.isolation != null || fault.repair != null) ...[
                  const SizedBox(height: NayaSpace.sm),
                  Wrap(
                    spacing: NayaSpace.lg,
                    runSpacing: NayaSpace.xs,
                    children: [
                      if (fault.isolation case final dmc?)
                        _LinkButton(
                          icon: Icons.manage_search,
                          label: 'Arızayı bul',
                          onTap: () => onOpenModule(dmc),
                        ),
                      if (fault.repair case final dmc?)
                        _LinkButton(
                          icon: Icons.build_outlined,
                          label: 'Onar',
                          onTap: () => onOpenModule(dmc),
                        ),
                    ],
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

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(NayaRadius.sm),
      child: Padding(
        // Dokunma alanı 40 px'in altına düşmesin.
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.text.small.copyWith(
                color: c.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.title,
    required this.dmc,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String dmc;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.body.copyWith(color: c.text)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.small),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    dmc,
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
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
