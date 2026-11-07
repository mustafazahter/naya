import 'package:xml/xml.dart';

import 'xml_text.dart';

/// Resimli parça kataloğundaki (IPD) bir satır: "Şekil 1, öğe 4".
class IpdItem {
  const IpdItem({
    required this.figure,
    required this.item,
    required this.indenture,
    required this.name,
    this.itemVariant,
    this.partNumber,
    this.manufacturerCode,
    this.quantity,
  });

  /// `<catalogSeqNumber>` elemanını okur; içindeki her `itemSeqNumber` için
  /// bir satır döner (aynı öğenin farklı varyantları).
  static List<IpdItem> fromCatalogSeqNumber(XmlElement csn) {
    final figure = csn.getAttribute('figureNumber') ?? '';
    final item = csn.getAttribute('item') ?? '';
    final indenture = int.tryParse(csn.getAttribute('indenture') ?? '') ?? 1;
    return [
      for (final isn in elementsNamed(csn, 'itemSeqNumber'))
        IpdItem(
          figure: figure,
          item: item,
          indenture: indenture,
          itemVariant: isn.getAttribute('itemSeqNumberValue'),
          name: _name(isn),
          partNumber: _partNumber(isn),
          manufacturerCode: firstDescendant(
            isn,
            'partRef',
          )?.getAttribute('manufacturerCodeValue'),
          quantity: _quantity(isn),
        ),
    ];
  }

  final String figure;
  final String item;

  /// Montajdaki derinlik: 1 ana montaj, 2 onun parçası...
  final int indenture;
  final String? itemVariant;
  final String name;
  final String? partNumber;
  final String? manufacturerCode;
  final String? quantity;

  @override
  String toString() =>
      '$figure/$item $name${partNumber == null ? '' : ' ($partNumber)'}';

  static String _name(XmlElement isn) {
    final descr = firstDescendant(isn, 'descrForPart');
    return descr == null ? '' : textOf(descr);
  }

  // 4.1 ve 5.0'da partRef/@partNumberValue; bazı eski verilerde partNumber.
  static String? _partNumber(XmlElement isn) {
    final ref = firstDescendant(
      isn,
      'partRef',
    )?.getAttribute('partNumberValue');
    if (ref != null) return ref;
    final old = firstDescendant(isn, 'partNumber');
    return old == null ? null : textOf(old);
  }

  static String? _quantity(XmlElement isn) {
    final q = firstDescendant(isn, 'quantityPerNextHigherAssy');
    if (q == null) return null;
    final text = textOf(q);
    return text.isEmpty ? null : text;
  }
}
