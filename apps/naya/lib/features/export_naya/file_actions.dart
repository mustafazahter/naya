import 'package:file_picker/file_picker.dart';

import '../../entities/product/product.dart';
import '../../shared/api/api_client.dart';

/// Dosyayı `.naya` olarak indirir ve kullanıcıya nereye kaydedeceğini
/// sorar. Web'de tarayıcının indirmesi, Android'de "Farklı kaydet".
/// Vazgeçilirse false.
///
/// İndirilen dosya sunucudakiyle bayt bayt aynı; tekrar içe aktarıldığında
/// aynı içerik açılır.
Future<bool> exportNaya(ApiClient api, Product product) async {
  final bytes = await api.getBytes('/api/library/${product.id}/file');
  final saved = await FilePicker.saveFile(
    dialogTitle: '.naya olarak kaydet',
    fileName: nayaFileName(product.title),
    bytes: bytes,
    mimeType: 'application/vnd.naya+zip',
  );
  return saved != null;
}

/// Kullanıcının kendi dosyasını siler.
Future<void> deleteUserFile(ApiClient api, Product product) =>
    api.delete('/api/library/${product.id}');

/// Başlıktan dosya adı: dosya sistemlerinin kabul etmediği işaretler
/// çıkar, Türkçe harfler kalır.
String nayaFileName(String title) {
  final cleaned = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return '${cleaned.isEmpty ? 'urun' : cleaned}.naya';
}
