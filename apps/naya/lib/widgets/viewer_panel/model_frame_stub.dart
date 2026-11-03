import 'package:flutter/widgets.dart';

import 'model_frame_controller.dart';

const isModelFrameSupported = false;

class ModelFrame extends StatelessWidget {
  const ModelFrame({
    super.key,
    required this.url,
    required this.controller,
    required this.onPartTap,
  });

  final String url;
  final ModelFrameController controller;
  final ValueChanged<String?> onPartTap;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
