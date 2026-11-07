/// Bir S1000D dosyası okunamadığında fırlatılır.
class S1000dException implements Exception {
  const S1000dException(this.message, {this.file});

  /// Sorunlu dosyanın adı; dosyadan bağımsız hatalarda (bozuk DMC metni
  /// gibi) boş.
  final String? file;
  final String message;

  @override
  String toString() => file == null ? message : '$file: $message';
}
