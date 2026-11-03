/// ZIP'in ilk kaydı olan `mimetype` dosyasının içeriği.
const nayaMimeType = 'application/vnd.naya+zip';

/// Bu paketin yazdığı format sürümü.
const currentFormatVersion = '1.0.0';

/// Okunabilen ana sürüm. Uyumu bozan her değişiklik bunu artırır.
const supportedMajorVersion = 1;

final _semver = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

/// `"1.2.3"` için 1 döner; sürüm bu biçimde değilse null.
int? majorVersionOf(String version) {
  final match = _semver.firstMatch(version);
  return match == null ? null : int.parse(match.group(1)!);
}
