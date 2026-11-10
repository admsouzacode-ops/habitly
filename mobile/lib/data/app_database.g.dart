// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
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
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🌱'),
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF2E7D32),
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1,2,3,4,5,6,7'),
  );
  static const VerificationMeta _reminderMeta = const VerificationMeta(
    'reminder',
  );
  @override
  late final GeneratedColumn<String> reminder = GeneratedColumn<String>(
    'reminder',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _goalTypeMeta = const VerificationMeta(
    'goalType',
  );
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
    'goal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _weeklyTargetMeta = const VerificationMeta(
    'weeklyTarget',
  );
  @override
  late final GeneratedColumn<int> weeklyTarget = GeneratedColumn<int>(
    'weekly_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _quantityTargetMeta = const VerificationMeta(
    'quantityTarget',
  );
  @override
  late final GeneratedColumn<double> quantityTarget = GeneratedColumn<double>(
    'quantity_target',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _quantityUnitMeta = const VerificationMeta(
    'quantityUnit',
  );
  @override
  late final GeneratedColumn<String> quantityUnit = GeneratedColumn<String>(
    'quantity_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityStepMeta = const VerificationMeta(
    'quantityStep',
  );
  @override
  late final GeneratedColumn<double> quantityStep = GeneratedColumn<double>(
    'quantity_step',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    colorValue,
    weekdays,
    reminder,
    createdAt,
    goalType,
    weeklyTarget,
    quantityTarget,
    quantityUnit,
    quantityStep,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    }
    if (data.containsKey('reminder')) {
      context.handle(
        _reminderMeta,
        reminder.isAcceptableOrUnknown(data['reminder']!, _reminderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('goal_type')) {
      context.handle(
        _goalTypeMeta,
        goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta),
      );
    }
    if (data.containsKey('weekly_target')) {
      context.handle(
        _weeklyTargetMeta,
        weeklyTarget.isAcceptableOrUnknown(
          data['weekly_target']!,
          _weeklyTargetMeta,
        ),
      );
    }
    if (data.containsKey('quantity_target')) {
      context.handle(
        _quantityTargetMeta,
        quantityTarget.isAcceptableOrUnknown(
          data['quantity_target']!,
          _quantityTargetMeta,
        ),
      );
    }
    if (data.containsKey('quantity_unit')) {
      context.handle(
        _quantityUnitMeta,
        quantityUnit.isAcceptableOrUnknown(
          data['quantity_unit']!,
          _quantityUnitMeta,
        ),
      );
    }
    if (data.containsKey('quantity_step')) {
      context.handle(
        _quantityStepMeta,
        quantityStep.isAcceptableOrUnknown(
          data['quantity_step']!,
          _quantityStepMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays'],
      )!,
      reminder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      goalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_type'],
      )!,
      weeklyTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_target'],
      )!,
      quantityTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_target'],
      )!,
      quantityUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_unit'],
      )!,
      quantityStep: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_step'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String name;
  final String icon;
  final int colorValue;

  /// Dias da semana ISO separados por vírgula: 1=seg ... 7=dom.
  final String weekdays;

  /// Horário de lembrete (HH:mm) nos dias de [weekdays]. Nulo = sem lembrete.
  final String? reminder;
  final DateTime createdAt;

  /// Tipo de meta (v4, app 1.0.0+7): 'daily' (dias da semana), 'weekly'
  /// (X vezes por semana, qualquer dia) ou 'quantity' (quantidade por dia).
  /// Hábitos antigos ficam 'daily'.
  final String goalType;

  /// Meta semanal (vezes por semana) quando goalType = 'weekly'.
  final int weeklyTarget;

  /// Meta diária quando goalType = 'quantity' (ex.: 2 litros, 8 copos).
  final double quantityTarget;

  /// Unidade da meta de quantidade (ex.: 'litros', 'copos', 'min').
  final String quantityUnit;

  /// Incremento do botão + (e do widget) para metas de quantidade.
  final double quantityStep;
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.weekdays,
    this.reminder,
    required this.createdAt,
    required this.goalType,
    required this.weeklyTarget,
    required this.quantityTarget,
    required this.quantityUnit,
    required this.quantityStep,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color_value'] = Variable<int>(colorValue);
    map['weekdays'] = Variable<String>(weekdays);
    if (!nullToAbsent || reminder != null) {
      map['reminder'] = Variable<String>(reminder);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['goal_type'] = Variable<String>(goalType);
    map['weekly_target'] = Variable<int>(weeklyTarget);
    map['quantity_target'] = Variable<double>(quantityTarget);
    map['quantity_unit'] = Variable<String>(quantityUnit);
    map['quantity_step'] = Variable<double>(quantityStep);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      colorValue: Value(colorValue),
      weekdays: Value(weekdays),
      reminder: reminder == null && nullToAbsent
          ? const Value.absent()
          : Value(reminder),
      createdAt: Value(createdAt),
      goalType: Value(goalType),
      weeklyTarget: Value(weeklyTarget),
      quantityTarget: Value(quantityTarget),
      quantityUnit: Value(quantityUnit),
      quantityStep: Value(quantityStep),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      weekdays: serializer.fromJson<String>(json['weekdays']),
      reminder: serializer.fromJson<String?>(json['reminder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      goalType: serializer.fromJson<String>(json['goalType']),
      weeklyTarget: serializer.fromJson<int>(json['weeklyTarget']),
      quantityTarget: serializer.fromJson<double>(json['quantityTarget']),
      quantityUnit: serializer.fromJson<String>(json['quantityUnit']),
      quantityStep: serializer.fromJson<double>(json['quantityStep']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'colorValue': serializer.toJson<int>(colorValue),
      'weekdays': serializer.toJson<String>(weekdays),
      'reminder': serializer.toJson<String?>(reminder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'goalType': serializer.toJson<String>(goalType),
      'weeklyTarget': serializer.toJson<int>(weeklyTarget),
      'quantityTarget': serializer.toJson<double>(quantityTarget),
      'quantityUnit': serializer.toJson<String>(quantityUnit),
      'quantityStep': serializer.toJson<double>(quantityStep),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    String? icon,
    int? colorValue,
    String? weekdays,
    Value<String?> reminder = const Value.absent(),
    DateTime? createdAt,
    String? goalType,
    int? weeklyTarget,
    double? quantityTarget,
    String? quantityUnit,
    double? quantityStep,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorValue: colorValue ?? this.colorValue,
    weekdays: weekdays ?? this.weekdays,
    reminder: reminder.present ? reminder.value : this.reminder,
    createdAt: createdAt ?? this.createdAt,
    goalType: goalType ?? this.goalType,
    weeklyTarget: weeklyTarget ?? this.weeklyTarget,
    quantityTarget: quantityTarget ?? this.quantityTarget,
    quantityUnit: quantityUnit ?? this.quantityUnit,
    quantityStep: quantityStep ?? this.quantityStep,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      reminder: data.reminder.present ? data.reminder.value : this.reminder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      weeklyTarget: data.weeklyTarget.present
          ? data.weeklyTarget.value
          : this.weeklyTarget,
      quantityTarget: data.quantityTarget.present
          ? data.quantityTarget.value
          : this.quantityTarget,
      quantityUnit: data.quantityUnit.present
          ? data.quantityUnit.value
          : this.quantityUnit,
      quantityStep: data.quantityStep.present
          ? data.quantityStep.value
          : this.quantityStep,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('colorValue: $colorValue, ')
          ..write('weekdays: $weekdays, ')
          ..write('reminder: $reminder, ')
          ..write('createdAt: $createdAt, ')
          ..write('goalType: $goalType, ')
          ..write('weeklyTarget: $weeklyTarget, ')
          ..write('quantityTarget: $quantityTarget, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('quantityStep: $quantityStep')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    icon,
    colorValue,
    weekdays,
    reminder,
    createdAt,
    goalType,
    weeklyTarget,
    quantityTarget,
    quantityUnit,
    quantityStep,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.colorValue == this.colorValue &&
          other.weekdays == this.weekdays &&
          other.reminder == this.reminder &&
          other.createdAt == this.createdAt &&
          other.goalType == this.goalType &&
          other.weeklyTarget == this.weeklyTarget &&
          other.quantityTarget == this.quantityTarget &&
          other.quantityUnit == this.quantityUnit &&
          other.quantityStep == this.quantityStep);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> colorValue;
  final Value<String> weekdays;
  final Value<String?> reminder;
  final Value<DateTime> createdAt;
  final Value<String> goalType;
  final Value<int> weeklyTarget;
  final Value<double> quantityTarget;
  final Value<String> quantityUnit;
  final Value<double> quantityStep;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.reminder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.goalType = const Value.absent(),
    this.weeklyTarget = const Value.absent(),
    this.quantityTarget = const Value.absent(),
    this.quantityUnit = const Value.absent(),
    this.quantityStep = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.reminder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.goalType = const Value.absent(),
    this.weeklyTarget = const Value.absent(),
    this.quantityTarget = const Value.absent(),
    this.quantityUnit = const Value.absent(),
    this.quantityStep = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? colorValue,
    Expression<String>? weekdays,
    Expression<String>? reminder,
    Expression<DateTime>? createdAt,
    Expression<String>? goalType,
    Expression<int>? weeklyTarget,
    Expression<double>? quantityTarget,
    Expression<String>? quantityUnit,
    Expression<double>? quantityStep,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (colorValue != null) 'color_value': colorValue,
      if (weekdays != null) 'weekdays': weekdays,
      if (reminder != null) 'reminder': reminder,
      if (createdAt != null) 'created_at': createdAt,
      if (goalType != null) 'goal_type': goalType,
      if (weeklyTarget != null) 'weekly_target': weeklyTarget,
      if (quantityTarget != null) 'quantity_target': quantityTarget,
      if (quantityUnit != null) 'quantity_unit': quantityUnit,
      if (quantityStep != null) 'quantity_step': quantityStep,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? colorValue,
    Value<String>? weekdays,
    Value<String?>? reminder,
    Value<DateTime>? createdAt,
    Value<String>? goalType,
    Value<int>? weeklyTarget,
    Value<double>? quantityTarget,
    Value<String>? quantityUnit,
    Value<double>? quantityStep,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      weekdays: weekdays ?? this.weekdays,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt ?? this.createdAt,
      goalType: goalType ?? this.goalType,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      quantityTarget: quantityTarget ?? this.quantityTarget,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      quantityStep: quantityStep ?? this.quantityStep,
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
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (reminder.present) {
      map['reminder'] = Variable<String>(reminder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (weeklyTarget.present) {
      map['weekly_target'] = Variable<int>(weeklyTarget.value);
    }
    if (quantityTarget.present) {
      map['quantity_target'] = Variable<double>(quantityTarget.value);
    }
    if (quantityUnit.present) {
      map['quantity_unit'] = Variable<String>(quantityUnit.value);
    }
    if (quantityStep.present) {
      map['quantity_step'] = Variable<double>(quantityStep.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('colorValue: $colorValue, ')
          ..write('weekdays: $weekdays, ')
          ..write('reminder: $reminder, ')
          ..write('createdAt: $createdAt, ')
          ..write('goalType: $goalType, ')
          ..write('weeklyTarget: $weeklyTarget, ')
          ..write('quantityTarget: $quantityTarget, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('quantityStep: $quantityStep')
          ..write(')'))
        .toString();
  }
}

class $CompletionsTable extends Completions
    with TableInfo<$CompletionsTable, Completion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, day, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Completion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, day},
  ];
  @override
  Completion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Completion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }
}

class Completion extends DataClass implements Insertable<Completion> {
  final int id;
  final int habitId;

  /// Dia local no formato YYYY-MM-DD.
  final String day;
  final DateTime completedAt;
  const Completion({
    required this.id,
    required this.habitId,
    required this.day,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['day'] = Variable<String>(day);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      day: Value(day),
      completedAt: Value(completedAt),
    );
  }

  factory Completion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Completion(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      day: serializer.fromJson<String>(json['day']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'day': serializer.toJson<String>(day),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  Completion copyWith({
    int? id,
    int? habitId,
    String? day,
    DateTime? completedAt,
  }) => Completion(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    day: day ?? this.day,
    completedAt: completedAt ?? this.completedAt,
  );
  Completion copyWithCompanion(CompletionsCompanion data) {
    return Completion(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      day: data.day.present ? data.day.value : this.day,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Completion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, day, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.day == this.day &&
          other.completedAt == this.completedAt);
}

class CompletionsCompanion extends UpdateCompanion<Completion> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> day;
  final Value<DateTime> completedAt;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.day = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  CompletionsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String day,
    this.completedAt = const Value.absent(),
  }) : habitId = Value(habitId),
       day = Value(day);
  static Insertable<Completion> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? day,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (day != null) 'day': day,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  CompletionsCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? day,
    Value<DateTime>? completedAt,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      day: day ?? this.day,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitDayNotesTable extends HabitDayNotes
    with TableInfo<$HabitDayNotesTable, HabitDayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitDayNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES habits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 280),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    day,
    note,
    reason,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_day_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitDayNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, day},
  ];
  @override
  HabitDayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitDayNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
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
  $HabitDayNotesTable createAlias(String alias) {
    return $HabitDayNotesTable(attachedDatabase, alias);
  }
}

class HabitDayNote extends DataClass implements Insertable<HabitDayNote> {
  final int id;
  final int habitId;

  /// Dia local no formato YYYY-MM-DD.
  final String day;

  /// Texto livre (até 280 caracteres; pode ser vazio se houver motivo).
  final String note;

  /// Código de [NoteReason] (ex.: 'sem_tempo'). Nulo = sem motivo rápido.
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HabitDayNote({
    required this.id,
    required this.habitId,
    required this.day,
    required this.note,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['day'] = Variable<String>(day);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitDayNotesCompanion toCompanion(bool nullToAbsent) {
    return HabitDayNotesCompanion(
      id: Value(id),
      habitId: Value(habitId),
      day: Value(day),
      note: Value(note),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitDayNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitDayNote(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      day: serializer.fromJson<String>(json['day']),
      note: serializer.fromJson<String>(json['note']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'day': serializer.toJson<String>(day),
      'note': serializer.toJson<String>(note),
      'reason': serializer.toJson<String?>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitDayNote copyWith({
    int? id,
    int? habitId,
    String? day,
    String? note,
    Value<String?> reason = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HabitDayNote(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    day: day ?? this.day,
    note: note ?? this.note,
    reason: reason.present ? reason.value : this.reason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitDayNote copyWithCompanion(HabitDayNotesCompanion data) {
    return HabitDayNote(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      day: data.day.present ? data.day.value : this.day,
      note: data.note.present ? data.note.value : this.note,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitDayNote(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('note: $note, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitId, day, note, reason, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitDayNote &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.day == this.day &&
          other.note == this.note &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitDayNotesCompanion extends UpdateCompanion<HabitDayNote> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> day;
  final Value<String> note;
  final Value<String?> reason;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HabitDayNotesCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.day = const Value.absent(),
    this.note = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HabitDayNotesCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String day,
    this.note = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : habitId = Value(habitId),
       day = Value(day);
  static Insertable<HabitDayNote> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? day,
    Expression<String>? note,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (day != null) 'day': day,
      if (note != null) 'note': note,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HabitDayNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? day,
    Value<String>? note,
    Value<String?>? reason,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return HabitDayNotesCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      day: day ?? this.day,
      note: note ?? this.note,
      reason: reason ?? this.reason,
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
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
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
    return (StringBuffer('HabitDayNotesCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('note: $note, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitAmountsTable extends HabitAmounts
    with TableInfo<$HabitAmountsTable, HabitAmount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitAmountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES habits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, day, amount, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_amounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitAmount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, day},
  ];
  @override
  HabitAmount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitAmount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitAmountsTable createAlias(String alias) {
    return $HabitAmountsTable(attachedDatabase, alias);
  }
}

class HabitAmount extends DataClass implements Insertable<HabitAmount> {
  final int id;
  final int habitId;

  /// Dia local no formato YYYY-MM-DD.
  final String day;
  final double amount;
  final DateTime updatedAt;
  const HabitAmount({
    required this.id,
    required this.habitId,
    required this.day,
    required this.amount,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['day'] = Variable<String>(day);
    map['amount'] = Variable<double>(amount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitAmountsCompanion toCompanion(bool nullToAbsent) {
    return HabitAmountsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      day: Value(day),
      amount: Value(amount),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitAmount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitAmount(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      day: serializer.fromJson<String>(json['day']),
      amount: serializer.fromJson<double>(json['amount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'day': serializer.toJson<String>(day),
      'amount': serializer.toJson<double>(amount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitAmount copyWith({
    int? id,
    int? habitId,
    String? day,
    double? amount,
    DateTime? updatedAt,
  }) => HabitAmount(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    day: day ?? this.day,
    amount: amount ?? this.amount,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitAmount copyWithCompanion(HabitAmountsCompanion data) {
    return HabitAmount(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      day: data.day.present ? data.day.value : this.day,
      amount: data.amount.present ? data.amount.value : this.amount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitAmount(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('amount: $amount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, day, amount, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitAmount &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.day == this.day &&
          other.amount == this.amount &&
          other.updatedAt == this.updatedAt);
}

class HabitAmountsCompanion extends UpdateCompanion<HabitAmount> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> day;
  final Value<double> amount;
  final Value<DateTime> updatedAt;
  const HabitAmountsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.day = const Value.absent(),
    this.amount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HabitAmountsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String day,
    this.amount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : habitId = Value(habitId),
       day = Value(day);
  static Insertable<HabitAmount> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? day,
    Expression<double>? amount,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (day != null) 'day': day,
      if (amount != null) 'amount': amount,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HabitAmountsCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? day,
    Value<double>? amount,
    Value<DateTime>? updatedAt,
  }) {
    return HabitAmountsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      day: day ?? this.day,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitAmountsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('amount: $amount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $HabitDayNotesTable habitDayNotes = $HabitDayNotesTable(this);
  late final $HabitAmountsTable habitAmounts = $HabitAmountsTable(this);
  late final Index idxCompletionsDay = Index(
    'idx_completions_day',
    'CREATE INDEX idx_completions_day ON completions (day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    completions,
    habitDayNotes,
    habitAmounts,
    idxCompletionsDay,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_day_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_amounts', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> icon,
      Value<int> colorValue,
      Value<String> weekdays,
      Value<String?> reminder,
      Value<DateTime> createdAt,
      Value<String> goalType,
      Value<int> weeklyTarget,
      Value<double> quantityTarget,
      Value<String> quantityUnit,
      Value<double> quantityStep,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> icon,
      Value<int> colorValue,
      Value<String> weekdays,
      Value<String?> reminder,
      Value<DateTime> createdAt,
      Value<String> goalType,
      Value<int> weeklyTarget,
      Value<double> quantityTarget,
      Value<String> quantityUnit,
      Value<double> quantityStep,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitDayNotesTable, List<HabitDayNote>>
  _habitDayNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitDayNotes,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitDayNotes.habitId),
  );

  $$HabitDayNotesTableProcessedTableManager get habitDayNotesRefs {
    final manager = $$HabitDayNotesTableTableManager(
      $_db,
      $_db.habitDayNotes,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitDayNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitAmountsTable, List<HabitAmount>>
  _habitAmountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitAmounts,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitAmounts.habitId),
  );

  $$HabitAmountsTableProcessedTableManager get habitAmountsRefs {
    final manager = $$HabitAmountsTableTableManager(
      $_db,
      $_db.habitAmounts,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitAmountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
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

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminder => $composableBuilder(
    column: $table.reminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeklyTarget => $composableBuilder(
    column: $table.weeklyTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityTarget => $composableBuilder(
    column: $table.quantityTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityUnit => $composableBuilder(
    column: $table.quantityUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityStep => $composableBuilder(
    column: $table.quantityStep,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> habitDayNotesRefs(
    Expression<bool> Function($$HabitDayNotesTableFilterComposer f) f,
  ) {
    final $$HabitDayNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitDayNotes,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitDayNotesTableFilterComposer(
            $db: $db,
            $table: $db.habitDayNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitAmountsRefs(
    Expression<bool> Function($$HabitAmountsTableFilterComposer f) f,
  ) {
    final $$HabitAmountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitAmounts,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitAmountsTableFilterComposer(
            $db: $db,
            $table: $db.habitAmounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
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

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminder => $composableBuilder(
    column: $table.reminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklyTarget => $composableBuilder(
    column: $table.weeklyTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityTarget => $composableBuilder(
    column: $table.quantityTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityUnit => $composableBuilder(
    column: $table.quantityUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityStep => $composableBuilder(
    column: $table.quantityStep,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<String> get reminder =>
      $composableBuilder(column: $table.reminder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<int> get weeklyTarget => $composableBuilder(
    column: $table.weeklyTarget,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityTarget => $composableBuilder(
    column: $table.quantityTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityUnit => $composableBuilder(
    column: $table.quantityUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityStep => $composableBuilder(
    column: $table.quantityStep,
    builder: (column) => column,
  );

  Expression<T> habitDayNotesRefs<T extends Object>(
    Expression<T> Function($$HabitDayNotesTableAnnotationComposer a) f,
  ) {
    final $$HabitDayNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitDayNotes,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitDayNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.habitDayNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitAmountsRefs<T extends Object>(
    Expression<T> Function($$HabitAmountsTableAnnotationComposer a) f,
  ) {
    final $$HabitAmountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitAmounts,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitAmountsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitAmounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({
            bool habitDayNotesRefs,
            bool habitAmountsRefs,
          })
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<String?> reminder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> goalType = const Value.absent(),
                Value<int> weeklyTarget = const Value.absent(),
                Value<double> quantityTarget = const Value.absent(),
                Value<String> quantityUnit = const Value.absent(),
                Value<double> quantityStep = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                icon: icon,
                colorValue: colorValue,
                weekdays: weekdays,
                reminder: reminder,
                createdAt: createdAt,
                goalType: goalType,
                weeklyTarget: weeklyTarget,
                quantityTarget: quantityTarget,
                quantityUnit: quantityUnit,
                quantityStep: quantityStep,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> weekdays = const Value.absent(),
                Value<String?> reminder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> goalType = const Value.absent(),
                Value<int> weeklyTarget = const Value.absent(),
                Value<double> quantityTarget = const Value.absent(),
                Value<String> quantityUnit = const Value.absent(),
                Value<double> quantityStep = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                colorValue: colorValue,
                weekdays: weekdays,
                reminder: reminder,
                createdAt: createdAt,
                goalType: goalType,
                weeklyTarget: weeklyTarget,
                quantityTarget: quantityTarget,
                quantityUnit: quantityUnit,
                quantityStep: quantityStep,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HabitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({habitDayNotesRefs = false, habitAmountsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (habitDayNotesRefs) db.habitDayNotes,
                    if (habitAmountsRefs) db.habitAmounts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (habitDayNotesRefs)
                        await $_getPrefetchedData<
                          Habit,
                          $HabitsTable,
                          HabitDayNote
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitDayNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitDayNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (habitAmountsRefs)
                        await $_getPrefetchedData<
                          Habit,
                          $HabitsTable,
                          HabitAmount
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitAmountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitAmountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool habitDayNotesRefs, bool habitAmountsRefs})
    >;
typedef $$CompletionsTableCreateCompanionBuilder =
    CompletionsCompanion Function({
      Value<int> id,
      required int habitId,
      required String day,
      Value<DateTime> completedAt,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<int> id,
      Value<int> habitId,
      Value<String> day,
      Value<DateTime> completedAt,
    });

class $$CompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableFilterComposer({
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

  ColumnFilters<int> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableOrderingComposer({
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

  ColumnOrderings<int> get habitId => $composableBuilder(
    column: $table.habitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletionsTable> {
  $$CompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$CompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletionsTable,
          Completion,
          $$CompletionsTableFilterComposer,
          $$CompletionsTableOrderingComposer,
          $$CompletionsTableAnnotationComposer,
          $$CompletionsTableCreateCompanionBuilder,
          $$CompletionsTableUpdateCompanionBuilder,
          (
            Completion,
            BaseReferences<_$AppDatabase, $CompletionsTable, Completion>,
          ),
          Completion,
          PrefetchHooks Function()
        > {
  $$CompletionsTableTableManager(_$AppDatabase db, $CompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => CompletionsCompanion(
                id: id,
                habitId: habitId,
                day: day,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String day,
                Value<DateTime> completedAt = const Value.absent(),
              }) => CompletionsCompanion.insert(
                id: id,
                habitId: habitId,
                day: day,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletionsTable,
      Completion,
      $$CompletionsTableFilterComposer,
      $$CompletionsTableOrderingComposer,
      $$CompletionsTableAnnotationComposer,
      $$CompletionsTableCreateCompanionBuilder,
      $$CompletionsTableUpdateCompanionBuilder,
      (
        Completion,
        BaseReferences<_$AppDatabase, $CompletionsTable, Completion>,
      ),
      Completion,
      PrefetchHooks Function()
    >;
typedef $$HabitDayNotesTableCreateCompanionBuilder =
    HabitDayNotesCompanion Function({
      Value<int> id,
      required int habitId,
      required String day,
      Value<String> note,
      Value<String?> reason,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$HabitDayNotesTableUpdateCompanionBuilder =
    HabitDayNotesCompanion Function({
      Value<int> id,
      Value<int> habitId,
      Value<String> day,
      Value<String> note,
      Value<String?> reason,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$HabitDayNotesTableReferences
    extends BaseReferences<_$AppDatabase, $HabitDayNotesTable, HabitDayNote> {
  $$HabitDayNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitDayNotes.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitDayNotesTableFilterComposer
    extends Composer<_$AppDatabase, $HabitDayNotesTable> {
  $$HabitDayNotesTableFilterComposer({
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

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
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

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitDayNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitDayNotesTable> {
  $$HabitDayNotesTableOrderingComposer({
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

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
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

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitDayNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitDayNotesTable> {
  $$HabitDayNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitDayNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitDayNotesTable,
          HabitDayNote,
          $$HabitDayNotesTableFilterComposer,
          $$HabitDayNotesTableOrderingComposer,
          $$HabitDayNotesTableAnnotationComposer,
          $$HabitDayNotesTableCreateCompanionBuilder,
          $$HabitDayNotesTableUpdateCompanionBuilder,
          (HabitDayNote, $$HabitDayNotesTableReferences),
          HabitDayNote,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitDayNotesTableTableManager(_$AppDatabase db, $HabitDayNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitDayNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitDayNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitDayNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HabitDayNotesCompanion(
                id: id,
                habitId: habitId,
                day: day,
                note: note,
                reason: reason,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String day,
                Value<String> note = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HabitDayNotesCompanion.insert(
                id: id,
                habitId: habitId,
                day: day,
                note: note,
                reason: reason,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitDayNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
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
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$HabitDayNotesTableReferences
                                    ._habitIdTable(db),
                                referencedColumn: $$HabitDayNotesTableReferences
                                    ._habitIdTable(db)
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

typedef $$HabitDayNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitDayNotesTable,
      HabitDayNote,
      $$HabitDayNotesTableFilterComposer,
      $$HabitDayNotesTableOrderingComposer,
      $$HabitDayNotesTableAnnotationComposer,
      $$HabitDayNotesTableCreateCompanionBuilder,
      $$HabitDayNotesTableUpdateCompanionBuilder,
      (HabitDayNote, $$HabitDayNotesTableReferences),
      HabitDayNote,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitAmountsTableCreateCompanionBuilder =
    HabitAmountsCompanion Function({
      Value<int> id,
      required int habitId,
      required String day,
      Value<double> amount,
      Value<DateTime> updatedAt,
    });
typedef $$HabitAmountsTableUpdateCompanionBuilder =
    HabitAmountsCompanion Function({
      Value<int> id,
      Value<int> habitId,
      Value<String> day,
      Value<double> amount,
      Value<DateTime> updatedAt,
    });

final class $$HabitAmountsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitAmountsTable, HabitAmount> {
  $$HabitAmountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitAmounts.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitAmountsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitAmountsTable> {
  $$HabitAmountsTableFilterComposer({
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

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitAmountsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitAmountsTable> {
  $$HabitAmountsTableOrderingComposer({
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

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitAmountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitAmountsTable> {
  $$HabitAmountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitAmountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitAmountsTable,
          HabitAmount,
          $$HabitAmountsTableFilterComposer,
          $$HabitAmountsTableOrderingComposer,
          $$HabitAmountsTableAnnotationComposer,
          $$HabitAmountsTableCreateCompanionBuilder,
          $$HabitAmountsTableUpdateCompanionBuilder,
          (HabitAmount, $$HabitAmountsTableReferences),
          HabitAmount,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitAmountsTableTableManager(_$AppDatabase db, $HabitAmountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitAmountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitAmountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitAmountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HabitAmountsCompanion(
                id: id,
                habitId: habitId,
                day: day,
                amount: amount,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String day,
                Value<double> amount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HabitAmountsCompanion.insert(
                id: id,
                habitId: habitId,
                day: day,
                amount: amount,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitAmountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
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
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$HabitAmountsTableReferences
                                    ._habitIdTable(db),
                                referencedColumn: $$HabitAmountsTableReferences
                                    ._habitIdTable(db)
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

typedef $$HabitAmountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitAmountsTable,
      HabitAmount,
      $$HabitAmountsTableFilterComposer,
      $$HabitAmountsTableOrderingComposer,
      $$HabitAmountsTableAnnotationComposer,
      $$HabitAmountsTableCreateCompanionBuilder,
      $$HabitAmountsTableUpdateCompanionBuilder,
      (HabitAmount, $$HabitAmountsTableReferences),
      HabitAmount,
      PrefetchHooks Function({bool habitId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$CompletionsTableTableManager get completions =>
      $$CompletionsTableTableManager(_db, _db.completions);
  $$HabitDayNotesTableTableManager get habitDayNotes =>
      $$HabitDayNotesTableTableManager(_db, _db.habitDayNotes);
  $$HabitAmountsTableTableManager get habitAmounts =>
      $$HabitAmountsTableTableManager(_db, _db.habitAmounts);
}
