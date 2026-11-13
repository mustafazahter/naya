import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import '../../entities/product/product_content.dart';
import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// DM okuyucu: bir S1000D veri modülünü okunur adımlar olarak gösterir.
///
/// Prosedürde adımlar işaretlenebilir; arıza bulmada sorular tek tek
/// sorulur ve cevaplara göre sonuca gidilir.
class DataModulePage extends ConsumerWidget {
  const DataModulePage({
    super.key,
    required this.productId,
    required this.dmc,
    required this.onOpenModule,
  });

  final String productId;
  final String dmc;

  /// Başvurulan başka bir DM'i açar.
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (productId: productId, dmc: dmc);
    final module = ref.watch(dataModuleProvider(key));
    return Scaffold(
      body: switch (module) {
        AsyncData(:final value) => _Reader(
          doc: value,
          productId: productId,
          onOpenModule: onOpenModule,
        ),
        AsyncError(:final error) => _Message(
          child: EmptyState(
            icon: Icons.description_outlined,
            title: 'DM açılamadı',
            message: error is ApiException
                ? error.message
                : 'Dosya okunamadı ya da bozuk.',
            actionLabel: 'Yeniden dene',
            onAction: () {
              // DM, ürünün içerik listesine bağlı; o da hata verdiyse
              // yalnız DM'i yenilemek aynı hatayı tekrar okur.
              if (ref.read(productContentProvider(productId)).hasError) {
                ref.invalidate(productContentProvider(productId));
              }
              ref.invalidate(dataModuleProvider(key));
            },
          ),
        ),
        _ => const _Message(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const _BackRow(),
        Expanded(child: Center(child: child)),
      ],
    ),
  );
}

class _BackRow extends StatelessWidget {
  const _BackRow({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      NayaSpace.md,
      NayaSpace.md,
      NayaSpace.gutter,
      0,
    ),
    child: Row(
      children: [
        RoundIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}

/// Okuyucunun gövdesi. İşaretlenen adımlar yalnız bu ekranda tutulur.
class _Reader extends StatefulWidget {
  const _Reader({
    required this.doc,
    required this.productId,
    required this.onOpenModule,
  });

  final DmDocument doc;
  final String productId;
  final ValueChanged<String> onOpenModule;

  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  final _done = <String>{};

  DmDocument get doc => widget.doc;

  List<DmStep> get _steps => doc.blocks.whereType<DmStep>().toList();

  static const _kinds = {
    'procedure': 'Prosedür',
    'faultIsolation': 'Arıza bulma',
    'description': 'Tanım',
    'illustratedPartsCatalog': 'Parça kataloğu',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final steps = _steps;
    final progress = steps.isEmpty ? null : _done.length / steps.length;
    final ctx = _ReaderContext(
      productId: widget.productId,
      onOpenModule: widget.onOpenModule,
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _BackRow(
            trailing: TechLabel(
              steps.isEmpty
                  ? _kinds[doc.contentType] ?? doc.contentType
                  : '${_done.length} / ${steps.length} adım',
              color: _done.length == steps.length && steps.isNotEmpty
                  ? c.accent
                  : null,
            ),
          ),
          const SizedBox(height: NayaSpace.md),
          // İnce ilerleme çizgisi; yalnız prosedürde.
          SizedBox(
            height: 2,
            child: progress == null
                ? null
                : TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: NayaMotion.base,
                    curve: NayaMotion.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 2,
                      backgroundColor: c.line,
                      color: c.accent,
                    ),
                  ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    NayaSpace.gutter,
                    NayaSpace.xl,
                    NayaSpace.gutter,
                    NayaSpace.xxxl,
                  ),
                  children: [
                    TechLabel(_kinds[doc.contentType] ?? doc.contentType),
                    const SizedBox(height: NayaSpace.sm),
                    Text(doc.techName, style: context.text.display),
                    if (doc.infoName != null)
                      Text(
                        doc.infoName!,
                        style: context.text.title.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    const SizedBox(height: NayaSpace.md),
                    SelectableText(
                      '${doc.code}',
                      style: context.text.mono.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                    if (doc.requirements case final r?) ...[
                      const SizedBox(height: NayaSpace.xxl),
                      _Requirements(r, ctx: ctx),
                    ],
                    const SizedBox(height: NayaSpace.xxl),
                    for (final block in doc.blocks)
                      if (block is DmIsolation)
                        _IsolationFlow(blocks: block.blocks, ctx: ctx)
                      else if (block is DmStep)
                        _StepTile(
                          step: block,
                          done: _done.contains(block.number),
                          isLast: block == steps.last,
                          ctx: ctx,
                          onToggle: () => setState(() {
                            if (!_done.remove(block.number)) {
                              _done.add(block.number);
                            }
                          }),
                        )
                      else
                        _Block(block, ctx: ctx),
                    if (doc.closing.isNotEmpty) ...[
                      const SizedBox(height: NayaSpace.xxl),
                      const SectionHeader(
                        label: 'Bitince',
                        title: 'Sonraki işlem',
                      ),
                      const SizedBox(height: NayaSpace.md),
                      for (final block in doc.closing) _Block(block, ctx: ctx),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloklara inen bilgiler; her blokta tekrar tekrar parametre olmasın.
class _ReaderContext {
  const _ReaderContext({required this.productId, required this.onOpenModule});

  final String productId;
  final ValueChanged<String> onOpenModule;
}

class _Requirements extends StatelessWidget {
  const _Requirements(this.r, {required this.ctx});

  final DmRequirements r;
  final _ReaderContext ctx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = [
      ('Aletler', Icons.handyman_outlined, r.equipment),
      ('Sarf malzemesi', Icons.water_drop_outlined, r.supplies),
      ('Yedek parça', Icons.settings_outlined, r.spares),
    ].where((g) => g.$3.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(label: 'Hazırlık', title: 'Başlamadan önce'),
        const SizedBox(height: NayaSpace.md),
        for (final admonition in r.safety) ...[
          _AdmonitionBox(admonition),
          const SizedBox(height: NayaSpace.sm),
        ],
        if (groups.isNotEmpty || r.conditions.isNotEmpty)
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, text) in r.conditions.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  _RequirementRow(
                    icon: Icons.rule,
                    label: 'Koşul',
                    child: _RichText(text, ctx: ctx),
                  ),
                ],
                for (final (i, (label, icon, items)) in groups.indexed) ...[
                  if (i > 0 || r.conditions.isNotEmpty)
                    Divider(height: 1, color: c.line),
                  _RequirementRow(
                    icon: icon,
                    label: label,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final item in items) _ItemLine(item)],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(NayaSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.platinum),
          const SizedBox(width: NayaSpace.md),
          SizedBox(width: 104, child: TechLabel(label)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine(this.item);

  final DmItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final qty = item.quantity == null
        ? null
        : '${item.quantity}${item.unit == null || item.unit == 'EA' ? ' adet' : ' ${item.unit}'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: NayaSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: context.text.body.copyWith(color: c.text)),
          if (item.partNumber != null || qty != null)
            Text(
              [?item.partNumber, ?qty].join(' · '),
              style: context.text.mono.copyWith(
                fontSize: 11,
                color: c.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Prosedür adımı: solda numara ve adımları bağlayan çizgi. Numaraya
/// dokununca adım yapıldı olarak işaretlenir.
class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.done,
    required this.isLast,
    required this.ctx,
    required this.onToggle,
  });

  final DmStep step;
  final bool done;
  final bool isLast;
  final _ReaderContext ctx;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Semantics(
                button: true,
                checked: done,
                label: 'Adım ${step.number}',
                child: InkResponse(
                  onTap: onToggle,
                  radius: 24,
                  child: AnimatedContainer(
                    duration: NayaMotion.fast,
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? c.accent : c.surface,
                      border: Border.all(color: done ? c.accent : c.lineStrong),
                    ),
                    child: done
                        ? Icon(Icons.check, size: 18, color: c.onAccent)
                        : Text(
                            step.number.padLeft(2, '0'),
                            style: context.text.mono.copyWith(
                              fontSize: 12,
                              color: c.text,
                            ),
                          ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: NayaSpace.xs),
                    color: done ? c.accent : c.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: NayaSpace.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: NayaSpace.xl),
              child: AnimatedOpacity(
                duration: NayaMotion.fast,
                opacity: done ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step.title != null) ...[
                      Text(
                        step.title!,
                        style: context.text.heading.copyWith(color: c.text),
                      ),
                      const SizedBox(height: NayaSpace.sm),
                    ],
                    for (final block in step.blocks) _Block(block, ctx: ctx),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir bloğu çizer; iç adımlar (2.1, 2.2) burada küçük numarayla.
class _Block extends StatelessWidget {
  const _Block(this.block, {required this.ctx});

  final DmBlock block;
  final _ReaderContext ctx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final child = switch (block) {
      DmParagraph(:final text) => _RichText(text, ctx: ctx),
      final DmAdmonition a => _AdmonitionBox(a),
      final DmFigure f => _FigureView(f, ctx: ctx),
      DmList(:final items, :final ordered) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: NayaSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      ordered ? '${i + 1}.' : '•',
                      style: context.text.body.copyWith(color: c.textMuted),
                    ),
                  ),
                  Expanded(child: _RichText(item, ctx: ctx)),
                ],
              ),
            ),
        ],
      ),
      DmSection(:final title, :final blocks) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            const SizedBox(height: NayaSpace.md),
            Text(title, style: context.text.heading.copyWith(color: c.text)),
            const SizedBox(height: NayaSpace.sm),
          ],
          for (final b in blocks) _Block(b, ctx: ctx),
        ],
      ),
      DmStep(:final number, :final title, :final blocks) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                number,
                style: context.text.mono.copyWith(
                  fontSize: 12,
                  color: c.textMuted,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: context.text.body.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                for (final b in blocks) _Block(b, ctx: ctx),
              ],
            ),
          ),
        ],
      ),
      final DmCatalog catalog => _CatalogTable(catalog),
      // Arıza bulma blokları _IsolationFlow'da çiziliyor.
      DmIsolation() ||
      DmIsolationStep() ||
      DmIsolationEnd() => const SizedBox.shrink(),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: NayaSpace.md),
      child: child,
    );
  }
}

/// Metin ve içindeki DM başvuruları (başlıklarıyla bağlantı olarak).
class _RichText extends StatelessWidget {
  const _RichText(this.text, {required this.ctx});

  final DmText text;
  final _ReaderContext ctx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.text.isNotEmpty)
          Text(
            text.text,
            style: context.text.body.copyWith(color: c.text, height: 1.5),
          ),
        for (final ref in text.refs) ...[
          const SizedBox(height: NayaSpace.sm),
          _ModuleLink(code: ref, ctx: ctx),
        ],
      ],
    );
  }
}

/// Başka bir DM'e bağlantı. Başlık o DM okunarak yazılır; okunamazsa kod.
class _ModuleLink extends ConsumerWidget {
  const _ModuleLink({required this.code, required this.ctx});

  final DmCode code;
  final _ReaderContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final dmc = '$code';
    final target = ref.watch(
      dataModuleProvider((productId: ctx.productId, dmc: dmc)),
    );
    // Yalnız dosyada gerçekten yoksa bağlantı kapanır; ağ hatasında açılır,
    // okuyucu sayfası "Yeniden dene" gösterir.
    final error = target.error;
    final missing = error is ApiException && error.isNotFound;
    final title = switch (target) {
      AsyncData(:final value) => [value.techName, ?value.infoName].join(' · '),
      _ when missing => 'Bu dosyada yok',
      AsyncError() => 'Yüklenemedi',
      _ => '…',
    };
    final available = !missing;
    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: available ? () => ctx.onOpenModule(dmc) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NayaSpace.lg,
            vertical: NayaSpace.md,
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: c.platinum),
              const SizedBox(width: NayaSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.body.copyWith(color: c.text),
                    ),
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
              if (available)
                Icon(Icons.chevron_right, size: 18, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdmonitionBox extends StatelessWidget {
  const _AdmonitionBox(this.admonition);

  final DmAdmonition admonition;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, icon, color) = switch (admonition.kind) {
      DmAdmonitionKind.warning => (
        'Uyarı',
        Icons.warning_amber_rounded,
        c.danger,
      ),
      DmAdmonitionKind.caution => ('Dikkat', Icons.error_outline, c.accent),
      DmAdmonitionKind.note => ('Not', Icons.info_outline, c.platinum),
    };
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(NayaSpace.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.all(NayaRadius.md),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: NayaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TechLabel(label, color: color),
                  const SizedBox(height: NayaSpace.xs),
                  for (final p in admonition.paragraphs)
                    Text(p, style: context.text.body.copyWith(color: c.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DM'deki çizim; `.naya` içinden sunucudan gelir. Dokununca tam ekran,
/// iki parmakla yakınlaştırılabilir.
class _FigureView extends ConsumerWidget {
  const _FigureView(this.figure, {required this.ctx});

  final DmFigure figure;
  final _ReaderContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final content = ref.watch(productContentProvider(ctx.productId)).value;
    final api = ref.watch(apiClientProvider);
    final urls = [
      for (final icn in figure.icns)
        if (content?.icnPath(icn) case final path?)
          productEntryUri(api, ctx.productId, path).toString(),
    ];
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final url in urls)
          Padding(
            padding: const EdgeInsets.only(bottom: NayaSpace.sm),
            child: GestureDetector(
              onTap: () => _zoom(context, url),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(NayaRadius.md),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: c.line),
                    borderRadius: const BorderRadius.all(NayaRadius.md),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      semanticLabel: figure.title,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const SkeletonBlock(),
                      errorBuilder: (context, _, _) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (figure.title.isNotEmpty)
          Row(
            children: [
              TechLabel('Şekil · ${figure.title}'),
              const Spacer(),
              Icon(Icons.zoom_in, size: 16, color: c.textMuted),
            ],
          ),
      ],
    );
  }

  void _zoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(child: Image.network(url, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class _CatalogTable extends StatelessWidget {
  const _CatalogTable(this.catalog);

  final DmCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, item) in catalog.items.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NayaSpace.lg,
                vertical: NayaSpace.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      item.item,
                      style: context.text.mono.copyWith(
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      // Alt montajlar içeriden başlar.
                      padding: EdgeInsets.only(
                        left: (item.indenture - 1) * NayaSpace.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: context.text.body.copyWith(color: c.text),
                          ),
                          if (item.partNumber != null)
                            Text(
                              item.partNumber!,
                              style: context.text.mono.copyWith(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (item.quantity != null)
                    Text(
                      '× ${item.quantity}',
                      style: context.text.mono.copyWith(
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Arıza bulma: sorular tek tek sorulur, cevaba göre sonraki soruya ya da
/// sonuca geçilir. Verilen cevaplar üstte özet olarak kalır.
class _IsolationFlow extends StatefulWidget {
  const _IsolationFlow({required this.blocks, required this.ctx});

  final List<DmBlock> blocks;
  final _ReaderContext ctx;

  @override
  State<_IsolationFlow> createState() => _IsolationFlowState();
}

class _IsolationFlowState extends State<_IsolationFlow> {
  /// Cevaplanan sorular ve verilen cevap.
  final _answers = <(DmIsolationStep, DmChoice)>[];

  late final Map<String, DmBlock> _byId = {
    for (final b in widget.blocks)
      if (b is DmIsolationStep) b.id: b else if (b is DmIsolationEnd) b.id: b,
  };

  List<DmIsolationStep> get _steps =>
      widget.blocks.whereType<DmIsolationStep>().toList();

  /// Şu an gösterilen soru ya da sonuç.
  DmBlock? get _current {
    if (_answers.isEmpty) return _steps.firstOrNull;
    return _byId[_answers.last.$2.target];
  }

  void _answer(DmIsolationStep step, DmChoice choice) =>
      setState(() => _answers.add((step, choice)));

  static String _label(DmChoice choice) => switch (choice.kind) {
    DmAnswerKind.yes => 'Evet',
    DmAnswerKind.no => 'Hayır',
    DmAnswerKind.choice => choice.label,
    DmAnswerKind.next => 'Devam',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = _current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NayaSpace.md),
        SectionHeader(
          label: 'Adım adım',
          title: 'Arızayı bul',
          trailing: _answers.isEmpty
              ? null
              : TextButton(
                  onPressed: () => setState(_answers.clear),
                  child: const Text('Baştan başla'),
                ),
        ),
        const SizedBox(height: NayaSpace.md),
        for (final (step, choice) in _answers)
          Padding(
            padding: const EdgeInsets.only(bottom: NayaSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    step.number.padLeft(2, '0'),
                    style: context.text.mono.copyWith(
                      fontSize: 12,
                      color: c.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(step.question.text, style: context.text.small),
                ),
                const SizedBox(width: NayaSpace.md),
                TechLabel(_label(choice), color: c.accent),
              ],
            ),
          ),
        AnimatedSwitcher(
          duration: NayaMotion.base,
          switchInCurve: NayaMotion.decelerate,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: switch (current) {
            final DmIsolationStep step => _QuestionCard(
              key: ValueKey(step.id),
              step: step,
              ctx: widget.ctx,
              labelOf: _label,
              onAnswer: (choice) => _answer(step, choice),
            ),
            final DmIsolationEnd end => _ResultCard(
              key: ValueKey(end.id),
              end: end,
              ctx: widget.ctx,
            ),
            // Cevabın hedefi dosyada yoksa boş alan yerine söyle.
            _ when _answers.isNotEmpty => _MissingTarget(
              key: const ValueKey('missing'),
              onRestart: () => setState(_answers.clear),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.step,
    required this.ctx,
    required this.labelOf,
    required this.onAnswer,
  });

  final DmIsolationStep step;
  final _ReaderContext ctx;
  final String Function(DmChoice) labelOf;
  final ValueChanged<DmChoice> onAnswer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      raised: true,
      padding: const EdgeInsets.all(NayaSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TechLabel('Adım ${step.number.padLeft(2, '0')}'),
          const SizedBox(height: NayaSpace.md),
          for (final note in step.notes) _AdmonitionBox(note),
          if (step.notes.isNotEmpty) const SizedBox(height: NayaSpace.md),
          _RichText(step.action, ctx: ctx),
          const SizedBox(height: NayaSpace.lg),
          Text(
            step.question.text,
            style: context.text.title.copyWith(color: c.text),
          ),
          const SizedBox(height: NayaSpace.xl),
          Wrap(
            spacing: NayaSpace.sm,
            runSpacing: NayaSpace.sm,
            children: [
              for (final choice in step.choices)
                choice.kind == DmAnswerKind.no
                    ? OutlinedButton(
                        onPressed: () => onAnswer(choice),
                        child: Text(labelOf(choice)),
                      )
                    : FilledButton(
                        onPressed: () => onAnswer(choice),
                        child: Text(labelOf(choice)),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cevabın götürdüğü adım dosyada bulunamadı.
class _MissingTarget extends StatelessWidget {
  const _MissingTarget({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.all(NayaSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu cevabın götürdüğü adım dosyada bulunamadı.',
            style: context.text.body.copyWith(color: c.text),
          ),
          const SizedBox(height: NayaSpace.md),
          OutlinedButton(
            onPressed: onRestart,
            child: const Text('Baştan başla'),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.end, required this.ctx});

  final DmIsolationEnd end;
  final _ReaderContext ctx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(NayaSpace.xl),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(NayaRadius.lg),
        border: Border.all(color: c.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: c.accent),
              const SizedBox(width: NayaSpace.sm),
              TechLabel('Sonuç', color: c.accent),
            ],
          ),
          const SizedBox(height: NayaSpace.md),
          _RichText(end.text, ctx: ctx),
        ],
      ),
    );
  }
}
