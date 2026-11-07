import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../shared/config/env.dart';
import '../../shared/platform/viewer_asset_server.dart';
import 'model_frame_controller.dart';

/// WebView yalnız mobilde var; masaüstünde ve testlerde yer tutucu çizilir.
bool get isModelFrameSupported => Platform.isAndroid || Platform.isIOS;

/// three.js viewer'ı bir WebView içinde gösterir (Android).
///
/// Viewer uygulamanın içindeki `assets/viewer`'dan, cihazın kendi içinde
/// açılan küçük bir sunucu üzerinden yüklenir. Komutlar sayfaya
/// `window.postMessage` ile gider; viewer'ın olayları `NayaBridge` adlı
/// JavaScript kanalından gelir. Mesajların biçimi web'deki iframe ile aynı.
class ModelFrame extends StatefulWidget {
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
  State<ModelFrame> createState() => _ModelFrameState();
}

class _ModelFrameState extends State<ModelFrame> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel('NayaBridge', onMessageReceived: _onMessage);
    widget.controller.attach(_send);
    _load();
  }

  @override
  void didUpdateWidget(ModelFrame old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _load();
    if (old.controller != widget.controller) {
      old.controller.detach();
      widget.controller.attach(_send);
    }
  }

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  Future<void> _load() async {
    final base = viewerUrl.isEmpty
        ? (await ViewerAssetServer.shared()).baseUrl
        : '$viewerUrl/';
    if (!mounted) return;
    await _web.loadRequest(Uri.parse('$base?${widget.query}'));
  }

  void _send(Map<String, Object?> command) {
    _web.runJavaScript('window.postMessage(${jsonEncode(command)}, "*");');
  }

  void _onMessage(JavaScriptMessage message) {
    final Object? data;
    try {
      data = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (data is! Map) return;
    switch (data['type']) {
      case 'partTap':
        widget.onPartTap(data['part'] as String?);
      case 'ready':
        widget.onReady?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _web,
      // Sürükleme ve iki parmakla yakınlaştırma doğrudan modele gitsin;
      // üstteki kaydırılabilir alanlar hareketi kapmasın.
      gestureRecognizers: {
        const Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }
}
