import 'package:drift/drift.dart';

/// Hesap rolleri. Misafirin hesabı olmadığı için burada yok: oturum
/// açmamış her istek misafirdir.
enum UserRole { user, admin }

@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Küçük harfe çevrilmiş halde saklanır; aynı adres iki kez açılamaz.
  TextColumn get email => text().unique()();

  /// Argon2id özeti, parametreleriyle birlikte tek satırda
  /// (`$argon2id$v=19$m=...`).
  TextColumn get passwordHash => text()();
  TextColumn get role => textEnum<UserRole>()();

  /// Üst üste hatalı giriş sayısı; başarılı girişte sıfırlanır.
  IntColumn get failedLogins => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Token'ın kendisi değil SHA-256 özeti. Veritabanı sızsa da oturumlar
  /// ele geçirilemez.
  TextColumn get tokenHash => text().unique()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Kütüphanedeki bir `.naya` dosyası: şablon ya da kullanıcının yüklediği.
@DataClassName('LibraryItemRow')
class LibraryItems extends Table {
  /// Rastgele, adreste görünen kimlik (`/api/library/<id>`).
  TextColumn get id => text()();

  /// Şablonlarda manifestteki `id`; açılışta aynı şablon yeniden
  /// eklenmesin, yeni sürümü eskisinin yerine geçsin diye.
  TextColumn get templateKey => text().nullable().unique()();

  /// Şablonlarda boş, kullanıcı dosyalarında sahibi.
  IntColumn get ownerId => integer().nullable().references(
    Users,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get title => text()();
  TextColumn get subtitle => text().withDefault(const Constant(''))();
  TextColumn get category => text()();
  IntColumn get partCount => integer()();
  IntColumn get faultCount => integer()();
  IntColumn get moduleCount => integer()();
  BoolColumn get hasModel => boolean()();

  /// Manifestin tamamı; atıflar ve S1000D bilgisi buradan okunur.
  TextColumn get manifestJson => text()();

  /// `storageDir/library` altındaki dosya adı.
  TextColumn get fileName => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
