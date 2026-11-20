import 'dart:convert';

/// Server-Sent Events akışındaki bir olay: `event:` adı ve `data:` metni.
class SseEvent {
  const SseEvent(this.name, this.data);

  /// `event:` satırı yoksa standarttaki gibi `message`.
  final String name;
  final String data;

  /// `data` JSON nesnesiyse onu, değilse boş nesneyi döner.
  Map<String, Object?> get json {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Aşağıda boş nesne.
    }
    return const {};
  }
}

/// Bayt akışını olaylara ayırır. Olaylar boş satırla biter; bir paket
/// yarım satırla bitebildiği için satırlar `LineSplitter` ile birleştirilir.
/// `:` ile başlayan satırlar yorumdur (bağlantıyı canlı tutmak için).
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  var name = 'message';
  final data = <String>[];
  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield SseEvent(name, data.join('\n'));
      name = 'message';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        name = value;
      case 'data':
        data.add(value);
    }
  }
  // Sunucu son boş satırı göndermeden kapattıysa elde kalan olay.
  if (data.isNotEmpty) yield SseEvent(name, data.join('\n'));
}
