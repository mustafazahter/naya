import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Yazı aileleri: metin için Inter, teknik veriler için JetBrains Mono.
abstract final class NayaFonts {
  /// Testlerde kapatılır; ağdan font indirilmez, sistem fontu kullanılır.
  static bool useGoogleFonts = true;

  static TextStyle sans(TextStyle style) =>
      useGoogleFonts ? GoogleFonts.inter(textStyle: style) : style;

  static TextStyle mono(TextStyle style) => useGoogleFonts
      ? GoogleFonts.jetBrainsMono(textStyle: style)
      : style.copyWith(fontFamily: 'monospace');
}

/// Token'lardan kurulan yazı stilleri.
class NayaText {
  NayaText(NayaColors c)
    : display = NayaFonts.sans(
        TextStyle(
          fontSize: NayaTypeScale.display,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.2,
          height: 1.05,
          color: c.text,
        ),
      ),
      title = NayaFonts.sans(
        TextStyle(
          fontSize: NayaTypeScale.title,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.15,
          color: c.text,
        ),
      ),
      heading = NayaFonts.sans(
        TextStyle(
          fontSize: NayaTypeScale.heading,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: c.text,
        ),
      ),
      body = NayaFonts.sans(
        TextStyle(
          fontSize: NayaTypeScale.body,
          height: 1.5,
          color: c.textSecondary,
        ),
      ),
      small = NayaFonts.sans(
        TextStyle(
          fontSize: NayaTypeScale.small,
          height: 1.4,
          color: c.textMuted,
        ),
      ),
      label = NayaFonts.mono(
        TextStyle(
          fontSize: NayaTypeScale.label,
          fontWeight: FontWeight.w500,
          letterSpacing: NayaTypeScale.labelTracking,
          color: c.textMuted,
        ),
      ),
      mono = NayaFonts.mono(
        TextStyle(fontSize: NayaTypeScale.small, color: c.textSecondary),
      );

  final TextStyle display;
  final TextStyle title;
  final TextStyle heading;
  final TextStyle body;
  final TextStyle small;

  /// Büyük harfle yazılan teknik etiketler: `SNS 41-20`, `TARAMA`.
  final TextStyle label;

  /// DMC kodları, kimlikler, ölçüler.
  final TextStyle mono;
}

/// Renkleri temaya bağlar; widget'lar `context.colors` ile okur.
class NayaTheme extends ThemeExtension<NayaTheme> {
  NayaTheme(this.colors) : text = NayaText(colors);

  final NayaColors colors;

  /// Stiller tema kurulurken bir kez üretilir, her build'de değil.
  final NayaText text;

  @override
  NayaTheme copyWith({NayaColors? colors}) => NayaTheme(colors ?? this.colors);

  @override
  NayaTheme lerp(NayaTheme? other, double t) {
    if (other == null || t == 0) return this;
    if (t == 1) return other;
    return NayaTheme(NayaColors.lerp(colors, other.colors, t));
  }
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? NayaColors.dark : NayaColors.light;
  final naya = NayaTheme(c);
  final text = naya.text;
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
    ),
    textTheme: TextTheme(
      displayLarge: text.display,
      titleLarge: text.title,
      titleMedium: text.heading,
      bodyMedium: text.body,
      bodySmall: text.small,
      labelSmall: text.label,
    ),
    dividerColor: c.line,
    // Renk açılış anında sabitlenmesin; tema değişince sayfa da değişsin.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
    ),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    extensions: [naya],
  );
}

extension NayaThemeContext on BuildContext {
  NayaTheme get _naya => Theme.of(this).extension<NayaTheme>()!;
  NayaColors get colors => _naya.colors;
  NayaText get text => _naya.text;
}
