import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Taslakta 3D viewer'ın yerini tutan bisiklet şeması.
///
/// Gerçek viewer (three.js) gelene kadar tarama, parlama, parçalara ayırma
/// ve yaklaşma hareketlerini denemek için. Parça kimlikleri `parts.json`
/// ile aynı; böylece teşhis sonucu doğrudan buraya bağlanabiliyor.
class SchematicPart {
  const SchematicPart(this.id, this.center, this.explode, this.draw);

  final String id;

  /// Taramada parçanın ne zaman yanacağını belirleyen merkez (400×240 kutu).
  final Offset center;

  /// Parçalara ayırırken gideceği yön ve mesafe.
  final Offset explode;
  final void Function(Canvas canvas, Paint paint) draw;
}

const schematicSize = Size(400, 240);
const _rear = Offset(104, 160);
const _front = Offset(300, 160);
const _crank = Offset(182, 166);
const _seat = Offset(166, 84);
const _headTop = Offset(270, 80);
const _headBottom = Offset(276, 104);

final bikeParts = <SchematicPart>[
  SchematicPart('frame', const Offset(200, 120), Offset.zero, (c, p) {
    c.drawPath(Path()..addPolygon(const [_rear, _crank, _seat], true), p);
    c.drawLine(_seat, _headTop, p);
    c.drawLine(_crank, _headBottom, p);
    c.drawLine(_headTop, _headBottom, p);
  }),
  SchematicPart('wheel.rear', _rear, const Offset(-26, 0), (c, p) {
    _wheel(c, p, _rear);
  }),
  SchematicPart('wheel.front', _front, const Offset(26, 0), (c, p) {
    _wheel(c, p, _front);
  }),
  SchematicPart('fork', const Offset(288, 132), const Offset(14, 0), (c, p) {
    c.drawLine(_headBottom, _front, p);
  }),
  SchematicPart('handlebar', const Offset(268, 64), const Offset(0, -18), (
    c,
    p,
  ) {
    c.drawLine(_headTop, const Offset(266, 64), p);
    c.drawPath(
      Path()
        ..moveTo(250, 62)
        ..quadraticBezierTo(268, 56, 288, 66),
      p,
    );
  }),
  SchematicPart('saddle', const Offset(158, 62), const Offset(0, -18), (c, p) {
    c.drawLine(_seat, const Offset(160, 64), p);
    c.drawPath(
      Path()
        ..moveTo(136, 60)
        ..quadraticBezierTo(158, 54, 182, 60),
      p,
    );
  }),
  SchematicPart(
    'brakes.rear.pad',
    const Offset(110, 98),
    const Offset(0, -16),
    (c, p) {
      c.drawRRect(
        RRect.fromLTRBR(104, 92, 116, 104, const Radius.circular(2)),
        p,
      );
    },
  ),
  SchematicPart(
    'brakes.front.pad',
    const Offset(296, 98),
    const Offset(0, -16),
    (c, p) {
      c.drawRRect(
        RRect.fromLTRBR(290, 92, 302, 104, const Radius.circular(2)),
        p,
      );
    },
  ),
  SchematicPart('drive.crank', _crank, const Offset(0, 22), (c, p) {
    c.drawCircle(_crank, 20, p);
    c.drawCircle(_crank, 4, p);
    c.drawLine(_crank, const Offset(198, 196), p);
    c.drawLine(const Offset(188, 196), const Offset(210, 196), p);
  }),
  SchematicPart('drive.chain', const Offset(142, 166), const Offset(0, 22), (
    c,
    p,
  ) {
    c.drawLine(const Offset(182, 146), const Offset(104, 151), p);
    c.drawLine(const Offset(182, 186), const Offset(104, 169), p);
  }),
  SchematicPart(
    'drive.derailleur',
    const Offset(110, 186),
    const Offset(0, 22),
    (c, p) {
      c.drawCircle(_rear, 9, p);
      c.drawPath(
        Path()
          ..moveTo(108, 168)
          ..lineTo(116, 190)
          ..lineTo(108, 204),
        p,
      );
      c.drawCircle(const Offset(116, 190), 3, p);
    },
  ),
];

void _wheel(Canvas c, Paint p, Offset hub) {
  c.drawCircle(hub, 62, p);
  final thin = Paint()
    ..color = p.color.withValues(alpha: p.color.a * 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = p.strokeWidth * 0.6
    ..maskFilter = p.maskFilter;
  c.drawCircle(hub, 55, thin);
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    c.drawLine(hub, hub + Offset(math.cos(a), math.sin(a)) * 55, thin);
  }
  c.drawCircle(hub, 4, p);
}

/// Şemayı çizer. [emphasis] parça kimliğinden 0..1 parlama değerine;
/// [dim] vurgulanmayan parçaların ne kadar soluklaşacağı.
class BikeSchematicPainter extends CustomPainter {
  BikeSchematicPainter({
    required this.transform,
    required this.emphasis,
    required this.dim,
    required this.explode,
    required this.lineColor,
    required this.accent,
  });

  /// Şema koordinatlarından ekrana: önce ölçek, sonra kaydırma.
  final ({Offset translate, double scale}) transform;
  final Map<String, double> emphasis;
  final double dim;
  final double explode;
  final Color lineColor;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..translate(transform.translate.dx, transform.translate.dy)
      ..scale(transform.scale);
    final width = 1.6 / transform.scale;

    for (final part in bikeParts) {
      final glow = emphasis[part.id] ?? 0;
      canvas.save();
      canvas.translate(part.explode.dx * explode, part.explode.dy * explode);

      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor.withValues(alpha: 1 - dim * (1 - glow));
      part.draw(canvas, base);

      if (glow > 0.01) {
        final halo = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 5
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.45 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 / transform.scale);
        part.draw(canvas, halo);
        part.draw(
          canvas,
          base
            ..color = Color.lerp(lineColor, accent, glow)!
            ..strokeWidth = width * (1 + glow * 0.6),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BikeSchematicPainter old) => true;
}

/// Perspektifli zemin ızgarası; sahneye derinlik verir.
class FloorGridPainter extends CustomPainter {
  FloorGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.52;
    final vanish = Offset(size.width / 2, horizon - size.height * 0.9);
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0, 0.48],
      ).createShader(Offset.zero & size);

    for (var i = -12; i <= 12; i++) {
      final x = size.width / 2 + i * size.width / 10;
      final dir = Offset(x, size.height) - vanish;
      final t = (horizon - vanish.dy) / dir.dy;
      canvas.drawLine(vanish + dir * t, Offset(x, size.height), paint);
    }
    for (var i = 0; i < 9; i++) {
      final y = horizon + (size.height - horizon) * math.pow(i / 8, 1.8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(FloorGridPainter old) => old.color != color;
}
