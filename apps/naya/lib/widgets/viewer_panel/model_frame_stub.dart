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
    this.onScanDone,
    this.onProgress,
    this.onLoadFailed,
    this.interactive = true,
  });

  /// Viewer adresine eklenecek sorgu: `embed&model=...&focus=...`.
  final String query;
  final ModelFrameController controller;
  final ValueChanged<String?> onPartTap;

  /// Model yüklenip viewer komut almaya hazır olduğunda.
  final VoidCallback? onReady;

  /// Tarama animasyonu bittiğinde.
  final ValueChanged<int>? onScanDone;

  /// Model inerken 0-1 arası ilerleme.
  final ValueChanged<double>? onProgress;

  /// Model yüklenemediğinde.
  final VoidCallback? onLoadFailed;

  /// false iken dokunuşlar viewer'a gitmez; üstte bir pencere ya da alt
  /// sayfa açıkken onların tıklamalarını yutmasın diye.
  final bool interactive;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
