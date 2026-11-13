import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/product/product.dart';
import '../../entities/product/product_content.dart';
import '../../features/diagnose/request_diagnosis.dart';
import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';
import '../../widgets/chat_panel/chat_panel.dart';
import '../../widgets/part_sheet/part_sheet.dart';
import '../../widgets/viewer_panel/model_frame.dart';
import '../../widgets/viewer_panel/model_frame_controller.dart';
import '../../widgets/viewer_panel/model_viewer_panel.dart';
import '../../widgets/viewer_panel/viewer_panel.dart';

/// Çalışma alanı: üstte model, altta sohbet. Geniş ekranda yan yana.
///
/// Model elle döndürülür ve parçalarına ayrılır; parçaya dokununca kartı
/// açılır, karttaki prosedürler DM okuyucuda açılır.
class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({
    super.key,
    required this.product,
    required this.onOpenModule,
  });

  final Product product;

  /// DM okuyucuyu açar. Sayfa diğer sayfaları bilmez; adres app'te.
  final ValueChanged<String> onOpenModule;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  final _viewer = ModelFrameController();

  /// Son teşhis, sürmekte olan mesaj ve hata.
  Diagnosis? _diagnosis;
  String? _pending;
  String? _error;

  /// Aynı konu üzerine yazılanlar. Sistem bir soru sorduysa cevap önceki
  /// belirtilerle birlikte gönderilir.
  final _thread = <String>[];

  /// Her teşhiste artar; eski teşhisin animasyonu yenisini bozmasın.
  var _run = 0;

  Product get product => widget.product;

  @override
  void dispose() {
    _viewer.dispose();
    super.dispose();
  }

  /// Modeldeki bir düğüme dokunuldu.
  void _onNodeTap(String node) {
    final content = ref.read(productContentProvider(product.id)).value;
    if (content == null) return;
    final part = content.partForNode(node);
    if (part == null) return;
    _openPart(content, part.id, node: node);
  }

  void _openPart(ProductContent content, String partId, {String? node}) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    Widget sheet(ScrollController? controller) => _PartSheetHost(
      content: content,
      initialPart: partId,
      node: node,
      controller: controller,
      onOpenModule: widget.onOpenModule,
      // Kartta başka parçaya geçince modelde de o parçaya bakılır.
      onPartChanged: (part) {
        final nodes = content.part(part)?.meshNodes ?? const [];
        if (nodes.isNotEmpty) _viewer.focus(nodes.first);
      },
    );

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
            child: SizedBox(
              width: 440,
              height: double.infinity,
              child: SafeArea(child: sheet(null)),
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
        builder: (context, controller) => sheet(controller),
      ),
    );
  }

  /// Yazılan belirtiyi teşhis ettirir, sonucu sohbette gösterir ve modelde
  /// canlandırır.
  Future<void> _onAsk(String text) async {
    final content = ref.read(productContentProvider(product.id)).value;
    if (content == null || _pending != null) return;

    // Önceki cevap bir soruysa bu mesaj onun cevabı; yeni bir konu değil.
    // Önceki deneme hata verdiyse soru hâlâ açık; konu yine aynı.
    final previous = _diagnosis;
    final followUp =
        previous != null &&
        previous.decision != DiagnosisDecision.focus &&
        previous.decision != DiagnosisDecision.notDiagnosis;
    final earlier = !followUp
        ? const <String>[]
        : _thread.length > 4
        ? _thread.sublist(_thread.length - 4)
        : List.of(_thread);

    final run = ++_run;
    setState(() {
      _pending = text;
      _error = null;
    });
    try {
      final diagnosis = await requestDiagnosis(
        ref.read(apiClientProvider),
        content,
        message: text,
        earlier: earlier,
      );
      if (!mounted || run != _run) return;
      if (!followUp) _thread.clear();
      _thread.add(text);
      setState(() {
        _diagnosis = diagnosis;
        _pending = null;
      });
      await _play(diagnosis, content, run);
    } on Object catch (e) {
      // Ağ hatası da, sunucudan gelen beklenmedik cevap da sohbette bir
      // mesaj olarak görünsün; yoksa "taranıyor" sonsuza dek kalır.
      if (!mounted || run != _run) return;
      setState(() {
        _pending = null;
        _error = switch (e) {
          ApiException(statusCode: 401) =>
            'Teşhis için giriş yapmanız gerekiyor.',
          ApiException(:final message) => message,
          _ => 'Sunucudan beklenmedik bir cevap geldi.',
        };
      });
    }
  }

  /// Teşhis animasyonu (3-4 sn): bant modeli tarar, adaylar olasılıkla
  /// orantılı parlar. Sonuç netse model parçalarına ayrılır ve kamera
  /// bulunan parçaya uçar; değilse adaylar parlak ya da soluk kalır, kamera
  /// yerinde durur.
  Future<void> _play(
    Diagnosis diagnosis,
    ProductContent content,
    int run,
  ) async {
    final weights = scanWeights(diagnosis, content);
    if (_viewer.exploded.value) _viewer.explode(0);
    if (weights.isEmpty) {
      _viewer.highlight(const {});
      return;
    }
    final finished = await _viewer.scan(weights);
    if (!finished || !mounted || run != _run || !diagnosis.isConfident) {
      return;
    }
    final nodes = content.part(diagnosis.top.partId)?.meshNodes ?? const [];
    if (nodes.isEmpty) return;
    _viewer.explode(1);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || run != _run) return;
    _viewer.focus(nodes.first);
  }

  /// Sohbetteki adaya dokunuldu: kartı açılır, modelde ona bakılır.
  void _onCandidateTap(String partId) {
    final content = ref.read(productContentProvider(product.id)).value;
    if (content == null) return;
    final nodes = content.part(partId)?.meshNodes ?? const [];
    if (nodes.isNotEmpty) _viewer.focus(nodes.first);
    _openPart(content, partId);
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(productContentProvider(product.id));
    final api = ref.watch(apiClientProvider);
    final data = content.value;

    final Widget viewer;
    final modelPath = product.modelPath;
    if (isModelFrameSupported && modelPath != null) {
      // Model ve montaj ağacı sunucudan; viewer'ın kendisi uygulamada gömülü.
      final model = productEntryUri(api, product.id, modelPath);
      final map = productEntryUri(api, product.id, 'map/parts.json');
      viewer = ModelViewerPanel(
        productTitle: product.title,
        subtitle: data == null
            ? 'Yükleniyor…'
            : '${data.parts.parts.length} parça · sürükle ve döndür',
        viewerQuery:
            'embed&model=${Uri.encodeQueryComponent('$model')}'
            '&map=${Uri.encodeQueryComponent('$map')}',
        controller: _viewer,
        onPartTap: _onNodeTap,
        partLabel: (node) => data?.nodeLabel(node) ?? node,
        credit: _creditLine(product),
        onBack: () => Navigator.of(context).maybePop(),
      );
    } else {
      // Masaüstünde ve testlerde WebView yok; şematik çizim.
      viewer = ViewerPanel(
        productTitle: product.title,
        diagnosis: sampleDiagnosis,
        onPartTap: (_) {},
        onBack: () => Navigator.of(context).maybePop(),
      );
    }

    final Widget chat = switch (content) {
      AsyncError(:final error) => _ContentError(
        message: error is ApiException
            ? error.message
            : 'Ürünün içeriği okunamadı.',
        onRetry: () => ref.invalidate(productContentProvider(product.id)),
      ),
      _ => ChatPanel(
        suggestions: [
          for (final s in data?.symptoms.take(4) ?? const <Never>[]) s.text,
        ],
        diagnosis: _diagnosis,
        pending: _pending,
        error: _error,
        onSend: _onAsk,
        canSend: data != null,
        onCandidateTap: _onCandidateTap,
        onOpenModule: widget.onOpenModule,
        productId: product.id,
      ),
    };

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

  /// CC BY atfı uygulamada görünmeli: "Model: T-FLEX CAD ST · CC BY 4.0".
  static String? _creditLine(Product product) {
    if (product.credits.isEmpty) return null;
    final credit = product.credits.first;
    final license = credit.license.replaceAll('-', ' ');
    return 'Model: ${credit.author} · $license';
  }
}

/// Kartın içinde parçadan parçaya geçilebilsin diye seçili parçayı tutar.
class _PartSheetHost extends StatefulWidget {
  const _PartSheetHost({
    required this.content,
    required this.initialPart,
    required this.onOpenModule,
    required this.onPartChanged,
    this.node,
    this.controller,
  });

  final ProductContent content;
  final String initialPart;
  final String? node;
  final ScrollController? controller;
  final ValueChanged<String> onOpenModule;
  final ValueChanged<String> onPartChanged;

  @override
  State<_PartSheetHost> createState() => _PartSheetHostState();
}

class _PartSheetHostState extends State<_PartSheetHost> {
  late String _partId = widget.initialPart;

  /// Gidilen parçalar; kartta geri dönebilmek için.
  final _history = <String>[];

  void _select(String id) {
    setState(() {
      _history.add(_partId);
      _partId = id;
    });
    widget.onPartChanged(id);
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.content.part(_partId);
    if (part == null) return const SizedBox.shrink();
    return PopScope(
      // Alt parçadan geri tuşu önce önceki parçaya döner.
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _history.isEmpty) return;
        setState(() => _partId = _history.removeLast());
        widget.onPartChanged(_partId);
      },
      child: AnimatedSwitcher(
        duration: NayaMotion.base,
        switchInCurve: NayaMotion.decelerate,
        child: PartSheet(
          key: ValueKey(_partId),
          content: widget.content,
          part: part,
          // Dokunulan düğüm yalnız ilk açılan parça için anlamlı.
          node: _partId == widget.initialPart ? widget.node : null,
          controller: widget.controller,
          onOpenModule: widget.onOpenModule,
          onSelectPart: _select,
        ),
      ),
    );
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'İçerik yüklenemedi',
        message: message,
        actionLabel: 'Yeniden dene',
        onAction: onRetry,
      ),
    );
  }
}
