import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/diagnosis/diagnosis.dart';
import '../../entities/product/product.dart';
import '../../entities/product/product_content.dart';
import '../../features/ask_ai/ask_ai.dart';
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

/// Çalışma alanında açılışta yapılacak iş; adresten gelir
/// (`?teshis=12`, `?sohbet=3`, `?sor=drive.chain`).
sealed class WorkspaceRequest {
  const WorkspaceRequest();
}

/// Geçmişteki teşhisi aç ve modelde yeniden oynat.
class OpenDiagnosis extends WorkspaceRequest {
  const OpenDiagnosis(this.id);
  final int id;
  @override
  bool operator ==(Object other) => other is OpenDiagnosis && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Kayıtlı sohbeti aç; yazılanlar aynı sohbete devam eder.
class OpenConversation extends WorkspaceRequest {
  const OpenConversation(this.id);
  final int id;
  @override
  bool operator ==(Object other) => other is OpenConversation && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Bir parça hakkında yeni sohbet başlat.
class AskAboutPart extends WorkspaceRequest {
  const AskAboutPart(this.partId);
  final String partId;
  @override
  bool operator ==(Object other) =>
      other is AskAboutPart && other.partId == partId;
  @override
  int get hashCode => partId.hashCode;
}

/// Çalışma alanı: üstte model, altta sohbet. Geniş ekranda yan yana.
///
/// Model elle döndürülür ve parçalarına ayrılır; parçaya dokununca kartı
/// açılır, karttaki prosedürler DM okuyucuda açılır. İlk mesaj teşhise
/// gider; sonuç netse sonraki sorular bulunan parça hakkında sohbete döner.
class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({
    super.key,
    required this.product,
    required this.onOpenModule,
    required this.onOpenPart,
    this.request,
    this.onRequestHandled,
    this.onOpenHistory,
    this.onSignIn,
    this.onOpenSettings,
  });

  final Product product;

  /// DM okuyucuyu açar. Sayfa diğer sayfaları bilmez; adres app'te.
  final ValueChanged<String> onOpenModule;

  /// Parçanın ayrıntı sayfasını açar (parça kimliğiyle).
  final ValueChanged<String> onOpenPart;
  final WorkspaceRequest? request;

  /// İstek alındı; adresteki sorgu temizlenir. Böylece "Yeni konu"dan sonra
  /// aynı teşhis ya da parça yeniden açılınca istek yine gelir.
  final VoidCallback? onRequestHandled;
  final VoidCallback? onOpenHistory;

  /// Yapay zekâ giriş ya da anahtar isterse sohbetteki düğmeler.
  final VoidCallback? onSignIn;
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  final _viewer = ModelFrameController();

  final _turns = <ChatTurn>[];
  var _diagnosing = false;
  ChatNotice? _notice;

  /// Son mesaj cevapsız kaldıysa (hata) yeniden yazılan onun yerine geçer;
  /// sohbette aynı soru iki kez görünmesin.
  var _lastFailed = false;

  /// Son teşhis. Bir soru sorduysa sıradaki mesaj onun cevabıdır.
  Diagnosis? _diagnosis;

  /// Aynı konu üzerine yazılanlar. Sistem bir soru sorduysa cevap önceki
  /// belirtilerle birlikte gönderilir.
  final _thread = <String>[];

  /// Sohbet modunda mıyız? Teşhis netleşince ya da bir parça sorulunca
  /// sonraki mesajlar sohbete gider. [_part] varsa sohbet o parça hakkında.
  var _chatting = false;
  String? _part;
  int? _conversation;
  StreamSubscription<AnswerEvent>? _answer;

  /// Her teşhiste artar; eski teşhisin animasyonu yenisini bozmasın.
  var _run = 0;

  /// Geniş ekranda sağ sütunda açık parça kartı; null ise sohbet görünür.
  /// Kart viewer'ın üstüne binmez, viewer düğmeleri hep görünür kalır.
  _DockedPart? _docked;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    _viewer.onEscape = _closeDocked;
    if (widget.request != null) unawaited(_handle(widget.request!));
  }

  @override
  void didUpdateWidget(WorkspacePage old) {
    super.didUpdateWidget(old);
    final request = widget.request;
    if (request != null && request != old.request) unawaited(_handle(request));
  }

  @override
  void dispose() {
    unawaited(_answer?.cancel());
    _viewer.dispose();
    super.dispose();
  }

  /// Adresten gelen isteği içerik yüklenince uygular.
  Future<void> _handle(WorkspaceRequest request) async {
    final ProductContent content;
    try {
      content = await ref.read(productContentProvider(product.id).future);
    } on Object {
      return; // İçerik hatası sohbet yerine zaten gösteriliyor.
    }
    if (!mounted) return;
    widget.onRequestHandled?.call();
    _reset();
    // Yükleme sürerken kullanıcı yeni bir şey başlatırsa (mesaj, "Yeni
    // konu", "hakkında sor") [_run] değişir; eski istek sohbete yazmaz.
    final run = _run;
    final api = ref.read(apiClientProvider);
    try {
      switch (request) {
        case AskAboutPart(:final partId):
          if (content.part(partId) == null) return;
          setState(() {
            _chatting = true;
            _part = partId;
          });
          final nodes = content.part(partId)!.meshNodes;
          await _viewer.whenReady();
          if (!mounted || run != _run) return;
          if (nodes.isNotEmpty) _viewer.focus(nodes.first);
        case OpenDiagnosis(:final id):
          setState(() => _diagnosing = true);
          final diagnosis = await loadDiagnosis(api, content, id);
          if (!mounted || run != _run) return;
          setState(() {
            _diagnosing = false;
            _turns.add(UserTurn(diagnosis.symptom));
            _showDiagnosis(diagnosis);
          });
          await _play(diagnosis, content, run);
        case OpenConversation(:final id):
          final (summary, messages) = await loadConversation(api, id);
          if (!mounted || run != _run) return;
          setState(() {
            _chatting = true;
            _conversation = summary.id;
            _part = summary.part;
            for (final m in messages) {
              _turns.add(
                m.fromUser
                    ? UserTurn(m.text)
                    : AnswerTurn(m.text, sources: m.sources),
              );
            }
          });
      }
    } on Object catch (e) {
      if (!mounted || run != _run) return;
      setState(() {
        _diagnosing = false;
        _notice = _noticeFor(e);
      });
    }
  }

  /// Sohbeti temizler; model de ilk haline döner.
  void _reset() {
    unawaited(_answer?.cancel());
    _answer = null;
    _run++;
    setState(() {
      _docked = null;
      _turns.clear();
      _thread.clear();
      _diagnosis = null;
      _diagnosing = false;
      _notice = null;
      _lastFailed = false;
      _chatting = false;
      _part = null;
      _conversation = null;
    });
    if (_viewer.exploded.value) _viewer.explode(0);
    _viewer.highlight(const {});
  }

  /// Teşhisi sohbete ekler ve sıradaki mesajın nereye gideceğini belirler.
  void _showDiagnosis(Diagnosis diagnosis) {
    _diagnosis = diagnosis;
    _turns.add(DiagnosisTurn(diagnosis));
    switch (diagnosis.decision) {
      case DiagnosisDecision.focus when diagnosis.candidates.isNotEmpty:
        _chatting = true;
        _part = diagnosis.top.partId;
      case DiagnosisDecision.notDiagnosis:
        _chatting = true;
      default:
        break;
    }
  }

  ChatNotice _noticeFor(Object error) => switch (error) {
    ApiException(statusCode: 401) => ChatNotice(
      'Yapay zekâyı kullanmak için giriş yapmalısın.',
      actionLabel: 'Giriş yap',
      onAction: widget.onSignIn,
    ),
    ApiException(code: 'no_key' || 'invalid_key', :final message) => ChatNotice(
      message,
      actionLabel: 'Ayarlara git',
      onAction: widget.onOpenSettings,
    ),
    ApiException(:final message) => ChatNotice(message),
    _ => const ChatNotice('Sunucudan beklenmedik bir cevap geldi.'),
  };

  /// Yazılan mesajı sohbete ekler; son başarısız mesajın yerine geçer.
  void _addUserTurn(String text) {
    if (_lastFailed && _turns.isNotEmpty && _turns.last is UserTurn) {
      _turns.removeLast();
    }
    _lastFailed = false;
    _notice = null;
    _turns.add(UserTurn(text));
  }

  void _onSend(String text) {
    if (_chatting) {
      _onChat(text);
    } else {
      unawaited(_onAsk(text));
    }
  }

  /// Parça sohbeti: cevap kelime kelime akar.
  void _onChat(String text) {
    if (_answer != null) return;
    setState(() {
      _addUserTurn(text);
      _turns.add(const AnswerTurn('', streaming: true));
    });
    final run = _run;
    var waiting = true;
    unawaited(_sweepWhile(run, () => waiting));
    // İlk kelime ya da hata gelince tarama durur, kamera konuya döner.
    void answered() {
      if (!waiting) return;
      waiting = false;
      if (run != _run) return;
      _viewer.highlight(const {});
      final content = ref.read(productContentProvider(product.id)).value;
      final part = _part;
      if (content != null && part != null) _focusPart(content, part);
    }

    final buffer = StringBuffer();
    void replaceAnswer(AnswerTurn turn) {
      if (_turns.isNotEmpty && _turns.last is AnswerTurn) {
        _turns[_turns.length - 1] = turn;
      }
    }

    _answer =
        askAi(
          ref.read(apiClientProvider),
          item: product.id,
          message: text,
          conversation: _conversation,
          part: _part,
        ).listen(
          (event) {
            if (!mounted) return;
            answered();
            setState(() {
              switch (event) {
                case AnswerDelta(:final text):
                  buffer.write(text);
                  replaceAnswer(AnswerTurn('$buffer', streaming: true));
                case AnswerDone(:final conversation, :final sources):
                  _conversation = conversation;
                  replaceAnswer(AnswerTurn('$buffer', sources: sources));
                  if (run == _run) _showSources(sources);
              }
            });
          },
          onError: (Object e) {
            if (!mounted) return;
            answered();
            setState(() {
              _answer = null;
              if (buffer.isEmpty) {
                _turns.removeLast();
                _lastFailed = true;
              } else {
                replaceAnswer(AnswerTurn('$buffer'));
              }
              _notice = _noticeFor(e);
            });
          },
          onDone: () {
            if (!mounted) return;
            answered();
            setState(() => _answer = null);
          },
          cancelOnError: true,
        );
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
    if (wide) {
      setState(() => _docked = _DockedPart(partId, node));
      return;
    }
    Widget sheet(ScrollController? controller) => _PartSheetHost(
      content: content,
      initialPart: partId,
      node: node,
      controller: controller,
      onOpenModule: widget.onOpenModule,
      onOpenDetails: (id) {
        Navigator.of(context).pop();
        widget.onOpenPart(id);
      },
      onAsk: (id) {
        Navigator.of(context).pop();
        _askAbout(id);
      },
      // Kartta başka parçaya geçince modelde de o parçaya bakılır.
      onPartChanged: (part) => _focusPart(content, part),
    );

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

  /// Cevap beklenirken modelde tarama bandı gidip gelir; kullanıcı
  /// yapay zekânın modele baktığını görür. [busy] false olunca o geçiş
  /// biter; yeni bir tarama ya da vurgu gelirse hemen kesilir.
  Future<void> _sweepWhile(int run, bool Function() busy) async {
    await _viewer.whenReady();
    while (mounted && run == _run && busy()) {
      final finished = await _viewer.scan(const {});
      if (!finished) return;
    }
  }

  /// Sohbet cevabının dayandığı DM'lerin parçaları modelde parlar; konu
  /// parçası varsa o tam, diğerleri soluk. Kaynak yoksa görünüm değişmez.
  void _showSources(List<String> sources) {
    final content = ref.read(productContentProvider(product.id)).value;
    if (content == null || sources.isEmpty) return;
    final weights = <String, double>{};
    for (final part in content.partsForModules(sources).take(6)) {
      for (final node in part.meshNodes) {
        weights[node] = part.id == _part ? 1 : 0.6;
      }
    }
    final topic = _part;
    for (final node
        in topic == null
            ? const <String>[]
            : content.part(topic)?.meshNodes ?? const <String>[]) {
      weights[node] = 1;
    }
    if (weights.isNotEmpty) _viewer.highlight(weights);
  }

  void _focusPart(ProductContent content, String partId) {
    final nodes = content.part(partId)?.meshNodes ?? const [];
    if (nodes.isNotEmpty) _viewer.focus(nodes.first);
  }

  void _closeDocked() {
    if (_docked != null) setState(() => _docked = null);
  }

  /// Ekrandaki geri oku sayfadan çıkar; açık kartın geri davranışına
  /// (önceki parça, sohbete dönüş) takılmaz.
  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  /// Yazılan belirtiyi teşhis ettirir, sonucu sohbette gösterir ve modelde
  /// canlandırır.
  Future<void> _onAsk(String text) async {
    final content = ref.read(productContentProvider(product.id)).value;
    if (content == null || _diagnosing) return;

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
      _addUserTurn(text);
      _diagnosing = true;
    });
    unawaited(_sweepWhile(run, () => _diagnosing));
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
        _diagnosing = false;
        _showDiagnosis(diagnosis);
      });
      await _play(diagnosis, content, run);
    } on Object catch (e) {
      // Ağ hatası da, sunucudan gelen beklenmedik cevap da sohbette bir
      // mesaj olarak görünsün; yoksa "taranıyor" sonsuza dek kalır.
      if (!mounted || run != _run) return;
      setState(() {
        _diagnosing = false;
        _lastFailed = true;
        _notice = _noticeFor(e);
      });
    }
  }

  /// Parça kartındaki "… hakkında sor": kart kapanır, sohbet o parçaya
  /// döner.
  void _askAbout(String partId) {
    _docked = null;
    _reset();
    setState(() {
      _chatting = true;
      _part = partId;
    });
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
    await _viewer.whenReady();
    if (!mounted || run != _run) return;
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
            '&map=${Uri.encodeQueryComponent('$map')}'
            // Kullanıcının kendi dosyası: Android'de model isteği oturum
            // token'ını başlıkta taşır. Adres cihazdaki yerel sunucuda kalır.
            '${!product.isTemplate && api.token != null ? '&auth=${Uri.encodeQueryComponent(api.token!)}' : ''}',
        controller: _viewer,
        onPartTap: _onNodeTap,
        partLabel: (node) => data?.nodeLabel(node) ?? node,
        onOpenDetails: (node) {
          final part = data?.partForNode(node);
          if (part != null) widget.onOpenPart(part.id);
        },
        credit: _creditLine(product),
        onBack: _leave,
      );
    } else {
      // Masaüstünde ve testlerde WebView yok; şematik çizim.
      viewer = ViewerPanel(
        productTitle: product.title,
        diagnosis: sampleDiagnosis,
        onPartTap: (_) {},
        onBack: _leave,
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
        turns: List.unmodifiable(_turns),
        diagnosing: _diagnosing,
        notice: _notice,
        topic: _part == null ? null : data?.part(_part!)?.name,
        onNewTopic: _reset,
        onOpenHistory: widget.onOpenHistory,
        onSend: _onSend,
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
                  child: SizedBox(
                    width: 420,
                    child: IndexedStack(
                      index: _docked == null || data == null ? 0 : 1,
                      sizing: StackFit.expand,
                      children: [
                        chat,
                        if (_docked != null && data != null)
                          _DockedSheet(
                            key: ValueKey(_docked),
                            content: data,
                            docked: _docked!,
                            onClose: _closeDocked,
                            onOpenModule: widget.onOpenModule,
                            onOpenDetails: (id) {
                              _closeDocked();
                              widget.onOpenPart(id);
                            },
                            onAsk: _askAbout,
                            onPartChanged: (part) => _focusPart(data, part),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          if (_docked != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _closeDocked();
            });
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
    required this.onOpenDetails,
    required this.onAsk,
    required this.onPartChanged,
    this.node,
    this.controller,
    this.onClose,
  });

  /// Verilirse kart bir sütunda duruyordur: sistemin geri tuşu (Android)
  /// sayfadan çıkmaz, önceki parçaya ya da sohbete döner. Web'de tarayıcının
  /// geri tuşu go_router'la sayfadan çıkar.
  final VoidCallback? onClose;

  final ProductContent content;
  final String initialPart;
  final String? node;
  final ScrollController? controller;
  final ValueChanged<String> onOpenModule;
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onAsk;
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
      canPop: _history.isEmpty && widget.onClose == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_history.isEmpty) {
          widget.onClose?.call();
          return;
        }
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
          onOpenDetails: () => widget.onOpenDetails(_partId),
          onAsk: () => widget.onAsk(_partId),
        ),
      ),
    );
  }
}

/// Sağ sütunda açılan parça kartı.
@immutable
class _DockedPart {
  const _DockedPart(this.part, this.node);

  final String part;
  final String? node;

  @override
  bool operator ==(Object other) =>
      other is _DockedPart && other.part == part && other.node == node;

  @override
  int get hashCode => Object.hash(part, node);
}

/// Geniş ekranda sohbetin yerine geçen parça kartı: üstte sohbete dönüş,
/// altında kart. Viewer'ın üstüne binmez, modeli karartmaz.
class _DockedSheet extends StatefulWidget {
  const _DockedSheet({
    required this.content,
    required this.docked,
    required this.onClose,
    required this.onOpenModule,
    required this.onOpenDetails,
    required this.onAsk,
    required this.onPartChanged,
    super.key,
  });

  final ProductContent content;
  final _DockedPart docked;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenModule;
  final ValueChanged<String> onOpenDetails;
  final ValueChanged<String> onAsk;
  final ValueChanged<String> onPartChanged;

  @override
  State<_DockedSheet> createState() => _DockedSheetState();
}

class _DockedSheetState extends State<_DockedSheet> {
  // Kart her açılışta (her parça yeni bir durum) odağı alır: sohbet alanı
  // odaktaysa bile Esc karta gider, gizlenen alana yazı yazılmaz.
  final _focus = FocusNode(debugLabel: 'parça kartı');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = widget;
    return ColoredBox(
      color: c.surface,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): w.onClose},
        child: Focus(
          focusNode: _focus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: w.onClose,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Sohbete dön'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Kartı kapat',
                      onPressed: w.onClose,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _PartSheetHost(
                  content: w.content,
                  initialPart: w.docked.part,
                  node: w.docked.node,
                  onClose: w.onClose,
                  onOpenModule: w.onOpenModule,
                  onOpenDetails: w.onOpenDetails,
                  onAsk: w.onAsk,
                  onPartChanged: w.onPartChanged,
                ),
              ),
            ],
          ),
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
