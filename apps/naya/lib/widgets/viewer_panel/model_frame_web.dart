import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../../shared/config/env.dart';
import 'model_frame_controller.dart';

const isModelFrameSupported = true;

/// three.js viewer'ı bir iframe içinde gösterir. Komutlar `postMessage` ile
/// gider, viewer'ın olayları (`partTap`) aynı yoldan geri gelir.
class ModelFrame extends StatefulWidget {
  const ModelFrame({
    super.key,
    required this.query,
    required this.controller,
    required this.onPartTap,
    this.onReady,
    this.onScanDone,
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

  /// false iken dokunuşlar viewer'a gitmez; üstte bir pencere ya da alt
  /// sayfa açıkken onların tıklamalarını yutmasın diye.
  final bool interactive;

  @override
  State<ModelFrame> createState() => _ModelFrameState();
}

class _ModelFrameState extends State<ModelFrame> {
  static var _count = 0;

  late final String _viewType = 'naya-viewer-${_count++}';
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _onMessage = _handleMessage.toJS;

  @override
  void initState() {
    super.initState();
    _frame = web.HTMLIFrameElement()
      ..src = _url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _frame);
    web.window.addEventListener('message', _onMessage);
    widget.controller.attach(_send);
  }

  /// Gömülü viewer uygulamayla aynı sunucudan gelir; Flutter web asset'leri
  /// `assets/` altında yayınlar.
  String get _url => viewerUrl.isEmpty
      ? 'assets/assets/viewer/index.html?${widget.query}'
      : '$viewerUrl/?${widget.query}';

  @override
  void dispose() {
    widget.controller.detach();
    web.window.removeEventListener('message', _onMessage);
    super.dispose();
  }

  void _send(Map<String, Object?> command) {
    _frame.contentWindow?.postMessage(command.jsify(), '*'.toJS);
  }

  void _handleMessage(web.Event event) {
    final message = event as web.MessageEvent;
    if (message.source != _frame.contentWindow) return;
    final data = message.data.dartify();
    if (data is! Map) return;
    switch (data['type']) {
      case 'partTap':
        widget.onPartTap(data['part'] as String?);
      case 'ready':
        widget.onReady?.call();
      case 'scanDone':
        final id = data['id'];
        if (id is num) widget.onScanDone?.call(id.toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web'de iframe, Flutter'ın üstünde çizdiği her şeyin altından tıklamayı
    // kendine alır. Üstte bir pencere açıkken iframe dokunuşa kapanır.
    _frame.style.pointerEvents = widget.interactive ? 'auto' : 'none';
    return HtmlElementView(viewType: _viewType);
  }
}
