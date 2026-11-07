/// `.naya` okunurken ya da yazılırken çıkan hataların ortak tipi.
///
/// Uygulama tek bir tip yakalayıp mesajı kullanıcıya gösterebilsin diye
/// hepsi bu sınıftan türer.
sealed class NayaFormatException implements Exception {
  const NayaFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Dosya bir `.naya` kabı değil: ZIP bozuk, `mimetype` yok ya da yanlış yerde.
class InvalidContainerException extends NayaFormatException {
  const InvalidContainerException(super.message);
}

/// Bir JSON dosyası (manifest ya da harita) beklenen yapıda değil.
class InvalidJsonException extends NayaFormatException {
  const InvalidJsonException(this.file, String problem)
    : super('$file: $problem');

  final String file;
}

/// Dosya, uygulamanın okuyamadığı bir ana sürümle yazılmış.
class UnsupportedVersionException extends NayaFormatException {
  const UnsupportedVersionException(this.version)
    : super(
        'Bu dosya format sürümü $version ile yazılmış; '
        'bu uygulama yalnız 1.x okuyabiliyor.',
      );

  final String version;
}

/// Dosyanın içeriği manifestteki SHA-256 özetleriyle uyuşmuyor.
class IntegrityException extends NayaFormatException {
  IntegrityException(this.problems)
    : super('Dosya bütünlüğü bozuk: ${problems.join('; ')}');

  final List<String> problems;
}

/// Harita dosyaları kendi içinde geçerli ama birbirini tutmuyor: bir arıza
/// olmayan parçayı, bir parça olmayan bölgeyi gösteriyor gibi.
class InvalidReferencesException extends NayaFormatException {
  InvalidReferencesException(this.problems)
    : super('Dosyalar arası bağlar bozuk: ${problems.join('; ')}');

  final List<String> problems;
}
