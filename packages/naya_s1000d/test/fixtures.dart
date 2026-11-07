import 'dart:io';

import 'package:naya_s1000d/naya_s1000d.dart';

/// `test/fixtures/csdb` altındaki örnek bisiklet verisi: Issue 5.0 ve bir
/// tane 4.1 DM, PM, DML, BREX ve iki görsel.
Map<String, List<int>> fixtureFiles() => {
  for (final f in Directory('test/fixtures/csdb').listSync().whereType<File>())
    'csdb/${f.uri.pathSegments.last}': f.readAsBytesSync(),
};

Csdb fixtureCsdb() => Csdb.read(fixtureFiles());

String fixture(String name) =>
    File('test/fixtures/csdb/$name').readAsStringSync();
