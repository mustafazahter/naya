import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Ekranlar arası tek geçiş: yeni ekran hafif büyüyerek belirir.
/// Her yerde aynı süre ve eğri kullanılsın diye tek yerde.
PageRouteBuilder<T> fadeThroughRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: NayaMotion.slow,
    reverseTransitionDuration: NayaMotion.base,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (context, animation, _, child) {
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
    },
  );
}
