import 'package:flutter/material.dart';

import '../entities/product/product.dart';
import '../pages/library/library_page.dart';
import '../pages/workspace/workspace_page.dart';
import '../shared/ui/routes.dart';
import '../shared/ui/theme.dart';

class NayaApp extends StatelessWidget {
  const NayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NAYA',
      debugShowCheckedModeBanner: false,
      // Tema cihaz ayarından gelir.
      themeMode: ThemeMode.system,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: Builder(
        builder: (context) =>
            LibraryPage(onOpen: (product) => _openWorkspace(context, product)),
      ),
    );
  }

  // Yönlendirme şimdilik burada; uygulama iskeletinde (2C) router'a taşınacak.
  void _openWorkspace(BuildContext context, Product product) {
    Navigator.of(context)
        .push(fadeThroughRoute<void>((_) => WorkspacePage(product: product)));
  }
}
