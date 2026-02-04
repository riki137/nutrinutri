// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatsMeta = const VerificationMeta('fats');
  @override
  late final GeneratedColumn<double> fats = GeneratedColumn<double>(
    'fats',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
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
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    calories,
    protein,
    carbs,
    fats,
    timestamp,
    normalizedName,
    imagePath,
    icon,
    status,
    description,
    durationMinutes,
    updatedAt,
    updatedBy,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryEntryRow> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fats')) {
      context.handle(
        _fatsMeta,
        fats.isAcceptableOrUnknown(data['fats']!, _fatsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
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
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      )!,
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs'],
      )!,
      fats: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fats'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }
}

class DiaryEntryRow extends DataClass implements Insertable<DiaryEntryRow> {
  final String id;
  final String name;
  final int type;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final int timestamp;
  final String normalizedName;
  final String? imagePath;
  final String? icon;
  final int status;
  final String? description;
  final int? durationMinutes;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const DiaryEntryRow({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.timestamp,
    required this.normalizedName,
    this.imagePath,
    this.icon,
    required this.status,
    this.description,
    this.durationMinutes,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<int>(type);
    map['calories'] = Variable<int>(calories);
    map['protein'] = Variable<double>(protein);
    map['carbs'] = Variable<double>(carbs);
    map['fats'] = Variable<double>(fats);
    map['timestamp'] = Variable<int>(timestamp);
    map['normalized_name'] = Variable<String>(normalizedName);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      calories: Value(calories),
      protein: Value(protein),
      carbs: Value(carbs),
      fats: Value(fats),
      timestamp: Value(timestamp),
      normalizedName: Value(normalizedName),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      status: Value(status),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DiaryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<int>(json['type']),
      calories: serializer.fromJson<int>(json['calories']),
      protein: serializer.fromJson<double>(json['protein']),
      carbs: serializer.fromJson<double>(json['carbs']),
      fats: serializer.fromJson<double>(json['fats']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      icon: serializer.fromJson<String?>(json['icon']),
      status: serializer.fromJson<int>(json['status']),
      description: serializer.fromJson<String?>(json['description']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(type),
      'calories': serializer.toJson<int>(calories),
      'protein': serializer.toJson<double>(protein),
      'carbs': serializer.toJson<double>(carbs),
      'fats': serializer.toJson<double>(fats),
      'timestamp': serializer.toJson<int>(timestamp),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'imagePath': serializer.toJson<String?>(imagePath),
      'icon': serializer.toJson<String?>(icon),
      'status': serializer.toJson<int>(status),
      'description': serializer.toJson<String?>(description),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  DiaryEntryRow copyWith({
    String? id,
    String? name,
    int? type,
    int? calories,
    double? protein,
    double? carbs,
    double? fats,
    int? timestamp,
    String? normalizedName,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    int? status,
    Value<String?> description = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => DiaryEntryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fats: fats ?? this.fats,
    timestamp: timestamp ?? this.timestamp,
    normalizedName: normalizedName ?? this.normalizedName,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    icon: icon.present ? icon.value : this.icon,
    status: status ?? this.status,
    description: description.present ? description.value : this.description,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DiaryEntryRow copyWithCompanion(DiaryEntriesCompanion data) {
    return DiaryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      calories: data.calories.present ? data.calories.value : this.calories,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fats: data.fats.present ? data.fats.value : this.fats,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      icon: data.icon.present ? data.icon.value : this.icon,
      status: data.status.present ? data.status.value : this.status,
      description: data.description.present
          ? data.description.value
          : this.description,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fats: $fats, ')
          ..write('timestamp: $timestamp, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('imagePath: $imagePath, ')
          ..write('icon: $icon, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    calories,
    protein,
    carbs,
    fats,
    timestamp,
    normalizedName,
    imagePath,
    icon,
    status,
    description,
    durationMinutes,
    updatedAt,
    updatedBy,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.calories == this.calories &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fats == this.fats &&
          other.timestamp == this.timestamp &&
          other.normalizedName == this.normalizedName &&
          other.imagePath == this.imagePath &&
          other.icon == this.icon &&
          other.status == this.status &&
          other.description == this.description &&
          other.durationMinutes == this.durationMinutes &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> type;
  final Value<int> calories;
  final Value<double> protein;
  final Value<double> carbs;
  final Value<double> fats;
  final Value<int> timestamp;
  final Value<String> normalizedName;
  final Value<String?> imagePath;
  final Value<String?> icon;
  final Value<int> status;
  final Value<String?> description;
  final Value<int?> durationMinutes;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fats = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.icon = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    required String id,
    required String name,
    required int type,
    required int calories,
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fats = const Value.absent(),
    required int timestamp,
    required String normalizedName,
    this.imagePath = const Value.absent(),
    this.icon = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       calories = Value(calories),
       timestamp = Value(timestamp),
       normalizedName = Value(normalizedName);
  static Insertable<DiaryEntryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? calories,
    Expression<double>? protein,
    Expression<double>? carbs,
    Expression<double>? fats,
    Expression<int>? timestamp,
    Expression<String>? normalizedName,
    Expression<String>? imagePath,
    Expression<String>? icon,
    Expression<int>? status,
    Expression<String>? description,
    Expression<int>? durationMinutes,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
      if (timestamp != null) 'timestamp': timestamp,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (imagePath != null) 'image_path': imagePath,
      if (icon != null) 'icon': icon,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiaryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? type,
    Value<int>? calories,
    Value<double>? protein,
    Value<double>? carbs,
    Value<double>? fats,
    Value<int>? timestamp,
    Value<String>? normalizedName,
    Value<String?>? imagePath,
    Value<String?>? icon,
    Value<int>? status,
    Value<String?>? description,
    Value<int?>? durationMinutes,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return DiaryEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      timestamp: timestamp ?? this.timestamp,
      normalizedName: normalizedName ?? this.normalizedName,
      imagePath: imagePath ?? this.imagePath,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (fats.present) {
      map['fats'] = Variable<double>(fats.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fats: $fats, ')
          ..write('timestamp: $timestamp, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('imagePath: $imagePath, ')
          ..write('icon: $icon, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityLevelMeta = const VerificationMeta(
    'activityLevel',
  );
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalCaloriesMeta = const VerificationMeta(
    'goalCalories',
  );
  @override
  late final GeneratedColumn<int> goalCalories = GeneratedColumn<int>(
    'goal_calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalProteinMeta = const VerificationMeta(
    'goalProtein',
  );
  @override
  late final GeneratedColumn<int> goalProtein = GeneratedColumn<int>(
    'goal_protein',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalCarbsMeta = const VerificationMeta(
    'goalCarbs',
  );
  @override
  late final GeneratedColumn<int> goalCarbs = GeneratedColumn<int>(
    'goal_carbs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalFatMeta = const VerificationMeta(
    'goalFat',
  );
  @override
  late final GeneratedColumn<int> goalFat = GeneratedColumn<int>(
    'goal_fat',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isConfiguredMeta = const VerificationMeta(
    'isConfigured',
  );
  @override
  late final GeneratedColumn<bool> isConfigured = GeneratedColumn<bool>(
    'is_configured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_configured" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
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
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    age,
    weightKg,
    heightCm,
    gender,
    activityLevel,
    goalCalories,
    goalProtein,
    goalCarbs,
    goalFat,
    isConfigured,
    updatedAt,
    updatedBy,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('activity_level')) {
      context.handle(
        _activityLevelMeta,
        activityLevel.isAcceptableOrUnknown(
          data['activity_level']!,
          _activityLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityLevelMeta);
    }
    if (data.containsKey('goal_calories')) {
      context.handle(
        _goalCaloriesMeta,
        goalCalories.isAcceptableOrUnknown(
          data['goal_calories']!,
          _goalCaloriesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_goalCaloriesMeta);
    }
    if (data.containsKey('goal_protein')) {
      context.handle(
        _goalProteinMeta,
        goalProtein.isAcceptableOrUnknown(
          data['goal_protein']!,
          _goalProteinMeta,
        ),
      );
    }
    if (data.containsKey('goal_carbs')) {
      context.handle(
        _goalCarbsMeta,
        goalCarbs.isAcceptableOrUnknown(data['goal_carbs']!, _goalCarbsMeta),
      );
    }
    if (data.containsKey('goal_fat')) {
      context.handle(
        _goalFatMeta,
        goalFat.isAcceptableOrUnknown(data['goal_fat']!, _goalFatMeta),
      );
    }
    if (data.containsKey('is_configured')) {
      context.handle(
        _isConfiguredMeta,
        isConfigured.isAcceptableOrUnknown(
          data['is_configured']!,
          _isConfiguredMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      activityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_level'],
      )!,
      goalCalories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_calories'],
      )!,
      goalProtein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_protein'],
      ),
      goalCarbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_carbs'],
      ),
      goalFat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_fat'],
      ),
      isConfigured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_configured'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final int age;
  final double weightKg;
  final double heightCm;
  final String gender;
  final String activityLevel;
  final int goalCalories;
  final int? goalProtein;
  final int? goalCarbs;
  final int? goalFat;
  final bool isConfigured;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const UserProfileRow({
    required this.id,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.goalCalories,
    this.goalProtein,
    this.goalCarbs,
    this.goalFat,
    required this.isConfigured,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['age'] = Variable<int>(age);
    map['weight_kg'] = Variable<double>(weightKg);
    map['height_cm'] = Variable<double>(heightCm);
    map['gender'] = Variable<String>(gender);
    map['activity_level'] = Variable<String>(activityLevel);
    map['goal_calories'] = Variable<int>(goalCalories);
    if (!nullToAbsent || goalProtein != null) {
      map['goal_protein'] = Variable<int>(goalProtein);
    }
    if (!nullToAbsent || goalCarbs != null) {
      map['goal_carbs'] = Variable<int>(goalCarbs);
    }
    if (!nullToAbsent || goalFat != null) {
      map['goal_fat'] = Variable<int>(goalFat);
    }
    map['is_configured'] = Variable<bool>(isConfigured);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      age: Value(age),
      weightKg: Value(weightKg),
      heightCm: Value(heightCm),
      gender: Value(gender),
      activityLevel: Value(activityLevel),
      goalCalories: Value(goalCalories),
      goalProtein: goalProtein == null && nullToAbsent
          ? const Value.absent()
          : Value(goalProtein),
      goalCarbs: goalCarbs == null && nullToAbsent
          ? const Value.absent()
          : Value(goalCarbs),
      goalFat: goalFat == null && nullToAbsent
          ? const Value.absent()
          : Value(goalFat),
      isConfigured: Value(isConfigured),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      age: serializer.fromJson<int>(json['age']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      gender: serializer.fromJson<String>(json['gender']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      goalCalories: serializer.fromJson<int>(json['goalCalories']),
      goalProtein: serializer.fromJson<int?>(json['goalProtein']),
      goalCarbs: serializer.fromJson<int?>(json['goalCarbs']),
      goalFat: serializer.fromJson<int?>(json['goalFat']),
      isConfigured: serializer.fromJson<bool>(json['isConfigured']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'age': serializer.toJson<int>(age),
      'weightKg': serializer.toJson<double>(weightKg),
      'heightCm': serializer.toJson<double>(heightCm),
      'gender': serializer.toJson<String>(gender),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'goalCalories': serializer.toJson<int>(goalCalories),
      'goalProtein': serializer.toJson<int?>(goalProtein),
      'goalCarbs': serializer.toJson<int?>(goalCarbs),
      'goalFat': serializer.toJson<int?>(goalFat),
      'isConfigured': serializer.toJson<bool>(isConfigured),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  UserProfileRow copyWith({
    int? id,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
    String? activityLevel,
    int? goalCalories,
    Value<int?> goalProtein = const Value.absent(),
    Value<int?> goalCarbs = const Value.absent(),
    Value<int?> goalFat = const Value.absent(),
    bool? isConfigured,
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => UserProfileRow(
    id: id ?? this.id,
    age: age ?? this.age,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    gender: gender ?? this.gender,
    activityLevel: activityLevel ?? this.activityLevel,
    goalCalories: goalCalories ?? this.goalCalories,
    goalProtein: goalProtein.present ? goalProtein.value : this.goalProtein,
    goalCarbs: goalCarbs.present ? goalCarbs.value : this.goalCarbs,
    goalFat: goalFat.present ? goalFat.value : this.goalFat,
    isConfigured: isConfigured ?? this.isConfigured,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      age: data.age.present ? data.age.value : this.age,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      gender: data.gender.present ? data.gender.value : this.gender,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      goalCalories: data.goalCalories.present
          ? data.goalCalories.value
          : this.goalCalories,
      goalProtein: data.goalProtein.present
          ? data.goalProtein.value
          : this.goalProtein,
      goalCarbs: data.goalCarbs.present ? data.goalCarbs.value : this.goalCarbs,
      goalFat: data.goalFat.present ? data.goalFat.value : this.goalFat,
      isConfigured: data.isConfigured.present
          ? data.isConfigured.value
          : this.isConfigured,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('age: $age, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('gender: $gender, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('goalCalories: $goalCalories, ')
          ..write('goalProtein: $goalProtein, ')
          ..write('goalCarbs: $goalCarbs, ')
          ..write('goalFat: $goalFat, ')
          ..write('isConfigured: $isConfigured, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    age,
    weightKg,
    heightCm,
    gender,
    activityLevel,
    goalCalories,
    goalProtein,
    goalCarbs,
    goalFat,
    isConfigured,
    updatedAt,
    updatedBy,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.age == this.age &&
          other.weightKg == this.weightKg &&
          other.heightCm == this.heightCm &&
          other.gender == this.gender &&
          other.activityLevel == this.activityLevel &&
          other.goalCalories == this.goalCalories &&
          other.goalProtein == this.goalProtein &&
          other.goalCarbs == this.goalCarbs &&
          other.goalFat == this.goalFat &&
          other.isConfigured == this.isConfigured &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<int> age;
  final Value<double> weightKg;
  final Value<double> heightCm;
  final Value<String> gender;
  final Value<String> activityLevel;
  final Value<int> goalCalories;
  final Value<int?> goalProtein;
  final Value<int?> goalCarbs;
  final Value<int?> goalFat;
  final Value<bool> isConfigured;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int?> deletedAt;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.age = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.gender = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.goalCalories = const Value.absent(),
    this.goalProtein = const Value.absent(),
    this.goalCarbs = const Value.absent(),
    this.goalFat = const Value.absent(),
    this.isConfigured = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    required int age,
    required double weightKg,
    required double heightCm,
    required String gender,
    required String activityLevel,
    required int goalCalories,
    this.goalProtein = const Value.absent(),
    this.goalCarbs = const Value.absent(),
    this.goalFat = const Value.absent(),
    this.isConfigured = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : age = Value(age),
       weightKg = Value(weightKg),
       heightCm = Value(heightCm),
       gender = Value(gender),
       activityLevel = Value(activityLevel),
       goalCalories = Value(goalCalories);
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<int>? age,
    Expression<double>? weightKg,
    Expression<double>? heightCm,
    Expression<String>? gender,
    Expression<String>? activityLevel,
    Expression<int>? goalCalories,
    Expression<int>? goalProtein,
    Expression<int>? goalCarbs,
    Expression<int>? goalFat,
    Expression<bool>? isConfigured,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (age != null) 'age': age,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (gender != null) 'gender': gender,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (goalCalories != null) 'goal_calories': goalCalories,
      if (goalProtein != null) 'goal_protein': goalProtein,
      if (goalCarbs != null) 'goal_carbs': goalCarbs,
      if (goalFat != null) 'goal_fat': goalFat,
      if (isConfigured != null) 'is_configured': isConfigured,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<int>? age,
    Value<double>? weightKg,
    Value<double>? heightCm,
    Value<String>? gender,
    Value<String>? activityLevel,
    Value<int>? goalCalories,
    Value<int?>? goalProtein,
    Value<int?>? goalCarbs,
    Value<int?>? goalFat,
    Value<bool>? isConfigured,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int?>? deletedAt,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goalCalories: goalCalories ?? this.goalCalories,
      goalProtein: goalProtein ?? this.goalProtein,
      goalCarbs: goalCarbs ?? this.goalCarbs,
      goalFat: goalFat ?? this.goalFat,
      isConfigured: isConfigured ?? this.isConfigured,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (goalCalories.present) {
      map['goal_calories'] = Variable<int>(goalCalories.value);
    }
    if (goalProtein.present) {
      map['goal_protein'] = Variable<int>(goalProtein.value);
    }
    if (goalCarbs.present) {
      map['goal_carbs'] = Variable<int>(goalCarbs.value);
    }
    if (goalFat.present) {
      map['goal_fat'] = Variable<int>(goalFat.value);
    }
    if (isConfigured.present) {
      map['is_configured'] = Variable<bool>(isConfigured.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('age: $age, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('gender: $gender, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('goalCalories: $goalCalories, ')
          ..write('goalProtein: $goalProtein, ')
          ..write('goalCarbs: $goalCarbs, ')
          ..write('goalFat: $goalFat, ')
          ..write('isConfigured: $isConfigured, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    defaultValue: const Constant('google/gemini-3-flash-preview'),
  );
  static const VerificationMeta _fallbackModelMeta = const VerificationMeta(
    'fallbackModel',
  );
  @override
  late final GeneratedColumn<String> fallbackModel = GeneratedColumn<String>(
    'fallback_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
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
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    apiKey,
    aiModel,
    fallbackModel,
    updatedAt,
    updatedBy,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('ai_model')) {
      context.handle(
        _aiModelMeta,
        aiModel.isAcceptableOrUnknown(data['ai_model']!, _aiModelMeta),
      );
    }
    if (data.containsKey('fallback_model')) {
      context.handle(
        _fallbackModelMeta,
        fallbackModel.isAcceptableOrUnknown(
          data['fallback_model']!,
          _fallbackModelMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      ),
      aiModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_model'],
      )!,
      fallbackModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fallback_model'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String? apiKey;
  final String aiModel;
  final String? fallbackModel;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const AppSettingsRow({
    required this.id,
    this.apiKey,
    required this.aiModel,
    this.fallbackModel,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || apiKey != null) {
      map['api_key'] = Variable<String>(apiKey);
    }
    map['ai_model'] = Variable<String>(aiModel);
    if (!nullToAbsent || fallbackModel != null) {
      map['fallback_model'] = Variable<String>(fallbackModel);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      apiKey: apiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(apiKey),
      aiModel: Value(aiModel),
      fallbackModel: fallbackModel == null && nullToAbsent
          ? const Value.absent()
          : Value(fallbackModel),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      apiKey: serializer.fromJson<String?>(json['apiKey']),
      aiModel: serializer.fromJson<String>(json['aiModel']),
      fallbackModel: serializer.fromJson<String?>(json['fallbackModel']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'apiKey': serializer.toJson<String?>(apiKey),
      'aiModel': serializer.toJson<String>(aiModel),
      'fallbackModel': serializer.toJson<String?>(fallbackModel),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    Value<String?> apiKey = const Value.absent(),
    String? aiModel,
    Value<String?> fallbackModel = const Value.absent(),
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => AppSettingsRow(
    id: id ?? this.id,
    apiKey: apiKey.present ? apiKey.value : this.apiKey,
    aiModel: aiModel ?? this.aiModel,
    fallbackModel: fallbackModel.present
        ? fallbackModel.value
        : this.fallbackModel,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      aiModel: data.aiModel.present ? data.aiModel.value : this.aiModel,
      fallbackModel: data.fallbackModel.present
          ? data.fallbackModel.value
          : this.fallbackModel,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('apiKey: $apiKey, ')
          ..write('aiModel: $aiModel, ')
          ..write('fallbackModel: $fallbackModel, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    apiKey,
    aiModel,
    fallbackModel,
    updatedAt,
    updatedBy,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.apiKey == this.apiKey &&
          other.aiModel == this.aiModel &&
          other.fallbackModel == this.fallbackModel &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String?> apiKey;
  final Value<String> aiModel;
  final Value<String?> fallbackModel;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int?> deletedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.fallbackModel = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.fallbackModel = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? apiKey,
    Expression<String>? aiModel,
    Expression<String>? fallbackModel,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apiKey != null) 'api_key': apiKey,
      if (aiModel != null) 'ai_model': aiModel,
      if (fallbackModel != null) 'fallback_model': fallbackModel,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? apiKey,
    Value<String>? aiModel,
    Value<String?>? fallbackModel,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int?>? deletedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      apiKey: apiKey ?? this.apiKey,
      aiModel: aiModel ?? this.aiModel,
      fallbackModel: fallbackModel ?? this.fallbackModel,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (aiModel.present) {
      map['ai_model'] = Variable<String>(aiModel.value);
    }
    if (fallbackModel.present) {
      map['fallback_model'] = Variable<String>(fallbackModel.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('apiKey: $apiKey, ')
          ..write('aiModel: $aiModel, ')
          ..write('fallbackModel: $fallbackModel, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPrefsTable extends LocalPrefs
    with TableInfo<$LocalPrefsTable, LocalPrefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPrefsTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPrefRow> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalPrefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPrefRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalPrefsTable createAlias(String alias) {
    return $LocalPrefsTable(attachedDatabase, alias);
  }
}

class LocalPrefRow extends DataClass implements Insertable<LocalPrefRow> {
  final String key;
  final String value;
  const LocalPrefRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalPrefsCompanion toCompanion(bool nullToAbsent) {
    return LocalPrefsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalPrefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPrefRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalPrefRow copyWith({String? key, String? value}) =>
      LocalPrefRow(key: key ?? this.key, value: value ?? this.value);
  LocalPrefRow copyWithCompanion(LocalPrefsCompanion data) {
    return LocalPrefRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPrefRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPrefRow &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalPrefsCompanion extends UpdateCompanion<LocalPrefRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalPrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPrefsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalPrefRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPrefsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalPrefsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $LocalPrefsTable localPrefs = $LocalPrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    diaryEntries,
    userProfiles,
    appSettings,
    localPrefs,
  ];
}

typedef $$DiaryEntriesTableCreateCompanionBuilder =
    DiaryEntriesCompanion Function({
      required String id,
      required String name,
      required int type,
      required int calories,
      Value<double> protein,
      Value<double> carbs,
      Value<double> fats,
      required int timestamp,
      required String normalizedName,
      Value<String?> imagePath,
      Value<String?> icon,
      Value<int> status,
      Value<String?> description,
      Value<int?> durationMinutes,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$DiaryEntriesTableUpdateCompanionBuilder =
    DiaryEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> type,
      Value<int> calories,
      Value<double> protein,
      Value<double> carbs,
      Value<double> fats,
      Value<int> timestamp,
      Value<String> normalizedName,
      Value<String?> imagePath,
      Value<String?> icon,
      Value<int> status,
      Value<String?> description,
      Value<int?> durationMinutes,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$DiaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableFilterComposer({
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

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fats => $composableBuilder(
    column: $table.fats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fats => $composableBuilder(
    column: $table.fats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableAnnotationComposer({
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

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get fats =>
      $composableBuilder(column: $table.fats, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DiaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiaryEntriesTable,
          DiaryEntryRow,
          $$DiaryEntriesTableFilterComposer,
          $$DiaryEntriesTableOrderingComposer,
          $$DiaryEntriesTableAnnotationComposer,
          $$DiaryEntriesTableCreateCompanionBuilder,
          $$DiaryEntriesTableUpdateCompanionBuilder,
          (
            DiaryEntryRow,
            BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntryRow>,
          ),
          DiaryEntryRow,
          PrefetchHooks Function()
        > {
  $$DiaryEntriesTableTableManager(_$AppDatabase db, $DiaryEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<double> fats = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiaryEntriesCompanion(
                id: id,
                name: name,
                type: type,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                timestamp: timestamp,
                normalizedName: normalizedName,
                imagePath: imagePath,
                icon: icon,
                status: status,
                description: description,
                durationMinutes: durationMinutes,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int type,
                required int calories,
                Value<double> protein = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<double> fats = const Value.absent(),
                required int timestamp,
                required String normalizedName,
                Value<String?> imagePath = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiaryEntriesCompanion.insert(
                id: id,
                name: name,
                type: type,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                timestamp: timestamp,
                normalizedName: normalizedName,
                imagePath: imagePath,
                icon: icon,
                status: status,
                description: description,
                durationMinutes: durationMinutes,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiaryEntriesTable,
      DiaryEntryRow,
      $$DiaryEntriesTableFilterComposer,
      $$DiaryEntriesTableOrderingComposer,
      $$DiaryEntriesTableAnnotationComposer,
      $$DiaryEntriesTableCreateCompanionBuilder,
      $$DiaryEntriesTableUpdateCompanionBuilder,
      (
        DiaryEntryRow,
        BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntryRow>,
      ),
      DiaryEntryRow,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      required int age,
      required double weightKg,
      required double heightCm,
      required String gender,
      required String activityLevel,
      required int goalCalories,
      Value<int?> goalProtein,
      Value<int?> goalCarbs,
      Value<int?> goalFat,
      Value<bool> isConfigured,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<int> age,
      Value<double> weightKg,
      Value<double> heightCm,
      Value<String> gender,
      Value<String> activityLevel,
      Value<int> goalCalories,
      Value<int?> goalProtein,
      Value<int?> goalCarbs,
      Value<int?> goalFat,
      Value<bool> isConfigured,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
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

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalCalories => $composableBuilder(
    column: $table.goalCalories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalProtein => $composableBuilder(
    column: $table.goalProtein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalCarbs => $composableBuilder(
    column: $table.goalCarbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalFat => $composableBuilder(
    column: $table.goalFat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConfigured => $composableBuilder(
    column: $table.isConfigured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
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

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalCalories => $composableBuilder(
    column: $table.goalCalories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalProtein => $composableBuilder(
    column: $table.goalProtein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalCarbs => $composableBuilder(
    column: $table.goalCarbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalFat => $composableBuilder(
    column: $table.goalFat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConfigured => $composableBuilder(
    column: $table.isConfigured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goalCalories => $composableBuilder(
    column: $table.goalCalories,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goalProtein => $composableBuilder(
    column: $table.goalProtein,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goalCarbs =>
      $composableBuilder(column: $table.goalCarbs, builder: (column) => column);

  GeneratedColumn<int> get goalFat =>
      $composableBuilder(column: $table.goalFat, builder: (column) => column);

  GeneratedColumn<bool> get isConfigured => $composableBuilder(
    column: $table.isConfigured,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfileRow,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> age = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<int> goalCalories = const Value.absent(),
                Value<int?> goalProtein = const Value.absent(),
                Value<int?> goalCarbs = const Value.absent(),
                Value<int?> goalFat = const Value.absent(),
                Value<bool> isConfigured = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                age: age,
                weightKg: weightKg,
                heightCm: heightCm,
                gender: gender,
                activityLevel: activityLevel,
                goalCalories: goalCalories,
                goalProtein: goalProtein,
                goalCarbs: goalCarbs,
                goalFat: goalFat,
                isConfigured: isConfigured,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int age,
                required double weightKg,
                required double heightCm,
                required String gender,
                required String activityLevel,
                required int goalCalories,
                Value<int?> goalProtein = const Value.absent(),
                Value<int?> goalCarbs = const Value.absent(),
                Value<int?> goalFat = const Value.absent(),
                Value<bool> isConfigured = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                age: age,
                weightKg: weightKg,
                heightCm: heightCm,
                gender: gender,
                activityLevel: activityLevel,
                goalCalories: goalCalories,
                goalProtein: goalProtein,
                goalCarbs: goalCarbs,
                goalFat: goalFat,
                isConfigured: isConfigured,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfileRow,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> apiKey,
      Value<String> aiModel,
      Value<String?> fallbackModel,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> apiKey,
      Value<String> aiModel,
      Value<String?> fallbackModel,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiModel => $composableBuilder(
    column: $table.aiModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fallbackModel => $composableBuilder(
    column: $table.fallbackModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiModel => $composableBuilder(
    column: $table.aiModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fallbackModel => $composableBuilder(
    column: $table.fallbackModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get aiModel =>
      $composableBuilder(column: $table.aiModel, builder: (column) => column);

  GeneratedColumn<String> get fallbackModel => $composableBuilder(
    column: $table.fallbackModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> apiKey = const Value.absent(),
                Value<String> aiModel = const Value.absent(),
                Value<String?> fallbackModel = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                apiKey: apiKey,
                aiModel: aiModel,
                fallbackModel: fallbackModel,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> apiKey = const Value.absent(),
                Value<String> aiModel = const Value.absent(),
                Value<String?> fallbackModel = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                apiKey: apiKey,
                aiModel: aiModel,
                fallbackModel: fallbackModel,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$LocalPrefsTableCreateCompanionBuilder =
    LocalPrefsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalPrefsTableUpdateCompanionBuilder =
    LocalPrefsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPrefsTable> {
  $$LocalPrefsTableFilterComposer({
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
}

class $$LocalPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPrefsTable> {
  $$LocalPrefsTableOrderingComposer({
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
}

class $$LocalPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPrefsTable> {
  $$LocalPrefsTableAnnotationComposer({
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
}

class $$LocalPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPrefsTable,
          LocalPrefRow,
          $$LocalPrefsTableFilterComposer,
          $$LocalPrefsTableOrderingComposer,
          $$LocalPrefsTableAnnotationComposer,
          $$LocalPrefsTableCreateCompanionBuilder,
          $$LocalPrefsTableUpdateCompanionBuilder,
          (
            LocalPrefRow,
            BaseReferences<_$AppDatabase, $LocalPrefsTable, LocalPrefRow>,
          ),
          LocalPrefRow,
          PrefetchHooks Function()
        > {
  $$LocalPrefsTableTableManager(_$AppDatabase db, $LocalPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPrefsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalPrefsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPrefsTable,
      LocalPrefRow,
      $$LocalPrefsTableFilterComposer,
      $$LocalPrefsTableOrderingComposer,
      $$LocalPrefsTableAnnotationComposer,
      $$LocalPrefsTableCreateCompanionBuilder,
      $$LocalPrefsTableUpdateCompanionBuilder,
      (
        LocalPrefRow,
        BaseReferences<_$AppDatabase, $LocalPrefsTable, LocalPrefRow>,
      ),
      LocalPrefRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiaryEntriesTableTableManager get diaryEntries =>
      $$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$LocalPrefsTableTableManager get localPrefs =>
      $$LocalPrefsTableTableManager(_db, _db.localPrefs);
}
