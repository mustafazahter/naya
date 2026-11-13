import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import '../../shared/utils/turkish_text.dart';
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
    this.controller,
    this.partLabel,
    this.subtitle = '3D · sürükle ve döndür',
    this.credit,
  });

  final String productTitle;

  /// Viewer'a giden sorgu, örneğin `embed&model=./models/bicycle.glb`.
  final String viewerQuery;
  final ValueChanged<String> onPartTap;

  /// Teşhiste bulunan parça (düğüm adı). Model yüklenince kamera ona
  /// yaklaşır, diğer parçalar saydamlaşır.
  final String? focusPart;
  final VoidCallback? onBack;

  /// Dışarıdan komut göndermek için (teşhis taraması gibi). Verilmezse
  /// panel kendi denetleyicisini kullanır.
  final ModelFrameController? controller;

  /// Seçili düğümün ekranda görünecek adı (`drive_chain` → "Zincir").
  final String Function(String node)? partLabel;

  /// Üst çubukta başlığın altındaki satır.
  final String subtitle;

  /// Modelin atfı (CC BY); sağ altta küçük yazılır.
  final String? credit;

  @override
  State<ModelViewerPanel> createState() => _ModelViewerPanelState();
}

class _ModelViewerPanelState extends State<ModelViewerPanel> {
  late final _controller = widget.controller ?? ModelFrameController();
  var _xray = false;
  var _isolated = false;
  String? _selected;

  void _onPartTap(String? id) {
    // İzole görünümde boşluğa dokunmak seçimi kaldırmasın; yoksa "bütün
    // modeli göster" düğmesi de kaybolur.
    if (id == null && _isolated) return;
    setState(() => _selected = id);
    if (id != null) widget.onPartTap(id);
  }

  /// Seçili parçayı tek başına gösterir ya da bütün modele döner.
  void _toggleIsolate() {
    final part = _selected;
    if (part == null) return;
    setState(() => _isolated = !_isolated);
    _controller.isolate(_isolated ? part : null);
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.focusPart;
  }

  @override
  void dispose() {
    // Dışarıdan verilen denetleyiciyi sahibi kapatır.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
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
      _xray = false;
      _isolated = false;
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
            onScanDone: _controller.scanFinished,
            // Üstte parça kartı ya da başka bir pencere açıksa model dokunuşu
            // almasın.
            interactive: ModalRoute.isCurrentOf(context) ?? true,
          ),
        ),
        Positioned(
          left: NayaSpace.md,
          right: NayaSpace.md,
          top: NayaSpace.md,
          child: SafeArea(
            bottom: false,
            // Web'de model bir iframe; üstündeki düğmeler PointerInterceptor
            // olmadan tıklanamıyor, tıklama iframe'e gidiyor.
            child: PointerInterceptor(
              child: ViewerTopBar(
                title: widget.productTitle,
                subtitle: widget.subtitle,
                onBack: widget.onBack,
              ),
            ),
          ),
        ),
        Positioned(
          right: NayaSpace.md,
          top: 0,
          bottom: 0,
          child: Center(
            child: PointerInterceptor(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Teşhis animasyonu da modeli ayırabildiği için durum
                  // denetleyicide.
                  ValueListenableBuilder(
                    valueListenable: _controller.exploded,
                    builder: (context, exploded, _) => RoundIconButton(
                      icon: Icons.open_in_full,
                      tooltip: 'Parçalarına ayır',
                      selected: exploded,
                      onPressed: () => _controller.explode(exploded ? 0 : 1),
                    ),
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
                  // Yalnız bir parça seçiliyken anlamlı.
                  if (_selected != null) ...[
                    const SizedBox(height: NayaSpace.sm),
                    RoundIconButton(
                      icon: Icons.filter_center_focus,
                      tooltip: _isolated
                          ? 'Bütün modeli göster'
                          : 'Yalnız bunu göster',
                      selected: _isolated,
                      onPressed: _toggleIsolate,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Seçili parça solda, atıf sağda; aynı satırda oldukları için uzun
        // bir parça adı atfın üstüne binmez, kısalır.
        Positioned(
          left: NayaSpace.lg,
          right: NayaSpace.lg,
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
                Expanded(
                  child: Text(
                    turkishUpperCase(
                      _selected == null
                          ? 'Parçaya dokun'
                          : widget.partLabel?.call(_selected!) ?? _selected!,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label.copyWith(color: c.textSecondary),
                  ),
                ),
                if (widget.credit != null) ...[
                  const SizedBox(width: NayaSpace.md),
                  Text(
                    widget.credit!,
                    style: context.text.small.copyWith(
                      fontSize: 10,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
