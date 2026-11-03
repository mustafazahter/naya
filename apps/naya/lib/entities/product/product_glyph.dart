import 'package:flutter/widgets.dart';

import 'product.dart';

/// Ürünün teknik çizim tarzında silueti. Kartlarda 3D model yüklenmeden
/// önce ürünü tanıtmak için; tek renk, ince çizgi.
class ProductGlyph extends StatelessWidget {
  const ProductGlyph({
    super.key,
    required this.category,
    required this.color,
    this.strokeWidth = 1.4,
  });

  final ProductCategory category;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 200 / 110,
      child: CustomPaint(painter: _GlyphPainter(category, color, strokeWidth)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.category, this.color, this.strokeWidth);

  final ProductCategory category;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    switch (category) {
      case ProductCategory.car:
        _car(canvas, paint);
      case ProductCategory.bicycle:
        _bicycle(canvas, paint);
      case ProductCategory.tank:
        _tank(canvas, paint);
      case ProductCategory.aircraft:
        _aircraft(canvas, paint);
    }
  }

  void _car(Canvas c, Paint p) {
    final body = Path()
      ..moveTo(14, 80)
      ..lineTo(14, 66)
      ..quadraticBezierTo(16, 60, 30, 58)
      ..lineTo(56, 55)
      ..lineTo(78, 38)
      ..quadraticBezierTo(84, 34, 96, 34)
      ..lineTo(126, 34)
      ..quadraticBezierTo(136, 34, 144, 42)
      ..lineTo(158, 55)
      ..lineTo(180, 59)
      ..quadraticBezierTo(188, 61, 188, 70)
      ..lineTo(188, 80);
    c.drawPath(body, p);
    c.drawLine(const Offset(14, 80), const Offset(36, 80), p);
    c.drawLine(const Offset(68, 80), const Offset(132, 80), p);
    c.drawLine(const Offset(164, 80), const Offset(188, 80), p);
    final window = Path()
      ..moveTo(64, 55)
      ..lineTo(82, 41)
      ..lineTo(124, 41)
      ..lineTo(140, 55)
      ..close();
    c.drawPath(window, p);
    c.drawLine(const Offset(102, 41), const Offset(102, 55), p);
    for (final x in [52.0, 148.0]) {
      c.drawCircle(Offset(x, 80), 15, p);
      c.drawCircle(Offset(x, 80), 6, p);
    }
  }

  void _bicycle(Canvas c, Paint p) {
    const rear = Offset(48, 76);
    const front = Offset(152, 76);
    const crank = Offset(92, 78);
    const seat = Offset(84, 40);
    const headTop = Offset(136, 38);
    const headBottom = Offset(139, 50);
    for (final hub in [rear, front]) {
      c.drawCircle(hub, 28, p);
      c.drawCircle(hub, 2, p);
    }
    c.drawPath(Path()..addPolygon([rear, crank, seat], true), p);
    c.drawLine(seat, headTop, p);
    c.drawLine(crank, headBottom, p);
    c.drawLine(headTop, headBottom, p);
    c.drawLine(headBottom, front, p);
    c.drawLine(seat, const Offset(81, 30), p);
    c.drawLine(const Offset(70, 29), const Offset(91, 29), p);
    c.drawLine(headTop, const Offset(133, 29), p);
    c.drawLine(const Offset(126, 28), const Offset(142, 30), p);
    c.drawCircle(crank, 7, p);
  }

  void _tank(Canvas c, Paint p) {
    c.drawRRect(RRect.fromLTRBR(18, 70, 182, 92, const Radius.circular(11)), p);
    for (var i = 0; i < 6; i++) {
      c.drawCircle(Offset(36 + i * 25.6, 81), 7, p);
    }
    c.drawPath(
      Path()..addPolygon(const [
        Offset(26, 70),
        Offset(40, 58),
        Offset(170, 58),
        Offset(178, 70),
      ], false),
      p,
    );
    c.drawPath(
      Path()..addPolygon(const [
        Offset(64, 58),
        Offset(74, 42),
        Offset(124, 42),
        Offset(136, 50),
        Offset(136, 58),
      ], false),
      p,
    );
    c.drawLine(const Offset(136, 48), const Offset(196, 45), p);
    c.drawLine(const Offset(136, 52), const Offset(196, 49), p);
  }

  void _aircraft(Canvas c, Paint p) {
    // Üstten görünüş: delta kanat, iki kuyruk dümeni. Diğerlerinden uzun
    // olduğu için biraz küçültülüyor.
    c
      ..translate(100, 55)
      ..scale(0.86)
      ..translate(-100, -55);
    c.drawPath(
      Path()..addPolygon(const [
        Offset(100, 6),
        Offset(106, 30),
        Offset(108, 46),
        Offset(170, 74),
        Offset(170, 80),
        Offset(110, 76),
        Offset(118, 96),
        Offset(118, 101),
        Offset(100, 98),
        Offset(82, 101),
        Offset(82, 96),
        Offset(90, 76),
        Offset(30, 80),
        Offset(30, 74),
        Offset(92, 46),
        Offset(94, 30),
      ], true),
      p,
    );
    c.drawLine(const Offset(100, 14), const Offset(100, 40), p);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.category != category || old.color != color;
}
