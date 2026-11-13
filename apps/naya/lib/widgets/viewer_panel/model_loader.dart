import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Model inerken viewer'ın üstünü kaplayan yükleme ekranı.
///
/// Arkada teknik çizim kâğıdı gibi bir ızgara ve yukarıdan aşağı geçen bir
/// tarama çizgisi, ortada ürünün adı harf harf belirir, altta büyük bir
/// yüzde sayacı ve ince bir ilerleme çizgisi. Model hazır olunca sayaç
/// 100'e varır, ekran yukarı kayarak açılır ve altında modelin açılış
/// animasyonu başlar.
class ModelLoader extends StatefulWidget {
  const ModelLoader({
    super.key,
    required this.title,
    required this.progress,
    required this.ready,
    required this.onFinished,
    this.failed = false,
  });

  final String title;

  /// Modelin inen kısmı (0-1); sunucu boyut vermezse hep 0 kalır.
  final double progress;

  /// Model çizilmeye hazır; ekran kapanır.
  final bool ready;

  /// Model yüklenemedi; ekran açık kalır ve sebebi yazar.
  final bool failed;

  /// Kapanış animasyonu bitti; ekran ağaçtan çıkarılabilir.
  final VoidCallback onFinished;

  @override
  State<ModelLoader> createState() => _ModelLoaderState();
}

class _ModelLoaderState extends State<ModelLoader>
    with TickerProviderStateMixin {
  /// Başlığın harf harf girişi.
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  /// Arkadaki tarama çizgisi.
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  /// Kapanış: içerik yukarı kayar, arka plan saydamlaşır.
  late final _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  /// Sayaç gerçek ilerlemeye yumuşakça yaklaşır; boyut bilinmiyorsa
  /// yavaşça kendisi ilerler ama %90'ı geçmez.
  late final Ticker _ticker;
  final _shown = ValueNotifier<double>(0);
  Duration _last = Duration.zero;

  @override
  void didUpdateWidget(ModelLoader old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) _finishSoon();
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    if (widget.ready) _finishSoon();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final seconds = elapsed.inMicroseconds / 1e6;
    // İndirme %0-90, kalan kısım modelin çözülüp sahneye konması.
    final guess = 0.9 * (1 - math.exp(-seconds / 5));
    final target = widget.ready ? 1.0 : math.max(widget.progress * 0.9, guess);
    final next =
        _shown.value + (target - _shown.value) * (1 - math.exp(-dt * 7));
    _shown.value = (target - next).abs() < 0.001 ? target : next;
  }

  Future<void> _finishSoon() async {
    // Sayaç 100'e varsın, sonra açılsın.
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) _exit.duration = const Duration(milliseconds: 200);
    await _exit.forward();
    if (!mounted) return;
    _ticker.stop();
    _sweep.stop();
    widget.onFinished();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _enter.dispose();
    _sweep.dispose();
    _exit.dispose();
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.of(context).disableAnimations;
    final exit = CurvedAnimation(parent: _exit, curve: NayaMotion.standard);

    return Semantics(
      label: widget.failed ? 'Model yüklenemedi' : 'Model yükleniyor',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: exit,
        builder: (context, child) => Opacity(
          opacity: 1 - exit.value,
          child: Transform.translate(
            offset: Offset(0, -48 * exit.value),
            child: child,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.1,
              colors: [c.viewportTop, c.viewportBottom],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _BlueprintPainter(
                    sweep: reduce ? null : _sweep,
                    line: c.line,
                    accent: c.accent,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NayaSpace.gutter,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StageLabel(
                        shown: _shown,
                        ready: widget.ready,
                        failed: widget.failed,
                      ),
                      const SizedBox(height: NayaSpace.md),
                      _RevealedTitle(
                        widget.title,
                        animation: reduce ? kAlwaysCompleteAnimation : _enter,
                      ),
                      if (widget.failed) ...[
                        const SizedBox(height: NayaSpace.md),
                        Text(
                          'Bağlantıyı kontrol edip sayfayı yenileyin.',
                          textAlign: TextAlign.center,
                          style: context.text.body,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!widget.failed)
                Positioned(
                  left: NayaSpace.xl,
                  right: NayaSpace.xl,
                  bottom: NayaSpace.xl,
                  child: _Counter(shown: _shown),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ne yapıldığını söyleyen küçük etiket; ilerlemeye göre değişir.
class _StageLabel extends StatelessWidget {
  const _StageLabel({
    required this.shown,
    required this.ready,
    required this.failed,
  });

  final ValueListenable<double> shown;
  final bool ready;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder(
      valueListenable: shown,
      builder: (context, value, _) {
        final text = failed
            ? 'Model yüklenemedi'
            : ready
            ? 'Montaj'
            : value < 0.6
            ? 'Geometri iniyor'
            : 'Parçalar ayrıştırılıyor';
        return AnimatedSwitcher(
          duration: NayaMotion.base,
          child: TechLabel(
            text,
            key: ValueKey(text),
            color: failed ? c.danger : c.accent,
          ),
        );
      },
    );
  }
}

/// Başlık harf harf, aşağıdan yukarı kayarak belirir.
class _RevealedTitle extends StatelessWidget {
  const _RevealedTitle(this.text, {required this.animation});

  final String text;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text.display.copyWith(
      color: c.text,
      fontSize: 48,
      height: 1.05,
      letterSpacing: -1.2,
    );
    final letters = text.characters.toList();
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (final (i, letter) in letters.indexed)
            _letter(letter, i, letters.length, style),
        ],
      ),
    );
  }

  Widget _letter(String letter, int i, int count, TextStyle style) {
    // Her harf toplam sürenin %45'inde girer; başlangıçlar sırayla kayar.
    final start = count <= 1 ? 0.0 : 0.55 * i / (count - 1);
    final t = NayaMotion.decelerate.transform(
      ((animation.value - start) / 0.45).clamp(0.0, 1.0),
    );
    return ClipRect(
      child: Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 28),
          child: Text(letter == ' ' ? ' ' : letter, style: style),
        ),
      ),
    );
  }
}

/// Büyük yüzde sayacı ve altında ince ilerleme çizgisi.
class _Counter extends StatelessWidget {
  const _Counter({required this.shown});

  final ValueListenable<double> shown;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder(
      valueListenable: shown,
      builder: (context, value, _) {
        final percent = (value * 100).floor().clamp(0, 100);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  percent.toString().padLeft(3, '0'),
                  style: context.text.mono.copyWith(
                    fontSize: 72,
                    height: 0.9,
                    fontWeight: FontWeight.w300,
                    color: c.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: NayaSpace.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TechLabel('%', color: c.textMuted),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TechLabel('3D · GLB', color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: NayaSpace.md),
            SizedBox(
              height: 2,
              child: CustomPaint(
                size: const Size(double.infinity, 2),
                painter: _BarPainter(
                  value: value,
                  track: c.line,
                  fill: c.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.value,
    required this.track,
    required this.fill,
  });

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = track
        ..strokeWidth = 1,
    );
    final end = size.width * value;
    canvas.drawLine(
      Offset(0, y),
      Offset(end, y),
      Paint()
        ..color = fill
        ..strokeWidth = 2,
    );
    // Çizginin ucunda parlayan bir nokta.
    canvas.drawCircle(
      Offset(end, y),
      6,
      Paint()
        ..color = fill.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.value != value;
}

/// Teknik çizim ızgarası: ince çizgiler, her dördüncüsü biraz daha belirgin,
/// kesişimlerde artı işaretleri; üstünden yatay bir tarama çizgisi geçer.
class _BlueprintPainter extends CustomPainter {
  _BlueprintPainter({
    required this.sweep,
    required this.line,
    required this.accent,
  }) : super(repaint: sweep);

  final Animation<double>? sweep;
  final Color line;
  final Color accent;

  static const _cell = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = line.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final strong = Paint()
      ..color = line.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    final columns = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil();
    for (var i = 0; i <= columns; i++) {
      final x = i * _cell;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 4 == 0 ? strong : thin,
      );
    }
    for (var j = 0; j <= rows; j++) {
      final y = j * _cell;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        j % 4 == 0 ? strong : thin,
      );
    }
    final cross = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var i = 0; i <= columns; i += 4) {
      for (var j = 0; j <= rows; j += 4) {
        final p = Offset(i * _cell, j * _cell);
        canvas
          ..drawLine(p - const Offset(4, 0), p + const Offset(4, 0), cross)
          ..drawLine(p - const Offset(0, 4), p + const Offset(0, 4), cross);
      }
    }

    // Kenarlara doğru kararan bir örtü; ızgara ortada okunur, kenarda söner.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
        ).createShader(Offset.zero & size),
    );

    final sweep = this.sweep;
    if (sweep == null) return;
    final y = size.height * NayaMotion.standard.transform(sweep.value);
    canvas.drawRect(
      Rect.fromLTWH(0, y - 80, size.width, 80),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0), accent.withValues(alpha: 0.08)],
        ).createShader(Rect.fromLTWH(0, y - 80, size.width, 80)),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BlueprintPainter old) =>
      old.line != line || old.accent != accent;
}
