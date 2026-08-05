// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    name,
    description,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
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
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class Deck extends DataClass implements Insertable<Deck> {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Deck({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Deck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Deck copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deck &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DecksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Deck> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DecksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<int> deckId = GeneratedColumn<int>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _germanMeta = const VerificationMeta('german');
  @override
  late final GeneratedColumn<String> german = GeneratedColumn<String>(
    'german',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleMeta = const VerificationMeta(
    'article',
  );
  @override
  late final GeneratedColumn<String> article = GeneratedColumn<String>(
    'article',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseFormMeta = const VerificationMeta(
    'baseForm',
  );
  @override
  late final GeneratedColumn<String> baseForm = GeneratedColumn<String>(
    'base_form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordTypeMeta = const VerificationMeta(
    'wordType',
  );
  @override
  late final GeneratedColumn<String> wordType = GeneratedColumn<String>(
    'word_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chineseMeta = const VerificationMeta(
    'chinese',
  );
  @override
  late final GeneratedColumn<String> chinese = GeneratedColumn<String>(
    'chinese',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 1000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proficiencyMeta = const VerificationMeta(
    'proficiency',
  );
  @override
  late final GeneratedColumn<int> proficiency = GeneratedColumn<int>(
    'proficiency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastStudyDateMeta = const VerificationMeta(
    'lastStudyDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastStudyDate =
      GeneratedColumn<DateTime>(
        'last_study_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verbPresentMeta = const VerificationMeta(
    'verbPresent',
  );
  @override
  late final GeneratedColumn<String> verbPresent = GeneratedColumn<String>(
    'verb_present',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verbPastMeta = const VerificationMeta(
    'verbPast',
  );
  @override
  late final GeneratedColumn<String> verbPast = GeneratedColumn<String>(
    'verb_past',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verbPerfectMeta = const VerificationMeta(
    'verbPerfect',
  );
  @override
  late final GeneratedColumn<String> verbPerfect = GeneratedColumn<String>(
    'verb_perfect',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nounGenitiveMeta = const VerificationMeta(
    'nounGenitive',
  );
  @override
  late final GeneratedColumn<String> nounGenitive = GeneratedColumn<String>(
    'noun_genitive',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nounPluralMeta = const VerificationMeta(
    'nounPlural',
  );
  @override
  late final GeneratedColumn<String> nounPlural = GeneratedColumn<String>(
    'noun_plural',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nounTypeMeta = const VerificationMeta(
    'nounType',
  );
  @override
  late final GeneratedColumn<String> nounType = GeneratedColumn<String>(
    'noun_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjComparativeMeta = const VerificationMeta(
    'adjComparative',
  );
  @override
  late final GeneratedColumn<String> adjComparative = GeneratedColumn<String>(
    'adj_comparative',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adjSuperlativeMeta = const VerificationMeta(
    'adjSuperlative',
  );
  @override
  late final GeneratedColumn<String> adjSuperlative = GeneratedColumn<String>(
    'adj_superlative',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    deckId,
    german,
    article,
    baseForm,
    wordType,
    chinese,
    example,
    tags,
    proficiency,
    isFavorite,
    lastStudyDate,
    verbPresent,
    verbPast,
    verbPerfect,
    nounGenitive,
    nounPlural,
    nounType,
    adjComparative,
    adjSuperlative,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('german')) {
      context.handle(
        _germanMeta,
        german.isAcceptableOrUnknown(data['german']!, _germanMeta),
      );
    } else if (isInserting) {
      context.missing(_germanMeta);
    }
    if (data.containsKey('article')) {
      context.handle(
        _articleMeta,
        article.isAcceptableOrUnknown(data['article']!, _articleMeta),
      );
    }
    if (data.containsKey('base_form')) {
      context.handle(
        _baseFormMeta,
        baseForm.isAcceptableOrUnknown(data['base_form']!, _baseFormMeta),
      );
    }
    if (data.containsKey('word_type')) {
      context.handle(
        _wordTypeMeta,
        wordType.isAcceptableOrUnknown(data['word_type']!, _wordTypeMeta),
      );
    }
    if (data.containsKey('chinese')) {
      context.handle(
        _chineseMeta,
        chinese.isAcceptableOrUnknown(data['chinese']!, _chineseMeta),
      );
    } else if (isInserting) {
      context.missing(_chineseMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('proficiency')) {
      context.handle(
        _proficiencyMeta,
        proficiency.isAcceptableOrUnknown(
          data['proficiency']!,
          _proficiencyMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('last_study_date')) {
      context.handle(
        _lastStudyDateMeta,
        lastStudyDate.isAcceptableOrUnknown(
          data['last_study_date']!,
          _lastStudyDateMeta,
        ),
      );
    }
    if (data.containsKey('verb_present')) {
      context.handle(
        _verbPresentMeta,
        verbPresent.isAcceptableOrUnknown(
          data['verb_present']!,
          _verbPresentMeta,
        ),
      );
    }
    if (data.containsKey('verb_past')) {
      context.handle(
        _verbPastMeta,
        verbPast.isAcceptableOrUnknown(data['verb_past']!, _verbPastMeta),
      );
    }
    if (data.containsKey('verb_perfect')) {
      context.handle(
        _verbPerfectMeta,
        verbPerfect.isAcceptableOrUnknown(
          data['verb_perfect']!,
          _verbPerfectMeta,
        ),
      );
    }
    if (data.containsKey('noun_genitive')) {
      context.handle(
        _nounGenitiveMeta,
        nounGenitive.isAcceptableOrUnknown(
          data['noun_genitive']!,
          _nounGenitiveMeta,
        ),
      );
    }
    if (data.containsKey('noun_plural')) {
      context.handle(
        _nounPluralMeta,
        nounPlural.isAcceptableOrUnknown(data['noun_plural']!, _nounPluralMeta),
      );
    }
    if (data.containsKey('noun_type')) {
      context.handle(
        _nounTypeMeta,
        nounType.isAcceptableOrUnknown(data['noun_type']!, _nounTypeMeta),
      );
    }
    if (data.containsKey('adj_comparative')) {
      context.handle(
        _adjComparativeMeta,
        adjComparative.isAcceptableOrUnknown(
          data['adj_comparative']!,
          _adjComparativeMeta,
        ),
      );
    }
    if (data.containsKey('adj_superlative')) {
      context.handle(
        _adjSuperlativeMeta,
        adjSuperlative.isAcceptableOrUnknown(
          data['adj_superlative']!,
          _adjSuperlativeMeta,
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
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_id'],
      )!,
      german: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}german'],
      )!,
      article: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article'],
      ),
      baseForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_form'],
      ),
      wordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_type'],
      ),
      chinese: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chinese'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      proficiency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}proficiency'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lastStudyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_study_date'],
      ),
      verbPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verb_present'],
      ),
      verbPast: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verb_past'],
      ),
      verbPerfect: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verb_perfect'],
      ),
      nounGenitive: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}noun_genitive'],
      ),
      nounPlural: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}noun_plural'],
      ),
      nounType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}noun_type'],
      ),
      adjComparative: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adj_comparative'],
      ),
      adjSuperlative: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adj_superlative'],
      ),
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
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final int deckId;
  final String german;
  final String? article;
  final String? baseForm;
  final String? wordType;
  final String chinese;
  final String? example;
  final String? tags;
  final int proficiency;
  final bool isFavorite;
  final DateTime? lastStudyDate;
  final String? verbPresent;
  final String? verbPast;
  final String? verbPerfect;
  final String? nounGenitive;
  final String? nounPlural;
  final String? nounType;
  final String? adjComparative;
  final String? adjSuperlative;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Word({
    required this.id,
    required this.deckId,
    required this.german,
    this.article,
    this.baseForm,
    this.wordType,
    required this.chinese,
    this.example,
    this.tags,
    required this.proficiency,
    required this.isFavorite,
    this.lastStudyDate,
    this.verbPresent,
    this.verbPast,
    this.verbPerfect,
    this.nounGenitive,
    this.nounPlural,
    this.nounType,
    this.adjComparative,
    this.adjSuperlative,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deck_id'] = Variable<int>(deckId);
    map['german'] = Variable<String>(german);
    if (!nullToAbsent || article != null) {
      map['article'] = Variable<String>(article);
    }
    if (!nullToAbsent || baseForm != null) {
      map['base_form'] = Variable<String>(baseForm);
    }
    if (!nullToAbsent || wordType != null) {
      map['word_type'] = Variable<String>(wordType);
    }
    map['chinese'] = Variable<String>(chinese);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['proficiency'] = Variable<int>(proficiency);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lastStudyDate != null) {
      map['last_study_date'] = Variable<DateTime>(lastStudyDate);
    }
    if (!nullToAbsent || verbPresent != null) {
      map['verb_present'] = Variable<String>(verbPresent);
    }
    if (!nullToAbsent || verbPast != null) {
      map['verb_past'] = Variable<String>(verbPast);
    }
    if (!nullToAbsent || verbPerfect != null) {
      map['verb_perfect'] = Variable<String>(verbPerfect);
    }
    if (!nullToAbsent || nounGenitive != null) {
      map['noun_genitive'] = Variable<String>(nounGenitive);
    }
    if (!nullToAbsent || nounPlural != null) {
      map['noun_plural'] = Variable<String>(nounPlural);
    }
    if (!nullToAbsent || nounType != null) {
      map['noun_type'] = Variable<String>(nounType);
    }
    if (!nullToAbsent || adjComparative != null) {
      map['adj_comparative'] = Variable<String>(adjComparative);
    }
    if (!nullToAbsent || adjSuperlative != null) {
      map['adj_superlative'] = Variable<String>(adjSuperlative);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      german: Value(german),
      article: article == null && nullToAbsent
          ? const Value.absent()
          : Value(article),
      baseForm: baseForm == null && nullToAbsent
          ? const Value.absent()
          : Value(baseForm),
      wordType: wordType == null && nullToAbsent
          ? const Value.absent()
          : Value(wordType),
      chinese: Value(chinese),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      proficiency: Value(proficiency),
      isFavorite: Value(isFavorite),
      lastStudyDate: lastStudyDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStudyDate),
      verbPresent: verbPresent == null && nullToAbsent
          ? const Value.absent()
          : Value(verbPresent),
      verbPast: verbPast == null && nullToAbsent
          ? const Value.absent()
          : Value(verbPast),
      verbPerfect: verbPerfect == null && nullToAbsent
          ? const Value.absent()
          : Value(verbPerfect),
      nounGenitive: nounGenitive == null && nullToAbsent
          ? const Value.absent()
          : Value(nounGenitive),
      nounPlural: nounPlural == null && nullToAbsent
          ? const Value.absent()
          : Value(nounPlural),
      nounType: nounType == null && nullToAbsent
          ? const Value.absent()
          : Value(nounType),
      adjComparative: adjComparative == null && nullToAbsent
          ? const Value.absent()
          : Value(adjComparative),
      adjSuperlative: adjSuperlative == null && nullToAbsent
          ? const Value.absent()
          : Value(adjSuperlative),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      deckId: serializer.fromJson<int>(json['deckId']),
      german: serializer.fromJson<String>(json['german']),
      article: serializer.fromJson<String?>(json['article']),
      baseForm: serializer.fromJson<String?>(json['baseForm']),
      wordType: serializer.fromJson<String?>(json['wordType']),
      chinese: serializer.fromJson<String>(json['chinese']),
      example: serializer.fromJson<String?>(json['example']),
      tags: serializer.fromJson<String?>(json['tags']),
      proficiency: serializer.fromJson<int>(json['proficiency']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastStudyDate: serializer.fromJson<DateTime?>(json['lastStudyDate']),
      verbPresent: serializer.fromJson<String?>(json['verbPresent']),
      verbPast: serializer.fromJson<String?>(json['verbPast']),
      verbPerfect: serializer.fromJson<String?>(json['verbPerfect']),
      nounGenitive: serializer.fromJson<String?>(json['nounGenitive']),
      nounPlural: serializer.fromJson<String?>(json['nounPlural']),
      nounType: serializer.fromJson<String?>(json['nounType']),
      adjComparative: serializer.fromJson<String?>(json['adjComparative']),
      adjSuperlative: serializer.fromJson<String?>(json['adjSuperlative']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckId': serializer.toJson<int>(deckId),
      'german': serializer.toJson<String>(german),
      'article': serializer.toJson<String?>(article),
      'baseForm': serializer.toJson<String?>(baseForm),
      'wordType': serializer.toJson<String?>(wordType),
      'chinese': serializer.toJson<String>(chinese),
      'example': serializer.toJson<String?>(example),
      'tags': serializer.toJson<String?>(tags),
      'proficiency': serializer.toJson<int>(proficiency),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastStudyDate': serializer.toJson<DateTime?>(lastStudyDate),
      'verbPresent': serializer.toJson<String?>(verbPresent),
      'verbPast': serializer.toJson<String?>(verbPast),
      'verbPerfect': serializer.toJson<String?>(verbPerfect),
      'nounGenitive': serializer.toJson<String?>(nounGenitive),
      'nounPlural': serializer.toJson<String?>(nounPlural),
      'nounType': serializer.toJson<String?>(nounType),
      'adjComparative': serializer.toJson<String?>(adjComparative),
      'adjSuperlative': serializer.toJson<String?>(adjSuperlative),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Word copyWith({
    int? id,
    int? deckId,
    String? german,
    Value<String?> article = const Value.absent(),
    Value<String?> baseForm = const Value.absent(),
    Value<String?> wordType = const Value.absent(),
    String? chinese,
    Value<String?> example = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    int? proficiency,
    bool? isFavorite,
    Value<DateTime?> lastStudyDate = const Value.absent(),
    Value<String?> verbPresent = const Value.absent(),
    Value<String?> verbPast = const Value.absent(),
    Value<String?> verbPerfect = const Value.absent(),
    Value<String?> nounGenitive = const Value.absent(),
    Value<String?> nounPlural = const Value.absent(),
    Value<String?> nounType = const Value.absent(),
    Value<String?> adjComparative = const Value.absent(),
    Value<String?> adjSuperlative = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Word(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    german: german ?? this.german,
    article: article.present ? article.value : this.article,
    baseForm: baseForm.present ? baseForm.value : this.baseForm,
    wordType: wordType.present ? wordType.value : this.wordType,
    chinese: chinese ?? this.chinese,
    example: example.present ? example.value : this.example,
    tags: tags.present ? tags.value : this.tags,
    proficiency: proficiency ?? this.proficiency,
    isFavorite: isFavorite ?? this.isFavorite,
    lastStudyDate: lastStudyDate.present
        ? lastStudyDate.value
        : this.lastStudyDate,
    verbPresent: verbPresent.present ? verbPresent.value : this.verbPresent,
    verbPast: verbPast.present ? verbPast.value : this.verbPast,
    verbPerfect: verbPerfect.present ? verbPerfect.value : this.verbPerfect,
    nounGenitive: nounGenitive.present ? nounGenitive.value : this.nounGenitive,
    nounPlural: nounPlural.present ? nounPlural.value : this.nounPlural,
    nounType: nounType.present ? nounType.value : this.nounType,
    adjComparative: adjComparative.present
        ? adjComparative.value
        : this.adjComparative,
    adjSuperlative: adjSuperlative.present
        ? adjSuperlative.value
        : this.adjSuperlative,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      german: data.german.present ? data.german.value : this.german,
      article: data.article.present ? data.article.value : this.article,
      baseForm: data.baseForm.present ? data.baseForm.value : this.baseForm,
      wordType: data.wordType.present ? data.wordType.value : this.wordType,
      chinese: data.chinese.present ? data.chinese.value : this.chinese,
      example: data.example.present ? data.example.value : this.example,
      tags: data.tags.present ? data.tags.value : this.tags,
      proficiency: data.proficiency.present
          ? data.proficiency.value
          : this.proficiency,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lastStudyDate: data.lastStudyDate.present
          ? data.lastStudyDate.value
          : this.lastStudyDate,
      verbPresent: data.verbPresent.present
          ? data.verbPresent.value
          : this.verbPresent,
      verbPast: data.verbPast.present ? data.verbPast.value : this.verbPast,
      verbPerfect: data.verbPerfect.present
          ? data.verbPerfect.value
          : this.verbPerfect,
      nounGenitive: data.nounGenitive.present
          ? data.nounGenitive.value
          : this.nounGenitive,
      nounPlural: data.nounPlural.present
          ? data.nounPlural.value
          : this.nounPlural,
      nounType: data.nounType.present ? data.nounType.value : this.nounType,
      adjComparative: data.adjComparative.present
          ? data.adjComparative.value
          : this.adjComparative,
      adjSuperlative: data.adjSuperlative.present
          ? data.adjSuperlative.value
          : this.adjSuperlative,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('german: $german, ')
          ..write('article: $article, ')
          ..write('baseForm: $baseForm, ')
          ..write('wordType: $wordType, ')
          ..write('chinese: $chinese, ')
          ..write('example: $example, ')
          ..write('tags: $tags, ')
          ..write('proficiency: $proficiency, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastStudyDate: $lastStudyDate, ')
          ..write('verbPresent: $verbPresent, ')
          ..write('verbPast: $verbPast, ')
          ..write('verbPerfect: $verbPerfect, ')
          ..write('nounGenitive: $nounGenitive, ')
          ..write('nounPlural: $nounPlural, ')
          ..write('nounType: $nounType, ')
          ..write('adjComparative: $adjComparative, ')
          ..write('adjSuperlative: $adjSuperlative, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    deckId,
    german,
    article,
    baseForm,
    wordType,
    chinese,
    example,
    tags,
    proficiency,
    isFavorite,
    lastStudyDate,
    verbPresent,
    verbPast,
    verbPerfect,
    nounGenitive,
    nounPlural,
    nounType,
    adjComparative,
    adjSuperlative,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.german == this.german &&
          other.article == this.article &&
          other.baseForm == this.baseForm &&
          other.wordType == this.wordType &&
          other.chinese == this.chinese &&
          other.example == this.example &&
          other.tags == this.tags &&
          other.proficiency == this.proficiency &&
          other.isFavorite == this.isFavorite &&
          other.lastStudyDate == this.lastStudyDate &&
          other.verbPresent == this.verbPresent &&
          other.verbPast == this.verbPast &&
          other.verbPerfect == this.verbPerfect &&
          other.nounGenitive == this.nounGenitive &&
          other.nounPlural == this.nounPlural &&
          other.nounType == this.nounType &&
          other.adjComparative == this.adjComparative &&
          other.adjSuperlative == this.adjSuperlative &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<int> deckId;
  final Value<String> german;
  final Value<String?> article;
  final Value<String?> baseForm;
  final Value<String?> wordType;
  final Value<String> chinese;
  final Value<String?> example;
  final Value<String?> tags;
  final Value<int> proficiency;
  final Value<bool> isFavorite;
  final Value<DateTime?> lastStudyDate;
  final Value<String?> verbPresent;
  final Value<String?> verbPast;
  final Value<String?> verbPerfect;
  final Value<String?> nounGenitive;
  final Value<String?> nounPlural;
  final Value<String?> nounType;
  final Value<String?> adjComparative;
  final Value<String?> adjSuperlative;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.german = const Value.absent(),
    this.article = const Value.absent(),
    this.baseForm = const Value.absent(),
    this.wordType = const Value.absent(),
    this.chinese = const Value.absent(),
    this.example = const Value.absent(),
    this.tags = const Value.absent(),
    this.proficiency = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastStudyDate = const Value.absent(),
    this.verbPresent = const Value.absent(),
    this.verbPast = const Value.absent(),
    this.verbPerfect = const Value.absent(),
    this.nounGenitive = const Value.absent(),
    this.nounPlural = const Value.absent(),
    this.nounType = const Value.absent(),
    this.adjComparative = const Value.absent(),
    this.adjSuperlative = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required int deckId,
    required String german,
    this.article = const Value.absent(),
    this.baseForm = const Value.absent(),
    this.wordType = const Value.absent(),
    required String chinese,
    this.example = const Value.absent(),
    this.tags = const Value.absent(),
    this.proficiency = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastStudyDate = const Value.absent(),
    this.verbPresent = const Value.absent(),
    this.verbPast = const Value.absent(),
    this.verbPerfect = const Value.absent(),
    this.nounGenitive = const Value.absent(),
    this.nounPlural = const Value.absent(),
    this.nounType = const Value.absent(),
    this.adjComparative = const Value.absent(),
    this.adjSuperlative = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : deckId = Value(deckId),
       german = Value(german),
       chinese = Value(chinese),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<int>? deckId,
    Expression<String>? german,
    Expression<String>? article,
    Expression<String>? baseForm,
    Expression<String>? wordType,
    Expression<String>? chinese,
    Expression<String>? example,
    Expression<String>? tags,
    Expression<int>? proficiency,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastStudyDate,
    Expression<String>? verbPresent,
    Expression<String>? verbPast,
    Expression<String>? verbPerfect,
    Expression<String>? nounGenitive,
    Expression<String>? nounPlural,
    Expression<String>? nounType,
    Expression<String>? adjComparative,
    Expression<String>? adjSuperlative,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (german != null) 'german': german,
      if (article != null) 'article': article,
      if (baseForm != null) 'base_form': baseForm,
      if (wordType != null) 'word_type': wordType,
      if (chinese != null) 'chinese': chinese,
      if (example != null) 'example': example,
      if (tags != null) 'tags': tags,
      if (proficiency != null) 'proficiency': proficiency,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastStudyDate != null) 'last_study_date': lastStudyDate,
      if (verbPresent != null) 'verb_present': verbPresent,
      if (verbPast != null) 'verb_past': verbPast,
      if (verbPerfect != null) 'verb_perfect': verbPerfect,
      if (nounGenitive != null) 'noun_genitive': nounGenitive,
      if (nounPlural != null) 'noun_plural': nounPlural,
      if (nounType != null) 'noun_type': nounType,
      if (adjComparative != null) 'adj_comparative': adjComparative,
      if (adjSuperlative != null) 'adj_superlative': adjSuperlative,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<int>? deckId,
    Value<String>? german,
    Value<String?>? article,
    Value<String?>? baseForm,
    Value<String?>? wordType,
    Value<String>? chinese,
    Value<String?>? example,
    Value<String?>? tags,
    Value<int>? proficiency,
    Value<bool>? isFavorite,
    Value<DateTime?>? lastStudyDate,
    Value<String?>? verbPresent,
    Value<String?>? verbPast,
    Value<String?>? verbPerfect,
    Value<String?>? nounGenitive,
    Value<String?>? nounPlural,
    Value<String?>? nounType,
    Value<String?>? adjComparative,
    Value<String?>? adjSuperlative,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      german: german ?? this.german,
      article: article ?? this.article,
      baseForm: baseForm ?? this.baseForm,
      wordType: wordType ?? this.wordType,
      chinese: chinese ?? this.chinese,
      example: example ?? this.example,
      tags: tags ?? this.tags,
      proficiency: proficiency ?? this.proficiency,
      isFavorite: isFavorite ?? this.isFavorite,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      verbPresent: verbPresent ?? this.verbPresent,
      verbPast: verbPast ?? this.verbPast,
      verbPerfect: verbPerfect ?? this.verbPerfect,
      nounGenitive: nounGenitive ?? this.nounGenitive,
      nounPlural: nounPlural ?? this.nounPlural,
      nounType: nounType ?? this.nounType,
      adjComparative: adjComparative ?? this.adjComparative,
      adjSuperlative: adjSuperlative ?? this.adjSuperlative,
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
    if (deckId.present) {
      map['deck_id'] = Variable<int>(deckId.value);
    }
    if (german.present) {
      map['german'] = Variable<String>(german.value);
    }
    if (article.present) {
      map['article'] = Variable<String>(article.value);
    }
    if (baseForm.present) {
      map['base_form'] = Variable<String>(baseForm.value);
    }
    if (wordType.present) {
      map['word_type'] = Variable<String>(wordType.value);
    }
    if (chinese.present) {
      map['chinese'] = Variable<String>(chinese.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (proficiency.present) {
      map['proficiency'] = Variable<int>(proficiency.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastStudyDate.present) {
      map['last_study_date'] = Variable<DateTime>(lastStudyDate.value);
    }
    if (verbPresent.present) {
      map['verb_present'] = Variable<String>(verbPresent.value);
    }
    if (verbPast.present) {
      map['verb_past'] = Variable<String>(verbPast.value);
    }
    if (verbPerfect.present) {
      map['verb_perfect'] = Variable<String>(verbPerfect.value);
    }
    if (nounGenitive.present) {
      map['noun_genitive'] = Variable<String>(nounGenitive.value);
    }
    if (nounPlural.present) {
      map['noun_plural'] = Variable<String>(nounPlural.value);
    }
    if (nounType.present) {
      map['noun_type'] = Variable<String>(nounType.value);
    }
    if (adjComparative.present) {
      map['adj_comparative'] = Variable<String>(adjComparative.value);
    }
    if (adjSuperlative.present) {
      map['adj_superlative'] = Variable<String>(adjSuperlative.value);
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
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('german: $german, ')
          ..write('article: $article, ')
          ..write('baseForm: $baseForm, ')
          ..write('wordType: $wordType, ')
          ..write('chinese: $chinese, ')
          ..write('example: $example, ')
          ..write('tags: $tags, ')
          ..write('proficiency: $proficiency, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastStudyDate: $lastStudyDate, ')
          ..write('verbPresent: $verbPresent, ')
          ..write('verbPast: $verbPast, ')
          ..write('verbPerfect: $verbPerfect, ')
          ..write('nounGenitive: $nounGenitive, ')
          ..write('nounPlural: $nounPlural, ')
          ..write('nounType: $nounType, ')
          ..write('adjComparative: $adjComparative, ')
          ..write('adjSuperlative: $adjSuperlative, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $Sm2StatesTable extends Sm2States
    with TableInfo<$Sm2StatesTable, Sm2State> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $Sm2StatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repetitionNMeta = const VerificationMeta(
    'repetitionN',
  );
  @override
  late final GeneratedColumn<int> repetitionN = GeneratedColumn<int>(
    'repetition_n',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<double> intervalDays = GeneratedColumn<double>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _nextReviewMeta = const VerificationMeta(
    'nextReview',
  );
  @override
  late final GeneratedColumn<DateTime> nextReview = GeneratedColumn<DateTime>(
    'next_review',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalReviewsMeta = const VerificationMeta(
    'totalReviews',
  );
  @override
  late final GeneratedColumn<int> totalReviews = GeneratedColumn<int>(
    'total_reviews',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctStreakMeta = const VerificationMeta(
    'correctStreak',
  );
  @override
  late final GeneratedColumn<int> correctStreak = GeneratedColumn<int>(
    'correct_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    wordId,
    repetitionN,
    intervalDays,
    easeFactor,
    nextReview,
    lastReview,
    totalReviews,
    correctStreak,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sm2_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sm2State> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('repetition_n')) {
      context.handle(
        _repetitionNMeta,
        repetitionN.isAcceptableOrUnknown(
          data['repetition_n']!,
          _repetitionNMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('next_review')) {
      context.handle(
        _nextReviewMeta,
        nextReview.isAcceptableOrUnknown(data['next_review']!, _nextReviewMeta),
      );
    } else if (isInserting) {
      context.missing(_nextReviewMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('total_reviews')) {
      context.handle(
        _totalReviewsMeta,
        totalReviews.isAcceptableOrUnknown(
          data['total_reviews']!,
          _totalReviewsMeta,
        ),
      );
    }
    if (data.containsKey('correct_streak')) {
      context.handle(
        _correctStreakMeta,
        correctStreak.isAcceptableOrUnknown(
          data['correct_streak']!,
          _correctStreakMeta,
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {wordId},
  ];
  @override
  Sm2State map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sm2State(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      repetitionN: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetition_n'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval_days'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      nextReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
      totalReviews: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_reviews'],
      )!,
      correctStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_streak'],
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
  $Sm2StatesTable createAlias(String alias) {
    return $Sm2StatesTable(attachedDatabase, alias);
  }
}

class Sm2State extends DataClass implements Insertable<Sm2State> {
  final int id;
  final int wordId;
  final int repetitionN;
  final double intervalDays;
  final double easeFactor;
  final DateTime nextReview;
  final DateTime? lastReview;
  final int totalReviews;
  final int correctStreak;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Sm2State({
    required this.id,
    required this.wordId,
    required this.repetitionN,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReview,
    this.lastReview,
    required this.totalReviews,
    required this.correctStreak,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['repetition_n'] = Variable<int>(repetitionN);
    map['interval_days'] = Variable<double>(intervalDays);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['next_review'] = Variable<DateTime>(nextReview);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    map['total_reviews'] = Variable<int>(totalReviews);
    map['correct_streak'] = Variable<int>(correctStreak);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  Sm2StatesCompanion toCompanion(bool nullToAbsent) {
    return Sm2StatesCompanion(
      id: Value(id),
      wordId: Value(wordId),
      repetitionN: Value(repetitionN),
      intervalDays: Value(intervalDays),
      easeFactor: Value(easeFactor),
      nextReview: Value(nextReview),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      totalReviews: Value(totalReviews),
      correctStreak: Value(correctStreak),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Sm2State.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sm2State(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      repetitionN: serializer.fromJson<int>(json['repetitionN']),
      intervalDays: serializer.fromJson<double>(json['intervalDays']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      nextReview: serializer.fromJson<DateTime>(json['nextReview']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      totalReviews: serializer.fromJson<int>(json['totalReviews']),
      correctStreak: serializer.fromJson<int>(json['correctStreak']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'repetitionN': serializer.toJson<int>(repetitionN),
      'intervalDays': serializer.toJson<double>(intervalDays),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'nextReview': serializer.toJson<DateTime>(nextReview),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'totalReviews': serializer.toJson<int>(totalReviews),
      'correctStreak': serializer.toJson<int>(correctStreak),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Sm2State copyWith({
    int? id,
    int? wordId,
    int? repetitionN,
    double? intervalDays,
    double? easeFactor,
    DateTime? nextReview,
    Value<DateTime?> lastReview = const Value.absent(),
    int? totalReviews,
    int? correctStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Sm2State(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    repetitionN: repetitionN ?? this.repetitionN,
    intervalDays: intervalDays ?? this.intervalDays,
    easeFactor: easeFactor ?? this.easeFactor,
    nextReview: nextReview ?? this.nextReview,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    totalReviews: totalReviews ?? this.totalReviews,
    correctStreak: correctStreak ?? this.correctStreak,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Sm2State copyWithCompanion(Sm2StatesCompanion data) {
    return Sm2State(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      repetitionN: data.repetitionN.present
          ? data.repetitionN.value
          : this.repetitionN,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      nextReview: data.nextReview.present
          ? data.nextReview.value
          : this.nextReview,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      totalReviews: data.totalReviews.present
          ? data.totalReviews.value
          : this.totalReviews,
      correctStreak: data.correctStreak.present
          ? data.correctStreak.value
          : this.correctStreak,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sm2State(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('repetitionN: $repetitionN, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('nextReview: $nextReview, ')
          ..write('lastReview: $lastReview, ')
          ..write('totalReviews: $totalReviews, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    repetitionN,
    intervalDays,
    easeFactor,
    nextReview,
    lastReview,
    totalReviews,
    correctStreak,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sm2State &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.repetitionN == this.repetitionN &&
          other.intervalDays == this.intervalDays &&
          other.easeFactor == this.easeFactor &&
          other.nextReview == this.nextReview &&
          other.lastReview == this.lastReview &&
          other.totalReviews == this.totalReviews &&
          other.correctStreak == this.correctStreak &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class Sm2StatesCompanion extends UpdateCompanion<Sm2State> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<int> repetitionN;
  final Value<double> intervalDays;
  final Value<double> easeFactor;
  final Value<DateTime> nextReview;
  final Value<DateTime?> lastReview;
  final Value<int> totalReviews;
  final Value<int> correctStreak;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const Sm2StatesCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.repetitionN = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.totalReviews = const Value.absent(),
    this.correctStreak = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  Sm2StatesCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    this.repetitionN = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.easeFactor = const Value.absent(),
    required DateTime nextReview,
    this.lastReview = const Value.absent(),
    this.totalReviews = const Value.absent(),
    this.correctStreak = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : wordId = Value(wordId),
       nextReview = Value(nextReview),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Sm2State> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<int>? repetitionN,
    Expression<double>? intervalDays,
    Expression<double>? easeFactor,
    Expression<DateTime>? nextReview,
    Expression<DateTime>? lastReview,
    Expression<int>? totalReviews,
    Expression<int>? correctStreak,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (repetitionN != null) 'repetition_n': repetitionN,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (nextReview != null) 'next_review': nextReview,
      if (lastReview != null) 'last_review': lastReview,
      if (totalReviews != null) 'total_reviews': totalReviews,
      if (correctStreak != null) 'correct_streak': correctStreak,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  Sm2StatesCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<int>? repetitionN,
    Value<double>? intervalDays,
    Value<double>? easeFactor,
    Value<DateTime>? nextReview,
    Value<DateTime?>? lastReview,
    Value<int>? totalReviews,
    Value<int>? correctStreak,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return Sm2StatesCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      repetitionN: repetitionN ?? this.repetitionN,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReview: nextReview ?? this.nextReview,
      lastReview: lastReview ?? this.lastReview,
      totalReviews: totalReviews ?? this.totalReviews,
      correctStreak: correctStreak ?? this.correctStreak,
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
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (repetitionN.present) {
      map['repetition_n'] = Variable<int>(repetitionN.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<double>(intervalDays.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<DateTime>(nextReview.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (totalReviews.present) {
      map['total_reviews'] = Variable<int>(totalReviews.value);
    }
    if (correctStreak.present) {
      map['correct_streak'] = Variable<int>(correctStreak.value);
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
    return (StringBuffer('Sm2StatesCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('repetitionN: $repetitionN, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('nextReview: $nextReview, ')
          ..write('lastReview: $lastReview, ')
          ..write('totalReviews: $totalReviews, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ConjugationCacheTable extends ConjugationCache
    with TableInfo<$ConjugationCacheTable, ConjugationCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConjugationCacheTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conjugationJsonMeta = const VerificationMeta(
    'conjugationJson',
  );
  @override
  late final GeneratedColumn<String> conjugationJson = GeneratedColumn<String>(
    'conjugation_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ai'),
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
    wordId,
    conjugationJson,
    source,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conjugation_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConjugationCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('conjugation_json')) {
      context.handle(
        _conjugationJsonMeta,
        conjugationJson.isAcceptableOrUnknown(
          data['conjugation_json']!,
          _conjugationJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conjugationJsonMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {wordId},
  ];
  @override
  ConjugationCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConjugationCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      conjugationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conjugation_json'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
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
  $ConjugationCacheTable createAlias(String alias) {
    return $ConjugationCacheTable(attachedDatabase, alias);
  }
}

class ConjugationCacheData extends DataClass
    implements Insertable<ConjugationCacheData> {
  final int id;
  final int wordId;
  final String conjugationJson;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConjugationCacheData({
    required this.id,
    required this.wordId,
    required this.conjugationJson,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['conjugation_json'] = Variable<String>(conjugationJson);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConjugationCacheCompanion toCompanion(bool nullToAbsent) {
    return ConjugationCacheCompanion(
      id: Value(id),
      wordId: Value(wordId),
      conjugationJson: Value(conjugationJson),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConjugationCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConjugationCacheData(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      conjugationJson: serializer.fromJson<String>(json['conjugationJson']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'conjugationJson': serializer.toJson<String>(conjugationJson),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConjugationCacheData copyWith({
    int? id,
    int? wordId,
    String? conjugationJson,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConjugationCacheData(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    conjugationJson: conjugationJson ?? this.conjugationJson,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConjugationCacheData copyWithCompanion(ConjugationCacheCompanion data) {
    return ConjugationCacheData(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      conjugationJson: data.conjugationJson.present
          ? data.conjugationJson.value
          : this.conjugationJson,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConjugationCacheData(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('conjugationJson: $conjugationJson, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordId, conjugationJson, source, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConjugationCacheData &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.conjugationJson == this.conjugationJson &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConjugationCacheCompanion extends UpdateCompanion<ConjugationCacheData> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<String> conjugationJson;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ConjugationCacheCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.conjugationJson = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConjugationCacheCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required String conjugationJson,
    this.source = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : wordId = Value(wordId),
       conjugationJson = Value(conjugationJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConjugationCacheData> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? conjugationJson,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (conjugationJson != null) 'conjugation_json': conjugationJson,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConjugationCacheCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<String>? conjugationJson,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ConjugationCacheCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      conjugationJson: conjugationJson ?? this.conjugationJson,
      source: source ?? this.source,
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
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (conjugationJson.present) {
      map['conjugation_json'] = Variable<String>(conjugationJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
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
    return (StringBuffer('ConjugationCacheCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('conjugationJson: $conjugationJson, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AiLookupCacheTable extends AiLookupCache
    with TableInfo<$AiLookupCacheTable, AiLookupCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiLookupCacheTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
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
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
    'engine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ai'),
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
    word,
    resultJson,
    engine,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_lookup_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiLookupCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_resultJsonMeta);
    }
    if (data.containsKey('engine')) {
      context.handle(
        _engineMeta,
        engine.isAcceptableOrUnknown(data['engine']!, _engineMeta),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {word, engine},
  ];
  @override
  AiLookupCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiLookupCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      )!,
      engine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine'],
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
  $AiLookupCacheTable createAlias(String alias) {
    return $AiLookupCacheTable(attachedDatabase, alias);
  }
}

class AiLookupCacheData extends DataClass
    implements Insertable<AiLookupCacheData> {
  final int id;
  final String word;
  final String resultJson;
  final String engine;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiLookupCacheData({
    required this.id,
    required this.word,
    required this.resultJson,
    required this.engine,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['result_json'] = Variable<String>(resultJson);
    map['engine'] = Variable<String>(engine);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiLookupCacheCompanion toCompanion(bool nullToAbsent) {
    return AiLookupCacheCompanion(
      id: Value(id),
      word: Value(word),
      resultJson: Value(resultJson),
      engine: Value(engine),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiLookupCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiLookupCacheData(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      resultJson: serializer.fromJson<String>(json['resultJson']),
      engine: serializer.fromJson<String>(json['engine']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'resultJson': serializer.toJson<String>(resultJson),
      'engine': serializer.toJson<String>(engine),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiLookupCacheData copyWith({
    int? id,
    String? word,
    String? resultJson,
    String? engine,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AiLookupCacheData(
    id: id ?? this.id,
    word: word ?? this.word,
    resultJson: resultJson ?? this.resultJson,
    engine: engine ?? this.engine,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AiLookupCacheData copyWithCompanion(AiLookupCacheCompanion data) {
    return AiLookupCacheData(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      engine: data.engine.present ? data.engine.value : this.engine,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiLookupCacheData(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('resultJson: $resultJson, ')
          ..write('engine: $engine, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, word, resultJson, engine, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiLookupCacheData &&
          other.id == this.id &&
          other.word == this.word &&
          other.resultJson == this.resultJson &&
          other.engine == this.engine &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiLookupCacheCompanion extends UpdateCompanion<AiLookupCacheData> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> resultJson;
  final Value<String> engine;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AiLookupCacheCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.engine = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AiLookupCacheCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String resultJson,
    this.engine = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : word = Value(word),
       resultJson = Value(resultJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AiLookupCacheData> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? resultJson,
    Expression<String>? engine,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (resultJson != null) 'result_json': resultJson,
      if (engine != null) 'engine': engine,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AiLookupCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? resultJson,
    Value<String>? engine,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AiLookupCacheCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      resultJson: resultJson ?? this.resultJson,
      engine: engine ?? this.engine,
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
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
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
    return (StringBuffer('AiLookupCacheCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('resultJson: $resultJson, ')
          ..write('engine: $engine, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AiRequestStatusTable extends AiRequestStatus
    with TableInfo<$AiRequestStatusTable, AiRequestStatusData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiRequestStatusTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
    'engine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ai'),
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
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRequestAtMeta = const VerificationMeta(
    'lastRequestAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRequestAt =
      GeneratedColumn<DateTime>(
        'last_request_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    engine,
    status,
    errorMessage,
    lastRequestAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_request_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiRequestStatusData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('engine')) {
      context.handle(
        _engineMeta,
        engine.isAcceptableOrUnknown(data['engine']!, _engineMeta),
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
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_request_at')) {
      context.handle(
        _lastRequestAtMeta,
        lastRequestAt.isAcceptableOrUnknown(
          data['last_request_at']!,
          _lastRequestAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastRequestAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {word, engine},
  ];
  @override
  AiRequestStatusData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiRequestStatusData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      engine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      lastRequestAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_request_at'],
      )!,
    );
  }

  @override
  $AiRequestStatusTable createAlias(String alias) {
    return $AiRequestStatusTable(attachedDatabase, alias);
  }
}

class AiRequestStatusData extends DataClass
    implements Insertable<AiRequestStatusData> {
  final int id;
  final String word;
  final String engine;
  final String status;
  final String? errorMessage;
  final DateTime lastRequestAt;
  const AiRequestStatusData({
    required this.id,
    required this.word,
    required this.engine,
    required this.status,
    this.errorMessage,
    required this.lastRequestAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['engine'] = Variable<String>(engine);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['last_request_at'] = Variable<DateTime>(lastRequestAt);
    return map;
  }

  AiRequestStatusCompanion toCompanion(bool nullToAbsent) {
    return AiRequestStatusCompanion(
      id: Value(id),
      word: Value(word),
      engine: Value(engine),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      lastRequestAt: Value(lastRequestAt),
    );
  }

  factory AiRequestStatusData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiRequestStatusData(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      engine: serializer.fromJson<String>(json['engine']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      lastRequestAt: serializer.fromJson<DateTime>(json['lastRequestAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'engine': serializer.toJson<String>(engine),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'lastRequestAt': serializer.toJson<DateTime>(lastRequestAt),
    };
  }

  AiRequestStatusData copyWith({
    int? id,
    String? word,
    String? engine,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? lastRequestAt,
  }) => AiRequestStatusData(
    id: id ?? this.id,
    word: word ?? this.word,
    engine: engine ?? this.engine,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    lastRequestAt: lastRequestAt ?? this.lastRequestAt,
  );
  AiRequestStatusData copyWithCompanion(AiRequestStatusCompanion data) {
    return AiRequestStatusData(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      engine: data.engine.present ? data.engine.value : this.engine,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      lastRequestAt: data.lastRequestAt.present
          ? data.lastRequestAt.value
          : this.lastRequestAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiRequestStatusData(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('engine: $engine, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('lastRequestAt: $lastRequestAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, word, engine, status, errorMessage, lastRequestAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiRequestStatusData &&
          other.id == this.id &&
          other.word == this.word &&
          other.engine == this.engine &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.lastRequestAt == this.lastRequestAt);
}

class AiRequestStatusCompanion extends UpdateCompanion<AiRequestStatusData> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> engine;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> lastRequestAt;
  const AiRequestStatusCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.engine = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.lastRequestAt = const Value.absent(),
  });
  AiRequestStatusCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    this.engine = const Value.absent(),
    required String status,
    this.errorMessage = const Value.absent(),
    required DateTime lastRequestAt,
  }) : word = Value(word),
       status = Value(status),
       lastRequestAt = Value(lastRequestAt);
  static Insertable<AiRequestStatusData> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? engine,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? lastRequestAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (engine != null) 'engine': engine,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (lastRequestAt != null) 'last_request_at': lastRequestAt,
    });
  }

  AiRequestStatusCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? engine,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<DateTime>? lastRequestAt,
  }) {
    return AiRequestStatusCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      engine: engine ?? this.engine,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRequestAt: lastRequestAt ?? this.lastRequestAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (lastRequestAt.present) {
      map['last_request_at'] = Variable<DateTime>(lastRequestAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiRequestStatusCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('engine: $engine, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('lastRequestAt: $lastRequestAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
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
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      Setting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyStatsTable extends StudyStats
    with TableInfo<$StudyStatsTable, StudyStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyStatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appearancesMeta = const VerificationMeta(
    'appearances',
  );
  @override
  late final GeneratedColumn<int> appearances = GeneratedColumn<int>(
    'appearances',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorsMeta = const VerificationMeta('errors');
  @override
  late final GeneratedColumn<int> errors = GeneratedColumn<int>(
    'errors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, wordId, date, appearances, errors];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('appearances')) {
      context.handle(
        _appearancesMeta,
        appearances.isAcceptableOrUnknown(
          data['appearances']!,
          _appearancesMeta,
        ),
      );
    }
    if (data.containsKey('errors')) {
      context.handle(
        _errorsMeta,
        errors.isAcceptableOrUnknown(data['errors']!, _errorsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {wordId, date},
  ];
  @override
  StudyStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      appearances: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}appearances'],
      )!,
      errors: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}errors'],
      )!,
    );
  }

  @override
  $StudyStatsTable createAlias(String alias) {
    return $StudyStatsTable(attachedDatabase, alias);
  }
}

class StudyStat extends DataClass implements Insertable<StudyStat> {
  final int id;
  final int wordId;

  /// 学习日期（当天 00:00:00）
  final DateTime date;

  /// 当天出现次数
  final int appearances;

  /// 当天错误次数
  final int errors;
  const StudyStat({
    required this.id,
    required this.wordId,
    required this.date,
    required this.appearances,
    required this.errors,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['date'] = Variable<DateTime>(date);
    map['appearances'] = Variable<int>(appearances);
    map['errors'] = Variable<int>(errors);
    return map;
  }

  StudyStatsCompanion toCompanion(bool nullToAbsent) {
    return StudyStatsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      date: Value(date),
      appearances: Value(appearances),
      errors: Value(errors),
    );
  }

  factory StudyStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyStat(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      date: serializer.fromJson<DateTime>(json['date']),
      appearances: serializer.fromJson<int>(json['appearances']),
      errors: serializer.fromJson<int>(json['errors']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'date': serializer.toJson<DateTime>(date),
      'appearances': serializer.toJson<int>(appearances),
      'errors': serializer.toJson<int>(errors),
    };
  }

  StudyStat copyWith({
    int? id,
    int? wordId,
    DateTime? date,
    int? appearances,
    int? errors,
  }) => StudyStat(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    date: date ?? this.date,
    appearances: appearances ?? this.appearances,
    errors: errors ?? this.errors,
  );
  StudyStat copyWithCompanion(StudyStatsCompanion data) {
    return StudyStat(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      date: data.date.present ? data.date.value : this.date,
      appearances: data.appearances.present
          ? data.appearances.value
          : this.appearances,
      errors: data.errors.present ? data.errors.value : this.errors,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyStat(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('date: $date, ')
          ..write('appearances: $appearances, ')
          ..write('errors: $errors')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, date, appearances, errors);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyStat &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.date == this.date &&
          other.appearances == this.appearances &&
          other.errors == this.errors);
}

class StudyStatsCompanion extends UpdateCompanion<StudyStat> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<DateTime> date;
  final Value<int> appearances;
  final Value<int> errors;
  const StudyStatsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.date = const Value.absent(),
    this.appearances = const Value.absent(),
    this.errors = const Value.absent(),
  });
  StudyStatsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required DateTime date,
    this.appearances = const Value.absent(),
    this.errors = const Value.absent(),
  }) : wordId = Value(wordId),
       date = Value(date);
  static Insertable<StudyStat> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<DateTime>? date,
    Expression<int>? appearances,
    Expression<int>? errors,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (date != null) 'date': date,
      if (appearances != null) 'appearances': appearances,
      if (errors != null) 'errors': errors,
    });
  }

  StudyStatsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<DateTime>? date,
    Value<int>? appearances,
    Value<int>? errors,
  }) {
    return StudyStatsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      date: date ?? this.date,
      appearances: appearances ?? this.appearances,
      errors: errors ?? this.errors,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (appearances.present) {
      map['appearances'] = Variable<int>(appearances.value);
    }
    if (errors.present) {
      map['errors'] = Variable<int>(errors.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyStatsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('date: $date, ')
          ..write('appearances: $appearances, ')
          ..write('errors: $errors')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $Sm2StatesTable sm2States = $Sm2StatesTable(this);
  late final $ConjugationCacheTable conjugationCache = $ConjugationCacheTable(
    this,
  );
  late final $AiLookupCacheTable aiLookupCache = $AiLookupCacheTable(this);
  late final $AiRequestStatusTable aiRequestStatus = $AiRequestStatusTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $StudyStatsTable studyStats = $StudyStatsTable(this);
  late final DeckDao deckDao = DeckDao(this as AppDatabase);
  late final WordDao wordDao = WordDao(this as AppDatabase);
  late final Sm2Dao sm2Dao = Sm2Dao(this as AppDatabase);
  late final ConjugationDao conjugationDao = ConjugationDao(
    this as AppDatabase,
  );
  late final AiCacheDao aiCacheDao = AiCacheDao(this as AppDatabase);
  late final AiStatusDao aiStatusDao = AiStatusDao(this as AppDatabase);
  late final StudyStatDao studyStatDao = StudyStatDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    decks,
    words,
    sm2States,
    conjugationCache,
    aiLookupCache,
    aiRequestStatus,
    settings,
    studyStats,
  ];
}

typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          Deck,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (Deck, BaseReferences<_$AppDatabase, $DecksTable, Deck>),
          Deck,
          PrefetchHooks Function()
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                description: description,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                description: description,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      Deck,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (Deck, BaseReferences<_$AppDatabase, $DecksTable, Deck>),
      Deck,
      PrefetchHooks Function()
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required int deckId,
      required String german,
      Value<String?> article,
      Value<String?> baseForm,
      Value<String?> wordType,
      required String chinese,
      Value<String?> example,
      Value<String?> tags,
      Value<int> proficiency,
      Value<bool> isFavorite,
      Value<DateTime?> lastStudyDate,
      Value<String?> verbPresent,
      Value<String?> verbPast,
      Value<String?> verbPerfect,
      Value<String?> nounGenitive,
      Value<String?> nounPlural,
      Value<String?> nounType,
      Value<String?> adjComparative,
      Value<String?> adjSuperlative,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<int> deckId,
      Value<String> german,
      Value<String?> article,
      Value<String?> baseForm,
      Value<String?> wordType,
      Value<String> chinese,
      Value<String?> example,
      Value<String?> tags,
      Value<int> proficiency,
      Value<bool> isFavorite,
      Value<DateTime?> lastStudyDate,
      Value<String?> verbPresent,
      Value<String?> verbPast,
      Value<String?> verbPerfect,
      Value<String?> nounGenitive,
      Value<String?> nounPlural,
      Value<String?> nounType,
      Value<String?> adjComparative,
      Value<String?> adjSuperlative,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
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

  ColumnFilters<int> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get german => $composableBuilder(
    column: $table.german,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get article => $composableBuilder(
    column: $table.article,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseForm => $composableBuilder(
    column: $table.baseForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordType => $composableBuilder(
    column: $table.wordType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chinese => $composableBuilder(
    column: $table.chinese,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proficiency => $composableBuilder(
    column: $table.proficiency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastStudyDate => $composableBuilder(
    column: $table.lastStudyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verbPresent => $composableBuilder(
    column: $table.verbPresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verbPast => $composableBuilder(
    column: $table.verbPast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verbPerfect => $composableBuilder(
    column: $table.verbPerfect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nounGenitive => $composableBuilder(
    column: $table.nounGenitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nounPlural => $composableBuilder(
    column: $table.nounPlural,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nounType => $composableBuilder(
    column: $table.nounType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adjComparative => $composableBuilder(
    column: $table.adjComparative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adjSuperlative => $composableBuilder(
    column: $table.adjSuperlative,
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
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
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

  ColumnOrderings<int> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get german => $composableBuilder(
    column: $table.german,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get article => $composableBuilder(
    column: $table.article,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseForm => $composableBuilder(
    column: $table.baseForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordType => $composableBuilder(
    column: $table.wordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chinese => $composableBuilder(
    column: $table.chinese,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proficiency => $composableBuilder(
    column: $table.proficiency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastStudyDate => $composableBuilder(
    column: $table.lastStudyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verbPresent => $composableBuilder(
    column: $table.verbPresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verbPast => $composableBuilder(
    column: $table.verbPast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verbPerfect => $composableBuilder(
    column: $table.verbPerfect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nounGenitive => $composableBuilder(
    column: $table.nounGenitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nounPlural => $composableBuilder(
    column: $table.nounPlural,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nounType => $composableBuilder(
    column: $table.nounType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adjComparative => $composableBuilder(
    column: $table.adjComparative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adjSuperlative => $composableBuilder(
    column: $table.adjSuperlative,
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
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get german =>
      $composableBuilder(column: $table.german, builder: (column) => column);

  GeneratedColumn<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => column);

  GeneratedColumn<String> get baseForm =>
      $composableBuilder(column: $table.baseForm, builder: (column) => column);

  GeneratedColumn<String> get wordType =>
      $composableBuilder(column: $table.wordType, builder: (column) => column);

  GeneratedColumn<String> get chinese =>
      $composableBuilder(column: $table.chinese, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get proficiency => $composableBuilder(
    column: $table.proficiency,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastStudyDate => $composableBuilder(
    column: $table.lastStudyDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verbPresent => $composableBuilder(
    column: $table.verbPresent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verbPast =>
      $composableBuilder(column: $table.verbPast, builder: (column) => column);

  GeneratedColumn<String> get verbPerfect => $composableBuilder(
    column: $table.verbPerfect,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nounGenitive => $composableBuilder(
    column: $table.nounGenitive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nounPlural => $composableBuilder(
    column: $table.nounPlural,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nounType =>
      $composableBuilder(column: $table.nounType, builder: (column) => column);

  GeneratedColumn<String> get adjComparative => $composableBuilder(
    column: $table.adjComparative,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adjSuperlative => $composableBuilder(
    column: $table.adjSuperlative,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
          Word,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deckId = const Value.absent(),
                Value<String> german = const Value.absent(),
                Value<String?> article = const Value.absent(),
                Value<String?> baseForm = const Value.absent(),
                Value<String?> wordType = const Value.absent(),
                Value<String> chinese = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> proficiency = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastStudyDate = const Value.absent(),
                Value<String?> verbPresent = const Value.absent(),
                Value<String?> verbPast = const Value.absent(),
                Value<String?> verbPerfect = const Value.absent(),
                Value<String?> nounGenitive = const Value.absent(),
                Value<String?> nounPlural = const Value.absent(),
                Value<String?> nounType = const Value.absent(),
                Value<String?> adjComparative = const Value.absent(),
                Value<String?> adjSuperlative = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                deckId: deckId,
                german: german,
                article: article,
                baseForm: baseForm,
                wordType: wordType,
                chinese: chinese,
                example: example,
                tags: tags,
                proficiency: proficiency,
                isFavorite: isFavorite,
                lastStudyDate: lastStudyDate,
                verbPresent: verbPresent,
                verbPast: verbPast,
                verbPerfect: verbPerfect,
                nounGenitive: nounGenitive,
                nounPlural: nounPlural,
                nounType: nounType,
                adjComparative: adjComparative,
                adjSuperlative: adjSuperlative,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deckId,
                required String german,
                Value<String?> article = const Value.absent(),
                Value<String?> baseForm = const Value.absent(),
                Value<String?> wordType = const Value.absent(),
                required String chinese,
                Value<String?> example = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> proficiency = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastStudyDate = const Value.absent(),
                Value<String?> verbPresent = const Value.absent(),
                Value<String?> verbPast = const Value.absent(),
                Value<String?> verbPerfect = const Value.absent(),
                Value<String?> nounGenitive = const Value.absent(),
                Value<String?> nounPlural = const Value.absent(),
                Value<String?> nounType = const Value.absent(),
                Value<String?> adjComparative = const Value.absent(),
                Value<String?> adjSuperlative = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => WordsCompanion.insert(
                id: id,
                deckId: deckId,
                german: german,
                article: article,
                baseForm: baseForm,
                wordType: wordType,
                chinese: chinese,
                example: example,
                tags: tags,
                proficiency: proficiency,
                isFavorite: isFavorite,
                lastStudyDate: lastStudyDate,
                verbPresent: verbPresent,
                verbPast: verbPast,
                verbPerfect: verbPerfect,
                nounGenitive: nounGenitive,
                nounPlural: nounPlural,
                nounType: nounType,
                adjComparative: adjComparative,
                adjSuperlative: adjSuperlative,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
      Word,
      PrefetchHooks Function()
    >;
typedef $$Sm2StatesTableCreateCompanionBuilder =
    Sm2StatesCompanion Function({
      Value<int> id,
      required int wordId,
      Value<int> repetitionN,
      Value<double> intervalDays,
      Value<double> easeFactor,
      required DateTime nextReview,
      Value<DateTime?> lastReview,
      Value<int> totalReviews,
      Value<int> correctStreak,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$Sm2StatesTableUpdateCompanionBuilder =
    Sm2StatesCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<int> repetitionN,
      Value<double> intervalDays,
      Value<double> easeFactor,
      Value<DateTime> nextReview,
      Value<DateTime?> lastReview,
      Value<int> totalReviews,
      Value<int> correctStreak,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$Sm2StatesTableFilterComposer
    extends Composer<_$AppDatabase, $Sm2StatesTable> {
  $$Sm2StatesTableFilterComposer({
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

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitionN => $composableBuilder(
    column: $table.repetitionN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
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
}

class $$Sm2StatesTableOrderingComposer
    extends Composer<_$AppDatabase, $Sm2StatesTable> {
  $$Sm2StatesTableOrderingComposer({
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

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitionN => $composableBuilder(
    column: $table.repetitionN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
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
}

class $$Sm2StatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $Sm2StatesTable> {
  $$Sm2StatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get repetitionN => $composableBuilder(
    column: $table.repetitionN,
    builder: (column) => column,
  );

  GeneratedColumn<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReview => $composableBuilder(
    column: $table.nextReview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$Sm2StatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $Sm2StatesTable,
          Sm2State,
          $$Sm2StatesTableFilterComposer,
          $$Sm2StatesTableOrderingComposer,
          $$Sm2StatesTableAnnotationComposer,
          $$Sm2StatesTableCreateCompanionBuilder,
          $$Sm2StatesTableUpdateCompanionBuilder,
          (Sm2State, BaseReferences<_$AppDatabase, $Sm2StatesTable, Sm2State>),
          Sm2State,
          PrefetchHooks Function()
        > {
  $$Sm2StatesTableTableManager(_$AppDatabase db, $Sm2StatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$Sm2StatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$Sm2StatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$Sm2StatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> repetitionN = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<DateTime> nextReview = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> totalReviews = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => Sm2StatesCompanion(
                id: id,
                wordId: wordId,
                repetitionN: repetitionN,
                intervalDays: intervalDays,
                easeFactor: easeFactor,
                nextReview: nextReview,
                lastReview: lastReview,
                totalReviews: totalReviews,
                correctStreak: correctStreak,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                Value<int> repetitionN = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                required DateTime nextReview,
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> totalReviews = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => Sm2StatesCompanion.insert(
                id: id,
                wordId: wordId,
                repetitionN: repetitionN,
                intervalDays: intervalDays,
                easeFactor: easeFactor,
                nextReview: nextReview,
                lastReview: lastReview,
                totalReviews: totalReviews,
                correctStreak: correctStreak,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$Sm2StatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $Sm2StatesTable,
      Sm2State,
      $$Sm2StatesTableFilterComposer,
      $$Sm2StatesTableOrderingComposer,
      $$Sm2StatesTableAnnotationComposer,
      $$Sm2StatesTableCreateCompanionBuilder,
      $$Sm2StatesTableUpdateCompanionBuilder,
      (Sm2State, BaseReferences<_$AppDatabase, $Sm2StatesTable, Sm2State>),
      Sm2State,
      PrefetchHooks Function()
    >;
typedef $$ConjugationCacheTableCreateCompanionBuilder =
    ConjugationCacheCompanion Function({
      Value<int> id,
      required int wordId,
      required String conjugationJson,
      Value<String> source,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ConjugationCacheTableUpdateCompanionBuilder =
    ConjugationCacheCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<String> conjugationJson,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ConjugationCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ConjugationCacheTable> {
  $$ConjugationCacheTableFilterComposer({
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

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conjugationJson => $composableBuilder(
    column: $table.conjugationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
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
}

class $$ConjugationCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ConjugationCacheTable> {
  $$ConjugationCacheTableOrderingComposer({
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

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conjugationJson => $composableBuilder(
    column: $table.conjugationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
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
}

class $$ConjugationCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConjugationCacheTable> {
  $$ConjugationCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get conjugationJson => $composableBuilder(
    column: $table.conjugationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConjugationCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConjugationCacheTable,
          ConjugationCacheData,
          $$ConjugationCacheTableFilterComposer,
          $$ConjugationCacheTableOrderingComposer,
          $$ConjugationCacheTableAnnotationComposer,
          $$ConjugationCacheTableCreateCompanionBuilder,
          $$ConjugationCacheTableUpdateCompanionBuilder,
          (
            ConjugationCacheData,
            BaseReferences<
              _$AppDatabase,
              $ConjugationCacheTable,
              ConjugationCacheData
            >,
          ),
          ConjugationCacheData,
          PrefetchHooks Function()
        > {
  $$ConjugationCacheTableTableManager(
    _$AppDatabase db,
    $ConjugationCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConjugationCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConjugationCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConjugationCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> conjugationJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConjugationCacheCompanion(
                id: id,
                wordId: wordId,
                conjugationJson: conjugationJson,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required String conjugationJson,
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ConjugationCacheCompanion.insert(
                id: id,
                wordId: wordId,
                conjugationJson: conjugationJson,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConjugationCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConjugationCacheTable,
      ConjugationCacheData,
      $$ConjugationCacheTableFilterComposer,
      $$ConjugationCacheTableOrderingComposer,
      $$ConjugationCacheTableAnnotationComposer,
      $$ConjugationCacheTableCreateCompanionBuilder,
      $$ConjugationCacheTableUpdateCompanionBuilder,
      (
        ConjugationCacheData,
        BaseReferences<
          _$AppDatabase,
          $ConjugationCacheTable,
          ConjugationCacheData
        >,
      ),
      ConjugationCacheData,
      PrefetchHooks Function()
    >;
typedef $$AiLookupCacheTableCreateCompanionBuilder =
    AiLookupCacheCompanion Function({
      Value<int> id,
      required String word,
      required String resultJson,
      Value<String> engine,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$AiLookupCacheTableUpdateCompanionBuilder =
    AiLookupCacheCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String> resultJson,
      Value<String> engine,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AiLookupCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AiLookupCacheTable> {
  $$AiLookupCacheTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engine => $composableBuilder(
    column: $table.engine,
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
}

class $$AiLookupCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AiLookupCacheTable> {
  $$AiLookupCacheTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engine => $composableBuilder(
    column: $table.engine,
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
}

class $$AiLookupCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiLookupCacheTable> {
  $$AiLookupCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AiLookupCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiLookupCacheTable,
          AiLookupCacheData,
          $$AiLookupCacheTableFilterComposer,
          $$AiLookupCacheTableOrderingComposer,
          $$AiLookupCacheTableAnnotationComposer,
          $$AiLookupCacheTableCreateCompanionBuilder,
          $$AiLookupCacheTableUpdateCompanionBuilder,
          (
            AiLookupCacheData,
            BaseReferences<
              _$AppDatabase,
              $AiLookupCacheTable,
              AiLookupCacheData
            >,
          ),
          AiLookupCacheData,
          PrefetchHooks Function()
        > {
  $$AiLookupCacheTableTableManager(_$AppDatabase db, $AiLookupCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiLookupCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiLookupCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiLookupCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> resultJson = const Value.absent(),
                Value<String> engine = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AiLookupCacheCompanion(
                id: id,
                word: word,
                resultJson: resultJson,
                engine: engine,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required String resultJson,
                Value<String> engine = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => AiLookupCacheCompanion.insert(
                id: id,
                word: word,
                resultJson: resultJson,
                engine: engine,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiLookupCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiLookupCacheTable,
      AiLookupCacheData,
      $$AiLookupCacheTableFilterComposer,
      $$AiLookupCacheTableOrderingComposer,
      $$AiLookupCacheTableAnnotationComposer,
      $$AiLookupCacheTableCreateCompanionBuilder,
      $$AiLookupCacheTableUpdateCompanionBuilder,
      (
        AiLookupCacheData,
        BaseReferences<_$AppDatabase, $AiLookupCacheTable, AiLookupCacheData>,
      ),
      AiLookupCacheData,
      PrefetchHooks Function()
    >;
typedef $$AiRequestStatusTableCreateCompanionBuilder =
    AiRequestStatusCompanion Function({
      Value<int> id,
      required String word,
      Value<String> engine,
      required String status,
      Value<String?> errorMessage,
      required DateTime lastRequestAt,
    });
typedef $$AiRequestStatusTableUpdateCompanionBuilder =
    AiRequestStatusCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String> engine,
      Value<String> status,
      Value<String?> errorMessage,
      Value<DateTime> lastRequestAt,
    });

class $$AiRequestStatusTableFilterComposer
    extends Composer<_$AppDatabase, $AiRequestStatusTable> {
  $$AiRequestStatusTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRequestAt => $composableBuilder(
    column: $table.lastRequestAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiRequestStatusTableOrderingComposer
    extends Composer<_$AppDatabase, $AiRequestStatusTable> {
  $$AiRequestStatusTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRequestAt => $composableBuilder(
    column: $table.lastRequestAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiRequestStatusTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiRequestStatusTable> {
  $$AiRequestStatusTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRequestAt => $composableBuilder(
    column: $table.lastRequestAt,
    builder: (column) => column,
  );
}

class $$AiRequestStatusTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiRequestStatusTable,
          AiRequestStatusData,
          $$AiRequestStatusTableFilterComposer,
          $$AiRequestStatusTableOrderingComposer,
          $$AiRequestStatusTableAnnotationComposer,
          $$AiRequestStatusTableCreateCompanionBuilder,
          $$AiRequestStatusTableUpdateCompanionBuilder,
          (
            AiRequestStatusData,
            BaseReferences<
              _$AppDatabase,
              $AiRequestStatusTable,
              AiRequestStatusData
            >,
          ),
          AiRequestStatusData,
          PrefetchHooks Function()
        > {
  $$AiRequestStatusTableTableManager(
    _$AppDatabase db,
    $AiRequestStatusTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiRequestStatusTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiRequestStatusTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiRequestStatusTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> engine = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> lastRequestAt = const Value.absent(),
              }) => AiRequestStatusCompanion(
                id: id,
                word: word,
                engine: engine,
                status: status,
                errorMessage: errorMessage,
                lastRequestAt: lastRequestAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                Value<String> engine = const Value.absent(),
                required String status,
                Value<String?> errorMessage = const Value.absent(),
                required DateTime lastRequestAt,
              }) => AiRequestStatusCompanion.insert(
                id: id,
                word: word,
                engine: engine,
                status: status,
                errorMessage: errorMessage,
                lastRequestAt: lastRequestAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiRequestStatusTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiRequestStatusTable,
      AiRequestStatusData,
      $$AiRequestStatusTableFilterComposer,
      $$AiRequestStatusTableOrderingComposer,
      $$AiRequestStatusTableAnnotationComposer,
      $$AiRequestStatusTableCreateCompanionBuilder,
      $$AiRequestStatusTableUpdateCompanionBuilder,
      (
        AiRequestStatusData,
        BaseReferences<
          _$AppDatabase,
          $AiRequestStatusTable,
          AiRequestStatusData
        >,
      ),
      AiRequestStatusData,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
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

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$StudyStatsTableCreateCompanionBuilder =
    StudyStatsCompanion Function({
      Value<int> id,
      required int wordId,
      required DateTime date,
      Value<int> appearances,
      Value<int> errors,
    });
typedef $$StudyStatsTableUpdateCompanionBuilder =
    StudyStatsCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<DateTime> date,
      Value<int> appearances,
      Value<int> errors,
    });

class $$StudyStatsTableFilterComposer
    extends Composer<_$AppDatabase, $StudyStatsTable> {
  $$StudyStatsTableFilterComposer({
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

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appearances => $composableBuilder(
    column: $table.appearances,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get errors => $composableBuilder(
    column: $table.errors,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyStatsTable> {
  $$StudyStatsTableOrderingComposer({
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

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appearances => $composableBuilder(
    column: $table.appearances,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errors => $composableBuilder(
    column: $table.errors,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyStatsTable> {
  $$StudyStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get appearances => $composableBuilder(
    column: $table.appearances,
    builder: (column) => column,
  );

  GeneratedColumn<int> get errors =>
      $composableBuilder(column: $table.errors, builder: (column) => column);
}

class $$StudyStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyStatsTable,
          StudyStat,
          $$StudyStatsTableFilterComposer,
          $$StudyStatsTableOrderingComposer,
          $$StudyStatsTableAnnotationComposer,
          $$StudyStatsTableCreateCompanionBuilder,
          $$StudyStatsTableUpdateCompanionBuilder,
          (
            StudyStat,
            BaseReferences<_$AppDatabase, $StudyStatsTable, StudyStat>,
          ),
          StudyStat,
          PrefetchHooks Function()
        > {
  $$StudyStatsTableTableManager(_$AppDatabase db, $StudyStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> appearances = const Value.absent(),
                Value<int> errors = const Value.absent(),
              }) => StudyStatsCompanion(
                id: id,
                wordId: wordId,
                date: date,
                appearances: appearances,
                errors: errors,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required DateTime date,
                Value<int> appearances = const Value.absent(),
                Value<int> errors = const Value.absent(),
              }) => StudyStatsCompanion.insert(
                id: id,
                wordId: wordId,
                date: date,
                appearances: appearances,
                errors: errors,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyStatsTable,
      StudyStat,
      $$StudyStatsTableFilterComposer,
      $$StudyStatsTableOrderingComposer,
      $$StudyStatsTableAnnotationComposer,
      $$StudyStatsTableCreateCompanionBuilder,
      $$StudyStatsTableUpdateCompanionBuilder,
      (StudyStat, BaseReferences<_$AppDatabase, $StudyStatsTable, StudyStat>),
      StudyStat,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$Sm2StatesTableTableManager get sm2States =>
      $$Sm2StatesTableTableManager(_db, _db.sm2States);
  $$ConjugationCacheTableTableManager get conjugationCache =>
      $$ConjugationCacheTableTableManager(_db, _db.conjugationCache);
  $$AiLookupCacheTableTableManager get aiLookupCache =>
      $$AiLookupCacheTableTableManager(_db, _db.aiLookupCache);
  $$AiRequestStatusTableTableManager get aiRequestStatus =>
      $$AiRequestStatusTableTableManager(_db, _db.aiRequestStatus);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$StudyStatsTableTableManager get studyStats =>
      $$StudyStatsTableTableManager(_db, _db.studyStats);
}
