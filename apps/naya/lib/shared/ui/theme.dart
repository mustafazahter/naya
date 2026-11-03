import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Token'lardan kurulan yazı stilleri.
class NayaText {
  NayaText(NayaColors c)
    : display = GoogleFonts.inter(
        fontSize: NayaTypeScale.display,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.2,
        height: 1.05,
        color: c.text,
      ),
      title = GoogleFonts.inter(
        fontSize: NayaTypeScale.title,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
        color: c.text,
      ),
      heading = GoogleFonts.inter(
        fontSize: NayaTypeScale.heading,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: c.text,
      ),
      body = GoogleFonts.inter(
        fontSize: NayaTypeScale.body,
        height: 1.5,
        color: c.textSecondary,
      ),
      small = GoogleFonts.inter(
        fontSize: NayaTypeScale.small,
        height: 1.4,
        color: c.textMuted,
      ),
      label = GoogleFonts.jetBrainsMono(
        fontSize: NayaTypeScale.label,
        fontWeight: FontWeight.w500,
        letterSpacing: NayaTypeScale.labelTracking,
        color: c.textMuted,
      ),
      mono = GoogleFonts.jetBrainsMono(
        fontSize: NayaTypeScale.small,
        color: c.textSecondary,
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
  const NayaTheme(this.colors);

  final NayaColors colors;

  @override
  NayaTheme copyWith({NayaColors? colors}) => NayaTheme(colors ?? this.colors);

  @override
  NayaTheme lerp(NayaTheme? other, double t) => other == null
      ? this
      : NayaTheme(NayaColors.lerp(colors, other.colors, t));
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? NayaColors.dark : NayaColors.light;
  final text = NayaText(c);
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
    extensions: [NayaTheme(c)],
  );
}

extension NayaThemeContext on BuildContext {
  NayaColors get colors => Theme.of(this).extension<NayaTheme>()!.colors;
  NayaText get text => NayaText(colors);
}
