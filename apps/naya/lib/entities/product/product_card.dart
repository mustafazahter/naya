import 'package:flutter/material.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import 'product.dart';
import 'product_glyph.dart';

/// Kütüphanedeki ürün kartı: üstte teknik çizim, altta ad ve sayılar.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onOpen,
  });

  final Product product;
  final int index;
  final VoidCallback onOpen;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.product;
    final number = (widget.index + 1).toString().padLeft(2, '0');

    return Semantics(
      button: true,
      label: '${p.title} şablonunu aç',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onOpen,
          child: AnimatedContainer(
            duration: NayaMotion.base,
            curve: NayaMotion.standard,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(NayaRadius.lg),
              border: Border.all(color: _hovered ? c.accent : c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Drawing(product: p, number: number, hovered: _hovered),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NayaSpace.lg,
                    NayaSpace.md,
                    NayaSpace.lg,
                    NayaSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.title, style: context.text.heading),
                          ),
                          AnimatedSlide(
                            duration: NayaMotion.base,
                            curve: NayaMotion.standard,
                            offset: Offset(_hovered ? 0.2 : 0, 0),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: _hovered ? c.accent : c.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(p.subtitle, style: context.text.small),
                      const SizedBox(height: NayaSpace.md),
                      TechLabel(
                        '${p.partCount} parça · ${p.faultCount} arıza · '
                        '${p.moduleCount} DM',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Drawing extends StatelessWidget {
  const _Drawing({
    required this.product,
    required this.number,
    required this.hovered,
  });

  final Product product;
  final String number;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.viewportTop, c.viewportBottom],
        ),
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGrid(c.line))),
          Positioned(
            left: NayaSpace.md,
            top: NayaSpace.md,
            child: TechLabel(number),
          ),
          Positioned(
            right: NayaSpace.md,
            top: NayaSpace.md,
            child: TechLabel(product.isTemplate ? 'Şablon' : 'Dosya'),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
              child: AnimatedScale(
                duration: NayaMotion.slow,
                curve: NayaMotion.decelerate,
                scale: hovered ? 1.04 : 1,
                child: ProductGlyph(
                  category: product.category,
                  color: hovered ? c.accent : c.platinum,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Teknik kâğıt hissi veren nokta ızgarası.
class _DotGrid extends CustomPainter {
  _DotGrid(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 16.0;
    for (var x = step; x < size.width; x += step) {
      for (var y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGrid old) => old.color != color;
}
