import 'dart:convert';

import 'package:naya_s1000d/naya_s1000d.dart';
import 'package:test/test.dart';

import 'builders.dart';

Matcher failsWith(String text, {String? file = 'x.xml'}) => throwsA(
  isA<S1000dException>()
      .having((e) => e.file, 'file', file)
      .having((e) => e.message, 'message', contains(text)),
);

void main() {
  group('XML olmayan girdi', () {
    for (final (name, xml) in [
      ('boş metin', ''),
      ('yalnız boşluk', '  \n '),
      ('yalnız XML bildirimi', '<?xml version="1.0"?>'),
      ('düz yazı', 'bu bir xml değil'),
      ('kapanmamış eleman', '<dmodule><content></dmodule>'),
      ('iki kök', '<dmodule/><dmodule/>'),
    ]) {
      test('DM: $name', () {
        expect(
          () => DataModule.parse(xml, file: 'x.xml'),
          throwsA(
            isA<S1000dException>().having((e) => e.file, 'file', 'x.xml'),
          ),
        );
      });

      test('PM: $name', () {
        expect(
          () => PublicationModule.parse(xml, file: 'x.xml'),
          throwsA(
            isA<S1000dException>().having((e) => e.file, 'file', 'x.xml'),
          ),
        );
      });

      test('DML: $name', () {
        expect(
          () => DataModuleList.parse(xml, file: 'x.xml'),
          throwsA(
            isA<S1000dException>().having((e) => e.file, 'file', 'x.xml'),
          ),
        );
      });
    }
  });

  group('zorunlu alan eksik', () {
    test('techName yok', () {
      expect(
        () => DataModule.parse(dmXml(title: '<dmTitle/>'), file: 'x.xml'),
        failsWith('techName'),
      );
    });

    test('dmTitle yoksa içerikteki başvurunun başlığı alınmaz', () {
      final ref = dmRefXml(
        dmCodeAttributes,
        title:
            '<dmRefAddressItems><dmTitle><techName>Başka DM</techName>'
            '</dmTitle></dmRefAddressItems>',
      );
      final xml = dmXml(
        title: '',
        content: '<description><para>$ref</para></description>',
      );
      expect(() => DataModule.parse(xml, file: 'x.xml'), failsWith('techName'));
    });

    test('kök adı büyük/küçük harfe duyarlı', () {
      expect(
        () => DataModule.parse('<DMODULE/>', file: 'x.xml'),
        failsWith('dmodule'),
      );
    });

    test('PM: pmCode yok', () {
      expect(
        () => PublicationModule.parse('<pm/>', file: 'x.xml'),
        failsWith('pmCode'),
      );
    });

    test('DML: dmlCode yok', () {
      expect(
        () => DataModuleList.parse('<dml/>', file: 'x.xml'),
        failsWith('dmlCode'),
      );
    });
  });

  group('zorunlu olmayan alan eksik', () {
    test('dil, sürüm ve tarih olmadan okunur', () {
      final d = DataModule.parse(
        dmXml(language: '', issueInfo: '', issueDate: ''),
      );
      expect(d.language, '');
      expect(d.issueNumber, '');
      expect(d.inWork, '');
      expect(d.issueDate, isNull);
    });

    test('sayı olmayan tarih yok sayılır', () {
      final d = DataModule.parse(
        dmXml(issueDate: '<issueDate year="yirmi" month="11" day="8"/>'),
      );
      expect(d.issueDate, isNull);
    });

    test('içeriksiz DM okunur, parça üretmez', () {
      final d = DataModule.parse(dmXml(content: ''));
      expect(d.contentType, '');
      expect(d.chunks, isEmpty);
      expect(d.dmRefs, isEmpty);
    });

    test('yalnız refs içeren içerik türsüz sayılır', () {
      final d = DataModule.parse(dmXml(content: '<refs/>'));
      expect(d.contentType, '');
    });

    test('PM başlıksız ve içeriksiz okunur', () {
      final pm = PublicationModule.parse('<pm>$pmCodeElement</pm>');
      expect(pm.title, '');
      expect(pm.entries, isEmpty);
    });
  });

  group('varlık (entity) tanımları', () {
    test('dış varlık okunmaz, dosya içeriği metne karışmaz', () {
      final xml =
          '<!DOCTYPE dmodule [<!ENTITY dis SYSTEM "file:///etc/passwd">]>'
          '${dmXml(content: '<description><para>Baş &dis; son</para></description>')}';
      final d = DataModule.parse(xml);
      expect(d.chunks.single.text, isNot(contains('root:')));
    });

    test('iç içe varlıklar açılmaz, bellek şişmez', () {
      final xml =
          '<!DOCTYPE dmodule ['
          '<!ENTITY a "aaaaaaaaaa">'
          '<!ENTITY b "&a;&a;&a;&a;&a;&a;&a;&a;&a;&a;">'
          '<!ENTITY c "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">'
          ']>'
          '${dmXml(content: '<description><para>&c;</para></description>')}';
      final d = DataModule.parse(xml);
      expect(d.chunks.single.text.length, lessThan(100));
    });
  });

  group('Csdb bozuk dosyalarla', () {
    Map<String, List<int>> withFile(String name, String xml) => {
      'csdb/DMC-X-A-D00-00-00-00AA-040A-A.XML': utf8.encode(dmXml()),
      'csdb/$name': utf8.encode(xml),
    };

    test('PM\'de bozuk dmRef sorun listesine dosya adıyla yazılır', () {
      final csdb = Csdb.read(
        withFile(
          'PMC-X.XML',
          pmXml('<pmEntry><dmRef><dmRefIdent/></dmRef></pmEntry>'),
        ),
      );
      expect(csdb.dataModules, hasLength(1));
      expect(csdb.publications, isEmpty);
      expect(csdb.problems.single.file, 'csdb/PMC-X.XML');
    });

    test('DML\'de özniteliği eksik dmCode dosya adıyla yazılır', () {
      final csdb = Csdb.read(
        withFile(
          'DML-X.XML',
          dmlXml('<dmlEntry>${dmRefXml('modelIdentCode="X"')}</dmlEntry>'),
        ),
      );
      expect(csdb.problems.single.file, 'csdb/DML-X.XML');
      expect(csdb.problems.single.message, contains('systemDiffCode'));
    });

    test('Latin-5 dosya UTF-8 değil diye bildirilir', () {
      final csdb = Csdb.read({
        'csdb/DMC-X-A-D00-00-00-00AA-040A-A.XML': latin1.encode('<a>ü</a>'),
      });
      expect(csdb.problems.single.message, contains('UTF-8'));
    });

    test('ZIP\'ten ters bölü ile gelen yollar da tanınır', () {
      final csdb = Csdb.read({
        'paket\\DMC-X-A-D00-00-00-00AA-040A-A.XML': utf8.encode(dmXml()),
        'paket\\ICN-X-00001-001-01.PNG': [0],
      });
      expect(csdb.dataModules, hasLength(1));
      expect(csdb.icns.keys, ['ICN-X-00001-001-01']);
    });

    test('uzantı küçük harfle de tanınır', () {
      final csdb = Csdb.read({
        'dmc-x-a-d00-00-00-00aa-040a-a.xml': utf8.encode(dmXml()),
      });
      expect(csdb.dataModules, hasLength(1));
    });

    test('boş klasör', () {
      final csdb = Csdb.read({});
      expect(csdb.dataModules, isEmpty);
      expect(csdb.snsTree, isEmpty);
      expect(csdb.chunks, isEmpty);
      expect(csdb.ipd, isEmpty);
      expect(csdb.missingReferences, isEmpty);
      expect(csdb.problems, isEmpty);
    });
  });
}
