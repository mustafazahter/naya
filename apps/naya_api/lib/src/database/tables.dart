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

/// Kullanıcının OpenRouter anahtarı, AES-GCM ile şifreli. Anahtar bir daha
/// istemciye gönderilmez; yalnız son dört karakteri gösterilir.
@DataClassName('AiKeyRow')
class AiKeys extends Table {
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Nonce + şifreli metin + doğrulama kodu (`KeyVault`).
  BlobColumn get secret => blob()();

  /// Ayarlarda "…a1b2" diye göstermek için son dört karakter.
  TextColumn get hint => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

/// Kullanıcının seçtiği modeller: `chat` (sohbet) ve `decision` (Jev).
/// Satır yoksa varsayılan model kullanılır.
@DataClassName('AiRoleRow')
class AiRoles extends Table {
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get model => text()();

  @override
  Set<Column<Object>> get primaryKey => {userId, role};
}

/// Her teşhis: girdi, olasılıkların tamamı, açıklama ve model sürümü.
/// Geçmişten aynen tekrar açılabilir.
@DataClassName('DiagnosisRow')
class Diagnoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get libraryItemId =>
      text().references(LibraryItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get message => text()();

  /// `DiagnosisResult.toJson()`.
  TextColumn get resultJson => text()();

  /// Sohbet modelinin açıklaması; alınamadıysa boş.
  TextColumn get explanation => text().withDefault(const Constant(''))();

  /// Karar modelinin sürümü (`jev-...`).
  TextColumn get model => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Bir ürün üzerine sohbet. Parça kartından açıldıysa [partId] dolu.
@DataClassName('ConversationRow')
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get libraryItemId =>
      text().references(LibraryItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get partId => text().nullable()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Sohbetteki mesajlar. [role] `user` ya da `assistant`.
@DataClassName('MessageRow')
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text()();

  /// Cevabın dayandığı DM'ler, JSON listesi.
  TextColumn get sourcesJson => text().withDefault(const Constant('[]'))();

  /// Mesaj bir teşhisle geldiyse onun kaydı.
  IntColumn get diagnosisId => integer().nullable().references(
    Diagnoses,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime()();
}
