import 'package:flutter/material.dart';

import '../../entities/part/part.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import 'model_frame.dart';
import 'model_frame_controller.dart';
import 'viewer_top_bar.dart';

/// Gerçek 3D model: elle döndürülür, yakınlaşılır, parçalarına ayrılır.
/// Model three.js viewer'da çiziliyor; kontroller ve etiketler burada.
class ModelViewerPanel extends StatefulWidget {
  const ModelViewerPanel({
    super.key,
    required this.productTitle,
    required this.viewerQuery,
    required this.onPartTap,
    this.focusPart,
    this.onBack,
  });

  final String productTitle;

  /// Viewer'a giden sorgu, örneğin `embed&model=./models/bicycle.glb`.
  final String viewerQuery;
  final ValueChanged<String> onPartTap;

  /// Teşhiste bulunan parça (düğüm adı). Model yüklenince kamera ona
  /// yaklaşır, diğer parçalar saydamlaşır.
  final String? focusPart;
  final VoidCallback? onBack;

  @override
  State<ModelViewerPanel> createState() => _ModelViewerPanelState();
}

class _ModelViewerPanelState extends State<ModelViewerPanel> {
  final _controller = ModelFrameController();
  var _exploded = false;
  var _xray = false;
  String? _selected;

  void _onPartTap(String? id) {
    setState(() => _selected = id);
    if (id != null) widget.onPartTap(id);
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.focusPart;
  }

  /// Odaklanılacak parça adreste gider; viewer model her yüklendiğinde
  /// kendisi yaklaşır, mesajın zamanlamasına bağlı kalmaz.
  String get _query {
    final focus = widget.focusPart;
    return focus == null
        ? widget.viewerQuery
        : '${widget.viewerQuery}&focus=${Uri.encodeQueryComponent(focus)}';
  }

  void _reset() {
    setState(() {
      _exploded = false;
      _xray = false;
      _selected = null;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        Positioned.fill(
          child: ModelFrame(
            query: _query,
            controller: _controller,
            onPartTap: _onPartTap,
          ),
        ),
        Positioned(
          left: NayaSpace.md,
          right: NayaSpace.md,
          top: NayaSpace.md,
          child: SafeArea(
            bottom: false,
            child: ViewerTopBar(
              title: widget.productTitle,
              subtitle: '3D · sürükle ve döndür',
              onBack: widget.onBack,
            ),
          ),
        ),
        Positioned(
          right: NayaSpace.md,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundIconButton(
                  icon: Icons.open_in_full,
                  tooltip: 'Parçalarına ayır',
                  selected: _exploded,
                  onPressed: () {
                    setState(() => _exploded = !_exploded);
                    _controller.explode(_exploded ? 1 : 0);
                  },
                ),
                const SizedBox(height: NayaSpace.sm),
                RoundIconButton(
                  icon: Icons.blur_on,
                  tooltip: 'X-ışını',
                  selected: _xray,
                  onPressed: () {
                    setState(() => _xray = !_xray);
                    _controller.xray(_xray);
                  },
                ),
                const SizedBox(height: NayaSpace.sm),
                RoundIconButton(
                  icon: Icons.center_focus_strong,
                  tooltip: 'Görünümü sıfırla',
                  onPressed: _reset,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: NayaSpace.lg,
          bottom: NayaSpace.lg,
          child: IgnorePointer(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selected == null ? c.platinum : c.accent,
                  ),
                ),
                const SizedBox(width: NayaSpace.sm),
                TechLabel(
                  _selected == null
                      ? 'Parçaya dokun'
                      : bicyclePartNames[_selected] ?? _selected!,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
