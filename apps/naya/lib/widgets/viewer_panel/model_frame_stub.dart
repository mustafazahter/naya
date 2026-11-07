import 'package:flutter/widgets.dart';

import 'model_frame_controller.dart';

const isModelFrameSupported = false;

class ModelFrame extends StatelessWidget {
  const ModelFrame({
    super.key,
    required this.query,
    required this.controller,
    required this.onPartTap,
    this.onReady,
  });

  /// Viewer adresine eklenecek sorgu: `embed&model=...&focus=...`.
  final String query;
  final ModelFrameController controller;
  final ValueChanged<String?> onPartTap;

  /// Model yüklenip viewer komut almaya hazır olduğunda.
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
