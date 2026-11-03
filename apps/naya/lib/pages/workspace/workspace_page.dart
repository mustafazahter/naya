import 'package:flutter/material.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/part/part.dart';
import '../../entities/product/product.dart';
import '../../shared/config/env.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import '../../widgets/chat_panel/chat_panel.dart';
import '../../widgets/part_sheet/part_sheet.dart';
import '../../widgets/viewer_panel/model_frame.dart';
import '../../widgets/viewer_panel/model_viewer_panel.dart';
import '../../widgets/viewer_panel/viewer_panel.dart';

/// Çalışma alanı: üstte model, altta sohbet. Geniş ekranda yan yana.
class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key, required this.product});

  final Product product;

  void _openPart(BuildContext context, String partId) {
    // Taslakta her aday aynı örnek parçayı açıyor.
    const part = sampleChain;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Kapat',
        barrierColor: Colors.black38,
        transitionDuration: NayaMotion.base,
        pageBuilder: (context, _, _) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: context.colors.surface,
            child: const SizedBox(
              width: 440,
              height: double.infinity,
              child: SafeArea(child: PartSheet(part: part)),
            ),
          ),
        ),
        transitionBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0.15, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: NayaMotion.decelerate,
                ),
              ),
          child: FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: NayaRadius.lg),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.94,
        builder: (context, controller) =>
            PartSheet(part: part, controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Şimdilik yalnız bisikletin gerçek modeli var; diğerleri şemayla.
    final model = product.modelFile;
    final Widget viewer = isModelFrameSupported && model != null
        ? ModelViewerPanel(
            productTitle: product.title,
            modelUrl: '$viewerUrl/?embed&model=$model',
            onPartTap: (id) => _openPart(context, id),
            onBack: () => Navigator.of(context).maybePop(),
          )
        : ViewerPanel(
            productTitle: product.title,
            diagnosis: sampleDiagnosis,
            onPartTap: (id) => _openPart(context, id),
            onBack: () => Navigator.of(context).maybePop(),
          );
    final chat = ChatPanel(
      diagnosis: sampleDiagnosis,
      onCandidateTap: (id) => _openPart(context, id),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(child: viewer),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: context.colors.line),
                    ),
                  ),
                  child: SizedBox(width: 420, child: chat),
                ),
              ],
            );
          }
          return Column(
            children: [
              SizedBox(height: box.maxHeight * 0.5, child: viewer),
              Expanded(child: chat),
            ],
          );
        },
      ),
    );
  }
}
