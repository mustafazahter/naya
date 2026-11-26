import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'shared/api/api_client.dart';
import 'shared/api/token_store.dart';

Future<void> main() async {
  // Web'de adresler `#/` olmadan: `/urun/<id>`, `/ayarlar`. Sunucu bilinmeyen
  // adreste index.html veriyor (4D); bu çağrı olmadan Flutter adresi yok
  // sayıp kütüphaneyi açıyordu, yenileme ve paylaşılan bağlantı bozuktu.
  // Android'de etkisi yok.
  // Eski `/#/urun/<id>` bağlantıları da açılsın: hash yol adresine çevrilir.
  if (kIsWeb && Uri.base.fragment.startsWith('/')) {
    BrowserPlatformLocation().replaceState(null, '', Uri.base.fragment);
  }
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // Android'de saklı oturum ilk istekten önce yüklensin; yoksa kütüphane
  // misafir gibi istenir ve kullanıcının dosyaları görünmez.
  final container = ProviderContainer();
  container.read(apiClientProvider).token = await container
      .read(tokenStoreProvider)
      .read();
  runApp(
    UncontrolledProviderScope(container: container, child: const NayaApp()),
  );
}
