import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/ui/theme.dart';
import 'router.dart';

class NayaApp extends ConsumerWidget {
  const NayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'NAYA',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      // Tema cihaz ayarından gelir.
      themeMode: ThemeMode.system,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
