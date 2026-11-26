import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/product/product.dart';
import '../../entities/product/product_card.dart';
import '../../entities/product/product_library.dart';
import '../../entities/session/session.dart';
import '../../features/export_naya/file_actions.dart';
import '../../features/prefetch_models/prefetch_models.dart';
import '../../features/search_library/library_search.dart';
import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/naya_emblem.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Açılış ekranı: hazır şablonlar ve kullanıcının dosyaları.
///
/// Ürün açılınca nereye gidileceğini sayfa bilmez; [onOpen] ile app
/// katmanına bırakır (bir sayfa diğerini import edemez).
class LibraryPage extends ConsumerWidget {
  const LibraryPage({
    super.key,
    required this.onOpen,
    this.onOpenSettings,
    this.onSignIn,
    this.onImport,
  });

  final ValueChanged<Product> onOpen;
  final VoidCallback? onOpenSettings;

  /// İçe aktarma sihirbazı.
  final VoidCallback? onImport;

  /// Misafirken avatara dokunulunca.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(filteredLibraryProvider);
    // Kütüphane gelince modeller arka planda iner (Android). Önce
    // şablonlar, sonra kullanıcının dosyaları. Her yeniden çizimde
    // çağrılabilir; istenmiş model yeniden kuyruğa girmez.
    if (ref.watch(productLibraryProvider).value case final all?) {
      prefetchLibraryModels(ref.read(apiClientProvider), [
        ...all.templates,
        ...all.userFiles,
      ]);
    }
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 720;
          final columns = box.maxWidth >= 1100 ? 4 : (wide ? 2 : 1);
          final gutter = wide ? NayaSpace.xxxl : NayaSpace.gutter;
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverList.list(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: _Header(
                        onOpenSettings: onOpenSettings,
                        onSignIn: onSignIn,
                      ),
                    ),
                    SizedBox(height: wide ? NayaSpace.xxxl : NayaSpace.xxl),
                    const _Hero(),
                    SizedBox(height: wide ? NayaSpace.xxxl : NayaSpace.xxl),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, NayaSpace.xxxl),
                sliver: SliverMainAxisGroup(
                  slivers: library.when(
                    skipLoadingOnRefresh: false,
                    loading: () => [_LoadingGrid.sliver(columns)],
                    error: (_, _) => [
                      SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Kütüphane yüklenemedi',
                          message: 'Bağlantını kontrol edip yeniden dene.',
                          actionLabel: 'Yeniden dene',
                          onAction: () =>
                              ref.invalidate(productLibraryProvider),
                        ),
                      ),
                    ],
                    data: (data) => _contentSlivers(
                      context,
                      data,
                      columns,
                      ref.read(apiClientProvider),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    ProductLibrary library,
    int columns,
    ApiClient api,
  ) {
    if (library.templates.isEmpty && library.userFiles.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off,
            title: 'Sonuç bulunamadı',
            message: 'Başka bir kelimeyle aramayı dene.',
          ),
        ),
      ];
    }
    return [
      if (library.templates.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            label: '${library.templates.length} ürün',
            title: 'Hazır şablonlar',
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: NayaSpace.lg)),
        SliverGrid.builder(
          itemCount: library.templates.length,
          gridDelegate: _gridDelegate(columns),
          itemBuilder: (context, i) => ProductCard(
            product: library.templates[i],
            index: i,
            onOpen: () => onOpen(library.templates[i]),
            onHover: () => prefetchModel(api, library.templates[i]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: NayaSpace.xxxl)),
      ],
      SliverList.list(
        children: [
          const SectionHeader(label: 'Senin', title: 'Dosyalarım'),
          const SizedBox(height: NayaSpace.lg),
          for (final file in library.userFiles)
            Padding(
              padding: const EdgeInsets.only(bottom: NayaSpace.sm),
              child: _FileRow(file, onOpen: () => onOpen(file)),
            ),
          const SizedBox(height: NayaSpace.sm),
          _ImportTile(onTap: onImport),
        ],
      ),
    ];
  }
}

SliverGridDelegate _gridDelegate(int columns) =>
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: NayaSpace.lg,
      crossAxisSpacing: NayaSpace.lg,
      mainAxisExtent: 260,
    );

/// Kartların yerini tutan iskelet; yüklenince düzen zıplamasın diye aynı ızgara.
abstract final class _LoadingGrid {
  static Widget sliver(int columns) => SliverGrid.builder(
    itemCount: 4,
    gridDelegate: _gridDelegate(columns),
    itemBuilder: (context, _) => const SkeletonBlock(),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _Header extends ConsumerWidget {
  const _Header({this.onOpenSettings, this.onSignIn});

  final VoidCallback? onOpenSettings;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final account = ref.watch(sessionProvider).value;
    return Padding(
      padding: const EdgeInsets.only(top: NayaSpace.lg),
      child: Row(
        children: [
          const NayaEmblem(size: 26),
          const SizedBox(width: NayaSpace.md),
          const NayaWordmark(height: 11),
          const Spacer(),
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: onOpenSettings,
            icon: Icon(Icons.tune, color: c.textSecondary),
          ),
          const SizedBox(width: NayaSpace.xs),
          // Misafirse giriş, giriş yapılmışsa hesap ayarları açılır.
          Tooltip(
            message: account?.email ?? 'Giriş yap',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: account == null ? onSignIn : onOpenSettings,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: account == null ? c.surfaceRaised : c.accent,
                child: account == null
                    ? Icon(Icons.person_outline, size: 18, color: c.text)
                    : Text(
                        account.initial,
                        style: context.text.small.copyWith(
                          color: c.onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TechLabel('Kütüphane'),
        const SizedBox(height: NayaSpace.md),
        Text('Neyi inceliyoruz?', style: context.text.display),
        const SizedBox(height: NayaSpace.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Bir ürün aç, sorunu anlat. NAYA parçaları tarar, en olası '
            'parçayı bulur ve tamirin adımlarını gösterir.',
            style: context.text.body,
          ),
        ),
        const SizedBox(height: NayaSpace.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const LibrarySearchField(),
        ),
      ],
    );
  }
}

enum _FileAction { open, export, delete }

class _FileRow extends ConsumerWidget {
  const _FileRow(this.file, {required this.onOpen});

  final Product file;
  final VoidCallback onOpen;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    _FileAction action,
  ) async {
    final api = ref.read(apiClientProvider);
    switch (action) {
      case _FileAction.open:
        onOpen();
      case _FileAction.export:
        try {
          final saved = await exportNaya(api, file);
          if (saved && context.mounted) {
            _showMessage(context, '${nayaFileName(file.title)} kaydedildi.');
          }
        } on ApiException catch (e) {
          if (context.mounted) _showMessage(context, e.message);
        }
      case _FileAction.delete:
        final sure = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dosya silinsin mi?'),
            content: Text(
              '“${file.title}” kütüphanenden kalkar. Geri almak için '
              '.naya olarak indirdiysen yeniden içe aktarabilirsin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
        if (sure != true) return;
        try {
          await deleteUserFile(api, file);
          ref.invalidate(productLibraryProvider);
        } on ApiException catch (e) {
          if (context.mounted) _showMessage(context, e.message);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: const BorderRadius.all(NayaRadius.md),
        child: _row(context, ref, c),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, NayaColors c) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(
        NayaSpace.lg,
        NayaSpace.md,
        NayaSpace.xs,
        NayaSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: const BorderRadius.all(NayaRadius.sm),
            ),
            // Süs; ekran okuyucu satırın adını okusun, rozeti değil.
            child: ExcludeSemantics(
              child: Text(
                '.naya',
                style: context.text.label.copyWith(fontSize: 9),
              ),
            ),
          ),
          const SizedBox(width: NayaSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: context.text.body.copyWith(color: c.text),
                ),
                Text(file.subtitle, style: context.text.small),
              ],
            ),
          ),
          TechLabel('${file.moduleCount} DM'),
          PopupMenuButton<_FileAction>(
            tooltip: 'Dosya işlemleri',
            icon: Icon(Icons.more_horiz, color: c.textMuted),
            onSelected: (action) => _act(context, ref, action),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _FileAction.open, child: Text('Aç')),
              PopupMenuItem(
                value: _FileAction.export,
                child: Text('.naya olarak indir'),
              ),
              PopupMenuItem(value: _FileAction.delete, child: Text('Sil')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(NayaRadius.md),
      child: CustomPaint(
        painter: _DashedBorder(c.lineStrong),
        child: Padding(
          padding: const EdgeInsets.all(NayaSpace.lg),
          child: Row(
            children: [
              Icon(Icons.add, color: c.accent),
              const SizedBox(width: NayaSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'S1000D paketi içe aktar',
                      style: context.text.body.copyWith(color: c.text),
                    ),
                    Text(
                      '.zip ya da .naya dosyası seç',
                      style: context.text.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, NayaRadius.md));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
