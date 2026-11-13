// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<UserRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UserRole>($UsersTable.$converterrole);
  static const VerificationMeta _failedLoginsMeta = const VerificationMeta(
    'failedLogins',
  );
  @override
  late final GeneratedColumn<int> failedLogins = GeneratedColumn<int>(
    'failed_logins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    passwordHash,
    role,
    failedLogins,
    lockedUntil,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('failed_logins')) {
      context.handle(
        _failedLoginsMeta,
        failedLogins.isAcceptableOrUnknown(
          data['failed_logins']!,
          _failedLoginsMeta,
        ),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      role: $UsersTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      failedLogins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_logins'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UserRole, String, String> $converterrole =
      const EnumNameConverter<UserRole>(UserRole.values);
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final int id;

  /// Küçük harfe çevrilmiş halde saklanır; aynı adres iki kez açılamaz.
  final String email;

  /// Argon2id özeti, parametreleriyle birlikte tek satırda
  /// (`$argon2id$v=19$m=...`).
  final String passwordHash;
  final UserRole role;

  /// Üst üste hatalı giriş sayısı; başarılı girişte sıfırlanır.
  final int failedLogins;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  const UserRow({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.failedLogins,
    this.lockedUntil,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    {
      map['role'] = Variable<String>($UsersTable.$converterrole.toSql(role));
    }
    map['failed_logins'] = Variable<int>(failedLogins);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      passwordHash: Value(passwordHash),
      role: Value(role),
      failedLogins: Value(failedLogins),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      createdAt: Value(createdAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<int>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      role: $UsersTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      failedLogins: serializer.fromJson<int>(json['failedLogins']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'role': serializer.toJson<String>(
        $UsersTable.$converterrole.toJson(role),
      ),
      'failedLogins': serializer.toJson<int>(failedLogins),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserRow copyWith({
    int? id,
    String? email,
    String? passwordHash,
    UserRole? role,
    int? failedLogins,
    Value<DateTime?> lockedUntil = const Value.absent(),
    DateTime? createdAt,
  }) => UserRow(
    id: id ?? this.id,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    failedLogins: failedLogins ?? this.failedLogins,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
    createdAt: createdAt ?? this.createdAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      role: data.role.present ? data.role.value : this.role,
      failedLogins: data.failedLogins.present
          ? data.failedLogins.value
          : this.failedLogins,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('failedLogins: $failedLogins, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    passwordHash,
    role,
    failedLogins,
    lockedUntil,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.role == this.role &&
          other.failedLogins == this.failedLogins &&
          other.lockedUntil == this.lockedUntil &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<int> id;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<UserRole> role;
  final Value<int> failedLogins;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.role = const Value.absent(),
    this.failedLogins = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String email,
    required String passwordHash,
    required UserRole role,
    this.failedLogins = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    required DateTime createdAt,
  }) : email = Value(email),
       passwordHash = Value(passwordHash),
       role = Value(role),
       createdAt = Value(createdAt);
  static Insertable<UserRow> custom({
    Expression<int>? id,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? role,
    Expression<int>? failedLogins,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (role != null) 'role': role,
      if (failedLogins != null) 'failed_logins': failedLogins,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<UserRole>? role,
    Value<int>? failedLogins,
    Value<DateTime?>? lockedUntil,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      failedLogins: failedLogins ?? this.failedLogins,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $UsersTable.$converterrole.toSql(role.value),
      );
    }
    if (failedLogins.present) {
      map['failed_logins'] = Variable<int>(failedLogins.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('role: $role, ')
          ..write('failedLogins: $failedLogins, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tokenHashMeta = const VerificationMeta(
    'tokenHash',
  );
  @override
  late final GeneratedColumn<String> tokenHash = GeneratedColumn<String>(
    'token_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    tokenHash,
    expiresAt,
    lastUsedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('token_hash')) {
      context.handle(
        _tokenHashMeta,
        tokenHash.isAcceptableOrUnknown(data['token_hash']!, _tokenHashMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenHashMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      tokenHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_hash'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final int userId;

  /// Token'ın kendisi değil SHA-256 özeti. Veritabanı sızsa da oturumlar
  /// ele geçirilemez.
  final String tokenHash;
  final DateTime expiresAt;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  const SessionRow({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.expiresAt,
    required this.lastUsedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['token_hash'] = Variable<String>(tokenHash);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      tokenHash: Value(tokenHash),
      expiresAt: Value(expiresAt),
      lastUsedAt: Value(lastUsedAt),
      createdAt: Value(createdAt),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      tokenHash: serializer.fromJson<String>(json['tokenHash']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'tokenHash': serializer.toJson<String>(tokenHash),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SessionRow copyWith({
    int? id,
    int? userId,
    String? tokenHash,
    DateTime? expiresAt,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) => SessionRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tokenHash: tokenHash ?? this.tokenHash,
    expiresAt: expiresAt ?? this.expiresAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tokenHash: data.tokenHash.present ? data.tokenHash.value : this.tokenHash,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, tokenHash, expiresAt, lastUsedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tokenHash == this.tokenHash &&
          other.expiresAt == this.expiresAt &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> tokenHash;
  final Value<DateTime> expiresAt;
  final Value<DateTime> lastUsedAt;
  final Value<DateTime> createdAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tokenHash = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String tokenHash,
    required DateTime expiresAt,
    required DateTime lastUsedAt,
    required DateTime createdAt,
  }) : userId = Value(userId),
       tokenHash = Value(tokenHash),
       expiresAt = Value(expiresAt),
       lastUsedAt = Value(lastUsedAt),
       createdAt = Value(createdAt);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? tokenHash,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tokenHash != null) 'token_hash': tokenHash,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? tokenHash,
    Value<DateTime>? expiresAt,
    Value<DateTime>? lastUsedAt,
    Value<DateTime>? createdAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tokenHash: tokenHash ?? this.tokenHash,
      expiresAt: expiresAt ?? this.expiresAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (tokenHash.present) {
      map['token_hash'] = Variable<String>(tokenHash.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tokenHash: $tokenHash, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LibraryItemsTable extends LibraryItems
    with TableInfo<$LibraryItemsTable, LibraryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateKeyMeta = const VerificationMeta(
    'templateKey',
  );
  @override
  late final GeneratedColumn<String> templateKey = GeneratedColumn<String>(
    'template_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<int> ownerId = GeneratedColumn<int>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partCountMeta = const VerificationMeta(
    'partCount',
  );
  @override
  late final GeneratedColumn<int> partCount = GeneratedColumn<int>(
    'part_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faultCountMeta = const VerificationMeta(
    'faultCount',
  );
  @override
  late final GeneratedColumn<int> faultCount = GeneratedColumn<int>(
    'fault_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleCountMeta = const VerificationMeta(
    'moduleCount',
  );
  @override
  late final GeneratedColumn<int> moduleCount = GeneratedColumn<int>(
    'module_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasModelMeta = const VerificationMeta(
    'hasModel',
  );
  @override
  late final GeneratedColumn<bool> hasModel = GeneratedColumn<bool>(
    'has_model',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_model" IN (0, 1))',
    ),
  );
  static const VerificationMeta _manifestJsonMeta = const VerificationMeta(
    'manifestJson',
  );
  @override
  late final GeneratedColumn<String> manifestJson = GeneratedColumn<String>(
    'manifest_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateKey,
    ownerId,
    title,
    subtitle,
    category,
    partCount,
    faultCount,
    moduleCount,
    hasModel,
    manifestJson,
    fileName,
    sizeBytes,
    sha256,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_key')) {
      context.handle(
        _templateKeyMeta,
        templateKey.isAcceptableOrUnknown(
          data['template_key']!,
          _templateKeyMeta,
        ),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('part_count')) {
      context.handle(
        _partCountMeta,
        partCount.isAcceptableOrUnknown(data['part_count']!, _partCountMeta),
      );
    } else if (isInserting) {
      context.missing(_partCountMeta);
    }
    if (data.containsKey('fault_count')) {
      context.handle(
        _faultCountMeta,
        faultCount.isAcceptableOrUnknown(data['fault_count']!, _faultCountMeta),
      );
    } else if (isInserting) {
      context.missing(_faultCountMeta);
    }
    if (data.containsKey('module_count')) {
      context.handle(
        _moduleCountMeta,
        moduleCount.isAcceptableOrUnknown(
          data['module_count']!,
          _moduleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_moduleCountMeta);
    }
    if (data.containsKey('has_model')) {
      context.handle(
        _hasModelMeta,
        hasModel.isAcceptableOrUnknown(data['has_model']!, _hasModelMeta),
      );
    } else if (isInserting) {
      context.missing(_hasModelMeta);
    }
    if (data.containsKey('manifest_json')) {
      context.handle(
        _manifestJsonMeta,
        manifestJson.isAcceptableOrUnknown(
          data['manifest_json']!,
          _manifestJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manifestJsonMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_key'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}owner_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      partCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_count'],
      )!,
      faultCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fault_count'],
      )!,
      moduleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}module_count'],
      )!,
      hasModel: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_model'],
      )!,
      manifestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest_json'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LibraryItemsTable createAlias(String alias) {
    return $LibraryItemsTable(attachedDatabase, alias);
  }
}

class LibraryItemRow extends DataClass implements Insertable<LibraryItemRow> {
  /// Rastgele, adreste görünen kimlik (`/api/library/<id>`).
  final String id;

  /// Şablonlarda manifestteki `id`; açılışta aynı şablon yeniden
  /// eklenmesin, yeni sürümü eskisinin yerine geçsin diye.
  final String? templateKey;

  /// Şablonlarda boş, kullanıcı dosyalarında sahibi.
  final int? ownerId;
  final String title;
  final String subtitle;
  final String category;
  final int partCount;
  final int faultCount;
  final int moduleCount;
  final bool hasModel;

  /// Manifestin tamamı; atıflar ve S1000D bilgisi buradan okunur.
  final String manifestJson;

  /// `storageDir/library` altındaki dosya adı.
  final String fileName;
  final int sizeBytes;
  final String sha256;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LibraryItemRow({
    required this.id,
    this.templateKey,
    this.ownerId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.partCount,
    required this.faultCount,
    required this.moduleCount,
    required this.hasModel,
    required this.manifestJson,
    required this.fileName,
    required this.sizeBytes,
    required this.sha256,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || templateKey != null) {
      map['template_key'] = Variable<String>(templateKey);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<int>(ownerId);
    }
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    map['category'] = Variable<String>(category);
    map['part_count'] = Variable<int>(partCount);
    map['fault_count'] = Variable<int>(faultCount);
    map['module_count'] = Variable<int>(moduleCount);
    map['has_model'] = Variable<bool>(hasModel);
    map['manifest_json'] = Variable<String>(manifestJson);
    map['file_name'] = Variable<String>(fileName);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['sha256'] = Variable<String>(sha256);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LibraryItemsCompanion toCompanion(bool nullToAbsent) {
    return LibraryItemsCompanion(
      id: Value(id),
      templateKey: templateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(templateKey),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      title: Value(title),
      subtitle: Value(subtitle),
      category: Value(category),
      partCount: Value(partCount),
      faultCount: Value(faultCount),
      moduleCount: Value(moduleCount),
      hasModel: Value(hasModel),
      manifestJson: Value(manifestJson),
      fileName: Value(fileName),
      sizeBytes: Value(sizeBytes),
      sha256: Value(sha256),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryItemRow(
      id: serializer.fromJson<String>(json['id']),
      templateKey: serializer.fromJson<String?>(json['templateKey']),
      ownerId: serializer.fromJson<int?>(json['ownerId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      category: serializer.fromJson<String>(json['category']),
      partCount: serializer.fromJson<int>(json['partCount']),
      faultCount: serializer.fromJson<int>(json['faultCount']),
      moduleCount: serializer.fromJson<int>(json['moduleCount']),
      hasModel: serializer.fromJson<bool>(json['hasModel']),
      manifestJson: serializer.fromJson<String>(json['manifestJson']),
      fileName: serializer.fromJson<String>(json['fileName']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String>(json['sha256']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateKey': serializer.toJson<String?>(templateKey),
      'ownerId': serializer.toJson<int?>(ownerId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'category': serializer.toJson<String>(category),
      'partCount': serializer.toJson<int>(partCount),
      'faultCount': serializer.toJson<int>(faultCount),
      'moduleCount': serializer.toJson<int>(moduleCount),
      'hasModel': serializer.toJson<bool>(hasModel),
      'manifestJson': serializer.toJson<String>(manifestJson),
      'fileName': serializer.toJson<String>(fileName),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String>(sha256),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LibraryItemRow copyWith({
    String? id,
    Value<String?> templateKey = const Value.absent(),
    Value<int?> ownerId = const Value.absent(),
    String? title,
    String? subtitle,
    String? category,
    int? partCount,
    int? faultCount,
    int? moduleCount,
    bool? hasModel,
    String? manifestJson,
    String? fileName,
    int? sizeBytes,
    String? sha256,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LibraryItemRow(
    id: id ?? this.id,
    templateKey: templateKey.present ? templateKey.value : this.templateKey,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    category: category ?? this.category,
    partCount: partCount ?? this.partCount,
    faultCount: faultCount ?? this.faultCount,
    moduleCount: moduleCount ?? this.moduleCount,
    hasModel: hasModel ?? this.hasModel,
    manifestJson: manifestJson ?? this.manifestJson,
    fileName: fileName ?? this.fileName,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    sha256: sha256 ?? this.sha256,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LibraryItemRow copyWithCompanion(LibraryItemsCompanion data) {
    return LibraryItemRow(
      id: data.id.present ? data.id.value : this.id,
      templateKey: data.templateKey.present
          ? data.templateKey.value
          : this.templateKey,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      category: data.category.present ? data.category.value : this.category,
      partCount: data.partCount.present ? data.partCount.value : this.partCount,
      faultCount: data.faultCount.present
          ? data.faultCount.value
          : this.faultCount,
      moduleCount: data.moduleCount.present
          ? data.moduleCount.value
          : this.moduleCount,
      hasModel: data.hasModel.present ? data.hasModel.value : this.hasModel,
      manifestJson: data.manifestJson.present
          ? data.manifestJson.value
          : this.manifestJson,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItemRow(')
          ..write('id: $id, ')
          ..write('templateKey: $templateKey, ')
          ..write('ownerId: $ownerId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('category: $category, ')
          ..write('partCount: $partCount, ')
          ..write('faultCount: $faultCount, ')
          ..write('moduleCount: $moduleCount, ')
          ..write('hasModel: $hasModel, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateKey,
    ownerId,
    title,
    subtitle,
    category,
    partCount,
    faultCount,
    moduleCount,
    hasModel,
    manifestJson,
    fileName,
    sizeBytes,
    sha256,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryItemRow &&
          other.id == this.id &&
          other.templateKey == this.templateKey &&
          other.ownerId == this.ownerId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.category == this.category &&
          other.partCount == this.partCount &&
          other.faultCount == this.faultCount &&
          other.moduleCount == this.moduleCount &&
          other.hasModel == this.hasModel &&
          other.manifestJson == this.manifestJson &&
          other.fileName == this.fileName &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LibraryItemsCompanion extends UpdateCompanion<LibraryItemRow> {
  final Value<String> id;
  final Value<String?> templateKey;
  final Value<int?> ownerId;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<String> category;
  final Value<int> partCount;
  final Value<int> faultCount;
  final Value<int> moduleCount;
  final Value<bool> hasModel;
  final Value<String> manifestJson;
  final Value<String> fileName;
  final Value<int> sizeBytes;
  final Value<String> sha256;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LibraryItemsCompanion({
    this.id = const Value.absent(),
    this.templateKey = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.category = const Value.absent(),
    this.partCount = const Value.absent(),
    this.faultCount = const Value.absent(),
    this.moduleCount = const Value.absent(),
    this.hasModel = const Value.absent(),
    this.manifestJson = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryItemsCompanion.insert({
    required String id,
    this.templateKey = const Value.absent(),
    this.ownerId = const Value.absent(),
    required String title,
    this.subtitle = const Value.absent(),
    required String category,
    required int partCount,
    required int faultCount,
    required int moduleCount,
    required bool hasModel,
    required String manifestJson,
    required String fileName,
    required int sizeBytes,
    required String sha256,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       category = Value(category),
       partCount = Value(partCount),
       faultCount = Value(faultCount),
       moduleCount = Value(moduleCount),
       hasModel = Value(hasModel),
       manifestJson = Value(manifestJson),
       fileName = Value(fileName),
       sizeBytes = Value(sizeBytes),
       sha256 = Value(sha256),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LibraryItemRow> custom({
    Expression<String>? id,
    Expression<String>? templateKey,
    Expression<int>? ownerId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? category,
    Expression<int>? partCount,
    Expression<int>? faultCount,
    Expression<int>? moduleCount,
    Expression<bool>? hasModel,
    Expression<String>? manifestJson,
    Expression<String>? fileName,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateKey != null) 'template_key': templateKey,
      if (ownerId != null) 'owner_id': ownerId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (category != null) 'category': category,
      if (partCount != null) 'part_count': partCount,
      if (faultCount != null) 'fault_count': faultCount,
      if (moduleCount != null) 'module_count': moduleCount,
      if (hasModel != null) 'has_model': hasModel,
      if (manifestJson != null) 'manifest_json': manifestJson,
      if (fileName != null) 'file_name': fileName,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? templateKey,
    Value<int?>? ownerId,
    Value<String>? title,
    Value<String>? subtitle,
    Value<String>? category,
    Value<int>? partCount,
    Value<int>? faultCount,
    Value<int>? moduleCount,
    Value<bool>? hasModel,
    Value<String>? manifestJson,
    Value<String>? fileName,
    Value<int>? sizeBytes,
    Value<String>? sha256,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LibraryItemsCompanion(
      id: id ?? this.id,
      templateKey: templateKey ?? this.templateKey,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      partCount: partCount ?? this.partCount,
      faultCount: faultCount ?? this.faultCount,
      moduleCount: moduleCount ?? this.moduleCount,
      hasModel: hasModel ?? this.hasModel,
      manifestJson: manifestJson ?? this.manifestJson,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateKey.present) {
      map['template_key'] = Variable<String>(templateKey.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<int>(ownerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (partCount.present) {
      map['part_count'] = Variable<int>(partCount.value);
    }
    if (faultCount.present) {
      map['fault_count'] = Variable<int>(faultCount.value);
    }
    if (moduleCount.present) {
      map['module_count'] = Variable<int>(moduleCount.value);
    }
    if (hasModel.present) {
      map['has_model'] = Variable<bool>(hasModel.value);
    }
    if (manifestJson.present) {
      map['manifest_json'] = Variable<String>(manifestJson.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateKey: $templateKey, ')
          ..write('ownerId: $ownerId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('category: $category, ')
          ..write('partCount: $partCount, ')
          ..write('faultCount: $faultCount, ')
          ..write('moduleCount: $moduleCount, ')
          ..write('hasModel: $hasModel, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiKeysTable extends AiKeys with TableInfo<$AiKeysTable, AiKeyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _secretMeta = const VerificationMeta('secret');
  @override
  late final GeneratedColumn<Uint8List> secret = GeneratedColumn<Uint8List>(
    'secret',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintMeta = const VerificationMeta('hint');
  @override
  late final GeneratedColumn<String> hint = GeneratedColumn<String>(
    'hint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, secret, hint, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiKeyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('secret')) {
      context.handle(
        _secretMeta,
        secret.isAcceptableOrUnknown(data['secret']!, _secretMeta),
      );
    } else if (isInserting) {
      context.missing(_secretMeta);
    }
    if (data.containsKey('hint')) {
      context.handle(
        _hintMeta,
        hint.isAcceptableOrUnknown(data['hint']!, _hintMeta),
      );
    } else if (isInserting) {
      context.missing(_hintMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  AiKeyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiKeyRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      secret: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}secret'],
      )!,
      hint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hint'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AiKeysTable createAlias(String alias) {
    return $AiKeysTable(attachedDatabase, alias);
  }
}

class AiKeyRow extends DataClass implements Insertable<AiKeyRow> {
  final int userId;

  /// Nonce + şifreli metin + doğrulama kodu (`KeyVault`).
  final Uint8List secret;

  /// Ayarlarda "…a1b2" diye göstermek için son dört karakter.
  final String hint;
  final DateTime updatedAt;
  const AiKeyRow({
    required this.userId,
    required this.secret,
    required this.hint,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['secret'] = Variable<Uint8List>(secret);
    map['hint'] = Variable<String>(hint);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiKeysCompanion toCompanion(bool nullToAbsent) {
    return AiKeysCompanion(
      userId: Value(userId),
      secret: Value(secret),
      hint: Value(hint),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiKeyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiKeyRow(
      userId: serializer.fromJson<int>(json['userId']),
      secret: serializer.fromJson<Uint8List>(json['secret']),
      hint: serializer.fromJson<String>(json['hint']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'secret': serializer.toJson<Uint8List>(secret),
      'hint': serializer.toJson<String>(hint),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiKeyRow copyWith({
    int? userId,
    Uint8List? secret,
    String? hint,
    DateTime? updatedAt,
  }) => AiKeyRow(
    userId: userId ?? this.userId,
    secret: secret ?? this.secret,
    hint: hint ?? this.hint,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AiKeyRow copyWithCompanion(AiKeysCompanion data) {
    return AiKeyRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      secret: data.secret.present ? data.secret.value : this.secret,
      hint: data.hint.present ? data.hint.value : this.hint,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiKeyRow(')
          ..write('userId: $userId, ')
          ..write('secret: $secret, ')
          ..write('hint: $hint, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, $driftBlobEquality.hash(secret), hint, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiKeyRow &&
          other.userId == this.userId &&
          $driftBlobEquality.equals(other.secret, this.secret) &&
          other.hint == this.hint &&
          other.updatedAt == this.updatedAt);
}

class AiKeysCompanion extends UpdateCompanion<AiKeyRow> {
  final Value<int> userId;
  final Value<Uint8List> secret;
  final Value<String> hint;
  final Value<DateTime> updatedAt;
  const AiKeysCompanion({
    this.userId = const Value.absent(),
    this.secret = const Value.absent(),
    this.hint = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AiKeysCompanion.insert({
    this.userId = const Value.absent(),
    required Uint8List secret,
    required String hint,
    required DateTime updatedAt,
  }) : secret = Value(secret),
       hint = Value(hint),
       updatedAt = Value(updatedAt);
  static Insertable<AiKeyRow> custom({
    Expression<int>? userId,
    Expression<Uint8List>? secret,
    Expression<String>? hint,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (secret != null) 'secret': secret,
      if (hint != null) 'hint': hint,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AiKeysCompanion copyWith({
    Value<int>? userId,
    Value<Uint8List>? secret,
    Value<String>? hint,
    Value<DateTime>? updatedAt,
  }) {
    return AiKeysCompanion(
      userId: userId ?? this.userId,
      secret: secret ?? this.secret,
      hint: hint ?? this.hint,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (secret.present) {
      map['secret'] = Variable<Uint8List>(secret.value);
    }
    if (hint.present) {
      map['hint'] = Variable<String>(hint.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiKeysCompanion(')
          ..write('userId: $userId, ')
          ..write('secret: $secret, ')
          ..write('hint: $hint, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AiRolesTable extends AiRoles with TableInfo<$AiRolesTable, AiRoleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiRolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, role, model];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_roles';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiRoleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, role};
  @override
  AiRoleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiRoleRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
    );
  }

  @override
  $AiRolesTable createAlias(String alias) {
    return $AiRolesTable(attachedDatabase, alias);
  }
}

class AiRoleRow extends DataClass implements Insertable<AiRoleRow> {
  final int userId;
  final String role;
  final String model;
  const AiRoleRow({
    required this.userId,
    required this.role,
    required this.model,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['role'] = Variable<String>(role);
    map['model'] = Variable<String>(model);
    return map;
  }

  AiRolesCompanion toCompanion(bool nullToAbsent) {
    return AiRolesCompanion(
      userId: Value(userId),
      role: Value(role),
      model: Value(model),
    );
  }

  factory AiRoleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiRoleRow(
      userId: serializer.fromJson<int>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      model: serializer.fromJson<String>(json['model']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'role': serializer.toJson<String>(role),
      'model': serializer.toJson<String>(model),
    };
  }

  AiRoleRow copyWith({int? userId, String? role, String? model}) => AiRoleRow(
    userId: userId ?? this.userId,
    role: role ?? this.role,
    model: model ?? this.model,
  );
  AiRoleRow copyWithCompanion(AiRolesCompanion data) {
    return AiRoleRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      model: data.model.present ? data.model.value : this.model,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiRoleRow(')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('model: $model')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, role, model);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiRoleRow &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.model == this.model);
}

class AiRolesCompanion extends UpdateCompanion<AiRoleRow> {
  final Value<int> userId;
  final Value<String> role;
  final Value<String> model;
  final Value<int> rowid;
  const AiRolesCompanion({
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.model = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiRolesCompanion.insert({
    required int userId,
    required String role,
    required String model,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       role = Value(role),
       model = Value(model);
  static Insertable<AiRoleRow> custom({
    Expression<int>? userId,
    Expression<String>? role,
    Expression<String>? model,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (model != null) 'model': model,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiRolesCompanion copyWith({
    Value<int>? userId,
    Value<String>? role,
    Value<String>? model,
    Value<int>? rowid,
  }) {
    return AiRolesCompanion(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      model: model ?? this.model,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiRolesCompanion(')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('model: $model, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiagnosesTable extends Diagnoses
    with TableInfo<$DiagnosesTable, DiagnosisRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiagnosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _libraryItemIdMeta = const VerificationMeta(
    'libraryItemId',
  );
  @override
  late final GeneratedColumn<String> libraryItemId = GeneratedColumn<String>(
    'library_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    libraryItemId,
    message,
    resultJson,
    explanation,
    model,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diagnoses';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiagnosisRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('library_item_id')) {
      context.handle(
        _libraryItemIdMeta,
        libraryItemId.isAcceptableOrUnknown(
          data['library_item_id']!,
          _libraryItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryItemIdMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiagnosisRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiagnosisRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      libraryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_item_id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DiagnosesTable createAlias(String alias) {
    return $DiagnosesTable(attachedDatabase, alias);
  }
}

class DiagnosisRow extends DataClass implements Insertable<DiagnosisRow> {
  final int id;
  final int userId;
  final String libraryItemId;
  final String message;

  /// `DiagnosisResult.toJson()`.
  final String resultJson;

  /// Sohbet modelinin açıklaması; alınamadıysa boş.
  final String explanation;

  /// Karar modelinin sürümü (`jev-...`).
  final String model;
  final DateTime createdAt;
  const DiagnosisRow({
    required this.id,
    required this.userId,
    required this.libraryItemId,
    required this.message,
    required this.resultJson,
    required this.explanation,
    required this.model,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['library_item_id'] = Variable<String>(libraryItemId);
    map['message'] = Variable<String>(message);
    map['result_json'] = Variable<String>(resultJson);
    map['explanation'] = Variable<String>(explanation);
    map['model'] = Variable<String>(model);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DiagnosesCompanion toCompanion(bool nullToAbsent) {
    return DiagnosesCompanion(
      id: Value(id),
      userId: Value(userId),
      libraryItemId: Value(libraryItemId),
      message: Value(message),
      resultJson: Value(resultJson),
      explanation: Value(explanation),
      model: Value(model),
      createdAt: Value(createdAt),
    );
  }

  factory DiagnosisRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiagnosisRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      libraryItemId: serializer.fromJson<String>(json['libraryItemId']),
      message: serializer.fromJson<String>(json['message']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      explanation: serializer.fromJson<String>(json['explanation']),
      model: serializer.fromJson<String>(json['model']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'libraryItemId': serializer.toJson<String>(libraryItemId),
      'message': serializer.toJson<String>(message),
      'resultJson': serializer.toJson<String>(resultJson),
      'explanation': serializer.toJson<String>(explanation),
      'model': serializer.toJson<String>(model),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DiagnosisRow copyWith({
    int? id,
    int? userId,
    String? libraryItemId,
    String? message,
    String? resultJson,
    String? explanation,
    String? model,
    DateTime? createdAt,
  }) => DiagnosisRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    libraryItemId: libraryItemId ?? this.libraryItemId,
    message: message ?? this.message,
    resultJson: resultJson ?? this.resultJson,
    explanation: explanation ?? this.explanation,
    model: model ?? this.model,
    createdAt: createdAt ?? this.createdAt,
  );
  DiagnosisRow copyWithCompanion(DiagnosesCompanion data) {
    return DiagnosisRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      libraryItemId: data.libraryItemId.present
          ? data.libraryItemId.value
          : this.libraryItemId,
      message: data.message.present ? data.message.value : this.message,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      model: data.model.present ? data.model.value : this.model,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiagnosisRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('libraryItemId: $libraryItemId, ')
          ..write('message: $message, ')
          ..write('resultJson: $resultJson, ')
          ..write('explanation: $explanation, ')
          ..write('model: $model, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    libraryItemId,
    message,
    resultJson,
    explanation,
    model,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiagnosisRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.libraryItemId == this.libraryItemId &&
          other.message == this.message &&
          other.resultJson == this.resultJson &&
          other.explanation == this.explanation &&
          other.model == this.model &&
          other.createdAt == this.createdAt);
}

class DiagnosesCompanion extends UpdateCompanion<DiagnosisRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> libraryItemId;
  final Value<String> message;
  final Value<String> resultJson;
  final Value<String> explanation;
  final Value<String> model;
  final Value<DateTime> createdAt;
  const DiagnosesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.libraryItemId = const Value.absent(),
    this.message = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.explanation = const Value.absent(),
    this.model = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DiagnosesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String libraryItemId,
    required String message,
    required String resultJson,
    this.explanation = const Value.absent(),
    required String model,
    required DateTime createdAt,
  }) : userId = Value(userId),
       libraryItemId = Value(libraryItemId),
       message = Value(message),
       resultJson = Value(resultJson),
       model = Value(model),
       createdAt = Value(createdAt);
  static Insertable<DiagnosisRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? libraryItemId,
    Expression<String>? message,
    Expression<String>? resultJson,
    Expression<String>? explanation,
    Expression<String>? model,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (libraryItemId != null) 'library_item_id': libraryItemId,
      if (message != null) 'message': message,
      if (resultJson != null) 'result_json': resultJson,
      if (explanation != null) 'explanation': explanation,
      if (model != null) 'model': model,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DiagnosesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? libraryItemId,
    Value<String>? message,
    Value<String>? resultJson,
    Value<String>? explanation,
    Value<String>? model,
    Value<DateTime>? createdAt,
  }) {
    return DiagnosesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      libraryItemId: libraryItemId ?? this.libraryItemId,
      message: message ?? this.message,
      resultJson: resultJson ?? this.resultJson,
      explanation: explanation ?? this.explanation,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (libraryItemId.present) {
      map['library_item_id'] = Variable<String>(libraryItemId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiagnosesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('libraryItemId: $libraryItemId, ')
          ..write('message: $message, ')
          ..write('resultJson: $resultJson, ')
          ..write('explanation: $explanation, ')
          ..write('model: $model, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _libraryItemIdMeta = const VerificationMeta(
    'libraryItemId',
  );
  @override
  late final GeneratedColumn<String> libraryItemId = GeneratedColumn<String>(
    'library_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<String> partId = GeneratedColumn<String>(
    'part_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    libraryItemId,
    partId,
    title,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('library_item_id')) {
      context.handle(
        _libraryItemIdMeta,
        libraryItemId.isAcceptableOrUnknown(
          data['library_item_id']!,
          _libraryItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryItemIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      libraryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_item_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationRow extends DataClass implements Insertable<ConversationRow> {
  final int id;
  final int userId;
  final String libraryItemId;
  final String? partId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConversationRow({
    required this.id,
    required this.userId,
    required this.libraryItemId,
    this.partId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['library_item_id'] = Variable<String>(libraryItemId);
    if (!nullToAbsent || partId != null) {
      map['part_id'] = Variable<String>(partId);
    }
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      userId: Value(userId),
      libraryItemId: Value(libraryItemId),
      partId: partId == null && nullToAbsent
          ? const Value.absent()
          : Value(partId),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      libraryItemId: serializer.fromJson<String>(json['libraryItemId']),
      partId: serializer.fromJson<String?>(json['partId']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'libraryItemId': serializer.toJson<String>(libraryItemId),
      'partId': serializer.toJson<String?>(partId),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConversationRow copyWith({
    int? id,
    int? userId,
    String? libraryItemId,
    Value<String?> partId = const Value.absent(),
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConversationRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    libraryItemId: libraryItemId ?? this.libraryItemId,
    partId: partId.present ? partId.value : this.partId,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConversationRow copyWithCompanion(ConversationsCompanion data) {
    return ConversationRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      libraryItemId: data.libraryItemId.present
          ? data.libraryItemId.value
          : this.libraryItemId,
      partId: data.partId.present ? data.partId.value : this.partId,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('libraryItemId: $libraryItemId, ')
          ..write('partId: $partId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    libraryItemId,
    partId,
    title,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.libraryItemId == this.libraryItemId &&
          other.partId == this.partId &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<ConversationRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> libraryItemId;
  final Value<String?> partId;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.libraryItemId = const Value.absent(),
    this.partId = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConversationsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String libraryItemId,
    this.partId = const Value.absent(),
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : userId = Value(userId),
       libraryItemId = Value(libraryItemId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConversationRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? libraryItemId,
    Expression<String>? partId,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (libraryItemId != null) 'library_item_id': libraryItemId,
      if (partId != null) 'part_id': partId,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConversationsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? libraryItemId,
    Value<String?>? partId,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      libraryItemId: libraryItemId ?? this.libraryItemId,
      partId: partId ?? this.partId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (libraryItemId.present) {
      map['library_item_id'] = Variable<String>(libraryItemId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<String>(partId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('libraryItemId: $libraryItemId, ')
          ..write('partId: $partId, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcesJsonMeta = const VerificationMeta(
    'sourcesJson',
  );
  @override
  late final GeneratedColumn<String> sourcesJson = GeneratedColumn<String>(
    'sources_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _diagnosisIdMeta = const VerificationMeta(
    'diagnosisId',
  );
  @override
  late final GeneratedColumn<int> diagnosisId = GeneratedColumn<int>(
    'diagnosis_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diagnoses (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    role,
    content,
    sourcesJson,
    diagnosisId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sources_json')) {
      context.handle(
        _sourcesJsonMeta,
        sourcesJson.isAcceptableOrUnknown(
          data['sources_json']!,
          _sourcesJsonMeta,
        ),
      );
    }
    if (data.containsKey('diagnosis_id')) {
      context.handle(
        _diagnosisIdMeta,
        diagnosisId.isAcceptableOrUnknown(
          data['diagnosis_id']!,
          _diagnosisIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      sourcesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources_json'],
      )!,
      diagnosisId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diagnosis_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final int id;
  final int conversationId;
  final String role;
  final String content;

  /// Cevabın dayandığı DM'ler, JSON listesi.
  final String sourcesJson;

  /// Mesaj bir teşhisle geldiyse onun kaydı.
  final int? diagnosisId;
  final DateTime createdAt;
  const MessageRow({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.sourcesJson,
    this.diagnosisId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<int>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['sources_json'] = Variable<String>(sourcesJson);
    if (!nullToAbsent || diagnosisId != null) {
      map['diagnosis_id'] = Variable<int>(diagnosisId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      sourcesJson: Value(sourcesJson),
      diagnosisId: diagnosisId == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosisId),
      createdAt: Value(createdAt),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      sourcesJson: serializer.fromJson<String>(json['sourcesJson']),
      diagnosisId: serializer.fromJson<int?>(json['diagnosisId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'sourcesJson': serializer.toJson<String>(sourcesJson),
      'diagnosisId': serializer.toJson<int?>(diagnosisId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageRow copyWith({
    int? id,
    int? conversationId,
    String? role,
    String? content,
    String? sourcesJson,
    Value<int?> diagnosisId = const Value.absent(),
    DateTime? createdAt,
  }) => MessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    sourcesJson: sourcesJson ?? this.sourcesJson,
    diagnosisId: diagnosisId.present ? diagnosisId.value : this.diagnosisId,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      sourcesJson: data.sourcesJson.present
          ? data.sourcesJson.value
          : this.sourcesJson,
      diagnosisId: data.diagnosisId.present
          ? data.diagnosisId.value
          : this.diagnosisId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('diagnosisId: $diagnosisId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    role,
    content,
    sourcesJson,
    diagnosisId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.sourcesJson == this.sourcesJson &&
          other.diagnosisId == this.diagnosisId &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<int> id;
  final Value<int> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> sourcesJson;
  final Value<int?> diagnosisId;
  final Value<DateTime> createdAt;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.sourcesJson = const Value.absent(),
    this.diagnosisId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int conversationId,
    required String role,
    required String content,
    this.sourcesJson = const Value.absent(),
    this.diagnosisId = const Value.absent(),
    required DateTime createdAt,
  }) : conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<MessageRow> custom({
    Expression<int>? id,
    Expression<int>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? sourcesJson,
    Expression<int>? diagnosisId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (sourcesJson != null) 'sources_json': sourcesJson,
      if (diagnosisId != null) 'diagnosis_id': diagnosisId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? conversationId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? sourcesJson,
    Value<int?>? diagnosisId,
    Value<DateTime>? createdAt,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      sourcesJson: sourcesJson ?? this.sourcesJson,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sourcesJson.present) {
      map['sources_json'] = Variable<String>(sourcesJson.value);
    }
    if (diagnosisId.present) {
      map['diagnosis_id'] = Variable<int>(diagnosisId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('sourcesJson: $sourcesJson, ')
          ..write('diagnosisId: $diagnosisId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$NayaDatabase extends GeneratedDatabase {
  _$NayaDatabase(QueryExecutor e) : super(e);
  $NayaDatabaseManager get managers => $NayaDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $LibraryItemsTable libraryItems = $LibraryItemsTable(this);
  late final $AiKeysTable aiKeys = $AiKeysTable(this);
  late final $AiRolesTable aiRoles = $AiRolesTable(this);
  late final $DiagnosesTable diagnoses = $DiagnosesTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    sessions,
    libraryItems,
    aiKeys,
    aiRoles,
    diagnoses,
    conversations,
    messages,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('library_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ai_keys', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ai_roles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('diagnoses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('diagnoses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('conversations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diagnoses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String email,
  required String passwordHash,
  required UserRole role,
  Value<int> failedLogins,
  Value<DateTime?> lockedUntil,
  required DateTime createdAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> email,
  Value<String> passwordHash,
  Value<UserRole> role,
  Value<int> failedLogins,
  Value<DateTime?> lockedUntil,
  Value<DateTime> createdAt,
});

final class $$UsersTableReferences
    extends BaseReferences<_$NayaDatabase, $UsersTable, UserRow> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'users__id__sessions__user_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LibraryItemsTable, List<LibraryItemRow>>
  _libraryItemsRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.libraryItems,
    aliasName: 'users__id__library_items__owner_id',
  );

  $$LibraryItemsTableProcessedTableManager get libraryItemsRefs {
    final manager = $$LibraryItemsTableTableManager(
      $_db,
      $_db.libraryItems,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_libraryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AiKeysTable, List<AiKeyRow>> _aiKeysRefsTable(
    _$NayaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.aiKeys,
    aliasName: 'users__id__ai_keys__user_id',
  );

  $$AiKeysTableProcessedTableManager get aiKeysRefs {
    final manager = $$AiKeysTableTableManager(
      $_db,
      $_db.aiKeys,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_aiKeysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AiRolesTable, List<AiRoleRow>> _aiRolesRefsTable(
    _$NayaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.aiRoles,
    aliasName: 'users__id__ai_roles__user_id',
  );

  $$AiRolesTableProcessedTableManager get aiRolesRefs {
    final manager = $$AiRolesTableTableManager(
      $_db,
      $_db.aiRoles,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_aiRolesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiagnosesTable, List<DiagnosisRow>>
  _diagnosesRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.diagnoses,
    aliasName: 'users__id__diagnoses__user_id',
  );

  $$DiagnosesTableProcessedTableManager get diagnosesRefs {
    final manager = $$DiagnosesTableTableManager(
      $_db,
      $_db.diagnoses,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_diagnosesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConversationsTable, List<ConversationRow>>
  _conversationsRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.conversations,
    aliasName: 'users__id__conversations__user_id',
  );

  $$ConversationsTableProcessedTableManager get conversationsRefs {
    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_conversationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$NayaDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UserRole, UserRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get failedLogins => $composableBuilder(
    column: $table.failedLogins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> libraryItemsRefs(
    Expression<bool> Function($$LibraryItemsTableFilterComposer f) f,
  ) {
    final $$LibraryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableFilterComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> aiKeysRefs(
    Expression<bool> Function($$AiKeysTableFilterComposer f) f,
  ) {
    final $$AiKeysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiKeys,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiKeysTableFilterComposer(
            $db: $db,
            $table: $db.aiKeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> aiRolesRefs(
    Expression<bool> Function($$AiRolesTableFilterComposer f) f,
  ) {
    final $$AiRolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiRoles,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiRolesTableFilterComposer(
            $db: $db,
            $table: $db.aiRoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diagnosesRefs(
    Expression<bool> Function($$DiagnosesTableFilterComposer f) f,
  ) {
    final $$DiagnosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableFilterComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationsRefs(
    Expression<bool> Function($$ConversationsTableFilterComposer f) f,
  ) {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$NayaDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedLogins => $composableBuilder(
    column: $table.failedLogins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$NayaDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<UserRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get failedLogins => $composableBuilder(
    column: $table.failedLogins,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> libraryItemsRefs<T extends Object>(
    Expression<T> Function($$LibraryItemsTableAnnotationComposer a) f,
  ) {
    final $$LibraryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> aiKeysRefs<T extends Object>(
    Expression<T> Function($$AiKeysTableAnnotationComposer a) f,
  ) {
    final $$AiKeysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiKeys,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiKeysTableAnnotationComposer(
            $db: $db,
            $table: $db.aiKeys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> aiRolesRefs<T extends Object>(
    Expression<T> Function($$AiRolesTableAnnotationComposer a) f,
  ) {
    final $$AiRolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiRoles,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiRolesTableAnnotationComposer(
            $db: $db,
            $table: $db.aiRoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> diagnosesRefs<T extends Object>(
    Expression<T> Function($$DiagnosesTableAnnotationComposer a) f,
  ) {
    final $$DiagnosesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conversationsRefs<T extends Object>(
    Expression<T> Function($$ConversationsTableAnnotationComposer a) f,
  ) {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, $$UsersTableReferences),
          UserRow,
          PrefetchHooks Function({
            bool sessionsRefs,
            bool libraryItemsRefs,
            bool aiKeysRefs,
            bool aiRolesRefs,
            bool diagnosesRefs,
            bool conversationsRefs,
          })
        > {
  $$UsersTableTableManager(_$NayaDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<UserRole> role = const Value.absent(),
                Value<int> failedLogins = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                email: email,
                passwordHash: passwordHash,
                role: role,
                failedLogins: failedLogins,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String email,
                required String passwordHash,
                required UserRole role,
                Value<int> failedLogins = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                required DateTime createdAt,
              }) => UsersCompanion.insert(
                id: id,
                email: email,
                passwordHash: passwordHash,
                role: role,
                failedLogins: failedLogins,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsersTable, UserRow>(table),
                  $$UsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionsRefs = false,
                libraryItemsRefs = false,
                aiKeysRefs = false,
                aiRolesRefs = false,
                diagnosesRefs = false,
                conversationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (libraryItemsRefs) db.libraryItems,
                    if (aiKeysRefs) db.aiKeys,
                    if (aiRolesRefs) db.aiRoles,
                    if (diagnosesRefs) db.diagnoses,
                    if (conversationsRefs) db.conversations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          SessionRow,
                          $SessionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                      if (libraryItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          LibraryItemRow,
                          $LibraryItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._libraryItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).libraryItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'owner_id',
                          typedResults: items,
                        ),
                      if (aiKeysRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          AiKeyRow,
                          $AiKeysTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._aiKeysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).aiKeysRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                      if (aiRolesRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          AiRoleRow,
                          $AiRolesTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._aiRolesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).aiRolesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                      if (diagnosesRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          DiagnosisRow,
                          $DiagnosesTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._diagnosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).diagnosesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                      if (conversationsRefs)
                        await $_getPrefetchedDataByColumns<
                          UserRow,
                          $UsersTable,
                          ConversationRow,
                          $ConversationsTable
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._conversationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, $$UsersTableReferences),
      UserRow,
      PrefetchHooks Function({
        bool sessionsRefs,
        bool libraryItemsRefs,
        bool aiKeysRefs,
        bool aiRolesRefs,
        bool diagnosesRefs,
        bool conversationsRefs,
      })
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required int userId,
  required String tokenHash,
  required DateTime expiresAt,
  required DateTime lastUsedAt,
  required DateTime createdAt,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String> tokenHash,
  Value<DateTime> expiresAt,
  Value<DateTime> lastUsedAt,
  Value<DateTime> createdAt,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$NayaDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$NayaDatabase db) =>
      db.users.createAlias('sessions__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$NayaDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenHash => $composableBuilder(
    column: $table.tokenHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$NayaDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenHash => $composableBuilder(
    column: $table.tokenHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$NayaDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tokenHash =>
      $composableBuilder(column: $table.tokenHash, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool userId})
        > {
  $$SessionsTableTableManager(_$NayaDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> tokenHash = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                userId: userId,
                tokenHash: tokenHash,
                expiresAt: expiresAt,
                lastUsedAt: lastUsedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String tokenHash,
                required DateTime expiresAt,
                required DateTime lastUsedAt,
                required DateTime createdAt,
              }) => SessionsCompanion.insert(
                id: id,
                userId: userId,
                tokenHash: tokenHash,
                expiresAt: expiresAt,
                lastUsedAt: lastUsedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$SessionsTableReferences._userIdTable(
                          db,
                        ),
                        referencedColumn: $$SessionsTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$LibraryItemsTableCreateCompanionBuilder =
    LibraryItemsCompanion Function({
      required String id,
      Value<String?> templateKey,
      Value<int?> ownerId,
      required String title,
      Value<String> subtitle,
      required String category,
      required int partCount,
      required int faultCount,
      required int moduleCount,
      required bool hasModel,
      required String manifestJson,
      required String fileName,
      required int sizeBytes,
      required String sha256,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LibraryItemsTableUpdateCompanionBuilder =
    LibraryItemsCompanion Function({
      Value<String> id,
      Value<String?> templateKey,
      Value<int?> ownerId,
      Value<String> title,
      Value<String> subtitle,
      Value<String> category,
      Value<int> partCount,
      Value<int> faultCount,
      Value<int> moduleCount,
      Value<bool> hasModel,
      Value<String> manifestJson,
      Value<String> fileName,
      Value<int> sizeBytes,
      Value<String> sha256,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LibraryItemsTableReferences
    extends BaseReferences<_$NayaDatabase, $LibraryItemsTable, LibraryItemRow> {
  $$LibraryItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _ownerIdTable(_$NayaDatabase db) =>
      db.users.createAlias('library_items__owner_id__users__id');

  $$UsersTableProcessedTableManager? get ownerId {
    final $_column = $_itemColumn<int>('owner_id');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DiagnosesTable, List<DiagnosisRow>>
  _diagnosesRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.diagnoses,
    aliasName: 'library_items__id__diagnoses__library_item_id',
  );

  $$DiagnosesTableProcessedTableManager get diagnosesRefs {
    final manager = $$DiagnosesTableTableManager(
      $_db,
      $_db.diagnoses,
    ).filter((f) => f.libraryItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diagnosesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConversationsTable, List<ConversationRow>>
  _conversationsRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.conversations,
    aliasName: 'library_items__id__conversations__library_item_id',
  );

  $$ConversationsTableProcessedTableManager get conversationsRefs {
    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.libraryItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_conversationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryItemsTableFilterComposer
    extends Composer<_$NayaDatabase, $LibraryItemsTable> {
  $$LibraryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partCount => $composableBuilder(
    column: $table.partCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get faultCount => $composableBuilder(
    column: $table.faultCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moduleCount => $composableBuilder(
    column: $table.moduleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasModel => $composableBuilder(
    column: $table.hasModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get ownerId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> diagnosesRefs(
    Expression<bool> Function($$DiagnosesTableFilterComposer f) f,
  ) {
    final $$DiagnosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.libraryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableFilterComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationsRefs(
    Expression<bool> Function($$ConversationsTableFilterComposer f) f,
  ) {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.libraryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryItemsTableOrderingComposer
    extends Composer<_$NayaDatabase, $LibraryItemsTable> {
  $$LibraryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partCount => $composableBuilder(
    column: $table.partCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get faultCount => $composableBuilder(
    column: $table.faultCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moduleCount => $composableBuilder(
    column: $table.moduleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasModel => $composableBuilder(
    column: $table.hasModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get ownerId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryItemsTableAnnotationComposer
    extends Composer<_$NayaDatabase, $LibraryItemsTable> {
  $$LibraryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateKey => $composableBuilder(
    column: $table.templateKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get partCount =>
      $composableBuilder(column: $table.partCount, builder: (column) => column);

  GeneratedColumn<int> get faultCount => $composableBuilder(
    column: $table.faultCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get moduleCount => $composableBuilder(
    column: $table.moduleCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasModel =>
      $composableBuilder(column: $table.hasModel, builder: (column) => column);

  GeneratedColumn<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get ownerId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> diagnosesRefs<T extends Object>(
    Expression<T> Function($$DiagnosesTableAnnotationComposer a) f,
  ) {
    final $$DiagnosesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.libraryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conversationsRefs<T extends Object>(
    Expression<T> Function($$ConversationsTableAnnotationComposer a) f,
  ) {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.libraryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryItemsTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $LibraryItemsTable,
          LibraryItemRow,
          $$LibraryItemsTableFilterComposer,
          $$LibraryItemsTableOrderingComposer,
          $$LibraryItemsTableAnnotationComposer,
          $$LibraryItemsTableCreateCompanionBuilder,
          $$LibraryItemsTableUpdateCompanionBuilder,
          (LibraryItemRow, $$LibraryItemsTableReferences),
          LibraryItemRow,
          PrefetchHooks Function({
            bool ownerId,
            bool diagnosesRefs,
            bool conversationsRefs,
          })
        > {
  $$LibraryItemsTableTableManager(_$NayaDatabase db, $LibraryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> templateKey = const Value.absent(),
                Value<int?> ownerId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> partCount = const Value.absent(),
                Value<int> faultCount = const Value.absent(),
                Value<int> moduleCount = const Value.absent(),
                Value<bool> hasModel = const Value.absent(),
                Value<String> manifestJson = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryItemsCompanion(
                id: id,
                templateKey: templateKey,
                ownerId: ownerId,
                title: title,
                subtitle: subtitle,
                category: category,
                partCount: partCount,
                faultCount: faultCount,
                moduleCount: moduleCount,
                hasModel: hasModel,
                manifestJson: manifestJson,
                fileName: fileName,
                sizeBytes: sizeBytes,
                sha256: sha256,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> templateKey = const Value.absent(),
                Value<int?> ownerId = const Value.absent(),
                required String title,
                Value<String> subtitle = const Value.absent(),
                required String category,
                required int partCount,
                required int faultCount,
                required int moduleCount,
                required bool hasModel,
                required String manifestJson,
                required String fileName,
                required int sizeBytes,
                required String sha256,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryItemsCompanion.insert(
                id: id,
                templateKey: templateKey,
                ownerId: ownerId,
                title: title,
                subtitle: subtitle,
                category: category,
                partCount: partCount,
                faultCount: faultCount,
                moduleCount: moduleCount,
                hasModel: hasModel,
                manifestJson: manifestJson,
                fileName: fileName,
                sizeBytes: sizeBytes,
                sha256: sha256,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryItemsTable, LibraryItemRow>(table),
                  $$LibraryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerId = false,
                diagnosesRefs = false,
                conversationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (diagnosesRefs) db.diagnoses,
                    if (conversationsRefs) db.conversations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.ownerId,
                            referencedTable: $$LibraryItemsTableReferences
                                ._ownerIdTable(db),
                            referencedColumn: $$LibraryItemsTableReferences
                                ._ownerIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (diagnosesRefs)
                        await $_getPrefetchedDataByColumns<
                          LibraryItemRow,
                          $LibraryItemsTable,
                          DiagnosisRow,
                          $DiagnosesTable
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryItemsTableReferences
                              ._diagnosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).diagnosesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'library_item_id',
                          typedResults: items,
                        ),
                      if (conversationsRefs)
                        await $_getPrefetchedDataByColumns<
                          LibraryItemRow,
                          $LibraryItemsTable,
                          ConversationRow,
                          $ConversationsTable
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryItemsTableReferences
                              ._conversationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'library_item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LibraryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $LibraryItemsTable,
      LibraryItemRow,
      $$LibraryItemsTableFilterComposer,
      $$LibraryItemsTableOrderingComposer,
      $$LibraryItemsTableAnnotationComposer,
      $$LibraryItemsTableCreateCompanionBuilder,
      $$LibraryItemsTableUpdateCompanionBuilder,
      (LibraryItemRow, $$LibraryItemsTableReferences),
      LibraryItemRow,
      PrefetchHooks Function({
        bool ownerId,
        bool diagnosesRefs,
        bool conversationsRefs,
      })
    >;
typedef $$AiKeysTableCreateCompanionBuilder = AiKeysCompanion Function({
  Value<int> userId,
  required Uint8List secret,
  required String hint,
  required DateTime updatedAt,
});
typedef $$AiKeysTableUpdateCompanionBuilder = AiKeysCompanion Function({
  Value<int> userId,
  Value<Uint8List> secret,
  Value<String> hint,
  Value<DateTime> updatedAt,
});

final class $$AiKeysTableReferences
    extends BaseReferences<_$NayaDatabase, $AiKeysTable, AiKeyRow> {
  $$AiKeysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$NayaDatabase db) =>
      db.users.createAlias('ai_keys__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AiKeysTableFilterComposer
    extends Composer<_$NayaDatabase, $AiKeysTable> {
  $$AiKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get secret => $composableBuilder(
    column: $table.secret,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hint => $composableBuilder(
    column: $table.hint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiKeysTableOrderingComposer
    extends Composer<_$NayaDatabase, $AiKeysTable> {
  $$AiKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get secret => $composableBuilder(
    column: $table.secret,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hint => $composableBuilder(
    column: $table.hint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiKeysTableAnnotationComposer
    extends Composer<_$NayaDatabase, $AiKeysTable> {
  $$AiKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get secret =>
      $composableBuilder(column: $table.secret, builder: (column) => column);

  GeneratedColumn<String> get hint =>
      $composableBuilder(column: $table.hint, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiKeysTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $AiKeysTable,
          AiKeyRow,
          $$AiKeysTableFilterComposer,
          $$AiKeysTableOrderingComposer,
          $$AiKeysTableAnnotationComposer,
          $$AiKeysTableCreateCompanionBuilder,
          $$AiKeysTableUpdateCompanionBuilder,
          (AiKeyRow, $$AiKeysTableReferences),
          AiKeyRow,
          PrefetchHooks Function({bool userId})
        > {
  $$AiKeysTableTableManager(_$NayaDatabase db, $AiKeysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiKeysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiKeysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<Uint8List> secret = const Value.absent(),
                Value<String> hint = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AiKeysCompanion(
                userId: userId,
                secret: secret,
                hint: hint,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                required Uint8List secret,
                required String hint,
                required DateTime updatedAt,
              }) => AiKeysCompanion.insert(
                userId: userId,
                secret: secret,
                hint: hint,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiKeysTable, AiKeyRow>(table),
                  $$AiKeysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$AiKeysTableReferences._userIdTable(
                          db,
                        ),
                        referencedColumn: $$AiKeysTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AiKeysTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $AiKeysTable,
      AiKeyRow,
      $$AiKeysTableFilterComposer,
      $$AiKeysTableOrderingComposer,
      $$AiKeysTableAnnotationComposer,
      $$AiKeysTableCreateCompanionBuilder,
      $$AiKeysTableUpdateCompanionBuilder,
      (AiKeyRow, $$AiKeysTableReferences),
      AiKeyRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$AiRolesTableCreateCompanionBuilder = AiRolesCompanion Function({
  required int userId,
  required String role,
  required String model,
  Value<int> rowid,
});
typedef $$AiRolesTableUpdateCompanionBuilder = AiRolesCompanion Function({
  Value<int> userId,
  Value<String> role,
  Value<String> model,
  Value<int> rowid,
});

final class $$AiRolesTableReferences
    extends BaseReferences<_$NayaDatabase, $AiRolesTable, AiRoleRow> {
  $$AiRolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$NayaDatabase db) =>
      db.users.createAlias('ai_roles__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AiRolesTableFilterComposer
    extends Composer<_$NayaDatabase, $AiRolesTable> {
  $$AiRolesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiRolesTableOrderingComposer
    extends Composer<_$NayaDatabase, $AiRolesTable> {
  $$AiRolesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiRolesTableAnnotationComposer
    extends Composer<_$NayaDatabase, $AiRolesTable> {
  $$AiRolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiRolesTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $AiRolesTable,
          AiRoleRow,
          $$AiRolesTableFilterComposer,
          $$AiRolesTableOrderingComposer,
          $$AiRolesTableAnnotationComposer,
          $$AiRolesTableCreateCompanionBuilder,
          $$AiRolesTableUpdateCompanionBuilder,
          (AiRoleRow, $$AiRolesTableReferences),
          AiRoleRow,
          PrefetchHooks Function({bool userId})
        > {
  $$AiRolesTableTableManager(_$NayaDatabase db, $AiRolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiRolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiRolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiRolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiRolesCompanion(
                userId: userId,
                role: role,
                model: model,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int userId,
                required String role,
                required String model,
                Value<int> rowid = const Value.absent(),
              }) => AiRolesCompanion.insert(
                userId: userId,
                role: role,
                model: model,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiRolesTable, AiRoleRow>(table),
                  $$AiRolesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $$AiRolesTableReferences._userIdTable(
                          db,
                        ),
                        referencedColumn: $$AiRolesTableReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AiRolesTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $AiRolesTable,
      AiRoleRow,
      $$AiRolesTableFilterComposer,
      $$AiRolesTableOrderingComposer,
      $$AiRolesTableAnnotationComposer,
      $$AiRolesTableCreateCompanionBuilder,
      $$AiRolesTableUpdateCompanionBuilder,
      (AiRoleRow, $$AiRolesTableReferences),
      AiRoleRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$DiagnosesTableCreateCompanionBuilder = DiagnosesCompanion Function({
  Value<int> id,
  required int userId,
  required String libraryItemId,
  required String message,
  required String resultJson,
  Value<String> explanation,
  required String model,
  required DateTime createdAt,
});
typedef $$DiagnosesTableUpdateCompanionBuilder = DiagnosesCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String> libraryItemId,
  Value<String> message,
  Value<String> resultJson,
  Value<String> explanation,
  Value<String> model,
  Value<DateTime> createdAt,
});

final class $$DiagnosesTableReferences
    extends BaseReferences<_$NayaDatabase, $DiagnosesTable, DiagnosisRow> {
  $$DiagnosesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$NayaDatabase db) =>
      db.users.createAlias('diagnoses__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LibraryItemsTable _libraryItemIdTable(_$NayaDatabase db) => db
      .libraryItems
      .createAlias('diagnoses__library_item_id__library_items__id');

  $$LibraryItemsTableProcessedTableManager get libraryItemId {
    final $_column = $_itemColumn<String>('library_item_id')!;

    final manager = $$LibraryItemsTableTableManager(
      $_db,
      $_db.libraryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<MessageRow>>
  _messagesRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'diagnoses__id__messages__diagnosis_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.diagnosisId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiagnosesTableFilterComposer
    extends Composer<_$NayaDatabase, $DiagnosesTable> {
  $$DiagnosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryItemsTableFilterComposer get libraryItemId {
    final $$LibraryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryItemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableFilterComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.diagnosisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiagnosesTableOrderingComposer
    extends Composer<_$NayaDatabase, $DiagnosesTable> {
  $$DiagnosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryItemsTableOrderingComposer get libraryItemId {
    final $$LibraryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryItemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiagnosesTableAnnotationComposer
    extends Composer<_$NayaDatabase, $DiagnosesTable> {
  $$DiagnosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryItemsTableAnnotationComposer get libraryItemId {
    final $$LibraryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryItemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.diagnosisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiagnosesTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $DiagnosesTable,
          DiagnosisRow,
          $$DiagnosesTableFilterComposer,
          $$DiagnosesTableOrderingComposer,
          $$DiagnosesTableAnnotationComposer,
          $$DiagnosesTableCreateCompanionBuilder,
          $$DiagnosesTableUpdateCompanionBuilder,
          (DiagnosisRow, $$DiagnosesTableReferences),
          DiagnosisRow,
          PrefetchHooks Function({
            bool userId,
            bool libraryItemId,
            bool messagesRefs,
          })
        > {
  $$DiagnosesTableTableManager(_$NayaDatabase db, $DiagnosesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiagnosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiagnosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiagnosesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> libraryItemId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DiagnosesCompanion(
                id: id,
                userId: userId,
                libraryItemId: libraryItemId,
                message: message,
                resultJson: resultJson,
                explanation: explanation,
                model: model,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String libraryItemId,
                required String message,
                required String resultJson,
                Value<String> explanation = const Value.absent(),
                required String model,
                required DateTime createdAt,
              }) => DiagnosesCompanion.insert(
                id: id,
                userId: userId,
                libraryItemId: libraryItemId,
                message: message,
                resultJson: resultJson,
                explanation: explanation,
                model: model,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiagnosesTable, DiagnosisRow>(table),
                  $$DiagnosesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, libraryItemId = false, messagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (messagesRefs) db.messages],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.userId,
                            referencedTable: $$DiagnosesTableReferences
                                ._userIdTable(db),
                            referencedColumn: $$DiagnosesTableReferences
                                ._userIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (libraryItemId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryItemId,
                            referencedTable: $$DiagnosesTableReferences
                                ._libraryItemIdTable(db),
                            referencedColumn: $$DiagnosesTableReferences
                                ._libraryItemIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messagesRefs)
                        await $_getPrefetchedDataByColumns<
                          DiagnosisRow,
                          $DiagnosesTable,
                          MessageRow,
                          $MessagesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DiagnosesTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiagnosesTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'diagnosis_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DiagnosesTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $DiagnosesTable,
      DiagnosisRow,
      $$DiagnosesTableFilterComposer,
      $$DiagnosesTableOrderingComposer,
      $$DiagnosesTableAnnotationComposer,
      $$DiagnosesTableCreateCompanionBuilder,
      $$DiagnosesTableUpdateCompanionBuilder,
      (DiagnosisRow, $$DiagnosesTableReferences),
      DiagnosisRow,
      PrefetchHooks Function({
        bool userId,
        bool libraryItemId,
        bool messagesRefs,
      })
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      required int userId,
      required String libraryItemId,
      Value<String?> partId,
      required String title,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> libraryItemId,
      Value<String?> partId,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ConversationsTableReferences
    extends
        BaseReferences<_$NayaDatabase, $ConversationsTable, ConversationRow> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$NayaDatabase db) =>
      db.users.createAlias('conversations__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LibraryItemsTable _libraryItemIdTable(_$NayaDatabase db) => db
      .libraryItems
      .createAlias('conversations__library_item_id__library_items__id');

  $$LibraryItemsTableProcessedTableManager get libraryItemId {
    final $_column = $_itemColumn<String>('library_item_id')!;

    final manager = $$LibraryItemsTableTableManager(
      $_db,
      $_db.libraryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<MessageRow>>
  _messagesRefsTable(_$NayaDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'conversations__id__messages__conversation_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$NayaDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryItemsTableFilterComposer get libraryItemId {
    final $$LibraryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryItemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableFilterComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$NayaDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryItemsTableOrderingComposer get libraryItemId {
    final $$LibraryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryItemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$NayaDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get partId =>
      $composableBuilder(column: $table.partId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryItemsTableAnnotationComposer get libraryItemId {
    final $$LibraryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryItemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $ConversationsTable,
          ConversationRow,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (ConversationRow, $$ConversationsTableReferences),
          ConversationRow,
          PrefetchHooks Function({
            bool userId,
            bool libraryItemId,
            bool messagesRefs,
          })
        > {
  $$ConversationsTableTableManager(_$NayaDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> libraryItemId = const Value.absent(),
                Value<String?> partId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                userId: userId,
                libraryItemId: libraryItemId,
                partId: partId,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String libraryItemId,
                Value<String?> partId = const Value.absent(),
                required String title,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ConversationsCompanion.insert(
                id: id,
                userId: userId,
                libraryItemId: libraryItemId,
                partId: partId,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConversationsTable, ConversationRow>(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, libraryItemId = false, messagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (messagesRefs) db.messages],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.userId,
                            referencedTable: $$ConversationsTableReferences
                                ._userIdTable(db),
                            referencedColumn: $$ConversationsTableReferences
                                ._userIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (libraryItemId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryItemId,
                            referencedTable: $$ConversationsTableReferences
                                ._libraryItemIdTable(db),
                            referencedColumn: $$ConversationsTableReferences
                                ._libraryItemIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messagesRefs)
                        await $_getPrefetchedDataByColumns<
                          ConversationRow,
                          $ConversationsTable,
                          MessageRow,
                          $MessagesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ConversationsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'conversation_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $ConversationsTable,
      ConversationRow,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (ConversationRow, $$ConversationsTableReferences),
      ConversationRow,
      PrefetchHooks Function({
        bool userId,
        bool libraryItemId,
        bool messagesRefs,
      })
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  required int conversationId,
  required String role,
  required String content,
  Value<String> sourcesJson,
  Value<int?> diagnosisId,
  required DateTime createdAt,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> id,
  Value<int> conversationId,
  Value<String> role,
  Value<String> content,
  Value<String> sourcesJson,
  Value<int?> diagnosisId,
  Value<DateTime> createdAt,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$NayaDatabase, $MessagesTable, MessageRow> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$NayaDatabase db) => db
      .conversations
      .createAlias('messages__conversation_id__conversations__id');

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DiagnosesTable _diagnosisIdTable(_$NayaDatabase db) =>
      db.diagnoses.createAlias('messages__diagnosis_id__diagnoses__id');

  $$DiagnosesTableProcessedTableManager? get diagnosisId {
    final $_column = $_itemColumn<int>('diagnosis_id');
    if ($_column == null) return null;
    final manager = $$DiagnosesTableTableManager(
      $_db,
      $_db.diagnoses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diagnosisIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$NayaDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiagnosesTableFilterComposer get diagnosisId {
    final $$DiagnosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableFilterComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$NayaDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiagnosesTableOrderingComposer get diagnosisId {
    final $$DiagnosesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableOrderingComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$NayaDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get sourcesJson => $composableBuilder(
    column: $table.sourcesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiagnosesTableAnnotationComposer get diagnosisId {
    final $$DiagnosesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnoses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosesTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$NayaDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (MessageRow, $$MessagesTableReferences),
          MessageRow,
          PrefetchHooks Function({bool conversationId, bool diagnosisId})
        > {
  $$MessagesTableTableManager(_$NayaDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> sourcesJson = const Value.absent(),
                Value<int?> diagnosisId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                sourcesJson: sourcesJson,
                diagnosisId: diagnosisId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int conversationId,
                required String role,
                required String content,
                Value<String> sourcesJson = const Value.absent(),
                Value<int?> diagnosisId = const Value.absent(),
                required DateTime createdAt,
              }) => MessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                sourcesJson: sourcesJson,
                diagnosisId: diagnosisId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, MessageRow>(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationId = false, diagnosisId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (conversationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.conversationId,
                            referencedTable: $$MessagesTableReferences
                                ._conversationIdTable(db),
                            referencedColumn: $$MessagesTableReferences
                                ._conversationIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (diagnosisId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.diagnosisId,
                            referencedTable: $$MessagesTableReferences
                                ._diagnosisIdTable(db),
                            referencedColumn: $$MessagesTableReferences
                                ._diagnosisIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$NayaDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, $$MessagesTableReferences),
      MessageRow,
      PrefetchHooks Function({bool conversationId, bool diagnosisId})
    >;

class $NayaDatabaseManager {
  final _$NayaDatabase _db;
  $NayaDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$LibraryItemsTableTableManager get libraryItems =>
      $$LibraryItemsTableTableManager(_db, _db.libraryItems);
  $$AiKeysTableTableManager get aiKeys =>
      $$AiKeysTableTableManager(_db, _db.aiKeys);
  $$AiRolesTableTableManager get aiRoles =>
      $$AiRolesTableTableManager(_db, _db.aiRoles);
  $$DiagnosesTableTableManager get diagnoses =>
      $$DiagnosesTableTableManager(_db, _db.diagnoses);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}
