import 'package:flutter/material.dart';

import '../../entities/product/product.dart';
import '../../entities/product/product_card.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/naya_emblem.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Açılış ekranı: hazır şablonlar ve kullanıcının dosyaları.
///
/// Ürün açılınca nereye gidileceğini sayfa bilmez; [onOpen] ile app
/// katmanına bırakır (bir sayfa diğerini import edemez).
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, required this.onOpen});

  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 720;
          final columns = box.maxWidth >= 1100 ? 4 : (wide ? 2 : 1);
          final gutter = wide ? NayaSpace.xxxl : NayaSpace.gutter;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
                sliver: SliverList.list(
                  children: [
                    const SafeArea(bottom: false, child: _Header()),
                    SizedBox(height: wide ? NayaSpace.xxxl : NayaSpace.xxl),
                    const _Hero(),
                    SizedBox(height: wide ? NayaSpace.xxxl : NayaSpace.xxl),
                    SectionHeader(
                      label: '${sampleTemplates.length} ürün',
                      title: 'Hazır şablonlar',
                    ),
                    const SizedBox(height: NayaSpace.lg),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverGrid.builder(
                  itemCount: sampleTemplates.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: NayaSpace.lg,
                    crossAxisSpacing: NayaSpace.lg,
                    mainAxisExtent: 260,
                  ),
                  itemBuilder: (context, i) => ProductCard(
                    product: sampleTemplates[i],
                    index: i,
                    onOpen: () => onOpen(sampleTemplates[i]),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  NayaSpace.xxxl,
                  gutter,
                  NayaSpace.xxxl,
                ),
                sliver: SliverList.list(
                  children: [
                    const SectionHeader(label: 'Senin', title: 'Dosyalarım'),
                    const SizedBox(height: NayaSpace.lg),
                    for (final file in sampleUserFiles) _FileRow(file),
                    const SizedBox(height: NayaSpace.md),
                    const _ImportTile(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
            onPressed: () {},
            icon: Icon(Icons.tune, color: c.textSecondary),
          ),
          const SizedBox(width: NayaSpace.xs),
          CircleAvatar(
            radius: 16,
            backgroundColor: c.surfaceRaised,
            child: Text(
              'MZ',
              style: context.text.label.copyWith(color: c.text),
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
    final c = context.colors;
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
          child: TextField(
            style: context.text.body.copyWith(color: c.text),
            decoration: InputDecoration(
              hintText: 'Ürün, parça ya da arıza ara',
              hintStyle: context.text.body.copyWith(color: c.textMuted),
              prefixIcon: Icon(Icons.search, color: c.textMuted),
              filled: true,
              fillColor: c.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(NayaRadius.md),
                borderSide: BorderSide(color: c.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(NayaRadius.md),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
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
      onTap: () {},
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
