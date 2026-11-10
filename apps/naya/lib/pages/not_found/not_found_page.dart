import 'package:flutter/material.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/tokens.dart';

/// Adresi bilinmeyen ya da artık olmayan bir ürüne gidilince çıkar.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NayaSpace.gutter),
          child: EmptyState(
            icon: Icons.explore_off_outlined,
            title: 'Burada bir şey yok',
            message: 'Aradığın ürün kaldırılmış ya da adres yanlış olabilir.',
            actionLabel: 'Kütüphaneye dön',
            onAction: onHome,
          ),
        ),
      ),
    );
  }
}
