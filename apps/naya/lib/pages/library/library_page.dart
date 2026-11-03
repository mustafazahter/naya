import 'package:flutter/material.dart';

import '../../shared/config/env.dart';

/// Şimdilik boş. Kütüphane ekranı tasarım taslağından sonra dolacak.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('NAYA · $apiUrl')));
  }
}
