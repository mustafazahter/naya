import 'package:xml/xml.dart';

import 'data_module.dart';
import 'dm_code.dart';
import 'errors.dart';
import 'ipd.dart';
import 'xml_text.dart';

/// Bir DM'in ekranda okunacak hali: ön koşullar, adımlar, uyarılar,
/// çizimler ve başka DM'lere başvurular.
///
/// [DataModule.chunks] arama için metni düzleştirir; bu sınıf yapıyı korur.
/// Uygulamadaki DM okuyucu bunu çizer.
///
/// ```dart
/// final doc = DmDocument.parse(xml);
/// for (final block in doc.blocks) { ... }
/// ```
class DmDocument {
  DmDocument._({
    required this.module,
    required this.requirements,
    required this.blocks,
    required this.closing,
  });

  /// Bozuk XML ya da DM olmayan belgede [S1000dException] fırlatır.
  factory DmDocument.parse(String xml, {String? file}) {
    final module = DataModule.parse(xml, file: file);
    final content = XmlDocument.parse(xml).rootElement.getElement('content');
    final body = content?.childElements
        .where((e) => e.name.local != 'refs')
        .firstOrNull;
    if (body == null) {
      return DmDocument._(
        module: module,
        requirements: null,
        blocks: const [],
        closing: const [],
      );
    }
    return switch (body.name.local) {
      'procedure' => _procedure(module, body),
      'faultIsolation' => _faultIsolation(module, body),
      'illustratedPartsCatalog' => DmDocument._(
        module: module,
        requirements: null,
        blocks: [DmCatalog(module.ipdItems)],
        closing: const [],
      ),
      _ => DmDocument._(
        module: module,
        requirements: null,
        blocks: _Blocks().read(body),
        closing: const [],
      ),
    };
  }

  /// Kod, başlık, dil gibi bilgiler.
  final DataModule module;

  DmCode get code => module.code;
  String get techName => module.techName;
  String? get infoName => module.infoName;

  /// `procedure`, `faultIsolation`, `description`, `illustratedPartsCatalog`.
  String get contentType => module.contentType;

  /// Başlamadan önce gerekenler; tanım DM'lerinde yok.
  final DmRequirements? requirements;
  final List<DmBlock> blocks;

  /// İş bitince yapılacaklar, çoğunlukla "sonraki işlem" başvurusu.
  final List<DmBlock> closing;

  static DmDocument _procedure(DataModule module, XmlElement body) {
    final main = body.getElement('mainProcedure');
    final close = body.getElement('closeRqmts');
    return DmDocument._(
      module: module,
      requirements: _requirements(body.getElement('preliminaryRqmts')),
      blocks: main == null ? const [] : _Blocks().read(main),
      closing: close == null ? const [] : _conditions(close),
    );
  }

  static DmDocument _faultIsolation(DataModule module, XmlElement body) {
    final blocks = <DmBlock>[];
    DmRequirements? requirements;
    final closing = <DmBlock>[];
    for (final procedure in body.findAllElements('faultIsolationProcedure')) {
      final descr = procedure.getElement('faultDescr');
      if (descr != null) {
        final text = textOf(descr);
        if (text.isNotEmpty) {
          blocks.add(DmSection('Arıza', [DmParagraph(DmText(text))]));
        }
      }
      final isolation = procedure.getElement('isolationProcedure');
      if (isolation == null) continue;
      requirements ??= _requirements(isolation.getElement('preliminaryRqmts'));
      final main = isolation.getElement('isolationMainProcedure');
      if (main != null) blocks.addAll(_isolation(main));
      final close = isolation.getElement('closeRqmts');
      if (close != null) closing.addAll(_conditions(close));
    }
    return DmDocument._(
      module: module,
      requirements: requirements,
      blocks: blocks,
      closing: closing,
    );
  }

  /// Arıza bulma adımları sırayla numaralanır; sonuçlar numarasız.
  static List<DmBlock> _isolation(XmlElement main) {
    final blocks = <DmBlock>[];
    var n = 0;
    for (final e in main.childElements) {
      switch (e.name.local) {
        case 'isolationStep':
          n++;
          blocks.add(
            DmIsolationStep(
              id: e.getAttribute('id') ?? 'step-$n',
              number: '$n',
              action: _text(e.getElement('action')),
              question: _text(e.getElement('isolationStepQuestion')),
              choices: _choices(e.getElement('isolationStepAnswer')),
            ),
          );
        case 'isolationProcedureEnd':
          blocks.add(
            DmIsolationEnd(
              id: e.getAttribute('id') ?? 'end-${blocks.length}',
              text: _text(e.getElement('action') ?? e),
            ),
          );
      }
    }
    return blocks;
  }

  /// Evet/hayır ya da çoktan seçmeli cevap (`listOfChoices`).
  static List<DmChoice> _choices(XmlElement? answer) {
    if (answer == null) return const [];
    final yesNo = answer.getElement('yesNoAnswer');
    if (yesNo != null) {
      return [
        for (final (name, kind) in [
          ('yesAnswer', DmAnswerKind.yes),
          ('noAnswer', DmAnswerKind.no),
        ])
          if (yesNo.getElement(name) case final e?)
            DmChoice(kind, '', e.getAttribute('nextActionRefId')),
      ];
    }
    return [
      for (final choice in answer.findAllElements('choice'))
        DmChoice(
          DmAnswerKind.choice,
          textOf(choice),
          choice.getAttribute('nextActionRefId'),
        ),
    ];
  }

  static DmRequirements? _requirements(XmlElement? pre) {
    if (pre == null) return null;
    final requirements = DmRequirements(
      conditions: [
        for (final block in _conditions(
          pre.getElement('reqCondGroup') ?? XmlElement(XmlName('empty')),
        ))
          if (block is DmParagraph) block.text,
      ],
      equipment: _items(pre, 'supportEquipDescr'),
      supplies: _items(pre, 'supplyDescr'),
      spares: _items(pre, 'spareDescr'),
      safety: [
        for (final safety in pre.findAllElements('safetyRqmts'))
          ..._Blocks().read(safety).whereType<DmAdmonition>(),
      ],
    );
    return requirements.isEmpty ? null : requirements;
  }

  static List<DmItem> _items(XmlElement pre, String name) => [
    for (final e in pre.findAllElements(name))
      DmItem(
        name: optionalText(e.getElement('name')) ?? textOf(e),
        partNumber: optionalText(firstDescendant(e, 'partNumber')),
        manufacturerCode: optionalText(firstDescendant(e, 'manufacturerCode')),
        quantity: optionalText(e.getElement('reqQuantity')),
        unit: e.getElement('reqQuantity')?.getAttribute('unitOfMeasure'),
      ),
  ];

  /// `reqCondGroup` içindeki koşullar; `reqCondDm` başvurusuyla birlikte.
  static List<DmBlock> _conditions(XmlElement group) => [
    for (final e in group.descendantElements)
      if (e.name.local == 'reqCondNoRef' ||
          e.name.local == 'reqCondDm' ||
          e.name.local == 'reqCondExternalPub')
        DmParagraph(_text(e)),
  ];

  static DmText _text(XmlElement? e) {
    if (e == null) return const DmText('');
    return DmText(
      textOf(e, skip: const {'dmRef'}),
      refs: [for (final ref in e.findAllElements('dmCode')) _code(ref)]
          .whereType<DmCode>()
          .toList(),
    );
  }

  static DmCode? _code(XmlElement e) {
    try {
      return DmCode.fromElement(e);
    } on S1000dException {
      return null;
    }
  }
}

/// Başlamadan önce gerekenler.
class DmRequirements {
  const DmRequirements({
    this.conditions = const [],
    this.equipment = const [],
    this.supplies = const [],
    this.spares = const [],
    this.safety = const [],
  });

  final List<DmText> conditions;

  /// Aletler ve test cihazları.
  final List<DmItem> equipment;

  /// Sarf malzemesi: yağ, temizleyici.
  final List<DmItem> supplies;

  /// Yedek parçalar.
  final List<DmItem> spares;
  final List<DmAdmonition> safety;

  bool get isEmpty =>
      conditions.isEmpty &&
      equipment.isEmpty &&
      supplies.isEmpty &&
      spares.isEmpty &&
      safety.isEmpty;
}

class DmItem {
  const DmItem({
    required this.name,
    this.partNumber,
    this.manufacturerCode,
    this.quantity,
    this.unit,
  });

  final String name;
  final String? partNumber;

  /// Üretici (CAGE) kodu; parça numarasıyla birlikte parçayı tanımlar.
  final String? manufacturerCode;
  final String? quantity;
  final String? unit;
}

/// Metin ve içinde geçen DM başvuruları.
class DmText {
  const DmText(this.text, {this.refs = const []});

  final String text;
  final List<DmCode> refs;

  @override
  String toString() => text;
}

/// Okuyucunun çizdiği parçalar.
sealed class DmBlock {
  const DmBlock();
}

class DmParagraph extends DmBlock {
  const DmParagraph(this.text);

  final DmText text;
}

enum DmAdmonitionKind {
  /// Kişiye zarar verebilir.
  warning,

  /// Ürüne zarar verebilir.
  caution,
  note,
}

class DmAdmonition extends DmBlock {
  const DmAdmonition(this.kind, this.paragraphs);

  final DmAdmonitionKind kind;
  final List<String> paragraphs;
}

class DmFigure extends DmBlock {
  const DmFigure(this.title, this.icns);

  final String title;

  /// Çizimlerin ICN'leri (`ICN-...`); dosya adının uzantısız hali.
  final List<String> icns;
}

class DmList extends DmBlock {
  const DmList(this.items, {required this.ordered});

  final List<DmText> items;
  final bool ordered;
}

/// Tanım DM'lerindeki başlıklı bölüm (`levelledPara`).
class DmSection extends DmBlock {
  const DmSection(this.title, this.blocks);

  final String title;
  final List<DmBlock> blocks;
}

/// Prosedür adımı. İç adımlar [blocks] içinde, numaraları `2.1` gibi.
class DmStep extends DmBlock {
  const DmStep({required this.number, required this.blocks, this.title});

  final String number;
  final String? title;
  final List<DmBlock> blocks;
}

/// Arıza bulmada bir soru: yap, bak, cevaba göre ilerle.
class DmIsolationStep extends DmBlock {
  const DmIsolationStep({
    required this.id,
    required this.number,
    required this.action,
    required this.question,
    this.choices = const [],
  });

  final String id;
  final String number;
  final DmText action;
  final DmText question;
  final List<DmChoice> choices;
}

enum DmAnswerKind { yes, no, choice }

/// Bir cevap ve götürdüğü yer: sonraki [DmIsolationStep]'in ya da
/// [DmIsolationEnd]'in `id`'si.
class DmChoice {
  const DmChoice(this.kind, this.label, this.target);

  final DmAnswerKind kind;

  /// Çoktan seçmelide cevabın metni; evet/hayırda boş, etiketi okuyucu
  /// kendi dilinde yazar.
  final String label;
  final String? target;
}

/// Arıza bulmanın vardığı sonuç: ne yapılmalı, hangi DM'le.
class DmIsolationEnd extends DmBlock {
  const DmIsolationEnd({required this.id, required this.text});

  final String id;
  final DmText text;
}

/// Parça kataloğu satırları.
class DmCatalog extends DmBlock {
  const DmCatalog(this.items);

  final List<IpdItem> items;
}

/// Bir elemanın çocuklarını sırayla bloklara çevirir. Tanımadığı ama metni
/// olan elemanlar paragraf olur; okuyucuda hiçbir metin kaybolmaz.
class _Blocks {
  List<DmBlock> read(XmlElement parent, {String numberPrefix = ''}) {
    final blocks = <DmBlock>[];
    var step = 0;
    for (final e in parent.childElements) {
      switch (e.name.local) {
        case 'title' || 'refs' || 'reqCondGroup':
          break;
        case 'para':
          blocks.addAll(_para(e));
        case 'warning':
          blocks.add(_admonition(DmAdmonitionKind.warning, e));
        case 'caution':
          blocks.add(_admonition(DmAdmonitionKind.caution, e));
        case 'note':
          blocks.add(_admonition(DmAdmonitionKind.note, e));
        case 'figure':
          blocks.add(
            DmFigure(
              optionalText(e.getElement('title')) ?? '',
              attributeValues(e.findAllElements('graphic'), 'infoEntityIdent'),
            ),
          );
        case 'randomList' || 'sequentialList':
          blocks.add(_list(e));
        case 'levelledPara':
          blocks.add(
            DmSection(optionalText(e.getElement('title')) ?? '', read(e)),
          );
        case 'proceduralStep':
          step++;
          final number = '$numberPrefix$step';
          final title = optionalText(e.getElement('title'));
          blocks.add(
            DmStep(
              number: number,
              title: title == null || title.isEmpty ? null : title,
              blocks: read(e, numberPrefix: '$number.'),
            ),
          );
        default:
          final text = DmDocument._text(e);
          if (text.text.isNotEmpty) blocks.add(DmParagraph(text));
      }
    }
    return blocks;
  }

  /// Paragrafın içindeki listeler ayrı blok olur, metin onlarsız alınır.
  List<DmBlock> _para(XmlElement para) {
    const lists = {'randomList', 'sequentialList'};
    final text = DmText(
      textOf(para, skip: {...lists, 'dmRef'}),
      refs: [
        for (final ref in para.findAllElements('dmCode')) DmDocument._code(ref),
      ].whereType<DmCode>().toList(),
    );
    return [
      if (text.text.isNotEmpty) DmParagraph(text),
      for (final e in para.childElements)
        if (lists.contains(e.name.local)) _list(e),
    ];
  }

  DmList _list(XmlElement list) => DmList([
    for (final item in elementsNamed(list, 'listItem')) DmDocument._text(item),
  ], ordered: list.name.local == 'sequentialList');

  DmAdmonition _admonition(DmAdmonitionKind kind, XmlElement e) {
    final paras = [
      for (final p in e.childElements)
        if (p.name.local == 'warningAndCautionPara' ||
            p.name.local == 'notePara')
          textOf(p),
    ].where((t) => t.isNotEmpty).toList();
    return DmAdmonition(kind, paras.isEmpty ? [textOf(e)] : paras);
  }
}
