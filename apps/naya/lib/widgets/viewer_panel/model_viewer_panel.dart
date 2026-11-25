import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import '../../shared/utils/turkish_text.dart';
import 'model_frame.dart';
import 'model_frame_controller.dart';
import 'model_loader.dart';
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
    this.onOpenDetails,
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

  /// Seçili parçanın bütün ayrıntılarını açar (düğüm adıyla). Verilirse
  /// parça seçiliyken altta "Ayrıntılar" düğmesi çıkar.
  final ValueChanged<String>? onOpenDetails;

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

  /// Yükleme ekranının durumu. Ekran kapanış animasyonu bitince kalkar.
  double _progress = 0;
  var _ready = false;
  var _failed = false;
  var _loading = true;

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

  final _topBarKey = GlobalKey();
  final _buttonsKey = GlobalKey();
  final _bottomRowKey = GlobalKey();
  EdgeInsets? _sentInsets;

  /// Üst çubuk, sağdaki düğmeler ve alt satırın modelin hangi kenarlarını
  /// kapladığını viewer'a bildirir. Değişmediyse yeniden göndermez.
  void _reportInsets() {
    if (!mounted || !_ready) return;
    final panel = context.findRenderObject() as RenderBox?;
    if (panel == null || !panel.hasSize) return;
    Rect? rectOf(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      return box.localToGlobal(Offset.zero, ancestor: panel) & box.size;
    }

    final top = rectOf(_topBarKey);
    final buttons = rectOf(_buttonsKey);
    final bottom = rectOf(_bottomRowKey);
    final insets = EdgeInsets.only(
      top: top?.bottom ?? 0,
      right: buttons == null ? 0 : panel.size.width - buttons.left,
      bottom: bottom == null ? 0 : panel.size.height - bottom.top,
    );
    if (insets == _sentInsets) return;
    _sentInsets = insets;
    _controller.insets(insets);
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
    // Düğmeler ve yazılar yerleşince ölçülür; ekran döner ya da parça
    // seçilip yeni düğme çıkarsa yeniden.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportInsets());
    final c = context.colors;
    return Stack(
      children: [
        Positioned.fill(
          // WebView'in içini ekran okuyucu göremez; ne olduğunu ve seçili
          // parçayı burada söyleriz. Parçalar sohbetten ve kartlardan da
          // açılabildiği için modele dokunmak zorunlu değil.
          child: Semantics(
            image: true,
            label:
                '${widget.productTitle}, 3D model'
                '${_selected == null ? '' : '. Seçili: ${widget.partLabel?.call(_selected!) ?? _selected}'}',
            child: ModelFrame(
              query: _query,
              controller: _controller,
              onPartTap: _onPartTap,
              onScanDone: _controller.scanFinished,
              onProgress: (value) => setState(() => _progress = value),
              onReady: () {
                _controller.markReady();
                setState(() => _ready = true);
              },
              onLoadFailed: () => setState(() => _failed = true),
              // Üstte parça kartı ya da başka bir pencere açıksa model dokunuşu
              // almasın.
              interactive: ModalRoute.isCurrentOf(context) ?? true,
            ),
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: PointerInterceptor(
              child: ModelLoader(
                title: widget.productTitle,
                progress: _progress,
                ready: _ready,
                failed: _failed,
                onFinished: () => setState(() => _loading = false),
              ),
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
                key: _topBarKey,
                title: widget.productTitle,
                subtitle: widget.subtitle,
                onBack: widget.onBack,
              ),
            ),
          ),
        ),
        // Düğmeler ve alt satır model hazır olunca belirir; yükleme
        // ekranının sayacının üstüne binmesin.
        Positioned(
          right: NayaSpace.md,
          top: 0,
          bottom: 0,
          child: _ShowWhen(
            visible: _ready,
            child: Center(
              child: PointerInterceptor(
                child: Column(
                  key: _buttonsKey,
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
        ),
        // Seçili parça solda, atıf sağda; aynı satırda oldukları için uzun
        // bir parça adı atfın üstüne binmez, kısalır.
        Positioned(
          left: NayaSpace.lg,
          right: NayaSpace.lg,
          bottom: NayaSpace.lg,
          child: _ShowWhen(
            visible: _ready,
            child: Row(
              key: _bottomRowKey,
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
                if (_selected != null && widget.onOpenDetails != null) ...[
                  const SizedBox(width: NayaSpace.md),
                  PointerInterceptor(
                    child: _DetailsButton(
                      onPressed: () => widget.onOpenDetails!(_selected!),
                    ),
                  ),
                ],
                if (widget.credit != null) ...[
                  const SizedBox(width: NayaSpace.md),
                  // Uzun atıf telefonda satırı taşırıp parça adını siliyordu;
                  // en fazla yarı genişlik, gerekirse iki satır.
                  Flexible(
                    child: Text(
                      widget.credit!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: context.text.small.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
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

/// Hazır olana kadar gizli ve dokunulmaz; sonra yumuşakça belirir.
class _ShowWhen extends StatelessWidget {
  const _ShowWhen({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: NayaMotion.slow,
        curve: NayaMotion.standard,
        child: child,
      ),
    );
  }
}

/// Seçili parçanın ayrıntı sayfasını açan küçük hap düğme.
class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.accent,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NayaSpace.lg,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ayrıntılar',
                style: context.text.small.copyWith(
                  color: c.onAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: NayaSpace.xs),
              Icon(Icons.arrow_forward, size: 16, color: c.onAccent),
            ],
          ),
        ),
      ),
    );
  }
}
