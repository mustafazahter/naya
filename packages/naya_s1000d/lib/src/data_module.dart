import 'package:xml/xml.dart';

import 'chunk.dart';
import 'dm_code.dart';
import 'errors.dart';
import 'ipd.dart';
import 'issue.dart';
import 'xml_text.dart';

/// Bir veri modülü (DM): kimliği, başlığı ve içeriğin aranabilir parçaları.
///
/// XML ağacı saklanmaz; .naya dosyasındaki ham XML zaten değişmeden durur,
/// gerektiğinde yeniden okunur.
class DataModule {
  DataModule({
    required this.code,
    required this.language,
    required this.issueNumber,
    required this.inWork,
    required this.techName,
    required this.contentType,
    this.infoName,
    this.issueDate,
    this.s1000dIssue,
    this.dmRefs = const [],
    this.icnRefs = const [],
    this.ipdItems = const [],
    this.chunks = const [],
  });

  /// [xml] metnini okur. [file] yalnız hata mesajı için.
  factory DataModule.parse(String xml, {String? file}) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } on XmlException catch (e) {
      throw S1000dException('XML okunamadı: ${e.message}', file: file);
    }
    final root = doc.rootElement;
    if (root.name.local != 'dmodule') {
      throw S1000dException(
        'Kök eleman "dmodule" değil: ${root.name.local}',
        file: file,
      );
    }
    final issue = issueOf(root);
    if (!isSupportedIssue(issue)) {
      throw S1000dException(
        'S1000D Issue $issue desteklenmiyor; 4.0 ve sonrası okunuyor',
        file: file,
      );
    }
    try {
      return _read(root, issue);
    } on S1000dException catch (e) {
      throw S1000dException(e.message, file: file);
    }
  }

  final DmCode code;

  /// `tr-TR` gibi.
  final String language;
  final String issueNumber;
  final String inWork;
  final String techName;
  final String? infoName;
  final DateTime? issueDate;
  final String? s1000dIssue;

  /// `content` altındaki ilk elemanın adı: `description`, `procedure`,
  /// `faultIsolation`, `illustratedPartsCatalog`, `brex`...
  final String contentType;

  /// İçerikte başvurulan diğer DM'ler.
  final List<DmCode> dmRefs;

  /// Başvurulan görseller (ICN).
  final List<String> icnRefs;
  final List<IpdItem> ipdItems;
  final List<Chunk> chunks;

  /// "Zincir - Sökme" gibi tam başlık.
  String get title => infoName == null ? techName : '$techName - $infoName';

  static DataModule _read(XmlElement root, String? issue) {
    final ident = firstDescendant(root, 'dmIdent');
    final dmCode = ident == null ? null : firstDescendant(ident, 'dmCode');
    if (ident == null || dmCode == null) {
      throw const S1000dException('dmIdent/dmCode bulunamadı');
    }
    final code = DmCode.fromElement(dmCode);
    final lang = ident.getElement('language');
    final issueInfo = ident.getElement('issueInfo');
    final title = firstDescendant(root, 'dmTitle');
    final techName = title?.getElement('techName');
    if (techName == null) throw const S1000dException('dmTitle/techName yok');
    final infoName = title?.getElement('infoName');

    final content = root.getElement('content');
    final body = content?.childElements
        .where((e) => e.name.local != 'refs')
        .firstOrNull;
    final contentType = body?.name.local ?? '';
    final fullTitle = infoName == null
        ? textOf(techName)
        : '${textOf(techName)} - ${textOf(infoName)}';

    final ipdItems = body == null || contentType != 'illustratedPartsCatalog'
        ? <IpdItem>[]
        : [
            for (final csn in body.findAllElements('catalogSeqNumber'))
              ...IpdItem.fromCatalogSeqNumber(csn),
          ];

    return DataModule(
      code: code,
      language: lang == null
          ? ''
          : [
              lang.getAttribute('languageIsoCode'),
              lang.getAttribute('countryIsoCode'),
            ].whereType<String>().join('-'),
      issueNumber: issueInfo?.getAttribute('issueNumber') ?? '',
      inWork: issueInfo?.getAttribute('inWork') ?? '',
      techName: textOf(techName),
      infoName: infoName == null ? null : textOf(infoName),
      issueDate: _date(firstDescendant(root, 'issueDate')),
      s1000dIssue: issue,
      contentType: contentType,
      dmRefs: content == null ? const [] : _dmRefs(content),
      icnRefs: _icnRefs(root),
      ipdItems: ipdItems,
      chunks: body == null
          ? const []
          : _Chunker(code, fullTitle).chunk(body, contentType),
    );
  }

  static DateTime? _date(XmlElement? e) {
    final y = int.tryParse(e?.getAttribute('year') ?? '');
    final m = int.tryParse(e?.getAttribute('month') ?? '');
    final d = int.tryParse(e?.getAttribute('day') ?? '');
    return y == null || m == null || d == null ? null : DateTime.utc(y, m, d);
  }

  static List<DmCode> _dmRefs(XmlElement content) {
    final refs = <DmCode>{};
    for (final ref in content.findAllElements('dmRef')) {
      final code = firstDescendant(ref, 'dmCode');
      if (code != null) refs.add(DmCode.fromElement(code));
    }
    return refs.toList();
  }
}

/// Görsel başvuruları: `graphic`, `symbol` ve `multimediaObject` elemanlarının
/// `infoEntityIdent` özniteliği.
List<String> _icnRefs(XmlElement root) {
  const names = {'graphic', 'symbol', 'multimediaObject'};
  final elements = root.descendantElements.where(
    (e) => names.contains(e.name.local),
  );
  return attributeValues(elements, 'infoEntityIdent');
}

/// İçeriği türüne göre aranabilir parçalara böler.
class _Chunker {
  _Chunker(this.code, this.title);

  final DmCode code;
  final String title;
  final _chunks = <Chunk>[];

  List<Chunk> chunk(XmlElement body, String type) {
    switch (type) {
      case 'description':
        _description(body);
      case 'procedure':
        _procedure(body);
      case 'faultIsolation':
        _faultIsolation(body);
      case 'illustratedPartsCatalog':
        _catalog(body);
      case 'brex':
        // İş kuralları; aramada işe yaramaz.
        break;
      default:
        _add('', body);
    }
    return _chunks;
  }

  void _add(String section, XmlElement e, {Set<String> skip = const {}}) {
    final text = textOf(e, skip: {'title', ...skip});
    if (text.isEmpty) return;
    _chunks.add(
      Chunk(
        dmc: code,
        dmTitle: title,
        section: section,
        text: text,
        partNumbers: _partNumbers(e),
        icns: _icnRefs(e),
      ),
    );
  }

  /// Parçada geçen parça numaraları: katalog ve metin içindeki `partRef`
  /// ile yedek parça listesindeki `identNumber` (5.0 şemasının istediği
  /// biçim). Takım numaraları alınmaz.
  List<String> _partNumbers(XmlElement e) {
    final numbers = attributeValues(
      e.findAllElements('partRef'),
      'partNumberValue',
    );
    for (final spare in e.findAllElements('spareDescr')) {
      for (final number in spare.findAllElements('partNumber')) {
        final text = textOf(number);
        if (text.isNotEmpty && !numbers.contains(text)) numbers.add(text);
      }
    }
    return numbers;
  }

  String _titleOf(XmlElement e) {
    final t = e.getElement('title');
    return t == null ? '' : textOf(t);
  }

  void _description(XmlElement body) {
    final paras = elementsNamed(body, 'levelledPara').toList();
    if (paras.isEmpty) {
      // Başlıksız, tek parça bir tanım.
      _add('', body);
      return;
    }
    void visit(XmlElement lp, List<String> path) {
      final here = [...path, if (_titleOf(lp).isNotEmpty) _titleOf(lp)];
      _add(here.join(' › '), lp, skip: {'levelledPara'});
      for (final child in elementsNamed(lp, 'levelledPara')) {
        visit(child, here);
      }
    }

    for (final lp in paras) {
      visit(lp, []);
    }
  }

  void _procedure(XmlElement body) {
    final pre = body.getElement('preliminaryRqmts');
    if (pre != null) _add('Ön koşullar', pre);
    final main = body.getElement('mainProcedure');
    if (main != null) {
      var n = 0;
      for (final step in elementsNamed(main, 'proceduralStep')) {
        n++;
        final title = _titleOf(step);
        _add(title.isEmpty ? 'Adım $n' : 'Adım $n: $title', step);
      }
    }
    final close = body.getElement('closeRqmts');
    if (close != null) _add('Son işlemler', close);
  }

  void _faultIsolation(XmlElement body) {
    for (final procedure in body.findAllElements('faultIsolationProcedure')) {
      final descr = procedure.getElement('faultDescr');
      if (descr != null) _add('Arıza tanımı', descr);
      var n = 0;
      for (final step in procedure.findAllElements('isolationStep')) {
        n++;
        _add('Adım $n', step);
      }
      for (final end in procedure.findAllElements('isolationProcedureEnd')) {
        _add('Sonuç', end);
      }
    }
    if (_chunks.isEmpty) _add('', body);
  }

  void _catalog(XmlElement body) {
    for (final csn in body.findAllElements('catalogSeqNumber')) {
      final figure = csn.getAttribute('figureNumber') ?? '';
      final item = csn.getAttribute('item') ?? '';
      _add('Şekil $figure, öğe $item', csn);
    }
  }
}
