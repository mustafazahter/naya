import 'package:flutter/material.dart';

import '../pages/library/library_page.dart';

class NayaApp extends StatelessWidget {
  const NayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'NAYA',
      debugShowCheckedModeBanner: false,
      home: LibraryPage(),
    );
  }
}
