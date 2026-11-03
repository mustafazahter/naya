import 'package:flutter/material.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Viewer'ın üst çubuğu: geri düğmesi ve ürün adı.
class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({
    super.key,
    required this.title,
    this.subtitle = 'Şablon · S1000D 5.0',
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          RoundIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Kütüphane',
            onPressed: onBack,
          ),
          const SizedBox(width: NayaSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TechLabel(subtitle),
              const SizedBox(height: 2),
              Text(title, style: context.text.heading),
            ],
          ),
        ),
      ],
    );
  }
}
