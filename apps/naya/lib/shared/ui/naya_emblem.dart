import 'package:flutter/widgets.dart';

import 'theme.dart';

/// NAYA işareti: parçalardan kurulmuş bir Λ. Uç ve gövde ayrı parçalar,
/// her biri bir aydınlık bir gölgeli yüzle çiziliyor.
///
/// Geometri `assets/brand/naya-emblem-*.svg` ile aynı (200×200 kutu).
class NayaEmblem extends StatelessWidget {
  const NayaEmblem({super.key, this.size = 28, this.gap = 0});

  final double size;

  /// Uç ile gövde arasına eklenecek boşluk (0..1). Teşhis ve yükleme
  /// anlarında parçaları biraz ayırmak için.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      size: Size.square(size),
      painter: _EmblemPainter(c.emblemLight, c.emblemDark, gap),
    );
  }
}

/// "NAYA" yazısı. A'ların ortası boş: logodaki Λ ile aynı aile.
class NayaWordmark extends StatelessWidget {
  const NayaWordmark({super.key, this.height = 12});

  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * 467 / 80, height),
      painter: _WordmarkPainter(context.colors.text),
    );
  }
}

const _tipLeft = [Offset(100, 15), Offset(82.3, 51), Offset(100, 51)];
const _tipRight = [Offset(100, 15), Offset(100, 51), Offset(117.7, 51)];
const _bodyLeft = [
  Offset(82.3, 64),
  Offset(30, 170),
  Offset(66, 158),
  Offset(100, 102),
  Offset(100, 64),
];
const _bodyRight = [
  Offset(100, 64),
  Offset(100, 102),
  Offset(134, 158),
  Offset(170, 170),
  Offset(117.7, 64),
];

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.light, this.dark, this.gap);

  final Color light;
  final Color dark;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);
    final lift = Offset(0, -gap * 18);
    _polygon(canvas, _tipLeft, light, lift);
    _polygon(canvas, _tipRight, dark, lift);
    _polygon(canvas, _bodyLeft, light, Offset.zero);
    _polygon(canvas, _bodyRight, dark, Offset.zero);
  }

  void _polygon(Canvas canvas, List<Offset> points, Color color, Offset shift) {
    final path = Path()..addPolygon([for (final p in points) p + shift], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.light != light || old.dark != dark || old.gap != gap;
}

const _letters = [
  [
    Offset(0, 80), Offset(0, 0), Offset(12.5, 0), Offset(62, 60.5), //
    Offset(62, 0), Offset(74, 0), Offset(74, 80), Offset(61.5, 80),
    Offset(12, 19.5), Offset(12, 80),
  ],
  [
    Offset(144, 0), Offset(157, 0), Offset(201, 80), Offset(187.8, 80), //
    Offset(150.5, 12.5), Offset(113, 80), Offset(100, 80),
  ],
  [
    Offset(240, 0), Offset(254.5, 0), Offset(285.5, 41.5), Offset(316.5, 0), //
    Offset(331, 0), Offset(292, 51.5), Offset(292, 80), Offset(280, 80),
    Offset(280, 51.5),
  ],
  [
    Offset(410, 0), Offset(423, 0), Offset(467, 80), Offset(453.8, 80), //
    Offset(416.5, 12.5), Offset(379, 80), Offset(366, 80),
  ],
];

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.height / 80);
    final paint = Paint()..color = color;
    for (final letter in _letters) {
      canvas.drawPath(Path()..addPolygon(letter, true), paint);
    }
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) => old.color != color;
}
