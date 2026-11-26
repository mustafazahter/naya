import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/product/product.dart';
import '../../entities/product/product_library.dart';
import '../../entities/session/session.dart';
import '../../features/export_naya/file_actions.dart';
import '../../features/import_zip/import_package.dart';
import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/page_shell.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// İçe aktarma sihirbazı: dosya seç → sunucuda tara ve ayrıştır → raporu
/// gör → aç ya da vazgeçip kaldır.
///
/// S1000D zip'inde sunucu montaj ağacını SNS'ten, arızaları arıza bulma
/// DM'lerinden kurar ve şematik bir 3D model çizer. Daha önce dışa
/// aktarılmış `.naya` olduğu gibi eklenir.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key, required this.onOpen, required this.onSignIn});

  final ValueChanged<Product> onOpen;
  final VoidCallback onSignIn;

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

sealed class _Stage {
  const _Stage();
}

class _Choosing extends _Stage {
  const _Choosing();
}

class _Working extends _Stage {
  const _Working(this.package);
  final PickedPackage package;
}

class _Done extends _Stage {
  const _Done(this.outcome);
  final ImportOutcome outcome;
}

class _Failed extends _Stage {
  const _Failed(this.message);
  final String message;
}

class _ImportPageState extends ConsumerState<ImportPage> {
  _Stage _stage = const _Choosing();
  var _removing = false;

  Future<void> _choose() async {
    final PickedPackage? package;
    try {
      package = await pickPackage();
    } on ImportFailure catch (e) {
      setState(() => _stage = _Failed(e.message));
      return;
    }
    if (package == null || !mounted) return;
    setState(() => _stage = _Working(package!));
    // Yükleme sürerken sayfadan çıkılırsa `ref` kullanılamaz; kütüphane yine
    // yenilensin diye kapsayıcı baştan alınır.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final outcome = await uploadPackage(ref.read(apiClientProvider), package);
      container.invalidate(productLibraryProvider);
      if (mounted) setState(() => _stage = _Done(outcome));
    } on ImportFailure catch (e) {
      if (mounted) setState(() => _stage = _Failed(e.message));
    }
  }

  /// Rapor beğenilmediyse eklenen dosya geri alınır.
  Future<void> _remove(Product product) async {
    setState(() => _removing = true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await deleteUserFile(ref.read(apiClientProvider), product);
      container.invalidate(productLibraryProvider);
      if (mounted) setState(() => _stage = const _Choosing());
    } on ApiException catch (e) {
      if (mounted) setState(() => _stage = _Failed(e.message));
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final signedIn = session.value != null;
    return PageShell(
      label: 'İçe aktarma',
      title: 'S1000D paketini getir',
      intro:
          'Dağınık S1000D dosyalarını zip olarak seç. NAYA tarar, '
          'ayrıştırır ve sistem numaralarından şematik bir 3D model kurar.',
      children: [
        AnimatedSwitcher(
          duration: NayaMotion.base,
          child: switch (_stage) {
            _ when session.isLoading => const SkeletonBlock(height: 200),
            _ when !signedIn => _SignInFirst(onSignIn: widget.onSignIn),
            _Choosing() => _ChooseCard(onChoose: _choose),
            _Working(:final package) => _WorkingCard(package: package),
            _Done(:final outcome) => _ReportCard(
              outcome: outcome,
              removing: _removing,
              onOpen: () => widget.onOpen(outcome.product),
              onRemove: () => _remove(outcome.product),
            ),
            _Failed(:final message) => _FailedCard(
              message: message,
              onRetry: _choose,
            ),
          },
        ),
      ],
    );
  }
}

class _SignInFirst extends StatelessWidget {
  const _SignInFirst({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'İçe aktardığın dosyalar hesabına kaydedilir; önce giriş yap.',
            style: context.text.body,
          ),
          const SizedBox(height: NayaSpace.lg),
          PrimaryButton(
            label: 'Giriş yap',
            icon: Icons.login,
            onPressed: onSignIn,
          ),
        ],
      ),
    );
  }
}

class _ChooseCard extends StatelessWidget {
  const _ChooseCard({required this.onChoose});

  final VoidCallback onChoose;

  static const _steps = [
    ('Tara', 'DM, PM, DML ve çizimler bulunur; okunamayanlar listelenir.'),
    (
      'Ayrıştır',
      'Sistem numaralarından montaj ağacı, arıza bulma DM’lerinden arızalar.',
    ),
    ('Çiz', 'Modeli olmayan veri için her parçaya bir blok: şematik 3D.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (title, text)) in _steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NayaSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    (i + 1).toString().padLeft(2, '0'),
                    style: context.text.mono.copyWith(color: c.accent),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.heading),
                      const SizedBox(height: NayaSpace.xs),
                      Text(text, style: context.text.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: NayaSpace.md),
        PrimaryButton(
          label: 'Dosya seç',
          icon: Icons.upload_file,
          onPressed: onChoose,
        ),
        const SizedBox(height: NayaSpace.md),
        Text(
          '.zip (S1000D dosyaları) ya da daha önce indirilmiş .naya · '
          'en çok 50 MB',
          textAlign: TextAlign.center,
          style: context.text.small,
        ),
      ],
    );
  }
}

class _WorkingCard extends StatelessWidget {
  const _WorkingCard({required this.package});

  final PickedPackage package;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FileLine(name: package.name, bytes: package.bytes.length),
          const SizedBox(height: NayaSpace.lg),
          ClipRRect(
            borderRadius: const BorderRadius.all(NayaRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: c.accent,
              backgroundColor: c.line,
            ),
          ),
          const SizedBox(height: NayaSpace.md),
          TechLabel(
            package.isNaya
                ? 'Yükleniyor ve doğrulanıyor'
                : 'Yükleniyor, taranıyor ve ayrıştırılıyor',
          ),
        ],
      ),
    );
  }
}

class _FileLine extends StatelessWidget {
  const _FileLine({required this.name, required this.bytes});

  final String name;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB'
        : '${(bytes / 1024).ceil()} KB';
    return Row(
      children: [
        Icon(Icons.folder_zip_outlined, color: c.textSecondary),
        const SizedBox(width: NayaSpace.md),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.body.copyWith(color: c.text),
          ),
        ),
        const SizedBox(width: NayaSpace.md),
        TechLabel(size),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.outcome,
    required this.removing,
    required this.onOpen,
    required this.onRemove,
  });

  final ImportOutcome outcome;
  final bool removing;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final product = outcome.product;
    final summary = outcome.summary;
    final stats = [
      ('DM', summary?.dataModules ?? product.moduleCount),
      ('Parça', summary?.parts ?? product.partCount),
      ('Arıza', summary?.faults ?? product.faultCount),
      if (summary != null) ('Çizim', summary.illustrations),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: c.accent, size: 20),
            const SizedBox(width: NayaSpace.sm),
            TechLabel('Kütüphaneye eklendi', color: c.accent),
          ],
        ),
        const SizedBox(height: NayaSpace.sm),
        Text(product.title, style: context.text.title),
        if (summary != null && summary.issue.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.xs),
          Text('S1000D ${summary.issue}', style: context.text.small),
        ],
        const SizedBox(height: NayaSpace.xl),
        Row(
          children: [
            for (final (i, (label, value)) in stats.indexed) ...[
              if (i > 0) const SizedBox(width: NayaSpace.sm),
              Expanded(
                child: _Stat(label: label, value: value),
              ),
            ],
          ],
        ),
        if (summary != null && summary.systems.isNotEmpty) ...[
          const SizedBox(height: NayaSpace.xl),
          const TechLabel('Sistemler'),
          const SizedBox(height: NayaSpace.sm),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, s) in summary.systems.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NayaSpace.lg,
                      vertical: NayaSpace.md,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            s.code,
                            style: context.text.mono.copyWith(color: c.accent),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s.title,
                            style: context.text.body.copyWith(color: c.text),
                          ),
                        ),
                        TechLabel('${s.parts} alt parça'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (summary != null) ...[
          const SizedBox(height: NayaSpace.lg),
          _Findings(
            title: 'Okunamayan dosya',
            items: summary.unreadable,
            warning: true,
          ),
          _Findings(title: 'Pakette olmayan başvuru', items: summary.missing),
          _Findings(title: 'S1000D dışı, atlanan', items: summary.skipped),
        ],
        const SizedBox(height: NayaSpace.xl),
        PrimaryButton(
          label: 'Aç',
          icon: Icons.view_in_ar_outlined,
          onPressed: removing ? null : onOpen,
        ),
        const SizedBox(height: NayaSpace.sm),
        TextButton(
          onPressed: removing ? null : onRemove,
          child: Text(
            removing ? 'Kaldırılıyor…' : 'Vazgeç ve kaldır',
            style: context.text.body.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: NayaSpace.md,
        vertical: NayaSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: context.text.title.copyWith(
              color: c.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: NayaSpace.xs),
          TechLabel(label),
        ],
      ),
    );
  }
}

/// Raporun uyarı listeleri; boşsa hiç görünmez, uzunsa açılıp kapanır.
class _Findings extends StatelessWidget {
  const _Findings({
    required this.title,
    required this.items,
    this.warning = false,
  });

  final String title;
  final List<String> items;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: NayaSpace.md),
        leading: Icon(
          warning ? Icons.error_outline : Icons.info_outline,
          size: 20,
          color: warning ? c.danger : c.textSecondary,
        ),
        title: Text(
          '$title · ${items.length}',
          style: context.text.body.copyWith(color: c.text),
        ),
        iconColor: c.textSecondary,
        collapsedIconColor: c.textMuted,
        children: [
          for (final item in items.take(50))
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: NayaSpace.xs),
                child: Text(item, style: context.text.small),
              ),
            ),
          if (items.length > 50)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                've ${items.length - 50} tane daha',
                style: context.text.small,
              ),
            ),
        ],
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: c.danger),
              const SizedBox(width: NayaSpace.md),
              Expanded(
                child: Text(
                  message,
                  style: context.text.body.copyWith(color: c.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: NayaSpace.lg),
          PrimaryButton(
            label: 'Başka dosya seç',
            icon: Icons.upload_file,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
