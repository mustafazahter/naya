/// İçe aktarmayı durduran hata. [message] kullanıcıya olduğu gibi
/// gösterilir; [code] API'nin hata kodu.
class ImportException implements Exception {
  const ImportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
