import 'package:flutter_test/flutter_test.dart';
import 'package:naya/entities/product/product_content.dart';
import 'package:naya_format/naya_format.dart';

void main() {
  group('parçanın anlatımı', () {
    ProductContent content(String? sns) => ProductContent(
      productId: 'ornek',
      parts: PartsFile([Part(id: 'parca', name: 'Parça', sns: sns)]),
      entryNames: const [
        'dm/DMC-M-A-D00-00-00-00AA-040A-A_001-00_TR-TR.XML',
        'dm/DMC-M-A-28-00-00-00AA-040A-A_001-00_TR-TR.XML',
        'dm/DMC-M-A-29-10-00-00AA-040A-A_001-00_TR-TR.XML',
      ],
    );

    test('önce kendi sistemi ve alt sistemi', () {
      expect(content('29-10').descriptionFor('parca'), contains('-29-10-'));
    });

    test('alt sistemin yoksa sisteminki', () {
      // "-10-00-" düz metin olarak 29-10-00'da da geçer; o seçilmemeli.
      expect(content('28-20').descriptionFor('parca'), contains('-28-00-'));
      expect(content('10-20').descriptionFor('parca'), contains('-D00-00-'));
    });

    test('küçük harfli SNS de bulunur', () {
      final named = ProductContent(
        productId: 'ornek',
        parts: PartsFile([
          const Part(id: 'parca', name: 'Parça', sns: 'da1-10'),
        ]),
        entryNames: const [
          'dm/DMC-M-A-D00-00-00-00AA-040A-A_001-00_TR-TR.XML',
          'dm/DMC-M-A-DA1-10-00-00AA-040A-A_001-00_TR-TR.XML',
        ],
      );
      expect(named.descriptionFor('parca'), contains('-DA1-10-'));
    });

    test('SNS yoksa ürünün genel tanıtımı', () {
      expect(content(null).descriptionFor('parca'), contains('-D00-00-'));
    });
  });
}
