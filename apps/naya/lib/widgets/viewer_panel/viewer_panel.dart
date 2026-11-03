import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import 'bike_schematic.dart';

/// Çalışma alanının üst yarısı: model, tarama animasyonu ve kontroller.
///
/// Açılışta teşhis animasyonunu oynatır: sistemler sırayla taranır, adaylar
/// olasılıklarıyla orantılı parlar, sonra kamera en olası parçaya yaklaşır.
class ViewerPanel extends StatefulWidget {
  const ViewerPanel({
    super.key,
    required this.productTitle,
    required this.diagnosis,
    required this.onPartTap,
    this.onBack,
  });

  final String productTitle;
  final Diagnosis diagnosis;
  final ValueChanged<String> onPartTap;
  final VoidCallback? onBack;

  @override
  State<ViewerPanel> createState() => _ViewerPanelState();
}

class _ViewerPanelState extends State<ViewerPanel>
    with TickerProviderStateMixin {
  late final _scan = AnimationController(
    vsync: this,
    duration: NayaMotion.scan,
  );
  late final _explode = AnimationController(
    vsync: this,
    duration: NayaMotion.slow,
  );
  var _xray = false;

  @override
  void initState() {
    super.initState();
    _scan.forward();
  }

  @override
  void dispose() {
    _scan.dispose();
    _explode.dispose();
    super.dispose();
  }

  void _toggleExplode() {
    _explode.value < 0.5
        ? _explode.animateTo(1, curve: NayaMotion.decelerate)
        : _explode.animateBack(0, curve: NayaMotion.standard);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [c.viewportTop, c.viewportBottom],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          return AnimatedBuilder(
            animation: Listenable.merge([_scan, _explode]),
            builder: (context, _) => _scene(context, box.biggest),
          );
        },
      ),
    );
  }

  Widget _scene(BuildContext context, Size size) {
    final c = context.colors;
    final frame = _ScanFrame(_scan.value, widget.diagnosis);
    final view = _fit(size, frame.focus);
    final found = widget.diagnosis.top;
    final foundPart = bikeParts.firstWhere((p) => p.id == found.partId);
    final calloutAt =
        view.translate +
        (foundPart.center + foundPart.explode * _explode.value) * view.scale;

    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: FloorGridPainter(c.line))),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => widget.onPartTap(found.partId),
            child: CustomPaint(
              painter: BikeSchematicPainter(
                transform: view,
                emphasis: frame.emphasis,
                dim: _xray ? 0.75 : frame.dim,
                explode: _explode.value,
                lineColor: c.platinum,
                accent: c.accent,
              ),
            ),
          ),
        ),
        if (frame.scanX != null)
          Positioned(
            left:
                view.translate.dx +
                frame.scanX! * schematicSize.width * view.scale,
            top: 0,
            bottom: 0,
            child: _ScanLine(color: c.accent),
          ),
        if (frame.callout > 0)
          Positioned(
            left: calloutAt.dx - 12,
            top: calloutAt.dy + 26,
            child: Opacity(
              opacity: frame.callout,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - frame.callout)),
                child: _Callout(
                  name: found.name,
                  probability: found.probability,
                  onTap: () => widget.onPartTap(found.partId),
                ),
              ),
            ),
          ),
        Positioned(
          left: NayaSpace.md,
          right: NayaSpace.md,
          top: NayaSpace.md,
          child: SafeArea(
            bottom: false,
            child: _TopBar(title: widget.productTitle, onBack: widget.onBack),
          ),
        ),
        Positioned(
          right: NayaSpace.md,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundIconButton(
                  icon: Icons.open_in_full,
                  tooltip: 'Parçalarına ayır',
                  selected: _explode.value > 0.5,
                  onPressed: _toggleExplode,
                ),
                const SizedBox(height: NayaSpace.sm),
                RoundIconButton(
                  icon: Icons.blur_on,
                  tooltip: 'X-ışını',
                  selected: _xray,
                  onPressed: () => setState(() => _xray = !_xray),
                ),
                const SizedBox(height: NayaSpace.sm),
                RoundIconButton(
                  icon: Icons.refresh,
                  tooltip: 'Yeniden tara',
                  onPressed: () => _scan.forward(from: 0),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: NayaSpace.lg,
          bottom: NayaSpace.lg,
          child: _Status(frame: frame, diagnosis: widget.diagnosis),
        ),
      ],
    );
  }

  /// Şemayı alana sığdırır; [focus] 0'dan 1'e giderken bulunan parçaya
  /// yaklaşır.
  ({Offset translate, double scale}) _fit(Size size, double focus) {
    final base =
        math.min(
          size.width / schematicSize.width,
          size.height / schematicSize.height,
        ) *
        0.78;
    final origin = Offset(
      (size.width - schematicSize.width * base) / 2,
      (size.height - schematicSize.height * base) / 2 + size.height * 0.03,
    );
    final part = bikeParts.firstWhere(
      (p) => p.id == widget.diagnosis.top.partId,
    );
    // Bulunan parça ortanın biraz soluna gelsin; sağda kontroller var.
    final center = Offset(size.width * 0.46, size.height * 0.48);
    final target = origin + part.center * base;
    final zoom = lerpDouble(1, 1.45, focus)!;
    final pivot = Offset.lerp(center, target, focus)!;
    return (translate: center + (origin - pivot) * zoom, scale: base * zoom);
  }
}

/// Animasyonun belli bir anındaki durum. Zaman çizelgesi:
/// 0-0.55 tarama, 0.5-0.72 adayların parlaması, 0.7-1 yaklaşma ve etiket.
class _ScanFrame {
  _ScanFrame(double t, Diagnosis d) {
    const scanEnd = 0.55;
    if (t < scanEnd) {
      final x = lerpDouble(-0.05, 1.05, t / scanEnd)!;
      scanX = x;
      systems = (x * d.systemsScanned).clamp(0, d.systemsScanned).ceil();
      for (final part in bikeParts) {
        final distance = part.center.dx / schematicSize.width - x;
        emphasis[part.id] = math.exp(-math.pow(distance / 0.05, 2)) * 0.9;
      }
    }

    final glow = _phase(t, 0.5, 0.72);
    for (final c in d.candidates) {
      final current = emphasis[c.partId] ?? 0;
      emphasis[c.partId] = math.max(
        current,
        glow * c.probability / d.top.probability,
      );
    }

    focus = NayaMotion.decelerate.transform(_phase(t, 0.7, 1));
    if (focus > 0) {
      for (final c in d.candidates.skip(1)) {
        emphasis[c.partId] = (emphasis[c.partId] ?? 0) * (1 - focus * 0.7);
      }
      emphasis[d.top.partId] = 1;
    }
    dim = 0.35 + 0.4 * focus;
    callout = NayaMotion.standard.transform(_phase(t, 0.84, 1));
  }

  final emphasis = <String, double>{};
  double? scanX;
  int systems = 0;
  late final double focus;
  late final double dim;
  late final double callout;

  bool get scanning => scanX != null;

  static double _phase(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0, 1);
}

class _ScanLine extends StatelessWidget {
  const _ScanLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color,
              color.withValues(alpha: 0),
            ],
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 18),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.name,
    required this.probability,
    required this.onTap,
  });

  final String name;
  final double probability;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$name parça kartını aç',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 1, height: 18, color: c.accent),
            Container(
              padding: const EdgeInsets.fromLTRB(
                NayaSpace.md,
                NayaSpace.sm,
                NayaSpace.sm,
                NayaSpace.sm,
              ),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.all(NayaRadius.sm),
                border: Border.all(color: c.accent.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: context.text.heading.copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: NayaSpace.sm),
                  Text(
                    '%${(probability * 100).round()}',
                    style: context.text.mono.copyWith(color: c.accent),
                  ),
                  const SizedBox(width: NayaSpace.xs),
                  Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          RoundIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Kütüphane',
            onPressed: onBack,
          ),
          const SizedBox(width: NayaSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TechLabel('Şablon · S1000D 5.0'),
              const SizedBox(height: 2),
              Text(title, style: context.text.heading),
            ],
          ),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.frame, required this.diagnosis});

  final _ScanFrame frame;
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final String text;
    if (frame.scanning) {
      text = 'Tarama · ${frame.systems}/${diagnosis.systemsScanned} sistem';
    } else if (frame.focus < 0.01) {
      text = 'Olasılıklar hesaplanıyor';
    } else {
      text = 'Bulundu · ${diagnosis.top.name}';
    }
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: frame.focus > 0 ? c.accent : c.platinum,
          ),
        ),
        const SizedBox(width: NayaSpace.sm),
        TechLabel(text, color: c.textSecondary),
      ],
    );
  }
}
