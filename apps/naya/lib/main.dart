import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'shared/api/api_client.dart';
import 'shared/api/token_store.dart';

Future<void> main() async {
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
