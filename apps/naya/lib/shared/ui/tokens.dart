import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Tasarım token'ları. Renk, yazı, boşluk, köşe ve hareket değerlerinin
/// tek kaynağı burası; ekranlarda sabit sayı ya da renk yazılmaz.
///
/// Renkler nötr gri ölçeği üstüne platin ve çelik mavi. Altın, kahve,
/// turuncu ve bej bilerek yok. Kırmızı yalnız uyarı için.
class NayaColors {
  const NayaColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.platinum,
    required this.accent,
    required this.accentStrong,
    required this.onAccent,
    required this.danger,
    required this.emblemLight,
    required this.emblemDark,
    required this.viewportTop,
    required this.viewportBottom,
  });

  /// Koyu tema: 3D efektlerin en iyi göründüğü, varsayılan teknik tema.
  static const dark = NayaColors(
    background: Color(0xFF0A0C0F),
    surface: Color(0xFF111419),
    surfaceRaised: Color(0xFF181C22),
    line: Color(0xFF232830),
    lineStrong: Color(0xFF343B45),
    text: Color(0xFFECEFF3),
    textSecondary: Color(0xFFA3ABB5),
    textMuted: Color(0xFF6B737E),
    platinum: Color(0xFFD5DAE1),
    accent: Color(0xFF8DB8F2),
    accentStrong: Color(0xFF5E95E0),
    onAccent: Color(0xFF07111F),
    danger: Color(0xFFE5534B),
    emblemLight: Color(0xFFECEFF3),
    emblemDark: Color(0xFF7C838D),
    viewportTop: Color(0xFF131820),
    viewportBottom: Color(0xFF07090C),
  );

  static const light = NayaColors(
    background: Color(0xFFF3F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEBEEF2),
    line: Color(0xFFDDE2E8),
    lineStrong: Color(0xFFC3CAD3),
    text: Color(0xFF14181E),
    textSecondary: Color(0xFF4A525C),
    textMuted: Color(0xFF7A828D),
    platinum: Color(0xFF2B3139),
    accent: Color(0xFF3D74C9),
    accentStrong: Color(0xFF2D5FAD),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC8373D),
    emblemLight: Color(0xFF1B2027),
    emblemDark: Color(0xFF6B737E),
    viewportTop: Color(0xFFFAFBFC),
    viewportBottom: Color(0xFFE2E7ED),
  );

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color platinum;
  final Color accent;
  final Color accentStrong;
  final Color onAccent;
  final Color danger;

  /// Logonun aydınlık ve gölgeli yüzleri.
  final Color emblemLight;
  final Color emblemDark;

  /// 3D sahnenin arka plan geçişi.
  final Color viewportTop;
  final Color viewportBottom;

  static NayaColors lerp(NayaColors a, NayaColors b, double t) => NayaColors(
    background: Color.lerp(a.background, b.background, t)!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
    line: Color.lerp(a.line, b.line, t)!,
    lineStrong: Color.lerp(a.lineStrong, b.lineStrong, t)!,
    text: Color.lerp(a.text, b.text, t)!,
    textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
    textMuted: Color.lerp(a.textMuted, b.textMuted, t)!,
    platinum: Color.lerp(a.platinum, b.platinum, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
    accentStrong: Color.lerp(a.accentStrong, b.accentStrong, t)!,
    onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
    danger: Color.lerp(a.danger, b.danger, t)!,
    emblemLight: Color.lerp(a.emblemLight, b.emblemLight, t)!,
    emblemDark: Color.lerp(a.emblemDark, b.emblemDark, t)!,
    viewportTop: Color.lerp(a.viewportTop, b.viewportTop, t)!,
    viewportBottom: Color.lerp(a.viewportBottom, b.viewportBottom, t)!,
  );
}

/// Yazı ölçeği. Aileler [NayaFonts] ile tema kurulurken bağlanır.
abstract final class NayaTypeScale {
  static const display = 40.0;
  static const title = 24.0;
  static const heading = 17.0;
  static const body = 15.0;
  static const small = 13.0;

  /// Teknik etiketler: büyük harf, geniş aralık, monospace.
  static const label = 11.0;
  static const labelTracking = 1.6;
}

/// 4'ün katları.
abstract final class NayaSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Telefonda ekran kenar boşluğu.
  static const gutter = 20.0;
}

abstract final class NayaRadius {
  static const sm = Radius.circular(6);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(20);
  static const pill = Radius.circular(999);
}

/// Hareket dili: her yerde aynı eğriler ve süreler.
abstract final class NayaMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);

  /// Teşhis animasyonu bilerek 3-4 saniye: tarama → parlama → yaklaşma.
  static const scan = Duration(milliseconds: 3400);

  /// Genel geçişler.
  static const standard = Cubic(0.2, 0, 0, 1);

  /// Ekrana giren öğeler ve kamera uçuşu: hızlı başlar, yavaşlayarak durur.
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Ekrandan çıkan öğeler.
  static const accelerate = Cubic(0.3, 0, 1, 1);
}
