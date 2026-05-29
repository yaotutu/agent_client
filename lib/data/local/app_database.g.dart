// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedAgentsTable extends CachedAgents
    with TableInfo<$CachedAgentsTable, CachedAgentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAgentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatarUrl,
    status,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_agents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAgentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  CachedAgentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAgentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedAgentsTable createAlias(String alias) {
    return $CachedAgentsTable(attachedDatabase, alias);
  }
}

class CachedAgentRow extends DataClass implements Insertable<CachedAgentRow> {
  final String id;
  final String name;
  final String? avatarUrl;
  final String status;
  final DateTime updatedAt;
  const CachedAgentRow({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedAgentsCompanion toCompanion(bool nullToAbsent) {
    return CachedAgentsCompanion(
      id: Value(id),
      name: Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedAgentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAgentRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedAgentRow copyWith({
    String? id,
    String? name,
    Value<String?> avatarUrl = const Value.absent(),
    String? status,
    DateTime? updatedAt,
  }) => CachedAgentRow(
    id: id ?? this.id,
    name: name ?? this.name,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedAgentRow copyWithCompanion(CachedAgentsCompanion data) {
    return CachedAgentRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAgentRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, avatarUrl, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAgentRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class CachedAgentsCompanion extends UpdateCompanion<CachedAgentRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> avatarUrl;
  final Value<String> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedAgentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAgentsCompanion.insert({
    required String id,
    required String name,
    this.avatarUrl = const Value.absent(),
    required String status,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<CachedAgentRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAgentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? avatarUrl,
    Value<String>? status,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedAgentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    return (StringBuffer('CachedAgentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedConversationsTable extends CachedConversations
    with TableInfo<$CachedConversationsTable, CachedConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [id, agentId, title, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
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
  CachedConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedConversationsTable createAlias(String alias) {
    return $CachedConversationsTable(attachedDatabase, alias);
  }
}

class CachedConversationRow extends DataClass
    implements Insertable<CachedConversationRow> {
  final String id;
  final String agentId;
  final String? title;
  final DateTime updatedAt;
  const CachedConversationRow({
    required this.id,
    required this.agentId,
    this.title,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_id'] = Variable<String>(agentId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedConversationsCompanion toCompanion(bool nullToAbsent) {
    return CachedConversationsCompanion(
      id: Value(id),
      agentId: Value(agentId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedConversationRow(
      id: serializer.fromJson<String>(json['id']),
      agentId: serializer.fromJson<String>(json['agentId']),
      title: serializer.fromJson<String?>(json['title']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentId': serializer.toJson<String>(agentId),
      'title': serializer.toJson<String?>(title),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedConversationRow copyWith({
    String? id,
    String? agentId,
    Value<String?> title = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedConversationRow(
    id: id ?? this.id,
    agentId: agentId ?? this.agentId,
    title: title.present ? title.value : this.title,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedConversationRow copyWithCompanion(CachedConversationsCompanion data) {
    return CachedConversationRow(
      id: data.id.present ? data.id.value : this.id,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      title: data.title.present ? data.title.value : this.title,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedConversationRow(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('title: $title, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, agentId, title, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedConversationRow &&
          other.id == this.id &&
          other.agentId == this.agentId &&
          other.title == this.title &&
          other.updatedAt == this.updatedAt);
}

class CachedConversationsCompanion
    extends UpdateCompanion<CachedConversationRow> {
  final Value<String> id;
  final Value<String> agentId;
  final Value<String?> title;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedConversationsCompanion({
    this.id = const Value.absent(),
    this.agentId = const Value.absent(),
    this.title = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedConversationsCompanion.insert({
    required String id,
    required String agentId,
    this.title = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agentId = Value(agentId),
       updatedAt = Value(updatedAt);
  static Insertable<CachedConversationRow> custom({
    Expression<String>? id,
    Expression<String>? agentId,
    Expression<String>? title,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentId != null) 'agent_id': agentId,
      if (title != null) 'title': title,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? agentId,
    Value<String?>? title,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedConversationsCompanion(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      title: title ?? this.title,
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
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
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
    return (StringBuffer('CachedConversationsCompanion(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('title: $title, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMessagesTable extends CachedMessages
    with TableInfo<$CachedMessagesTable, CachedMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentIdMeta = const VerificationMeta(
    'agentId',
  );
  @override
  late final GeneratedColumn<String> agentId = GeneratedColumn<String>(
    'agent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
    agentId,
    conversationId,
    role,
    content,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_id')) {
      context.handle(
        _agentIdMeta,
        agentId.isAcceptableOrUnknown(data['agent_id']!, _agentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_agentIdMeta);
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  CachedMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      agentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedMessagesTable createAlias(String alias) {
    return $CachedMessagesTable(attachedDatabase, alias);
  }
}

class CachedMessageRow extends DataClass
    implements Insertable<CachedMessageRow> {
  final String id;
  final String agentId;
  final String conversationId;
  final String role;
  final String content;
  final String status;
  final DateTime createdAt;
  const CachedMessageRow({
    required this.id,
    required this.agentId,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_id'] = Variable<String>(agentId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesCompanion(
      id: Value(id),
      agentId: Value(agentId),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory CachedMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessageRow(
      id: serializer.fromJson<String>(json['id']),
      agentId: serializer.fromJson<String>(json['agentId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentId': serializer.toJson<String>(agentId),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CachedMessageRow copyWith({
    String? id,
    String? agentId,
    String? conversationId,
    String? role,
    String? content,
    String? status,
    DateTime? createdAt,
  }) => CachedMessageRow(
    id: id ?? this.id,
    agentId: agentId ?? this.agentId,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedMessageRow copyWithCompanion(CachedMessagesCompanion data) {
    return CachedMessageRow(
      id: data.id.present ? data.id.value : this.id,
      agentId: data.agentId.present ? data.agentId.value : this.agentId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessageRow(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    conversationId,
    role,
    content,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessageRow &&
          other.id == this.id &&
          other.agentId == this.agentId &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class CachedMessagesCompanion extends UpdateCompanion<CachedMessageRow> {
  final Value<String> id;
  final Value<String> agentId;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CachedMessagesCompanion({
    this.id = const Value.absent(),
    this.agentId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMessagesCompanion.insert({
    required String id,
    required String agentId,
    required String conversationId,
    required String role,
    required String content,
    required String status,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       agentId = Value(agentId),
       conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<CachedMessageRow> custom({
    Expression<String>? id,
    Expression<String>? agentId,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentId != null) 'agent_id': agentId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? agentId,
    Value<String>? conversationId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedMessagesCompanion(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentId.present) {
      map['agent_id'] = Variable<String>(agentId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('agentId: $agentId, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedAgentsTable cachedAgents = $CachedAgentsTable(this);
  late final $CachedConversationsTable cachedConversations =
      $CachedConversationsTable(this);
  late final $CachedMessagesTable cachedMessages = $CachedMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedAgents,
    cachedConversations,
    cachedMessages,
  ];
}

typedef $$CachedAgentsTableCreateCompanionBuilder =
    CachedAgentsCompanion Function({
      required String id,
      required String name,
      Value<String?> avatarUrl,
      required String status,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedAgentsTableUpdateCompanionBuilder =
    CachedAgentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> avatarUrl,
      Value<String> status,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedAgentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAgentsTable> {
  $$CachedAgentsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAgentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAgentsTable> {
  $$CachedAgentsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAgentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAgentsTable> {
  $$CachedAgentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedAgentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAgentsTable,
          CachedAgentRow,
          $$CachedAgentsTableFilterComposer,
          $$CachedAgentsTableOrderingComposer,
          $$CachedAgentsTableAnnotationComposer,
          $$CachedAgentsTableCreateCompanionBuilder,
          $$CachedAgentsTableUpdateCompanionBuilder,
          (
            CachedAgentRow,
            BaseReferences<_$AppDatabase, $CachedAgentsTable, CachedAgentRow>,
          ),
          CachedAgentRow,
          PrefetchHooks Function()
        > {
  $$CachedAgentsTableTableManager(_$AppDatabase db, $CachedAgentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAgentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAgentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAgentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAgentsCompanion(
                id: id,
                name: name,
                avatarUrl: avatarUrl,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> avatarUrl = const Value.absent(),
                required String status,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAgentsCompanion.insert(
                id: id,
                name: name,
                avatarUrl: avatarUrl,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAgentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAgentsTable,
      CachedAgentRow,
      $$CachedAgentsTableFilterComposer,
      $$CachedAgentsTableOrderingComposer,
      $$CachedAgentsTableAnnotationComposer,
      $$CachedAgentsTableCreateCompanionBuilder,
      $$CachedAgentsTableUpdateCompanionBuilder,
      (
        CachedAgentRow,
        BaseReferences<_$AppDatabase, $CachedAgentsTable, CachedAgentRow>,
      ),
      CachedAgentRow,
      PrefetchHooks Function()
    >;
typedef $$CachedConversationsTableCreateCompanionBuilder =
    CachedConversationsCompanion Function({
      required String id,
      required String agentId,
      Value<String?> title,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedConversationsTableUpdateCompanionBuilder =
    CachedConversationsCompanion Function({
      Value<String> id,
      Value<String> agentId,
      Value<String?> title,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedConversationsTable> {
  $$CachedConversationsTableFilterComposer({
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

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedConversationsTable> {
  $$CachedConversationsTableOrderingComposer({
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

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedConversationsTable> {
  $$CachedConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedConversationsTable,
          CachedConversationRow,
          $$CachedConversationsTableFilterComposer,
          $$CachedConversationsTableOrderingComposer,
          $$CachedConversationsTableAnnotationComposer,
          $$CachedConversationsTableCreateCompanionBuilder,
          $$CachedConversationsTableUpdateCompanionBuilder,
          (
            CachedConversationRow,
            BaseReferences<
              _$AppDatabase,
              $CachedConversationsTable,
              CachedConversationRow
            >,
          ),
          CachedConversationRow,
          PrefetchHooks Function()
        > {
  $$CachedConversationsTableTableManager(
    _$AppDatabase db,
    $CachedConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedConversationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedConversationsCompanion(
                id: id,
                agentId: agentId,
                title: title,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agentId,
                Value<String?> title = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedConversationsCompanion.insert(
                id: id,
                agentId: agentId,
                title: title,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedConversationsTable,
      CachedConversationRow,
      $$CachedConversationsTableFilterComposer,
      $$CachedConversationsTableOrderingComposer,
      $$CachedConversationsTableAnnotationComposer,
      $$CachedConversationsTableCreateCompanionBuilder,
      $$CachedConversationsTableUpdateCompanionBuilder,
      (
        CachedConversationRow,
        BaseReferences<
          _$AppDatabase,
          $CachedConversationsTable,
          CachedConversationRow
        >,
      ),
      CachedConversationRow,
      PrefetchHooks Function()
    >;
typedef $$CachedMessagesTableCreateCompanionBuilder =
    CachedMessagesCompanion Function({
      required String id,
      required String agentId,
      required String conversationId,
      required String role,
      required String content,
      required String status,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CachedMessagesTableUpdateCompanionBuilder =
    CachedMessagesCompanion Function({
      Value<String> id,
      Value<String> agentId,
      Value<String> conversationId,
      Value<String> role,
      Value<String> content,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CachedMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableFilterComposer({
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

  ColumnFilters<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get agentId => $composableBuilder(
    column: $table.agentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentId =>
      $composableBuilder(column: $table.agentId, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMessagesTable,
          CachedMessageRow,
          $$CachedMessagesTableFilterComposer,
          $$CachedMessagesTableOrderingComposer,
          $$CachedMessagesTableAnnotationComposer,
          $$CachedMessagesTableCreateCompanionBuilder,
          $$CachedMessagesTableUpdateCompanionBuilder,
          (
            CachedMessageRow,
            BaseReferences<
              _$AppDatabase,
              $CachedMessagesTable,
              CachedMessageRow
            >,
          ),
          CachedMessageRow,
          PrefetchHooks Function()
        > {
  $$CachedMessagesTableTableManager(
    _$AppDatabase db,
    $CachedMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> agentId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMessagesCompanion(
                id: id,
                agentId: agentId,
                conversationId: conversationId,
                role: role,
                content: content,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String agentId,
                required String conversationId,
                required String role,
                required String content,
                required String status,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMessagesCompanion.insert(
                id: id,
                agentId: agentId,
                conversationId: conversationId,
                role: role,
                content: content,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMessagesTable,
      CachedMessageRow,
      $$CachedMessagesTableFilterComposer,
      $$CachedMessagesTableOrderingComposer,
      $$CachedMessagesTableAnnotationComposer,
      $$CachedMessagesTableCreateCompanionBuilder,
      $$CachedMessagesTableUpdateCompanionBuilder,
      (
        CachedMessageRow,
        BaseReferences<_$AppDatabase, $CachedMessagesTable, CachedMessageRow>,
      ),
      CachedMessageRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedAgentsTableTableManager get cachedAgents =>
      $$CachedAgentsTableTableManager(_db, _db.cachedAgents);
  $$CachedConversationsTableTableManager get cachedConversations =>
      $$CachedConversationsTableTableManager(_db, _db.cachedConversations);
  $$CachedMessagesTableTableManager get cachedMessages =>
      $$CachedMessagesTableTableManager(_db, _db.cachedMessages);
}
