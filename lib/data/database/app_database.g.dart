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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
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

class $DeletionLogsTable extends DeletionLogs
    with TableInfo<$DeletionLogsTable, DeletionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletionLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deckNameMeta = const VerificationMeta(
    'deckName',
  );
  @override
  late final GeneratedColumn<String> deckName = GeneratedColumn<String>(
    'deck_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _germanMeta = const VerificationMeta('german');
  @override
  late final GeneratedColumn<String> german = GeneratedColumn<String>(
    'german',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, deckName, german, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deletion_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_name')) {
      context.handle(
        _deckNameMeta,
        deckName.isAcceptableOrUnknown(data['deck_name']!, _deckNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deckNameMeta);
    }
    if (data.containsKey('german')) {
      context.handle(
        _germanMeta,
        german.isAcceptableOrUnknown(data['german']!, _germanMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeletionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletionLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_name'],
      )!,
      german: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}german'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletionLogsTable createAlias(String alias) {
    return $DeletionLogsTable(attachedDatabase, alias);
  }
}

class DeletionLog extends DataClass implements Insertable<DeletionLog> {
  final int id;
  final String deckName;
  final String german;
  final DateTime deletedAt;
  const DeletionLog({
    required this.id,
    required this.deckName,
    required this.german,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deck_name'] = Variable<String>(deckName);
    map['german'] = Variable<String>(german);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletionLogsCompanion toCompanion(bool nullToAbsent) {
    return DeletionLogsCompanion(
      id: Value(id),
      deckName: Value(deckName),
      german: Value(german),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletionLog(
      id: serializer.fromJson<int>(json['id']),
      deckName: serializer.fromJson<String>(json['deckName']),
      german: serializer.fromJson<String>(json['german']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckName': serializer.toJson<String>(deckName),
      'german': serializer.toJson<String>(german),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletionLog copyWith({
    int? id,
    String? deckName,
    String? german,
    DateTime? deletedAt,
  }) => DeletionLog(
    id: id ?? this.id,
    deckName: deckName ?? this.deckName,
    german: german ?? this.german,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletionLog copyWithCompanion(DeletionLogsCompanion data) {
    return DeletionLog(
      id: data.id.present ? data.id.value : this.id,
      deckName: data.deckName.present ? data.deckName.value : this.deckName,
      german: data.german.present ? data.german.value : this.german,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletionLog(')
          ..write('id: $id, ')
          ..write('deckName: $deckName, ')
          ..write('german: $german, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deckName, german, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletionLog &&
          other.id == this.id &&
          other.deckName == this.deckName &&
          other.german == this.german &&
          other.deletedAt == this.deletedAt);
}

class DeletionLogsCompanion extends UpdateCompanion<DeletionLog> {
  final Value<int> id;
  final Value<String> deckName;
  final Value<String> german;
  final Value<DateTime> deletedAt;
  const DeletionLogsCompanion({
    this.id = const Value.absent(),
    this.deckName = const Value.absent(),
    this.german = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DeletionLogsCompanion.insert({
    this.id = const Value.absent(),
    required String deckName,
    this.german = const Value.absent(),
    required DateTime deletedAt,
  }) : deckName = Value(deckName),
       deletedAt = Value(deletedAt);
  static Insertable<DeletionLog> custom({
    Expression<int>? id,
    Expression<String>? deckName,
    Expression<String>? german,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckName != null) 'deck_name': deckName,
      if (german != null) 'german': german,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DeletionLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? deckName,
    Value<String>? german,
    Value<DateTime>? deletedAt,
  }) {
    return DeletionLogsCompanion(
      id: id ?? this.id,
      deckName: deckName ?? this.deckName,
      german: german ?? this.german,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deckName.present) {
      map['deck_name'] = Variable<String>(deckName.value);
    }
    if (german.present) {
      map['german'] = Variable<String>(german.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletionLogsCompanion(')
          ..write('id: $id, ')
          ..write('deckName: $deckName, ')
          ..write('german: $german, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _skillMeta = const VerificationMeta('skill');
  @override
  late final GeneratedColumn<String> skill = GeneratedColumn<String>(
    'skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseTypeMeta = const VerificationMeta(
    'exerciseType',
  );
  @override
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
    'exercise_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stimulusKindMeta = const VerificationMeta(
    'stimulusKind',
  );
  @override
  late final GeneratedColumn<String> stimulusKind = GeneratedColumn<String>(
    'stimulus_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _stimulusTextMeta = const VerificationMeta(
    'stimulusText',
  );
  @override
  late final GeneratedColumn<String> stimulusText = GeneratedColumn<String>(
    'stimulus_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<int> totalScore = GeneratedColumn<int>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<int> maxScore = GeneratedColumn<int>(
    'max_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<String> promptVersion = GeneratedColumn<String>(
    'prompt_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _aiModelMeta = const VerificationMeta(
    'aiModel',
  );
  @override
  late final GeneratedColumn<String> aiModel = GeneratedColumn<String>(
    'ai_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    skill,
    exerciseType,
    level,
    difficulty,
    topic,
    title,
    instructions,
    stimulusKind,
    stimulusText,
    status,
    totalScore,
    maxScore,
    durationSeconds,
    errorMessage,
    schemaVersion,
    promptVersion,
    aiModel,
    createdAt,
    submittedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('skill')) {
      context.handle(
        _skillMeta,
        skill.isAcceptableOrUnknown(data['skill']!, _skillMeta),
      );
    } else if (isInserting) {
      context.missing(_skillMeta);
    }
    if (data.containsKey('exercise_type')) {
      context.handle(
        _exerciseTypeMeta,
        exerciseType.isAcceptableOrUnknown(
          data['exercise_type']!,
          _exerciseTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseTypeMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
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
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('stimulus_kind')) {
      context.handle(
        _stimulusKindMeta,
        stimulusKind.isAcceptableOrUnknown(
          data['stimulus_kind']!,
          _stimulusKindMeta,
        ),
      );
    }
    if (data.containsKey('stimulus_text')) {
      context.handle(
        _stimulusTextMeta,
        stimulusText.isAcceptableOrUnknown(
          data['stimulus_text']!,
          _stimulusTextMeta,
        ),
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
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
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
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    }
    if (data.containsKey('ai_model')) {
      context.handle(
        _aiModelMeta,
        aiModel.isAcceptableOrUnknown(data['ai_model']!, _aiModelMeta),
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
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      skill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill'],
      )!,
      exerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_type'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      )!,
      stimulusKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stimulus_kind'],
      )!,
      stimulusText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stimulus_text'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_score'],
      )!,
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_score'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_version'],
      )!,
      aiModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_model'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;

  /// 技能分类：listening / reading / writing
  final String skill;

  /// 题型编码（见 ExerciseType.code；改名需做旧记录兼容）
  final String exerciseType;

  /// CEFR 等级：A1..C2
  final String level;

  /// 难度：easy / normal / hard
  final String difficulty;

  /// 主题（中文名，用作 i18n key 与提示词内容）
  final String topic;
  final String title;
  final String instructions;

  /// 材料类型：text / audio / none
  final String stimulusKind;

  /// 材料正文（阅读短文 / 听力原文）
  final String stimulusText;

  /// 状态：ready（已生成待作答）/ submitted（已提交并批改）/ failed
  final String status;
  final int totalScore;
  final int maxScore;

  /// 作答耗时（秒），未提交时为 null
  final int? durationSeconds;
  final String? errorMessage;

  /// 生成格式版本（schema）
  final int schemaVersion;

  /// 提示词版本（质量排查用）
  final String promptVersion;

  /// 生成所用模型名（质量排查用，不含任何密钥）
  final String aiModel;
  final DateTime createdAt;
  final DateTime? submittedAt;
  const Exercise({
    required this.id,
    required this.skill,
    required this.exerciseType,
    required this.level,
    required this.difficulty,
    required this.topic,
    required this.title,
    required this.instructions,
    required this.stimulusKind,
    required this.stimulusText,
    required this.status,
    required this.totalScore,
    required this.maxScore,
    this.durationSeconds,
    this.errorMessage,
    required this.schemaVersion,
    required this.promptVersion,
    required this.aiModel,
    required this.createdAt,
    this.submittedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['skill'] = Variable<String>(skill);
    map['exercise_type'] = Variable<String>(exerciseType);
    map['level'] = Variable<String>(level);
    map['difficulty'] = Variable<String>(difficulty);
    map['topic'] = Variable<String>(topic);
    map['title'] = Variable<String>(title);
    map['instructions'] = Variable<String>(instructions);
    map['stimulus_kind'] = Variable<String>(stimulusKind);
    map['stimulus_text'] = Variable<String>(stimulusText);
    map['status'] = Variable<String>(status);
    map['total_score'] = Variable<int>(totalScore);
    map['max_score'] = Variable<int>(maxScore);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    map['prompt_version'] = Variable<String>(promptVersion);
    map['ai_model'] = Variable<String>(aiModel);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<DateTime>(submittedAt);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      skill: Value(skill),
      exerciseType: Value(exerciseType),
      level: Value(level),
      difficulty: Value(difficulty),
      topic: Value(topic),
      title: Value(title),
      instructions: Value(instructions),
      stimulusKind: Value(stimulusKind),
      stimulusText: Value(stimulusText),
      status: Value(status),
      totalScore: Value(totalScore),
      maxScore: Value(maxScore),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      schemaVersion: Value(schemaVersion),
      promptVersion: Value(promptVersion),
      aiModel: Value(aiModel),
      createdAt: Value(createdAt),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      skill: serializer.fromJson<String>(json['skill']),
      exerciseType: serializer.fromJson<String>(json['exerciseType']),
      level: serializer.fromJson<String>(json['level']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      topic: serializer.fromJson<String>(json['topic']),
      title: serializer.fromJson<String>(json['title']),
      instructions: serializer.fromJson<String>(json['instructions']),
      stimulusKind: serializer.fromJson<String>(json['stimulusKind']),
      stimulusText: serializer.fromJson<String>(json['stimulusText']),
      status: serializer.fromJson<String>(json['status']),
      totalScore: serializer.fromJson<int>(json['totalScore']),
      maxScore: serializer.fromJson<int>(json['maxScore']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      promptVersion: serializer.fromJson<String>(json['promptVersion']),
      aiModel: serializer.fromJson<String>(json['aiModel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      submittedAt: serializer.fromJson<DateTime?>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'skill': serializer.toJson<String>(skill),
      'exerciseType': serializer.toJson<String>(exerciseType),
      'level': serializer.toJson<String>(level),
      'difficulty': serializer.toJson<String>(difficulty),
      'topic': serializer.toJson<String>(topic),
      'title': serializer.toJson<String>(title),
      'instructions': serializer.toJson<String>(instructions),
      'stimulusKind': serializer.toJson<String>(stimulusKind),
      'stimulusText': serializer.toJson<String>(stimulusText),
      'status': serializer.toJson<String>(status),
      'totalScore': serializer.toJson<int>(totalScore),
      'maxScore': serializer.toJson<int>(maxScore),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'promptVersion': serializer.toJson<String>(promptVersion),
      'aiModel': serializer.toJson<String>(aiModel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'submittedAt': serializer.toJson<DateTime?>(submittedAt),
    };
  }

  Exercise copyWith({
    int? id,
    String? skill,
    String? exerciseType,
    String? level,
    String? difficulty,
    String? topic,
    String? title,
    String? instructions,
    String? stimulusKind,
    String? stimulusText,
    String? status,
    int? totalScore,
    int? maxScore,
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    int? schemaVersion,
    String? promptVersion,
    String? aiModel,
    DateTime? createdAt,
    Value<DateTime?> submittedAt = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    skill: skill ?? this.skill,
    exerciseType: exerciseType ?? this.exerciseType,
    level: level ?? this.level,
    difficulty: difficulty ?? this.difficulty,
    topic: topic ?? this.topic,
    title: title ?? this.title,
    instructions: instructions ?? this.instructions,
    stimulusKind: stimulusKind ?? this.stimulusKind,
    stimulusText: stimulusText ?? this.stimulusText,
    status: status ?? this.status,
    totalScore: totalScore ?? this.totalScore,
    maxScore: maxScore ?? this.maxScore,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    promptVersion: promptVersion ?? this.promptVersion,
    aiModel: aiModel ?? this.aiModel,
    createdAt: createdAt ?? this.createdAt,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      skill: data.skill.present ? data.skill.value : this.skill,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      level: data.level.present ? data.level.value : this.level,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      topic: data.topic.present ? data.topic.value : this.topic,
      title: data.title.present ? data.title.value : this.title,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      stimulusKind: data.stimulusKind.present
          ? data.stimulusKind.value
          : this.stimulusKind,
      stimulusText: data.stimulusText.present
          ? data.stimulusText.value
          : this.stimulusText,
      status: data.status.present ? data.status.value : this.status,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      aiModel: data.aiModel.present ? data.aiModel.value : this.aiModel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('skill: $skill, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('level: $level, ')
          ..write('difficulty: $difficulty, ')
          ..write('topic: $topic, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('stimulusKind: $stimulusKind, ')
          ..write('stimulusText: $stimulusText, ')
          ..write('status: $status, ')
          ..write('totalScore: $totalScore, ')
          ..write('maxScore: $maxScore, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('aiModel: $aiModel, ')
          ..write('createdAt: $createdAt, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    skill,
    exerciseType,
    level,
    difficulty,
    topic,
    title,
    instructions,
    stimulusKind,
    stimulusText,
    status,
    totalScore,
    maxScore,
    durationSeconds,
    errorMessage,
    schemaVersion,
    promptVersion,
    aiModel,
    createdAt,
    submittedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.skill == this.skill &&
          other.exerciseType == this.exerciseType &&
          other.level == this.level &&
          other.difficulty == this.difficulty &&
          other.topic == this.topic &&
          other.title == this.title &&
          other.instructions == this.instructions &&
          other.stimulusKind == this.stimulusKind &&
          other.stimulusText == this.stimulusText &&
          other.status == this.status &&
          other.totalScore == this.totalScore &&
          other.maxScore == this.maxScore &&
          other.durationSeconds == this.durationSeconds &&
          other.errorMessage == this.errorMessage &&
          other.schemaVersion == this.schemaVersion &&
          other.promptVersion == this.promptVersion &&
          other.aiModel == this.aiModel &&
          other.createdAt == this.createdAt &&
          other.submittedAt == this.submittedAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> skill;
  final Value<String> exerciseType;
  final Value<String> level;
  final Value<String> difficulty;
  final Value<String> topic;
  final Value<String> title;
  final Value<String> instructions;
  final Value<String> stimulusKind;
  final Value<String> stimulusText;
  final Value<String> status;
  final Value<int> totalScore;
  final Value<int> maxScore;
  final Value<int?> durationSeconds;
  final Value<String?> errorMessage;
  final Value<int> schemaVersion;
  final Value<String> promptVersion;
  final Value<String> aiModel;
  final Value<DateTime> createdAt;
  final Value<DateTime?> submittedAt;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.skill = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.level = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.topic = const Value.absent(),
    this.title = const Value.absent(),
    this.instructions = const Value.absent(),
    this.stimulusKind = const Value.absent(),
    this.stimulusText = const Value.absent(),
    this.status = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.submittedAt = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String skill,
    required String exerciseType,
    required String level,
    required String difficulty,
    this.topic = const Value.absent(),
    required String title,
    this.instructions = const Value.absent(),
    this.stimulusKind = const Value.absent(),
    this.stimulusText = const Value.absent(),
    required String status,
    this.totalScore = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.aiModel = const Value.absent(),
    required DateTime createdAt,
    this.submittedAt = const Value.absent(),
  }) : skill = Value(skill),
       exerciseType = Value(exerciseType),
       level = Value(level),
       difficulty = Value(difficulty),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? skill,
    Expression<String>? exerciseType,
    Expression<String>? level,
    Expression<String>? difficulty,
    Expression<String>? topic,
    Expression<String>? title,
    Expression<String>? instructions,
    Expression<String>? stimulusKind,
    Expression<String>? stimulusText,
    Expression<String>? status,
    Expression<int>? totalScore,
    Expression<int>? maxScore,
    Expression<int>? durationSeconds,
    Expression<String>? errorMessage,
    Expression<int>? schemaVersion,
    Expression<String>? promptVersion,
    Expression<String>? aiModel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? submittedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (skill != null) 'skill': skill,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (level != null) 'level': level,
      if (difficulty != null) 'difficulty': difficulty,
      if (topic != null) 'topic': topic,
      if (title != null) 'title': title,
      if (instructions != null) 'instructions': instructions,
      if (stimulusKind != null) 'stimulus_kind': stimulusKind,
      if (stimulusText != null) 'stimulus_text': stimulusText,
      if (status != null) 'status': status,
      if (totalScore != null) 'total_score': totalScore,
      if (maxScore != null) 'max_score': maxScore,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (errorMessage != null) 'error_message': errorMessage,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (aiModel != null) 'ai_model': aiModel,
      if (createdAt != null) 'created_at': createdAt,
      if (submittedAt != null) 'submitted_at': submittedAt,
    });
  }

  ExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? skill,
    Value<String>? exerciseType,
    Value<String>? level,
    Value<String>? difficulty,
    Value<String>? topic,
    Value<String>? title,
    Value<String>? instructions,
    Value<String>? stimulusKind,
    Value<String>? stimulusText,
    Value<String>? status,
    Value<int>? totalScore,
    Value<int>? maxScore,
    Value<int?>? durationSeconds,
    Value<String?>? errorMessage,
    Value<int>? schemaVersion,
    Value<String>? promptVersion,
    Value<String>? aiModel,
    Value<DateTime>? createdAt,
    Value<DateTime?>? submittedAt,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      skill: skill ?? this.skill,
      exerciseType: exerciseType ?? this.exerciseType,
      level: level ?? this.level,
      difficulty: difficulty ?? this.difficulty,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      stimulusKind: stimulusKind ?? this.stimulusKind,
      stimulusText: stimulusText ?? this.stimulusText,
      status: status ?? this.status,
      totalScore: totalScore ?? this.totalScore,
      maxScore: maxScore ?? this.maxScore,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      promptVersion: promptVersion ?? this.promptVersion,
      aiModel: aiModel ?? this.aiModel,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (skill.present) {
      map['skill'] = Variable<String>(skill.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(exerciseType.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (stimulusKind.present) {
      map['stimulus_kind'] = Variable<String>(stimulusKind.value);
    }
    if (stimulusText.present) {
      map['stimulus_text'] = Variable<String>(stimulusText.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<int>(totalScore.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<int>(maxScore.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<String>(promptVersion.value);
    }
    if (aiModel.present) {
      map['ai_model'] = Variable<String>(aiModel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('skill: $skill, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('level: $level, ')
          ..write('difficulty: $difficulty, ')
          ..write('topic: $topic, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('stimulusKind: $stimulusKind, ')
          ..write('stimulusText: $stimulusText, ')
          ..write('status: $status, ')
          ..write('totalScore: $totalScore, ')
          ..write('maxScore: $maxScore, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('aiModel: $aiModel, ')
          ..write('createdAt: $createdAt, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseQuestionsTable extends ExerciseQuestions
    with TableInfo<$ExerciseQuestionsTable, ExerciseQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseQuestionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionKeyMeta = const VerificationMeta(
    'questionKey',
  );
  @override
  late final GeneratedColumn<String> questionKey = GeneratedColumn<String>(
    'question_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionTypeMeta = const VerificationMeta(
    'questionType',
  );
  @override
  late final GeneratedColumn<String> questionType = GeneratedColumn<String>(
    'question_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextTextMeta = const VerificationMeta(
    'contextText',
  );
  @override
  late final GeneratedColumn<String> contextText = GeneratedColumn<String>(
    'context_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _answerKeyJsonMeta = const VerificationMeta(
    'answerKeyJson',
  );
  @override
  late final GeneratedColumn<String> answerKeyJson = GeneratedColumn<String>(
    'answer_key_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  static const VerificationMeta _rubricJsonMeta = const VerificationMeta(
    'rubricJson',
  );
  @override
  late final GeneratedColumn<String> rubricJson = GeneratedColumn<String>(
    'rubric_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    questionKey,
    orderIndex,
    questionType,
    prompt,
    contextText,
    optionsJson,
    answerKeyJson,
    points,
    explanation,
    rubricJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('question_key')) {
      context.handle(
        _questionKeyMeta,
        questionKey.isAcceptableOrUnknown(
          data['question_key']!,
          _questionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionKeyMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('question_type')) {
      context.handle(
        _questionTypeMeta,
        questionType.isAcceptableOrUnknown(
          data['question_type']!,
          _questionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTypeMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('context_text')) {
      context.handle(
        _contextTextMeta,
        contextText.isAcceptableOrUnknown(
          data['context_text']!,
          _contextTextMeta,
        ),
      );
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('answer_key_json')) {
      context.handle(
        _answerKeyJsonMeta,
        answerKeyJson.isAcceptableOrUnknown(
          data['answer_key_json']!,
          _answerKeyJsonMeta,
        ),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
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
    if (data.containsKey('rubric_json')) {
      context.handle(
        _rubricJsonMeta,
        rubricJson.isAcceptableOrUnknown(data['rubric_json']!, _rubricJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseQuestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      questionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_key'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      questionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_type'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      contextText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_text'],
      ),
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      answerKeyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_key_json'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      rubricJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rubric_json'],
      ),
    );
  }

  @override
  $ExerciseQuestionsTable createAlias(String alias) {
    return $ExerciseQuestionsTable(attachedDatabase, alias);
  }
}

class ExerciseQuestion extends DataClass
    implements Insertable<ExerciseQuestion> {
  final int id;

  /// 所属练习（删除练习时由 DAO 手工级联删除，与项目现有写法一致）
  final int exerciseId;

  /// 题目在练习内的稳定 key（AI 侧的 q1/q2…），用于把答题记录对回题目
  final String questionKey;

  /// 展示顺序（0 基）
  final int orderIndex;

  /// 题干类型：single_choice / multiple_choice / true_false / fill_blank
  /// / dictation / ordering / free_text
  final String questionType;
  final String prompt;

  /// 题目附带的上下文（如完形填空所在句子）
  final String? contextText;

  /// 选项列表（JSON 数组；非选择题为空数组）
  final String optionsJson;

  /// 标准答案 / 可接受答案（JSON，见 AnswerKey）
  final String answerKeyJson;
  final int points;

  /// 解析（结果页展示）
  final String explanation;

  /// 开放式题目的评分维度（JSON，见 Rubric）
  final String? rubricJson;
  const ExerciseQuestion({
    required this.id,
    required this.exerciseId,
    required this.questionKey,
    required this.orderIndex,
    required this.questionType,
    required this.prompt,
    this.contextText,
    required this.optionsJson,
    required this.answerKeyJson,
    required this.points,
    required this.explanation,
    this.rubricJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['question_key'] = Variable<String>(questionKey);
    map['order_index'] = Variable<int>(orderIndex);
    map['question_type'] = Variable<String>(questionType);
    map['prompt'] = Variable<String>(prompt);
    if (!nullToAbsent || contextText != null) {
      map['context_text'] = Variable<String>(contextText);
    }
    map['options_json'] = Variable<String>(optionsJson);
    map['answer_key_json'] = Variable<String>(answerKeyJson);
    map['points'] = Variable<int>(points);
    map['explanation'] = Variable<String>(explanation);
    if (!nullToAbsent || rubricJson != null) {
      map['rubric_json'] = Variable<String>(rubricJson);
    }
    return map;
  }

  ExerciseQuestionsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseQuestionsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      questionKey: Value(questionKey),
      orderIndex: Value(orderIndex),
      questionType: Value(questionType),
      prompt: Value(prompt),
      contextText: contextText == null && nullToAbsent
          ? const Value.absent()
          : Value(contextText),
      optionsJson: Value(optionsJson),
      answerKeyJson: Value(answerKeyJson),
      points: Value(points),
      explanation: Value(explanation),
      rubricJson: rubricJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rubricJson),
    );
  }

  factory ExerciseQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseQuestion(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      questionKey: serializer.fromJson<String>(json['questionKey']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      questionType: serializer.fromJson<String>(json['questionType']),
      prompt: serializer.fromJson<String>(json['prompt']),
      contextText: serializer.fromJson<String?>(json['contextText']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      answerKeyJson: serializer.fromJson<String>(json['answerKeyJson']),
      points: serializer.fromJson<int>(json['points']),
      explanation: serializer.fromJson<String>(json['explanation']),
      rubricJson: serializer.fromJson<String?>(json['rubricJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'questionKey': serializer.toJson<String>(questionKey),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'questionType': serializer.toJson<String>(questionType),
      'prompt': serializer.toJson<String>(prompt),
      'contextText': serializer.toJson<String?>(contextText),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'answerKeyJson': serializer.toJson<String>(answerKeyJson),
      'points': serializer.toJson<int>(points),
      'explanation': serializer.toJson<String>(explanation),
      'rubricJson': serializer.toJson<String?>(rubricJson),
    };
  }

  ExerciseQuestion copyWith({
    int? id,
    int? exerciseId,
    String? questionKey,
    int? orderIndex,
    String? questionType,
    String? prompt,
    Value<String?> contextText = const Value.absent(),
    String? optionsJson,
    String? answerKeyJson,
    int? points,
    String? explanation,
    Value<String?> rubricJson = const Value.absent(),
  }) => ExerciseQuestion(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    questionKey: questionKey ?? this.questionKey,
    orderIndex: orderIndex ?? this.orderIndex,
    questionType: questionType ?? this.questionType,
    prompt: prompt ?? this.prompt,
    contextText: contextText.present ? contextText.value : this.contextText,
    optionsJson: optionsJson ?? this.optionsJson,
    answerKeyJson: answerKeyJson ?? this.answerKeyJson,
    points: points ?? this.points,
    explanation: explanation ?? this.explanation,
    rubricJson: rubricJson.present ? rubricJson.value : this.rubricJson,
  );
  ExerciseQuestion copyWithCompanion(ExerciseQuestionsCompanion data) {
    return ExerciseQuestion(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      questionKey: data.questionKey.present
          ? data.questionKey.value
          : this.questionKey,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      questionType: data.questionType.present
          ? data.questionType.value
          : this.questionType,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      contextText: data.contextText.present
          ? data.contextText.value
          : this.contextText,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      answerKeyJson: data.answerKeyJson.present
          ? data.answerKeyJson.value
          : this.answerKeyJson,
      points: data.points.present ? data.points.value : this.points,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      rubricJson: data.rubricJson.present
          ? data.rubricJson.value
          : this.rubricJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseQuestion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('questionKey: $questionKey, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('questionType: $questionType, ')
          ..write('prompt: $prompt, ')
          ..write('contextText: $contextText, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('answerKeyJson: $answerKeyJson, ')
          ..write('points: $points, ')
          ..write('explanation: $explanation, ')
          ..write('rubricJson: $rubricJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    questionKey,
    orderIndex,
    questionType,
    prompt,
    contextText,
    optionsJson,
    answerKeyJson,
    points,
    explanation,
    rubricJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseQuestion &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.questionKey == this.questionKey &&
          other.orderIndex == this.orderIndex &&
          other.questionType == this.questionType &&
          other.prompt == this.prompt &&
          other.contextText == this.contextText &&
          other.optionsJson == this.optionsJson &&
          other.answerKeyJson == this.answerKeyJson &&
          other.points == this.points &&
          other.explanation == this.explanation &&
          other.rubricJson == this.rubricJson);
}

class ExerciseQuestionsCompanion extends UpdateCompanion<ExerciseQuestion> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<String> questionKey;
  final Value<int> orderIndex;
  final Value<String> questionType;
  final Value<String> prompt;
  final Value<String?> contextText;
  final Value<String> optionsJson;
  final Value<String> answerKeyJson;
  final Value<int> points;
  final Value<String> explanation;
  final Value<String?> rubricJson;
  const ExerciseQuestionsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.questionKey = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.questionType = const Value.absent(),
    this.prompt = const Value.absent(),
    this.contextText = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.answerKeyJson = const Value.absent(),
    this.points = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rubricJson = const Value.absent(),
  });
  ExerciseQuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required String questionKey,
    required int orderIndex,
    required String questionType,
    required String prompt,
    this.contextText = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.answerKeyJson = const Value.absent(),
    this.points = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rubricJson = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       questionKey = Value(questionKey),
       orderIndex = Value(orderIndex),
       questionType = Value(questionType),
       prompt = Value(prompt);
  static Insertable<ExerciseQuestion> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<String>? questionKey,
    Expression<int>? orderIndex,
    Expression<String>? questionType,
    Expression<String>? prompt,
    Expression<String>? contextText,
    Expression<String>? optionsJson,
    Expression<String>? answerKeyJson,
    Expression<int>? points,
    Expression<String>? explanation,
    Expression<String>? rubricJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (questionKey != null) 'question_key': questionKey,
      if (orderIndex != null) 'order_index': orderIndex,
      if (questionType != null) 'question_type': questionType,
      if (prompt != null) 'prompt': prompt,
      if (contextText != null) 'context_text': contextText,
      if (optionsJson != null) 'options_json': optionsJson,
      if (answerKeyJson != null) 'answer_key_json': answerKeyJson,
      if (points != null) 'points': points,
      if (explanation != null) 'explanation': explanation,
      if (rubricJson != null) 'rubric_json': rubricJson,
    });
  }

  ExerciseQuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<String>? questionKey,
    Value<int>? orderIndex,
    Value<String>? questionType,
    Value<String>? prompt,
    Value<String?>? contextText,
    Value<String>? optionsJson,
    Value<String>? answerKeyJson,
    Value<int>? points,
    Value<String>? explanation,
    Value<String?>? rubricJson,
  }) {
    return ExerciseQuestionsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      questionKey: questionKey ?? this.questionKey,
      orderIndex: orderIndex ?? this.orderIndex,
      questionType: questionType ?? this.questionType,
      prompt: prompt ?? this.prompt,
      contextText: contextText ?? this.contextText,
      optionsJson: optionsJson ?? this.optionsJson,
      answerKeyJson: answerKeyJson ?? this.answerKeyJson,
      points: points ?? this.points,
      explanation: explanation ?? this.explanation,
      rubricJson: rubricJson ?? this.rubricJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (questionKey.present) {
      map['question_key'] = Variable<String>(questionKey.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (questionType.present) {
      map['question_type'] = Variable<String>(questionType.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (contextText.present) {
      map['context_text'] = Variable<String>(contextText.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (answerKeyJson.present) {
      map['answer_key_json'] = Variable<String>(answerKeyJson.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (rubricJson.present) {
      map['rubric_json'] = Variable<String>(rubricJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('questionKey: $questionKey, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('questionType: $questionType, ')
          ..write('prompt: $prompt, ')
          ..write('contextText: $contextText, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('answerKeyJson: $answerKeyJson, ')
          ..write('points: $points, ')
          ..write('explanation: $explanation, ')
          ..write('rubricJson: $rubricJson')
          ..write(')'))
        .toString();
  }
}

class $ExerciseAttemptsTable extends ExerciseAttempts
    with TableInfo<$ExerciseAttemptsTable, ExerciseAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseAttemptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userAnswerMeta = const VerificationMeta(
    'userAnswer',
  );
  @override
  late final GeneratedColumn<String> userAnswer = GeneratedColumn<String>(
    'user_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<double> maxScore = GeneratedColumn<double>(
    'max_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPartialMeta = const VerificationMeta(
    'isPartial',
  );
  @override
  late final GeneratedColumn<bool> isPartial = GeneratedColumn<bool>(
    'is_partial',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_partial" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _graderTypeMeta = const VerificationMeta(
    'graderType',
  );
  @override
  late final GeneratedColumn<String> graderType = GeneratedColumn<String>(
    'grader_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('program'),
  );
  static const VerificationMeta _feedbackJsonMeta = const VerificationMeta(
    'feedbackJson',
  );
  @override
  late final GeneratedColumn<String> feedbackJson = GeneratedColumn<String>(
    'feedback_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    questionId,
    userAnswer,
    score,
    maxScore,
    isCorrect,
    isPartial,
    graderType,
    feedbackJson,
    submittedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('user_answer')) {
      context.handle(
        _userAnswerMeta,
        userAnswer.isAcceptableOrUnknown(data['user_answer']!, _userAnswerMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    }
    if (data.containsKey('is_partial')) {
      context.handle(
        _isPartialMeta,
        isPartial.isAcceptableOrUnknown(data['is_partial']!, _isPartialMeta),
      );
    }
    if (data.containsKey('grader_type')) {
      context.handle(
        _graderTypeMeta,
        graderType.isAcceptableOrUnknown(data['grader_type']!, _graderTypeMeta),
      );
    }
    if (data.containsKey('feedback_json')) {
      context.handle(
        _feedbackJsonMeta,
        feedbackJson.isAcceptableOrUnknown(
          data['feedback_json']!,
          _feedbackJsonMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submittedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_id'],
      )!,
      userAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_answer'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_score'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      isPartial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_partial'],
      )!,
      graderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grader_type'],
      )!,
      feedbackJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback_json'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      )!,
    );
  }

  @override
  $ExerciseAttemptsTable createAlias(String alias) {
    return $ExerciseAttemptsTable(attachedDatabase, alias);
  }
}

class ExerciseAttempt extends DataClass implements Insertable<ExerciseAttempt> {
  final int id;
  final int exerciseId;
  final int questionId;

  /// 用户原始答案（自由文本原样保存，不标准化）
  final String userAnswer;
  final double score;
  final double maxScore;
  final bool isCorrect;
  final bool isPartial;

  /// 判分方式：program / ai / unavailable（AI 失败，分数暂不可用）
  final String graderType;
  final String? feedbackJson;
  final DateTime submittedAt;
  const ExerciseAttempt({
    required this.id,
    required this.exerciseId,
    required this.questionId,
    required this.userAnswer,
    required this.score,
    required this.maxScore,
    required this.isCorrect,
    required this.isPartial,
    required this.graderType,
    this.feedbackJson,
    required this.submittedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['question_id'] = Variable<int>(questionId);
    map['user_answer'] = Variable<String>(userAnswer);
    map['score'] = Variable<double>(score);
    map['max_score'] = Variable<double>(maxScore);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['is_partial'] = Variable<bool>(isPartial);
    map['grader_type'] = Variable<String>(graderType);
    if (!nullToAbsent || feedbackJson != null) {
      map['feedback_json'] = Variable<String>(feedbackJson);
    }
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    return map;
  }

  ExerciseAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseAttemptsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      questionId: Value(questionId),
      userAnswer: Value(userAnswer),
      score: Value(score),
      maxScore: Value(maxScore),
      isCorrect: Value(isCorrect),
      isPartial: Value(isPartial),
      graderType: Value(graderType),
      feedbackJson: feedbackJson == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackJson),
      submittedAt: Value(submittedAt),
    );
  }

  factory ExerciseAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseAttempt(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      userAnswer: serializer.fromJson<String>(json['userAnswer']),
      score: serializer.fromJson<double>(json['score']),
      maxScore: serializer.fromJson<double>(json['maxScore']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      isPartial: serializer.fromJson<bool>(json['isPartial']),
      graderType: serializer.fromJson<String>(json['graderType']),
      feedbackJson: serializer.fromJson<String?>(json['feedbackJson']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'questionId': serializer.toJson<int>(questionId),
      'userAnswer': serializer.toJson<String>(userAnswer),
      'score': serializer.toJson<double>(score),
      'maxScore': serializer.toJson<double>(maxScore),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'isPartial': serializer.toJson<bool>(isPartial),
      'graderType': serializer.toJson<String>(graderType),
      'feedbackJson': serializer.toJson<String?>(feedbackJson),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
    };
  }

  ExerciseAttempt copyWith({
    int? id,
    int? exerciseId,
    int? questionId,
    String? userAnswer,
    double? score,
    double? maxScore,
    bool? isCorrect,
    bool? isPartial,
    String? graderType,
    Value<String?> feedbackJson = const Value.absent(),
    DateTime? submittedAt,
  }) => ExerciseAttempt(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    questionId: questionId ?? this.questionId,
    userAnswer: userAnswer ?? this.userAnswer,
    score: score ?? this.score,
    maxScore: maxScore ?? this.maxScore,
    isCorrect: isCorrect ?? this.isCorrect,
    isPartial: isPartial ?? this.isPartial,
    graderType: graderType ?? this.graderType,
    feedbackJson: feedbackJson.present ? feedbackJson.value : this.feedbackJson,
    submittedAt: submittedAt ?? this.submittedAt,
  );
  ExerciseAttempt copyWithCompanion(ExerciseAttemptsCompanion data) {
    return ExerciseAttempt(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      userAnswer: data.userAnswer.present
          ? data.userAnswer.value
          : this.userAnswer,
      score: data.score.present ? data.score.value : this.score,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      isPartial: data.isPartial.present ? data.isPartial.value : this.isPartial,
      graderType: data.graderType.present
          ? data.graderType.value
          : this.graderType,
      feedbackJson: data.feedbackJson.present
          ? data.feedbackJson.value
          : this.feedbackJson,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttempt(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('questionId: $questionId, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('isPartial: $isPartial, ')
          ..write('graderType: $graderType, ')
          ..write('feedbackJson: $feedbackJson, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    questionId,
    userAnswer,
    score,
    maxScore,
    isCorrect,
    isPartial,
    graderType,
    feedbackJson,
    submittedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseAttempt &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.questionId == this.questionId &&
          other.userAnswer == this.userAnswer &&
          other.score == this.score &&
          other.maxScore == this.maxScore &&
          other.isCorrect == this.isCorrect &&
          other.isPartial == this.isPartial &&
          other.graderType == this.graderType &&
          other.feedbackJson == this.feedbackJson &&
          other.submittedAt == this.submittedAt);
}

class ExerciseAttemptsCompanion extends UpdateCompanion<ExerciseAttempt> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<int> questionId;
  final Value<String> userAnswer;
  final Value<double> score;
  final Value<double> maxScore;
  final Value<bool> isCorrect;
  final Value<bool> isPartial;
  final Value<String> graderType;
  final Value<String?> feedbackJson;
  final Value<DateTime> submittedAt;
  const ExerciseAttemptsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.isPartial = const Value.absent(),
    this.graderType = const Value.absent(),
    this.feedbackJson = const Value.absent(),
    this.submittedAt = const Value.absent(),
  });
  ExerciseAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required int questionId,
    this.userAnswer = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.isPartial = const Value.absent(),
    this.graderType = const Value.absent(),
    this.feedbackJson = const Value.absent(),
    required DateTime submittedAt,
  }) : exerciseId = Value(exerciseId),
       questionId = Value(questionId),
       submittedAt = Value(submittedAt);
  static Insertable<ExerciseAttempt> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<int>? questionId,
    Expression<String>? userAnswer,
    Expression<double>? score,
    Expression<double>? maxScore,
    Expression<bool>? isCorrect,
    Expression<bool>? isPartial,
    Expression<String>? graderType,
    Expression<String>? feedbackJson,
    Expression<DateTime>? submittedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (questionId != null) 'question_id': questionId,
      if (userAnswer != null) 'user_answer': userAnswer,
      if (score != null) 'score': score,
      if (maxScore != null) 'max_score': maxScore,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (isPartial != null) 'is_partial': isPartial,
      if (graderType != null) 'grader_type': graderType,
      if (feedbackJson != null) 'feedback_json': feedbackJson,
      if (submittedAt != null) 'submitted_at': submittedAt,
    });
  }

  ExerciseAttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? exerciseId,
    Value<int>? questionId,
    Value<String>? userAnswer,
    Value<double>? score,
    Value<double>? maxScore,
    Value<bool>? isCorrect,
    Value<bool>? isPartial,
    Value<String>? graderType,
    Value<String?>? feedbackJson,
    Value<DateTime>? submittedAt,
  }) {
    return ExerciseAttemptsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      questionId: questionId ?? this.questionId,
      userAnswer: userAnswer ?? this.userAnswer,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      isCorrect: isCorrect ?? this.isCorrect,
      isPartial: isPartial ?? this.isPartial,
      graderType: graderType ?? this.graderType,
      feedbackJson: feedbackJson ?? this.feedbackJson,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (userAnswer.present) {
      map['user_answer'] = Variable<String>(userAnswer.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<double>(maxScore.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (isPartial.present) {
      map['is_partial'] = Variable<bool>(isPartial.value);
    }
    if (graderType.present) {
      map['grader_type'] = Variable<String>(graderType.value);
    }
    if (feedbackJson.present) {
      map['feedback_json'] = Variable<String>(feedbackJson.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('questionId: $questionId, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('isPartial: $isPartial, ')
          ..write('graderType: $graderType, ')
          ..write('feedbackJson: $feedbackJson, ')
          ..write('submittedAt: $submittedAt')
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
  late final $DeletionLogsTable deletionLogs = $DeletionLogsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $ExerciseQuestionsTable exerciseQuestions =
      $ExerciseQuestionsTable(this);
  late final $ExerciseAttemptsTable exerciseAttempts = $ExerciseAttemptsTable(
    this,
  );
  late final DeckDao deckDao = DeckDao(this as AppDatabase);
  late final WordDao wordDao = WordDao(this as AppDatabase);
  late final Sm2Dao sm2Dao = Sm2Dao(this as AppDatabase);
  late final ConjugationDao conjugationDao = ConjugationDao(
    this as AppDatabase,
  );
  late final AiCacheDao aiCacheDao = AiCacheDao(this as AppDatabase);
  late final AiStatusDao aiStatusDao = AiStatusDao(this as AppDatabase);
  late final StudyStatDao studyStatDao = StudyStatDao(this as AppDatabase);
  late final ExerciseDao exerciseDao = ExerciseDao(this as AppDatabase);
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
    deletionLogs,
    exercises,
    exerciseQuestions,
    exerciseAttempts,
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

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordsTable, List<Word>> _wordsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.words,
    aliasName: 'decks__id__words__deck_id',
  );

  $$WordsTableProcessedTableManager get wordsRefs {
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  Expression<bool> wordsRefs(
    Expression<bool> Function($$WordsTableFilterComposer f) f,
  ) {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  Expression<T> wordsRefs<T extends Object>(
    Expression<T> Function($$WordsTableAnnotationComposer a) f,
  ) {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Deck, $$DecksTableReferences),
          Deck,
          PrefetchHooks Function({bool wordsRefs})
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
              .map(
                (e) => (
                  e.readTable<$DecksTable, Deck>(table),
                  $$DecksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wordsRefs) db.words],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordsRefs)
                    await $_getPrefetchedDataByColumns<
                      Deck,
                      $DecksTable,
                      Word,
                      $WordsTable
                    >(
                      currentTable: table,
                      referencedTable: $$DecksTableReferences._wordsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$DecksTableReferences(db, table, p0).wordsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'deck_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (Deck, $$DecksTableReferences),
      Deck,
      PrefetchHooks Function({bool wordsRefs})
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

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias('words__deck_id__decks__id');

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<int>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$Sm2StatesTable, List<Sm2State>>
  _sm2StatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sm2States,
    aliasName: 'words__id__sm2_states__word_id',
  );

  $$Sm2StatesTableProcessedTableManager get sm2StatesRefs {
    final manager = $$Sm2StatesTableTableManager(
      $_db,
      $_db.sm2States,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sm2StatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConjugationCacheTable, List<ConjugationCacheData>>
  _conjugationCacheRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.conjugationCache,
    aliasName: 'words__id__conjugation_cache__word_id',
  );

  $$ConjugationCacheTableProcessedTableManager get conjugationCacheRefs {
    final manager = $$ConjugationCacheTableTableManager(
      $_db,
      $_db.conjugationCache,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _conjugationCacheRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StudyStatsTable, List<StudyStat>>
  _studyStatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.studyStats,
    aliasName: 'words__id__study_stats__word_id',
  );

  $$StudyStatsTableProcessedTableManager get studyStatsRefs {
    final manager = $$StudyStatsTableTableManager(
      $_db,
      $_db.studyStats,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_studyStatsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sm2StatesRefs(
    Expression<bool> Function($$Sm2StatesTableFilterComposer f) f,
  ) {
    final $$Sm2StatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sm2States,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$Sm2StatesTableFilterComposer(
            $db: $db,
            $table: $db.sm2States,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conjugationCacheRefs(
    Expression<bool> Function($$ConjugationCacheTableFilterComposer f) f,
  ) {
    final $$ConjugationCacheTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conjugationCache,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConjugationCacheTableFilterComposer(
            $db: $db,
            $table: $db.conjugationCache,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> studyStatsRefs(
    Expression<bool> Function($$StudyStatsTableFilterComposer f) f,
  ) {
    final $$StudyStatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studyStats,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyStatsTableFilterComposer(
            $db: $db,
            $table: $db.studyStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sm2StatesRefs<T extends Object>(
    Expression<T> Function($$Sm2StatesTableAnnotationComposer a) f,
  ) {
    final $$Sm2StatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sm2States,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$Sm2StatesTableAnnotationComposer(
            $db: $db,
            $table: $db.sm2States,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conjugationCacheRefs<T extends Object>(
    Expression<T> Function($$ConjugationCacheTableAnnotationComposer a) f,
  ) {
    final $$ConjugationCacheTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.conjugationCache,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConjugationCacheTableAnnotationComposer(
            $db: $db,
            $table: $db.conjugationCache,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> studyStatsRefs<T extends Object>(
    Expression<T> Function($$StudyStatsTableAnnotationComposer a) f,
  ) {
    final $$StudyStatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studyStats,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyStatsTableAnnotationComposer(
            $db: $db,
            $table: $db.studyStats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool deckId,
            bool sm2StatesRefs,
            bool conjugationCacheRefs,
            bool studyStatsRefs,
          })
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
              .map(
                (e) => (
                  e.readTable<$WordsTable, Word>(table),
                  $$WordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                deckId = false,
                sm2StatesRefs = false,
                conjugationCacheRefs = false,
                studyStatsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sm2StatesRefs) db.sm2States,
                    if (conjugationCacheRefs) db.conjugationCache,
                    if (studyStatsRefs) db.studyStats,
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
                        if (deckId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deckId,
                                    referencedTable: $$WordsTableReferences
                                        ._deckIdTable(db),
                                    referencedColumn: $$WordsTableReferences
                                        ._deckIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sm2StatesRefs)
                        await $_getPrefetchedDataByColumns<
                          Word,
                          $WordsTable,
                          Sm2State,
                          $Sm2StatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._sm2StatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).sm2StatesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'word_id',
                          typedResults: items,
                        ),
                      if (conjugationCacheRefs)
                        await $_getPrefetchedDataByColumns<
                          Word,
                          $WordsTable,
                          ConjugationCacheData,
                          $ConjugationCacheTable
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._conjugationCacheRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).conjugationCacheRefs,
                          currentColumn: 'id',
                          referencedColumn: 'word_id',
                          typedResults: items,
                        ),
                      if (studyStatsRefs)
                        await $_getPrefetchedDataByColumns<
                          Word,
                          $WordsTable,
                          StudyStat,
                          $StudyStatsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._studyStatsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).studyStatsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'word_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({
        bool deckId,
        bool sm2StatesRefs,
        bool conjugationCacheRefs,
        bool studyStatsRefs,
      })
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

final class $$Sm2StatesTableReferences
    extends BaseReferences<_$AppDatabase, $Sm2StatesTable, Sm2State> {
  $$Sm2StatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('sm2_states__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (Sm2State, $$Sm2StatesTableReferences),
          Sm2State,
          PrefetchHooks Function({bool wordId})
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
              .map(
                (e) => (
                  e.readTable<$Sm2StatesTable, Sm2State>(table),
                  $$Sm2StatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
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
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$Sm2StatesTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$Sm2StatesTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
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
      (Sm2State, $$Sm2StatesTableReferences),
      Sm2State,
      PrefetchHooks Function({bool wordId})
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

final class $$ConjugationCacheTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConjugationCacheTable,
          ConjugationCacheData
        > {
  $$ConjugationCacheTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('conjugation_cache__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (ConjugationCacheData, $$ConjugationCacheTableReferences),
          ConjugationCacheData,
          PrefetchHooks Function({bool wordId})
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
              .map(
                (e) => (
                  e.readTable<$ConjugationCacheTable, ConjugationCacheData>(
                    table,
                  ),
                  $$ConjugationCacheTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
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
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable:
                                    $$ConjugationCacheTableReferences
                                        ._wordIdTable(db),
                                referencedColumn:
                                    $$ConjugationCacheTableReferences
                                        ._wordIdTable(db)
                                        .id,
                              )
                              as T;
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
      (ConjugationCacheData, $$ConjugationCacheTableReferences),
      ConjugationCacheData,
      PrefetchHooks Function({bool wordId})
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
              .map(
                (e) => (
                  e.readTable<$AiLookupCacheTable, AiLookupCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AiLookupCacheTable,
                    AiLookupCacheData
                  >(db, table, e),
                ),
              )
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
              .map(
                (e) => (
                  e.readTable<$AiRequestStatusTable, AiRequestStatusData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $AiRequestStatusTable,
                    AiRequestStatusData
                  >(db, table, e),
                ),
              )
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
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
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

final class $$StudyStatsTableReferences
    extends BaseReferences<_$AppDatabase, $StudyStatsTable, StudyStat> {
  $$StudyStatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('study_stats__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get appearances => $composableBuilder(
    column: $table.appearances,
    builder: (column) => column,
  );

  GeneratedColumn<int> get errors =>
      $composableBuilder(column: $table.errors, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (StudyStat, $$StudyStatsTableReferences),
          StudyStat,
          PrefetchHooks Function({bool wordId})
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
              .map(
                (e) => (
                  e.readTable<$StudyStatsTable, StudyStat>(table),
                  $$StudyStatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
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
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$StudyStatsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$StudyStatsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
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
      (StudyStat, $$StudyStatsTableReferences),
      StudyStat,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$DeletionLogsTableCreateCompanionBuilder =
    DeletionLogsCompanion Function({
      Value<int> id,
      required String deckName,
      Value<String> german,
      required DateTime deletedAt,
    });
typedef $$DeletionLogsTableUpdateCompanionBuilder =
    DeletionLogsCompanion Function({
      Value<int> id,
      Value<String> deckName,
      Value<String> german,
      Value<DateTime> deletedAt,
    });

class $$DeletionLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DeletionLogsTable> {
  $$DeletionLogsTableFilterComposer({
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

  ColumnFilters<String> get deckName => $composableBuilder(
    column: $table.deckName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get german => $composableBuilder(
    column: $table.german,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletionLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeletionLogsTable> {
  $$DeletionLogsTableOrderingComposer({
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

  ColumnOrderings<String> get deckName => $composableBuilder(
    column: $table.deckName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get german => $composableBuilder(
    column: $table.german,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletionLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeletionLogsTable> {
  $$DeletionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckName =>
      $composableBuilder(column: $table.deckName, builder: (column) => column);

  GeneratedColumn<String> get german =>
      $composableBuilder(column: $table.german, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletionLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeletionLogsTable,
          DeletionLog,
          $$DeletionLogsTableFilterComposer,
          $$DeletionLogsTableOrderingComposer,
          $$DeletionLogsTableAnnotationComposer,
          $$DeletionLogsTableCreateCompanionBuilder,
          $$DeletionLogsTableUpdateCompanionBuilder,
          (
            DeletionLog,
            BaseReferences<_$AppDatabase, $DeletionLogsTable, DeletionLog>,
          ),
          DeletionLog,
          PrefetchHooks Function()
        > {
  $$DeletionLogsTableTableManager(_$AppDatabase db, $DeletionLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deckName = const Value.absent(),
                Value<String> german = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
              }) => DeletionLogsCompanion(
                id: id,
                deckName: deckName,
                german: german,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deckName,
                Value<String> german = const Value.absent(),
                required DateTime deletedAt,
              }) => DeletionLogsCompanion.insert(
                id: id,
                deckName: deckName,
                german: german,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeletionLogsTable, DeletionLog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DeletionLogsTable,
                    DeletionLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletionLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeletionLogsTable,
      DeletionLog,
      $$DeletionLogsTableFilterComposer,
      $$DeletionLogsTableOrderingComposer,
      $$DeletionLogsTableAnnotationComposer,
      $$DeletionLogsTableCreateCompanionBuilder,
      $$DeletionLogsTableUpdateCompanionBuilder,
      (
        DeletionLog,
        BaseReferences<_$AppDatabase, $DeletionLogsTable, DeletionLog>,
      ),
      DeletionLog,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      required String skill,
      required String exerciseType,
      required String level,
      required String difficulty,
      Value<String> topic,
      required String title,
      Value<String> instructions,
      Value<String> stimulusKind,
      Value<String> stimulusText,
      required String status,
      Value<int> totalScore,
      Value<int> maxScore,
      Value<int?> durationSeconds,
      Value<String?> errorMessage,
      Value<int> schemaVersion,
      Value<String> promptVersion,
      Value<String> aiModel,
      required DateTime createdAt,
      Value<DateTime?> submittedAt,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<int> id,
      Value<String> skill,
      Value<String> exerciseType,
      Value<String> level,
      Value<String> difficulty,
      Value<String> topic,
      Value<String> title,
      Value<String> instructions,
      Value<String> stimulusKind,
      Value<String> stimulusText,
      Value<String> status,
      Value<int> totalScore,
      Value<int> maxScore,
      Value<int?> durationSeconds,
      Value<String?> errorMessage,
      Value<int> schemaVersion,
      Value<String> promptVersion,
      Value<String> aiModel,
      Value<DateTime> createdAt,
      Value<DateTime?> submittedAt,
    });

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
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

  ColumnFilters<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stimulusKind => $composableBuilder(
    column: $table.stimulusKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stimulusText => $composableBuilder(
    column: $table.stimulusText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiModel => $composableBuilder(
    column: $table.aiModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
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

  ColumnOrderings<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stimulusKind => $composableBuilder(
    column: $table.stimulusKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stimulusText => $composableBuilder(
    column: $table.stimulusText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiModel => $composableBuilder(
    column: $table.aiModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get skill =>
      $composableBuilder(column: $table.skill, builder: (column) => column);

  GeneratedColumn<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stimulusKind => $composableBuilder(
    column: $table.stimulusKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stimulusText => $composableBuilder(
    column: $table.stimulusText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiModel =>
      $composableBuilder(column: $table.aiModel, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> skill = const Value.absent(),
                Value<String> exerciseType = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String> stimulusKind = const Value.absent(),
                Value<String> stimulusText = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> maxScore = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> promptVersion = const Value.absent(),
                Value<String> aiModel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                skill: skill,
                exerciseType: exerciseType,
                level: level,
                difficulty: difficulty,
                topic: topic,
                title: title,
                instructions: instructions,
                stimulusKind: stimulusKind,
                stimulusText: stimulusText,
                status: status,
                totalScore: totalScore,
                maxScore: maxScore,
                durationSeconds: durationSeconds,
                errorMessage: errorMessage,
                schemaVersion: schemaVersion,
                promptVersion: promptVersion,
                aiModel: aiModel,
                createdAt: createdAt,
                submittedAt: submittedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String skill,
                required String exerciseType,
                required String level,
                required String difficulty,
                Value<String> topic = const Value.absent(),
                required String title,
                Value<String> instructions = const Value.absent(),
                Value<String> stimulusKind = const Value.absent(),
                Value<String> stimulusText = const Value.absent(),
                required String status,
                Value<int> totalScore = const Value.absent(),
                Value<int> maxScore = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> promptVersion = const Value.absent(),
                Value<String> aiModel = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> submittedAt = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                skill: skill,
                exerciseType: exerciseType,
                level: level,
                difficulty: difficulty,
                topic: topic,
                title: title,
                instructions: instructions,
                stimulusKind: stimulusKind,
                stimulusText: stimulusText,
                status: status,
                totalScore: totalScore,
                maxScore: maxScore,
                durationSeconds: durationSeconds,
                errorMessage: errorMessage,
                schemaVersion: schemaVersion,
                promptVersion: promptVersion,
                aiModel: aiModel,
                createdAt: createdAt,
                submittedAt: submittedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$ExerciseQuestionsTableCreateCompanionBuilder =
    ExerciseQuestionsCompanion Function({
      Value<int> id,
      required int exerciseId,
      required String questionKey,
      required int orderIndex,
      required String questionType,
      required String prompt,
      Value<String?> contextText,
      Value<String> optionsJson,
      Value<String> answerKeyJson,
      Value<int> points,
      Value<String> explanation,
      Value<String?> rubricJson,
    });
typedef $$ExerciseQuestionsTableUpdateCompanionBuilder =
    ExerciseQuestionsCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<String> questionKey,
      Value<int> orderIndex,
      Value<String> questionType,
      Value<String> prompt,
      Value<String?> contextText,
      Value<String> optionsJson,
      Value<String> answerKeyJson,
      Value<int> points,
      Value<String> explanation,
      Value<String?> rubricJson,
    });

class $$ExerciseQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseQuestionsTable> {
  $$ExerciseQuestionsTableFilterComposer({
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

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionKey => $composableBuilder(
    column: $table.questionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextText => $composableBuilder(
    column: $table.contextText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerKeyJson => $composableBuilder(
    column: $table.answerKeyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rubricJson => $composableBuilder(
    column: $table.rubricJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseQuestionsTable> {
  $$ExerciseQuestionsTableOrderingComposer({
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

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionKey => $composableBuilder(
    column: $table.questionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextText => $composableBuilder(
    column: $table.contextText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerKeyJson => $composableBuilder(
    column: $table.answerKeyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rubricJson => $composableBuilder(
    column: $table.rubricJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseQuestionsTable> {
  $$ExerciseQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionKey => $composableBuilder(
    column: $table.questionKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionType => $composableBuilder(
    column: $table.questionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get contextText => $composableBuilder(
    column: $table.contextText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerKeyJson => $composableBuilder(
    column: $table.answerKeyJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rubricJson => $composableBuilder(
    column: $table.rubricJson,
    builder: (column) => column,
  );
}

class $$ExerciseQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseQuestionsTable,
          ExerciseQuestion,
          $$ExerciseQuestionsTableFilterComposer,
          $$ExerciseQuestionsTableOrderingComposer,
          $$ExerciseQuestionsTableAnnotationComposer,
          $$ExerciseQuestionsTableCreateCompanionBuilder,
          $$ExerciseQuestionsTableUpdateCompanionBuilder,
          (
            ExerciseQuestion,
            BaseReferences<
              _$AppDatabase,
              $ExerciseQuestionsTable,
              ExerciseQuestion
            >,
          ),
          ExerciseQuestion,
          PrefetchHooks Function()
        > {
  $$ExerciseQuestionsTableTableManager(
    _$AppDatabase db,
    $ExerciseQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseQuestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<String> questionKey = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> questionType = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String?> contextText = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> answerKeyJson = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String?> rubricJson = const Value.absent(),
              }) => ExerciseQuestionsCompanion(
                id: id,
                exerciseId: exerciseId,
                questionKey: questionKey,
                orderIndex: orderIndex,
                questionType: questionType,
                prompt: prompt,
                contextText: contextText,
                optionsJson: optionsJson,
                answerKeyJson: answerKeyJson,
                points: points,
                explanation: explanation,
                rubricJson: rubricJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required String questionKey,
                required int orderIndex,
                required String questionType,
                required String prompt,
                Value<String?> contextText = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> answerKeyJson = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String?> rubricJson = const Value.absent(),
              }) => ExerciseQuestionsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                questionKey: questionKey,
                orderIndex: orderIndex,
                questionType: questionType,
                prompt: prompt,
                contextText: contextText,
                optionsJson: optionsJson,
                answerKeyJson: answerKeyJson,
                points: points,
                explanation: explanation,
                rubricJson: rubricJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseQuestionsTable, ExerciseQuestion>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseQuestionsTable,
                    ExerciseQuestion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseQuestionsTable,
      ExerciseQuestion,
      $$ExerciseQuestionsTableFilterComposer,
      $$ExerciseQuestionsTableOrderingComposer,
      $$ExerciseQuestionsTableAnnotationComposer,
      $$ExerciseQuestionsTableCreateCompanionBuilder,
      $$ExerciseQuestionsTableUpdateCompanionBuilder,
      (
        ExerciseQuestion,
        BaseReferences<
          _$AppDatabase,
          $ExerciseQuestionsTable,
          ExerciseQuestion
        >,
      ),
      ExerciseQuestion,
      PrefetchHooks Function()
    >;
typedef $$ExerciseAttemptsTableCreateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<int> id,
      required int exerciseId,
      required int questionId,
      Value<String> userAnswer,
      Value<double> score,
      Value<double> maxScore,
      Value<bool> isCorrect,
      Value<bool> isPartial,
      Value<String> graderType,
      Value<String?> feedbackJson,
      required DateTime submittedAt,
    });
typedef $$ExerciseAttemptsTableUpdateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<int> id,
      Value<int> exerciseId,
      Value<int> questionId,
      Value<String> userAnswer,
      Value<double> score,
      Value<double> maxScore,
      Value<bool> isCorrect,
      Value<bool> isPartial,
      Value<String> graderType,
      Value<String?> feedbackJson,
      Value<DateTime> submittedAt,
    });

class $$ExerciseAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableFilterComposer({
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

  ColumnFilters<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPartial => $composableBuilder(
    column: $table.isPartial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get graderType => $composableBuilder(
    column: $table.graderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedbackJson => $composableBuilder(
    column: $table.feedbackJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableOrderingComposer({
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

  ColumnOrderings<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPartial => $composableBuilder(
    column: $table.isPartial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get graderType => $composableBuilder(
    column: $table.graderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedbackJson => $composableBuilder(
    column: $table.feedbackJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<bool> get isPartial =>
      $composableBuilder(column: $table.isPartial, builder: (column) => column);

  GeneratedColumn<String> get graderType => $composableBuilder(
    column: $table.graderType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedbackJson => $composableBuilder(
    column: $table.feedbackJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );
}

class $$ExerciseAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseAttemptsTable,
          ExerciseAttempt,
          $$ExerciseAttemptsTableFilterComposer,
          $$ExerciseAttemptsTableOrderingComposer,
          $$ExerciseAttemptsTableAnnotationComposer,
          $$ExerciseAttemptsTableCreateCompanionBuilder,
          $$ExerciseAttemptsTableUpdateCompanionBuilder,
          (
            ExerciseAttempt,
            BaseReferences<
              _$AppDatabase,
              $ExerciseAttemptsTable,
              ExerciseAttempt
            >,
          ),
          ExerciseAttempt,
          PrefetchHooks Function()
        > {
  $$ExerciseAttemptsTableTableManager(
    _$AppDatabase db,
    $ExerciseAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> exerciseId = const Value.absent(),
                Value<int> questionId = const Value.absent(),
                Value<String> userAnswer = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> maxScore = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<bool> isPartial = const Value.absent(),
                Value<String> graderType = const Value.absent(),
                Value<String?> feedbackJson = const Value.absent(),
                Value<DateTime> submittedAt = const Value.absent(),
              }) => ExerciseAttemptsCompanion(
                id: id,
                exerciseId: exerciseId,
                questionId: questionId,
                userAnswer: userAnswer,
                score: score,
                maxScore: maxScore,
                isCorrect: isCorrect,
                isPartial: isPartial,
                graderType: graderType,
                feedbackJson: feedbackJson,
                submittedAt: submittedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int exerciseId,
                required int questionId,
                Value<String> userAnswer = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> maxScore = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<bool> isPartial = const Value.absent(),
                Value<String> graderType = const Value.absent(),
                Value<String?> feedbackJson = const Value.absent(),
                required DateTime submittedAt,
              }) => ExerciseAttemptsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                questionId: questionId,
                userAnswer: userAnswer,
                score: score,
                maxScore: maxScore,
                isCorrect: isCorrect,
                isPartial: isPartial,
                graderType: graderType,
                feedbackJson: feedbackJson,
                submittedAt: submittedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseAttemptsTable, ExerciseAttempt>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseAttemptsTable,
                    ExerciseAttempt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseAttemptsTable,
      ExerciseAttempt,
      $$ExerciseAttemptsTableFilterComposer,
      $$ExerciseAttemptsTableOrderingComposer,
      $$ExerciseAttemptsTableAnnotationComposer,
      $$ExerciseAttemptsTableCreateCompanionBuilder,
      $$ExerciseAttemptsTableUpdateCompanionBuilder,
      (
        ExerciseAttempt,
        BaseReferences<_$AppDatabase, $ExerciseAttemptsTable, ExerciseAttempt>,
      ),
      ExerciseAttempt,
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
  $$DeletionLogsTableTableManager get deletionLogs =>
      $$DeletionLogsTableTableManager(_db, _db.deletionLogs);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$ExerciseQuestionsTableTableManager get exerciseQuestions =>
      $$ExerciseQuestionsTableTableManager(_db, _db.exerciseQuestions);
  $$ExerciseAttemptsTableTableManager get exerciseAttempts =>
      $$ExerciseAttemptsTableTableManager(_db, _db.exerciseAttempts);
}
