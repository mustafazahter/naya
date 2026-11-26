import 'dart:async';

import '../api/api_client.dart';

/// Web: modeller tarayıcının HTTP önbelleğinde. Adresler sürümlü (`?v=`)
/// ve sunucu onları bir yıl `immutable` önbelleklettiği için ayrı bir
/// önbellek gerekmez; viewer iframe'i aynı adresi isteyince önbellekten
/// gelir.
class ModelCache {
  ModelCache._();

  static final instance = ModelCache._();

  final _started = <String>{};

  /// Web'de viewer modeli doğrudan sunucudan alır.
  String? localPath(
    ApiClient api,
    String productId,
    String path, {
    required String? version,
  }) => null;

  /// Modeli önbelleğe çeker (kartın üstüne gelinince). Sürümsüz adres
  /// kısa önbellekte kalacağı için çekilmez; her adres bir kez.
  void prefetch(
    ApiClient api,
    String productId,
    String path, {
    required String? version,
  }) {
    if (version == null || !_started.add(path)) return;
    unawaited(
      api.getBytes(path).then<void>((_) {}).catchError((Object _) {
        _started.remove(path);
      }),
    );
  }
}
