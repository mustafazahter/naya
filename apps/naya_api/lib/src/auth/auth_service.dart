import 'package:drift/drift.dart';

import '../database/database.dart';
import 'password_hasher.dart';
import 'session_token.dart';

/// Oturum açmış kullanıcı. Misafirde (oturum yok) istekte hiç bulunmaz.
class AuthUser {
  const AuthUser({required this.id, required this.email, required this.role});

  final int id;
  final String email;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'role': role.name,
  };
}

/// Hesap işlemlerinde kullanıcıya gösterilecek hatalar. [code] istemcinin
/// mesajı seçmesi için, [message] doğrudan gösterilebilecek Türkçe metin.
class AuthException implements Exception {
  const AuthException(this.code, this.message, {this.retryAfter});

  final String code;
  final String message;

  /// Hesap kilitliyse ne kadar sonra yeniden denenebileceği.
  final Duration? retryAfter;

  @override
  String toString() => '$code: $message';
}

/// Girişin sonucu: istemciye verilecek token ve kullanıcı.
class LoginResult {
  const LoginResult(this.token, this.user);

  final String token;
  final AuthUser user;
}

/// Kayıt, giriş, çıkış ve oturum doğrulama.
class AuthService {
  AuthService(this._db, {PasswordHasher? hasher, DateTime Function()? clock})
    : _hasher = hasher ?? const PasswordHasher(),
      _clock = clock ?? DateTime.now;

  final NayaDatabase _db;
  final PasswordHasher _hasher;
  final DateTime Function() _clock;

  static const sessionLifetime = Duration(days: 30);
  static const maxFailedLogins = 5;
  static const lockDuration = Duration(minutes: 15);

  /// Oturum süresini her istekte yazmamak için en fazla saatte bir
  /// uzatıyoruz.
  static const _touchInterval = Duration(hours: 1);

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Bilinmeyen e-postayla girişte de bir özet doğrulanıyor; yoksa cevabın
  /// hızından adresin kayıtlı olup olmadığı anlaşılırdı.
  String? _dummyHash;

  Future<AuthUser> register(String email, String password) async {
    final normalized = _normalizeEmail(email);
    _checkPassword(password);
    final existing = await _findUser(normalized);
    if (existing != null) {
      throw const AuthException(
        'email_taken',
        'Bu e-posta ile açılmış bir hesap var.',
      );
    }
    return _insertUser(normalized, password, UserRole.user);
  }

  Future<LoginResult> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final user = await _findUser(normalized);
    if (user == null) {
      _dummyHash ??= await _hasher.hash('naya-dummy-password');
      await _hasher.verify(password, _dummyHash!);
      throw _invalidCredentials;
    }

    final now = _clock();
    final lockedUntil = user.lockedUntil;
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      throw _locked(lockedUntil.difference(now));
    }

    if (!await _hasher.verify(password, user.passwordHash)) {
      await _recordFailure(user, now);
      throw _invalidCredentials;
    }

    await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
      const UsersCompanion(failedLogins: Value(0), lockedUntil: Value(null)),
    );
    final token = await _createSession(user.id, now);
    return LoginResult(token, _toAuthUser(user));
  }

  /// Kayıttan sonra ayrıca giriş yaptırmamak için doğrudan oturum açar.
  Future<String> startSession(AuthUser user) =>
      _createSession(user.id, _clock());

  /// Token geçerliyse kullanıcıyı döner ve oturumu uzatır.
  Future<AuthUser?> authenticate(String token) async {
    final hash = SessionToken.hash(token);
    final query = _db.select(_db.sessions).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.sessions.userId)),
    ])..where(_db.sessions.tokenHash.equals(hash));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final session = row.readTable(_db.sessions);
    final now = _clock();
    if (!session.expiresAt.isAfter(now)) {
      await (_db.delete(
        _db.sessions,
      )..where((s) => s.id.equals(session.id))).go();
      return null;
    }
    if (now.difference(session.lastUsedAt) >= _touchInterval) {
      await (_db.update(
        _db.sessions,
      )..where((s) => s.id.equals(session.id))).write(
        SessionsCompanion(
          lastUsedAt: Value(now),
          expiresAt: Value(now.add(sessionLifetime)),
        ),
      );
    }
    return _toAuthUser(row.readTable(_db.users));
  }

  /// Çıkış: oturum satırı silinir, token bir daha kullanılamaz.
  Future<void> logout(String token) async {
    final hash = SessionToken.hash(token);
    await (_db.delete(
      _db.sessions,
    )..where((s) => s.tokenHash.equals(hash))).go();
  }

  /// Açılışta admin hesabını hazırlar. Hesap zaten admin ise şifresine
  /// dokunulmaz, uygulamadan değiştirilmiş olabilir.
  ///
  /// Kayıt herkese açık olduğu için biri bu e-postayla önceden hesap açmış
  /// olabilir. Bu yüzden var olan bir hesap yalnız şifresi de tutuyorsa admin
  /// yapılır; tutmuyorsa `admin_password_mismatch` hatası atılır ve hesaba
  /// dokunulmaz.
  Future<void> ensureAdmin(String email, String password) async {
    final normalized = _normalizeEmail(email);
    final existing = await _findUser(normalized);
    if (existing == null) {
      _checkPassword(password);
      await _insertUser(normalized, password, UserRole.admin);
      return;
    }
    if (existing.role == UserRole.admin) return;
    if (!await _hasher.verify(password, existing.passwordHash)) {
      throw const AuthException(
        'admin_password_mismatch',
        'NAYA_ADMIN_EMAIL ile açılmış bir hesap var ama şifresi '
            'NAYA_ADMIN_PASSWORD ile uyuşmuyor; admin yapılmadı.',
      );
    }
    await (_db.update(_db.users)..where((u) => u.id.equals(existing.id))).write(
      const UsersCompanion(role: Value(UserRole.admin)),
    );
  }

  /// Süresi dolmuş oturumları siler; yedekle birlikte günde bir çalışır.
  Future<int> deleteExpiredSessions() => (_db.delete(
    _db.sessions,
  )..where((s) => s.expiresAt.isSmallerOrEqualValue(_clock()))).go();

  Future<AuthUser> _insertUser(
    String email,
    String password,
    UserRole role,
  ) async {
    final id = await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            email: email,
            passwordHash: await _hasher.hash(password),
            role: role,
            createdAt: _clock(),
          ),
        );
    return AuthUser(id: id, email: email, role: role);
  }

  Future<void> _recordFailure(UserRow user, DateTime now) async {
    final failures = user.failedLogins + 1;
    final lock = failures >= maxFailedLogins;
    await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
      UsersCompanion(
        // Kilit konunca sayaç sıfırlanır; süre bitince yine 5 hak olur.
        failedLogins: Value(lock ? 0 : failures),
        lockedUntil: Value(lock ? now.add(lockDuration) : null),
      ),
    );
    if (lock) throw _locked(lockDuration);
  }

  Future<String> _createSession(int userId, DateTime now) async {
    final token = SessionToken.generate();
    await _db
        .into(_db.sessions)
        .insert(
          SessionsCompanion.insert(
            userId: userId,
            tokenHash: SessionToken.hash(token),
            expiresAt: now.add(sessionLifetime),
            lastUsedAt: now,
            createdAt: now,
          ),
        );
    return token;
  }

  Future<UserRow?> _findUser(String email) => (_db.select(
    _db.users,
  )..where((u) => u.email.equals(email))).getSingleOrNull();

  static AuthUser _toAuthUser(UserRow row) =>
      AuthUser(id: row.id, email: row.email, role: row.role);

  static String _normalizeEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.length > 254 || !_emailPattern.hasMatch(normalized)) {
      throw const AuthException(
        'invalid_email',
        'Geçerli bir e-posta adresi girin.',
      );
    }
    return normalized;
  }

  static void _checkPassword(String password) {
    if (password.length < 8) {
      throw const AuthException(
        'weak_password',
        'Şifre en az 8 karakter olmalı.',
      );
    }
    // Argon2id uzun girdiyi de işler; sınır yalnız kötüye kullanıma karşı.
    if (password.length > 256) {
      throw const AuthException(
        'weak_password',
        'Şifre en fazla 256 karakter olabilir.',
      );
    }
  }

  static const _invalidCredentials = AuthException(
    'invalid_credentials',
    'E-posta ya da şifre yanlış.',
  );

  static AuthException _locked(Duration retryAfter) {
    final minutes = (retryAfter.inSeconds / 60).ceil();
    return AuthException(
      'locked',
      'Çok fazla hatalı deneme. $minutes dakika sonra tekrar deneyin.',
      retryAfter: retryAfter,
    );
  }
}
