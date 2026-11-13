import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naya_s1000d/naya_s1000d.dart';

import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import 'product_content.dart';

/// DM'deki çizim; `.naya` içinden sunucudan gelir. Dokununca tam ekran,
/// iki parmakla yakınlaştırılabilir.
class DmFigureView extends ConsumerWidget {
  const DmFigureView(this.figure, {super.key, required this.productId});

  final DmFigure figure;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final content = ref.watch(productContentProvider(productId)).value;
    final api = ref.watch(apiClientProvider);
    final urls = [
      for (final icn in figure.icns)
        if (content?.icnPath(icn) case final path?)
          productEntryUri(api, productId, path).toString(),
    ];
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final url in urls)
          Padding(
            padding: const EdgeInsets.only(bottom: NayaSpace.sm),
            child: GestureDetector(
              onTap: () => _zoom(context, url),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(NayaRadius.md),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: c.line),
                    borderRadius: const BorderRadius.all(NayaRadius.md),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      semanticLabel: figure.title,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const SkeletonBlock(),
                      errorBuilder: (context, _, _) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (figure.title.isNotEmpty)
          Row(
            children: [
              Expanded(child: TechLabel('Şekil · ${figure.title}')),
              const SizedBox(width: NayaSpace.sm),
              Icon(Icons.zoom_in, size: 16, color: c.textMuted),
            ],
          ),
      ],
    );
  }

  void _zoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(child: Image.network(url, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
