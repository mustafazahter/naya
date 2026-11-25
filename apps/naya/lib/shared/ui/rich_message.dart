import 'package:flutter/material.dart';

import 'tokens.dart';

/// Yapay zekânın yazdığı kısa Markdown'u gösterir: paragraflar, madde ve
/// numaralı listeler, `**kalın**`, `*italik*`, `` `kod` ``. Başlıklar
/// (`# …`) kalın paragraf olur. Tam bir Markdown motoru değil; sohbet
/// cevaplarında görülen biçimler için yeter ve paket gerektirmez.
class RichMessage extends StatelessWidget {
  const RichMessage(this.text, {this.style, this.trailing, super.key});

  final String text;
  final TextStyle? style;

  /// Son paragrafın sonuna eklenir (akış sürerken imleç gibi).
  final InlineSpan? trailing;

  static final _bullet = RegExp(r'^\s*[-*•]\s+');
  static final _numbered = RegExp(r'^\s*(\d+)[.)]\s+');
  static final _heading = RegExp(r'^\s*#{1,6}\s+');

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final blocks = _blocks(text);
    if (blocks.isEmpty) {
      return Text.rich(TextSpan(children: [?trailing]), style: base);
    }
    final children = <Widget>[];
    for (final (i, block) in blocks.indexed) {
      final last = i == blocks.length - 1;
      final spans = [
        ...inlineSpans(block.text, base),
        if (last && trailing != null) trailing!,
      ];
      final body = Text.rich(
        TextSpan(children: spans),
        style: block.heading
            ? base.copyWith(fontWeight: FontWeight.w600)
            : base,
      );
      if (i > 0) {
        children.add(
          SizedBox(height: block.listItem ? NayaSpace.xs : NayaSpace.sm),
        );
      }
      children.add(
        block.marker == null
            ? body
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 22, child: Text(block.marker!, style: base)),
                  Expanded(child: body),
                ],
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Satırları paragraf ve liste öğelerine ayırır. Boş satır paragrafı
  /// bitirir; liste dışındaki ardışık satırlar aynı paragrafta birleşir.
  static List<_Block> _blocks(String text) {
    final blocks = <_Block>[];
    final paragraph = <String>[];
    void flush() {
      if (paragraph.isEmpty) return;
      blocks.add(_Block(paragraph.join(' ')));
      paragraph.clear();
    }

    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flush();
        continue;
      }
      final bullet = _bullet.firstMatch(line);
      final numbered = _numbered.firstMatch(line);
      if (bullet != null) {
        flush();
        blocks.add(_Block(line.substring(bullet.end), marker: '•'));
      } else if (numbered != null) {
        flush();
        blocks.add(
          _Block(line.substring(numbered.end), marker: '${numbered[1]}.'),
        );
      } else if (_heading.hasMatch(line)) {
        flush();
        blocks.add(_Block(line.replaceFirst(_heading, ''), heading: true));
      } else {
        paragraph.add(line.trim());
      }
    }
    flush();
    return blocks;
  }

  static final _inline = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])|(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)',
  );

  /// Satır içi biçimler: kalın, italik, kod. Kapanmamış işaretler (akış
  /// sürerken yarım kalan `**`) düz metin olarak görünür.
  @visibleForTesting
  static List<InlineSpan> inlineSpans(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      final bold = m[1] ?? m[2];
      final code = m[3];
      final italic = m[4] ?? m[5];
      if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      } else if (code != null) {
        spans.add(
          TextSpan(
            text: code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (base.fontSize ?? 14) * 0.92,
            ),
          ),
        );
      } else if (italic != null) {
        spans.add(
          TextSpan(
            text: italic,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return spans;
  }
}

class _Block {
  _Block(this.text, {this.marker, this.heading = false});

  final String text;
  final String? marker;
  final bool heading;

  bool get listItem => marker != null;
}
