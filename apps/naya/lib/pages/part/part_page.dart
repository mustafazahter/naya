import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naya_format/naya_format.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import '../../entities/product/dm_figure_view.dart';
import '../../entities/product/procedure_preview.dart';
import '../../entities/product/product_content.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Bir parçanın her şeyi tek sayfada: ne işe yarar, sistemin anlatımı,
/// şemaları, nasıl bozulur ve her arızanın nasıl onarılacağı, bakım
/// prosedürleri ve parça kataloğu.
///
/// Modelde parça seçilip "Ayrıntılar"a basılınca açılır. Bütün bilgi
/// `.naya`'dan gelir; arızaların onarım adımları sayfanın içinde açılır,
/// tamamı DM okuyucuda.
class PartPage extends ConsumerWidget {
  const PartPage({
    super.key,
    required this.productId,
    required this.partId,
    required this.onOpenModule,
    required this.onOpenPart,
  });

  final String productId;
  final String partId;

  /// DM okuyucuyu açar.
  final ValueChanged<String> onOpenModule;

  /// Başka bir parçanın sayfasına geçer (alt parça).
  final ValueChanged<String> onOpenPart;

  /// İçerik bu genişliği geçmez; geniş ekranda satırlar okunur kalır.
  static const maxWidth = 880.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(productContentProvider(productId));
    return Scaffold(
      body: switch (content) {
        AsyncData(:final value) => switch (value.part(partId)) {
          final part? => _PartView(
            content: value,
            part: part,
            onOpenModule: onOpenModule,
            onOpenPart: onOpenPart,
          ),
          null => EmptyState(
            icon: Icons.search_off,
            title: 'Böyle bir parça yok',
            message: 'Bu üründe "$partId" diye bir parça bulunamadı.',
          ),
        },
        AsyncError() => const EmptyState(
          icon: Icons.cloud_off,
          title: 'Parça okunamadı',
          message: 'Ürünün içeriği sunucudan alınamadı.',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PartView extends StatelessWidget {
  const _PartView({
    required this.content,
    required this.part,
    required this.onOpenModule,
    required this.onOpenPart,
  });

  final ProductContent content;
  final Part part;
  final ValueChanged<String> onOpenModule;
  final ValueChanged<String> onOpenPart;

  @override
  Widget build(BuildContext context) {
    final faults = content.faultsFor(part.id);
    final procedures = part.procedures.entries.toList()
      ..sort((a, b) => _rank(a.key).compareTo(_rank(b.key)));
    final children = content.childrenOf(part.id);
    final description = content.descriptionFor(part.id);
    final modules = content.modulesAbout(part.id);

    // Bölümler yalnız içeriği varsa görünür; numaraları sıraya göre verilir.
    final sections = <(String, String, Widget)>[
      if (description != null)
        (
          'Anlatım',
          'Nasıl çalışır',
          _Description(
            productId: content.productId,
            dmc: description,
            onOpen: () => onOpenModule(description),
          ),
        ),
      if (modules.isNotEmpty)
        (
          'Şemalar',
          'Çizimler',
          _FigureGallery(productId: content.productId, modules: modules),
        ),
      (
        'Arızalar',
        'Nasıl bozulur, nasıl onarılır',
        _FaultList(
          content: content,
          part: part,
          faults: faults,
          onOpenModule: onOpenModule,
        ),
      ),
      if (procedures.isNotEmpty)
        (
          'Bakım',
          'Prosedürler',
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, entry) in procedures.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.colors.line),
                  _ProcedureTile(
                    productId: content.productId,
                    kind: _procedureLabels[entry.key] ?? entry.key,
                    dmc: entry.value,
                    onTap: () => onOpenModule(entry.value),
                  ),
                ],
              ],
            ),
          ),
        ),
      if (part.ipd != null || children.isNotEmpty)
        (
          'Katalog',
          'Parçalar',
          _Catalog(
            part: part,
            children: children,
            onOpenModule: onOpenModule,
            onOpenPart: onOpenPart,
          ),
        ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Hero(
            content: content,
            part: part,
            faultCount: faults.length,
            procedureCount: procedures.length,
          ),
        ),
        for (final (i, (label, title, body)) in sections.indexed)
          SliverToBoxAdapter(
            child: _Section(
              number: i + 1,
              label: label,
              title: title,
              child: body,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: NayaSpace.xxxl)),
      ],
    );
  }

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

  static int _rank(String kind) {
    final i = _procedureOrder.indexOf(kind);
    return i < 0 ? _procedureOrder.length : i;
  }
}

/// Sayfanın içeriğini ortalar ve genişliğini sınırlar.
class _Column extends StatelessWidget {
  const _Column({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PartPage.maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NayaSpace.gutter),
          child: child,
        ),
      ),
    );
  }
}

/// Üst kısım: geri, yol, büyük ad, ne işe yaradığı ve kısa sayılar.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.content,
    required this.part,
    required this.faultCount,
    required this.procedureCount,
  });

  final ProductContent content;
  final Part part;
  final int faultCount;
  final int procedureCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = content.pathTo(part.id);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.viewportTop, c.background],
        ),
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: _Column(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: NayaSpace.md),
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Geri',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: NayaSpace.md),
                  Expanded(
                    child: TechLabel(
                      [for (final p in path.take(path.length - 1)) p.name]
                          .join('  ›  '),
                    ),
                  ),
                ],
              ),
              SizedBox(height: wide ? NayaSpace.xxxl : NayaSpace.xl),
              Wrap(
                spacing: NayaSpace.md,
                runSpacing: NayaSpace.xs,
                children: [
                  if (part.sns != null) TechLabel('SNS ${part.sns}'),
                  TechLabel('Parça', color: c.accent),
                ],
              ),
              const SizedBox(height: NayaSpace.sm),
              Text(
                part.name,
                style: context.text.display.copyWith(
                  fontSize: wide ? 56 : 40,
                  height: 1.02,
                  letterSpacing: wide ? -1.6 : -1,
                  color: c.text,
                ),
              ),
              if (part.function != null) ...[
                const SizedBox(height: NayaSpace.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    part.function!,
                    style: context.text.body.copyWith(
                      fontSize: wide ? 19 : 16,
                      height: 1.5,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: NayaSpace.xl),
              Wrap(
                spacing: NayaSpace.xxl,
                runSpacing: NayaSpace.md,
                children: [
                  _Stat(value: faultCount, label: 'Olası arıza'),
                  _Stat(value: procedureCount, label: 'Prosedür'),
                  _Stat(
                    value: content.childrenOf(part.id).length,
                    label: 'Alt parça',
                  ),
                ],
              ),
              const SizedBox(height: NayaSpace.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: context.text.mono.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: c.text,
          ),
        ),
        const SizedBox(height: 2),
        TechLabel(label),
      ],
    );
  }
}

/// Numaralı bölüm: solda "01", başlık ve içerik.
class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.label,
    required this.title,
    required this.child,
  });

  final int number;
  final String label;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Column(
      child: Padding(
        padding: const EdgeInsets.only(top: NayaSpace.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  number.toString().padLeft(2, '0'),
                  style: context.text.mono.copyWith(
                    fontSize: 13,
                    color: c.accent,
                  ),
                ),
                const SizedBox(width: NayaSpace.md),
                Expanded(
                  child: SectionHeader(label: label, title: title),
                ),
              ],
            ),
            const SizedBox(height: NayaSpace.lg),
            child,
          ],
        ),
      ),
    );
  }
}

/// Sistemin tanıtım DM'inden ilk bölümler; tamamı okuyucuda.
class _Description extends ConsumerWidget {
  const _Description({
    required this.productId,
    required this.dmc,
    required this.onOpen,
  });

  final String productId;
  final String dmc;
  final VoidCallback onOpen;

  static const shownSections = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final module = ref.watch(
      dataModuleProvider((productId: productId, dmc: dmc)),
    );
    final doc = module.value;
    if (doc == null) {
      return module.hasError
          ? const SizedBox.shrink()
          : const SkeletonBlock(height: 120);
    }
    final sections = doc.blocks.whereType<DmSection>().toList();
    final loose = [
      for (final b in doc.blocks.whereType<DmParagraph>()) b.text.text,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final text in loose.take(2)) ...[
          Text(text, style: context.text.body.copyWith(color: c.text)),
          const SizedBox(height: NayaSpace.md),
        ],
        for (final section in sections.take(shownSections)) ...[
          Text(
            section.title,
            style: context.text.heading.copyWith(color: c.text),
          ),
          const SizedBox(height: NayaSpace.xs),
          for (final p in section.blocks.whereType<DmParagraph>().take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: NayaSpace.sm),
              child: Text(p.text.text, style: context.text.body),
            ),
          const SizedBox(height: NayaSpace.md),
        ],
        TextButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: Text('Tamamını oku · ${doc.techName}'),
        ),
      ],
    );
  }
}

/// Parçayla ilgili DM'lerdeki bütün çizimler, yan yana kaydırılır.
class _FigureGallery extends ConsumerWidget {
  const _FigureGallery({required this.productId, required this.modules});

  final String productId;
  final List<String> modules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = [
      for (final dmc in modules)
        ref.watch(dataModuleProvider((productId: productId, dmc: dmc))),
    ];
    final seen = <String>{};
    final figures = [
      for (final module in loaded)
        if (module.value case final doc?)
          for (final figure in _figuresIn(doc.blocks))
            if (seen.add(figure.icns.join('|'))) figure,
    ];
    if (figures.isEmpty) {
      final waiting = loaded.any((m) => m.isLoading);
      return waiting
          ? const SkeletonBlock(height: 220)
          : Text('Bu parça için çizim yok.', style: context.text.small);
    }
    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: figures.length,
        separatorBuilder: (_, _) => const SizedBox(width: NayaSpace.lg),
        // Bir şekilde birden çok çizim olabilir; kart kendi içinde kayar.
        itemBuilder: (context, i) => SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: DmFigureView(figures[i], productId: productId),
          ),
        ),
      ),
    );
  }

  /// Adımların ve bölümlerin içindekiler dahil.
  static Iterable<DmFigure> _figuresIn(List<DmBlock> blocks) sync* {
    for (final block in blocks) {
      switch (block) {
        case DmFigure():
          yield block;
        case DmStep(:final blocks) || DmSection(:final blocks):
          yield* _figuresIn(blocks);
        default:
          break;
      }
    }
  }
}

/// Arızalar, en ciddisi önce. İlki açık gelir; açılan arızanın belirtileri
/// ve onarım prosedürü (adımlarıyla) sayfada görünür.
class _FaultList extends StatelessWidget {
  const _FaultList({
    required this.content,
    required this.part,
    required this.faults,
    required this.onOpenModule,
  });

  final ProductContent content;
  final Part part;
  final List<Fault> faults;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    if (faults.isEmpty) {
      return Text(
        'Bu parça için kayıtlı arıza yok.',
        style: context.text.small,
      );
    }
    return Column(
      children: [
        for (final (i, fault) in faults.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NayaSpace.md),
            child: _FaultCard(
              key: ValueKey(fault.id),
              productId: content.productId,
              fault: fault,
              partName: fault.part == part.id
                  ? null
                  : content.part(fault.part)?.name,
              symptoms: [
                for (final s in fault.symptoms) content.symptomText(s),
              ],
              initiallyOpen: i == 0,
              onOpenModule: onOpenModule,
            ),
          ),
      ],
    );
  }
}

class _FaultCard extends StatefulWidget {
  const _FaultCard({
    super.key,
    required this.productId,
    required this.fault,
    required this.symptoms,
    required this.initiallyOpen,
    required this.onOpenModule,
    this.partName,
  });

  final String productId;
  final Fault fault;
  final List<String> symptoms;
  final bool initiallyOpen;
  final ValueChanged<String> onOpenModule;

  /// Arıza bir alt parçadaysa onun adı.
  final String? partName;

  @override
  State<_FaultCard> createState() => _FaultCardState();
}

class _FaultCardState extends State<_FaultCard> {
  late var _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fault = widget.fault;
    return Panel(
      raised: _open,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: const BorderRadius.all(NayaRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(NayaSpace.lg),
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
                        if (widget.partName != null) ...[
                          TechLabel(widget.partName!),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          fault.cause,
                          style: context.text.body.copyWith(
                            color: c.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: NayaMotion.base,
                    child: Icon(Icons.expand_more, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: NayaMotion.base,
            curve: NayaMotion.standard,
            alignment: Alignment.topCenter,
            child: _open
                ? _details(context)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context) {
    final c = context.colors;
    final fault = widget.fault;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NayaSpace.lg,
        0,
        NayaSpace.lg,
        NayaSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.symptoms.isNotEmpty) ...[
            const TechLabel('Belirtiler'),
            const SizedBox(height: NayaSpace.sm),
            for (final symptom in widget.symptoms)
              Padding(
                padding: const EdgeInsets.only(bottom: NayaSpace.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 10),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.accent,
                        ),
                      ),
                    ),
                    Expanded(child: Text(symptom, style: context.text.body)),
                  ],
                ),
              ),
            const SizedBox(height: NayaSpace.lg),
          ],
          if (fault.repair case final dmc?)
            ProcedurePreview(
              productId: widget.productId,
              dmc: dmc,
              onOpen: () => widget.onOpenModule(dmc),
            ),
          if (fault.isolation case final dmc?) ...[
            const SizedBox(height: NayaSpace.sm),
            TextButton.icon(
              onPressed: () => widget.onOpenModule(dmc),
              icon: const Icon(Icons.manage_search, size: 18),
              label: const Text('Emin değilseniz: arızayı adım adım bulun'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Prosedür satırı: türü, DM başlığı ve kaç adım olduğu.
class _ProcedureTile extends ConsumerWidget {
  const _ProcedureTile({
    required this.productId,
    required this.kind,
    required this.dmc,
    required this.onTap,
  });

  final String productId;
  final String kind;
  final String dmc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final doc = ref
        .watch(dataModuleProvider((productId: productId, dmc: dmc)))
        .value;
    final steps = doc == null ? 0 : stepTexts(doc).length;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(NayaSpace.lg),
        child: Row(
          children: [
            SizedBox(width: 96, child: TechLabel(kind)),
            const SizedBox(width: NayaSpace.md),
            Expanded(
              child: Text(
                doc == null ? dmc : [doc.techName, ?doc.infoName].join(' · '),
                overflow: TextOverflow.ellipsis,
                style: context.text.body.copyWith(color: c.text),
              ),
            ),
            if (steps > 0) ...[
              const SizedBox(width: NayaSpace.md),
              TechLabel('$steps adım'),
            ],
            const SizedBox(width: NayaSpace.sm),
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Parça kataloğundaki yeri ve alt parçalar.
class _Catalog extends StatelessWidget {
  const _Catalog({
    required this.part,
    required this.children,
    required this.onOpenModule,
    required this.onOpenPart,
  });

  final Part part;
  final List<Part> children;
  final ValueChanged<String> onOpenModule;
  final ValueChanged<String> onOpenPart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (part.ipd case final ipd?)
          Panel(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => onOpenModule(ipd.dmc),
              child: Padding(
                padding: const EdgeInsets.all(NayaSpace.lg),
                child: Row(
                  children: [
                    Icon(Icons.view_list_outlined, color: c.textMuted),
                    const SizedBox(width: NayaSpace.md),
                    Expanded(
                      child: Text(
                        'Parça kataloğu · Şekil ${ipd.figure} · '
                        'Öğe ${ipd.item}',
                        style: context.text.body.copyWith(color: c.text),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                  ],
                ),
              ),
            ),
          ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.lg),
          Wrap(
            spacing: NayaSpace.sm,
            runSpacing: NayaSpace.sm,
            children: [
              for (final child in children)
                SuggestionChip(child.name, onTap: () => onOpenPart(child.id)),
            ],
          ),
        ],
      ],
    );
  }
}
