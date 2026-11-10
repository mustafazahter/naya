import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Geçişi süren ekranlar için ortak süre.
const fadeThroughDuration = NayaMotion.slow;
const fadeThroughReverseDuration = NayaMotion.base;

/// Ekranlar arası tek geçiş: yeni ekran hafif büyüyerek belirir.
/// Her yerde aynı süre ve eğri kullanılsın diye tek yerde.
Widget fadeThroughTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: NayaMotion.decelerate,
    reverseCurve: NayaMotion.accelerate,
  );
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween(begin: 0.97, end: 1.0).animate(curved),
      child: child,
    ),
  );
}
