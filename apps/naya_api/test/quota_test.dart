import 'dart:io';

import 'package:naya_api/server.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late NayaDatabase db;
  late Directory dir;
  late AuthUser user;

  setUp(() async {
    db = NayaDatabase.memory();
    dir = await Directory.systemTemp.createTemp('naya_quota_test');
    final auth = AuthService(db, hasher: const PasswordHasher.fast());
    user = await auth.register('enes@ornek.com', 'gizli-sifre');
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('kişi başına sınır aşılınca yükleme reddedilir', () async {
    final file = sampleNaya(id: 'jenerator');
    // Sınır iki dosyaya yetecek kadar; üçüncüsü sığmaz.
    final library = LibraryService(
      db,
      dir.path,
      maxBytesPerUser: file.length * 2,
    );
    await library.addUserFile(user, file);
    await library.addUserFile(user, file);
    await expectLater(
      library.addUserFile(user, file),
      throwsA(
        isA<LibraryException>().having((e) => e.code, 'code', 'quota_exceeded'),
      ),
    );
  });

  test('admin için sınır yok', () async {
    final file = sampleNaya(id: 'jenerator');
    final library = LibraryService(db, dir.path, maxBytesPerUser: file.length);
    final admin = AuthUser(
      id: user.id,
      email: user.email,
      role: UserRole.admin,
    );
    await library.addUserFile(admin, file);
    await library.addUserFile(admin, file);
    expect((await library.list(admin)).userFiles, hasLength(2));
  });
}
