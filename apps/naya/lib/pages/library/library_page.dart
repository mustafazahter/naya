import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/product/product.dart';
import '../../entities/product/product_card.dart';
import '../../entities/product/product_library.dart';
import '../../features/search_library/library_search.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/naya_emblem.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Açılış ekranı: hazır şablonlar ve kullanıcının dosyaları.
///
/// Ürün açılınca nereye gidileceğini sayfa bilmez; [onOpen] ile app
/// katmanına bırakır (bir sayfa diğerini import edemez).
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key, required this.onOpen});

  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(filteredLibraryProvider);
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
                    const SafeArea(bottom: false, child: _Header()),
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
                    data: (data) => _contentSlivers(context, data, columns),
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
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: NayaSpace.xxxl)),
      ],
      SliverList.list(
        children: [
          const SectionHeader(label: 'Senin', title: 'Dosyalarım'),
          const SizedBox(height: NayaSpace.lg),
          for (final file in library.userFiles) _FileRow(file),
          const SizedBox(height: NayaSpace.md),
          const _ImportTile(),
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

void _showComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what yakında geliyor.')));
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            onPressed: () => _showComingSoon(context, 'Ayarlar'),
            icon: Icon(Icons.tune, color: c.textSecondary),
          ),
          const SizedBox(width: NayaSpace.xs),
          // Hesap sistemi gelene kadar (3C) herkes misafir.
          Semantics(
            label: 'Misafir',
            child: CircleAvatar(
              radius: 16,
              backgroundColor: c.surfaceRaised,
              child: Icon(Icons.person_outline, size: 18, color: c.text),
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

class _FileRow extends StatelessWidget {
  const _FileRow(this.file);

  final Product file;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: NayaSpace.lg,
        vertical: NayaSpace.md,
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
            child: Text(
              '.naya',
              style: context.text.label.copyWith(fontSize: 9),
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
          const SizedBox(width: NayaSpace.sm),
          Icon(Icons.more_horiz, color: c.textMuted),
        ],
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => _showComingSoon(context, 'İçe aktarma'),
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
