/// Bilgi kodunu (infoCode) `parts.json`'daki prosedür anahtarına çevirir.
///
/// Anahtarlar şablonlardakilerle ve uygulamanın etiketleriyle aynı
/// (`part_page.dart`). Eşleme, dört şablondaki 900'ü aşkın prosedürden
/// çıkarıldı. Tanıtım (0xx), kullanım (1xx), onarım (6xx) ve katalog (94x)
/// prosedür değil; null döner.
String? procedureKind(String infoCode) {
  final code = int.tryParse(infoCode);
  if (code == null) return null;
  return switch (code) {
    >= 400 && < 500 => 'isolate',
    >= 300 && < 340 => 'inspect',
    >= 340 && < 400 => 'measure',
    >= 270 && < 280 => 'adjust',
    >= 230 && < 240 => 'adjust',
    >= 240 && < 250 => 'lubricate',
    >= 210 && < 220 => 'refill',
    >= 220 && < 230 => 'clean',
    >= 250 && < 270 => 'clean',
    >= 500 && < 600 => 'remove',
    >= 700 && < 800 => 'install',
    >= 900 && < 940 => 'replace',
    _ => null,
  };
}
