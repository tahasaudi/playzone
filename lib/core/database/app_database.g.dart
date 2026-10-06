// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, EmployeeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pinHashMeta =
      const VerificationMeta('pinHash');
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
      'pin_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPartnerMeta =
      const VerificationMeta('isPartner');
  @override
  late final GeneratedColumn<bool> isPartner = GeneratedColumn<bool>(
      'is_partner', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_partner" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _partnerShareMeta =
      const VerificationMeta('partnerShare');
  @override
  late final GeneratedColumn<double> partnerShare = GeneratedColumn<double>(
      'partner_share', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        role,
        pinHash,
        isPartner,
        partnerShare,
        active,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(Insertable<EmployeeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(_pinHashMeta,
          pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta));
    } else if (isInserting) {
      context.missing(_pinHashMeta);
    }
    if (data.containsKey('is_partner')) {
      context.handle(_isPartnerMeta,
          isPartner.isAcceptableOrUnknown(data['is_partner']!, _isPartnerMeta));
    }
    if (data.containsKey('partner_share')) {
      context.handle(
          _partnerShareMeta,
          partnerShare.isAcceptableOrUnknown(
              data['partner_share']!, _partnerShareMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {phone},
      ];
  @override
  EmployeeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      pinHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin_hash'])!,
      isPartner: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_partner'])!,
      partnerShare: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}partner_share']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }
}

class EmployeeRow extends DataClass implements Insertable<EmployeeRow> {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String pinHash;

  /// Partner of the business (شريك): eligible for a profit share, and
  /// their withdrawals (مسحوبات) reduce their share rather than being a
  /// plain debt. Whether the share applies is a per-employee admin call.
  final bool isPartner;

  /// Profit share as a percent 0–100 (شركاء بنص = 50).
  final double? partnerShare;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EmployeeRow(
      {required this.id,
      required this.name,
      required this.phone,
      required this.role,
      required this.pinHash,
      required this.isPartner,
      this.partnerShare,
      required this.active,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['role'] = Variable<String>(role);
    map['pin_hash'] = Variable<String>(pinHash);
    map['is_partner'] = Variable<bool>(isPartner);
    if (!nullToAbsent || partnerShare != null) {
      map['partner_share'] = Variable<double>(partnerShare);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      role: Value(role),
      pinHash: Value(pinHash),
      isPartner: Value(isPartner),
      partnerShare: partnerShare == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerShare),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EmployeeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      role: serializer.fromJson<String>(json['role']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      isPartner: serializer.fromJson<bool>(json['isPartner']),
      partnerShare: serializer.fromJson<double?>(json['partnerShare']),
      active: serializer.fromJson<bool>(json['active']),
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
      'phone': serializer.toJson<String>(phone),
      'role': serializer.toJson<String>(role),
      'pinHash': serializer.toJson<String>(pinHash),
      'isPartner': serializer.toJson<bool>(isPartner),
      'partnerShare': serializer.toJson<double?>(partnerShare),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EmployeeRow copyWith(
          {int? id,
          String? name,
          String? phone,
          String? role,
          String? pinHash,
          bool? isPartner,
          Value<double?> partnerShare = const Value.absent(),
          bool? active,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      EmployeeRow(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        pinHash: pinHash ?? this.pinHash,
        isPartner: isPartner ?? this.isPartner,
        partnerShare:
            partnerShare.present ? partnerShare.value : this.partnerShare,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EmployeeRow copyWithCompanion(EmployeesCompanion data) {
    return EmployeeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      role: data.role.present ? data.role.value : this.role,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      isPartner: data.isPartner.present ? data.isPartner.value : this.isPartner,
      partnerShare: data.partnerShare.present
          ? data.partnerShare.value
          : this.partnerShare,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('isPartner: $isPartner, ')
          ..write('partnerShare: $partnerShare, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, role, pinHash, isPartner,
      partnerShare, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.role == this.role &&
          other.pinHash == this.pinHash &&
          other.isPartner == this.isPartner &&
          other.partnerShare == this.partnerShare &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EmployeesCompanion extends UpdateCompanion<EmployeeRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> role;
  final Value<String> pinHash;
  final Value<bool> isPartner;
  final Value<double?> partnerShare;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.isPartner = const Value.absent(),
    this.partnerShare = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EmployeesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String phone,
    required String role,
    required String pinHash,
    this.isPartner = const Value.absent(),
    this.partnerShare = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        phone = Value(phone),
        role = Value(role),
        pinHash = Value(pinHash);
  static Insertable<EmployeeRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? role,
    Expression<String>? pinHash,
    Expression<bool>? isPartner,
    Expression<double>? partnerShare,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (pinHash != null) 'pin_hash': pinHash,
      if (isPartner != null) 'is_partner': isPartner,
      if (partnerShare != null) 'partner_share': partnerShare,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EmployeesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<String>? role,
      Value<String>? pinHash,
      Value<bool>? isPartner,
      Value<double?>? partnerShare,
      Value<bool>? active,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return EmployeesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      pinHash: pinHash ?? this.pinHash,
      isPartner: isPartner ?? this.isPartner,
      partnerShare: partnerShare ?? this.partnerShare,
      active: active ?? this.active,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (isPartner.present) {
      map['is_partner'] = Variable<bool>(isPartner.value);
    }
    if (partnerShare.present) {
      map['partner_share'] = Variable<double>(partnerShare.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('pinHash: $pinHash, ')
          ..write('isPartner: $isPartner, ')
          ..write('partnerShare: $partnerShare, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DeviceTypesTable extends DeviceTypes
    with TableInfo<$DeviceTypesTable, DeviceTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _defaultHourlyRateMeta =
      const VerificationMeta('defaultHourlyRate');
  @override
  late final GeneratedColumn<double> defaultHourlyRate =
      GeneratedColumn<double>('default_hourly_rate', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _defaultHourlyRateMultiMeta =
      const VerificationMeta('defaultHourlyRateMulti');
  @override
  late final GeneratedColumn<double> defaultHourlyRateMulti =
      GeneratedColumn<double>('default_hourly_rate_multi', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, defaultHourlyRate, defaultHourlyRateMulti];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_types';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceTypeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('default_hourly_rate')) {
      context.handle(
          _defaultHourlyRateMeta,
          defaultHourlyRate.isAcceptableOrUnknown(
              data['default_hourly_rate']!, _defaultHourlyRateMeta));
    }
    if (data.containsKey('default_hourly_rate_multi')) {
      context.handle(
          _defaultHourlyRateMultiMeta,
          defaultHourlyRateMulti.isAcceptableOrUnknown(
              data['default_hourly_rate_multi']!, _defaultHourlyRateMultiMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name},
      ];
  @override
  DeviceTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceTypeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      defaultHourlyRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}default_hourly_rate'])!,
      defaultHourlyRateMulti: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}default_hourly_rate_multi'])!,
    );
  }

  @override
  $DeviceTypesTable createAlias(String alias) {
    return $DeviceTypesTable(attachedDatabase, alias);
  }
}

class DeviceTypeRow extends DataClass implements Insertable<DeviceTypeRow> {
  final int id;
  final String name;
  final double defaultHourlyRate;
  final double defaultHourlyRateMulti;
  const DeviceTypeRow(
      {required this.id,
      required this.name,
      required this.defaultHourlyRate,
      required this.defaultHourlyRateMulti});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['default_hourly_rate'] = Variable<double>(defaultHourlyRate);
    map['default_hourly_rate_multi'] = Variable<double>(defaultHourlyRateMulti);
    return map;
  }

  DeviceTypesCompanion toCompanion(bool nullToAbsent) {
    return DeviceTypesCompanion(
      id: Value(id),
      name: Value(name),
      defaultHourlyRate: Value(defaultHourlyRate),
      defaultHourlyRateMulti: Value(defaultHourlyRateMulti),
    );
  }

  factory DeviceTypeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceTypeRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      defaultHourlyRate: serializer.fromJson<double>(json['defaultHourlyRate']),
      defaultHourlyRateMulti:
          serializer.fromJson<double>(json['defaultHourlyRateMulti']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'defaultHourlyRate': serializer.toJson<double>(defaultHourlyRate),
      'defaultHourlyRateMulti':
          serializer.toJson<double>(defaultHourlyRateMulti),
    };
  }

  DeviceTypeRow copyWith(
          {int? id,
          String? name,
          double? defaultHourlyRate,
          double? defaultHourlyRateMulti}) =>
      DeviceTypeRow(
        id: id ?? this.id,
        name: name ?? this.name,
        defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
        defaultHourlyRateMulti:
            defaultHourlyRateMulti ?? this.defaultHourlyRateMulti,
      );
  DeviceTypeRow copyWithCompanion(DeviceTypesCompanion data) {
    return DeviceTypeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      defaultHourlyRate: data.defaultHourlyRate.present
          ? data.defaultHourlyRate.value
          : this.defaultHourlyRate,
      defaultHourlyRateMulti: data.defaultHourlyRateMulti.present
          ? data.defaultHourlyRateMulti.value
          : this.defaultHourlyRateMulti,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTypeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('defaultHourlyRate: $defaultHourlyRate, ')
          ..write('defaultHourlyRateMulti: $defaultHourlyRateMulti')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, defaultHourlyRate, defaultHourlyRateMulti);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceTypeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.defaultHourlyRate == this.defaultHourlyRate &&
          other.defaultHourlyRateMulti == this.defaultHourlyRateMulti);
}

class DeviceTypesCompanion extends UpdateCompanion<DeviceTypeRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> defaultHourlyRate;
  final Value<double> defaultHourlyRateMulti;
  const DeviceTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.defaultHourlyRate = const Value.absent(),
    this.defaultHourlyRateMulti = const Value.absent(),
  });
  DeviceTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.defaultHourlyRate = const Value.absent(),
    this.defaultHourlyRateMulti = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DeviceTypeRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? defaultHourlyRate,
    Expression<double>? defaultHourlyRateMulti,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (defaultHourlyRate != null) 'default_hourly_rate': defaultHourlyRate,
      if (defaultHourlyRateMulti != null)
        'default_hourly_rate_multi': defaultHourlyRateMulti,
    });
  }

  DeviceTypesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? defaultHourlyRate,
      Value<double>? defaultHourlyRateMulti}) {
    return DeviceTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      defaultHourlyRateMulti:
          defaultHourlyRateMulti ?? this.defaultHourlyRateMulti,
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
    if (defaultHourlyRate.present) {
      map['default_hourly_rate'] = Variable<double>(defaultHourlyRate.value);
    }
    if (defaultHourlyRateMulti.present) {
      map['default_hourly_rate_multi'] =
          Variable<double>(defaultHourlyRateMulti.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('defaultHourlyRate: $defaultHourlyRate, ')
          ..write('defaultHourlyRateMulti: $defaultHourlyRateMulti')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _deviceTypeIdMeta =
      const VerificationMeta('deviceTypeId');
  @override
  late final GeneratedColumn<int> deviceTypeId = GeneratedColumn<int>(
      'device_type_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES device_types (id)'));
  static const VerificationMeta _customHourlyRateMeta =
      const VerificationMeta('customHourlyRate');
  @override
  late final GeneratedColumn<double> customHourlyRate = GeneratedColumn<double>(
      'custom_hourly_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _customHourlyRateMultiMeta =
      const VerificationMeta('customHourlyRateMulti');
  @override
  late final GeneratedColumn<double> customHourlyRateMulti =
      GeneratedColumn<double>('custom_hourly_rate_multi', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('available'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        deviceTypeId,
        customHourlyRate,
        customHourlyRateMulti,
        status,
        notes,
        active,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_type_id')) {
      context.handle(
          _deviceTypeIdMeta,
          deviceTypeId.isAcceptableOrUnknown(
              data['device_type_id']!, _deviceTypeIdMeta));
    } else if (isInserting) {
      context.missing(_deviceTypeIdMeta);
    }
    if (data.containsKey('custom_hourly_rate')) {
      context.handle(
          _customHourlyRateMeta,
          customHourlyRate.isAcceptableOrUnknown(
              data['custom_hourly_rate']!, _customHourlyRateMeta));
    }
    if (data.containsKey('custom_hourly_rate_multi')) {
      context.handle(
          _customHourlyRateMultiMeta,
          customHourlyRateMulti.isAcceptableOrUnknown(
              data['custom_hourly_rate_multi']!, _customHourlyRateMultiMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      deviceTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_type_id'])!,
      customHourlyRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}custom_hourly_rate']),
      customHourlyRateMulti: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}custom_hourly_rate_multi']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final int id;
  final String name;
  final int deviceTypeId;
  final double? customHourlyRate;
  final double? customHourlyRateMulti;
  final String status;
  final String? notes;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DeviceRow(
      {required this.id,
      required this.name,
      required this.deviceTypeId,
      this.customHourlyRate,
      this.customHourlyRateMulti,
      required this.status,
      this.notes,
      required this.active,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['device_type_id'] = Variable<int>(deviceTypeId);
    if (!nullToAbsent || customHourlyRate != null) {
      map['custom_hourly_rate'] = Variable<double>(customHourlyRate);
    }
    if (!nullToAbsent || customHourlyRateMulti != null) {
      map['custom_hourly_rate_multi'] = Variable<double>(customHourlyRateMulti);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      deviceTypeId: Value(deviceTypeId),
      customHourlyRate: customHourlyRate == null && nullToAbsent
          ? const Value.absent()
          : Value(customHourlyRate),
      customHourlyRateMulti: customHourlyRateMulti == null && nullToAbsent
          ? const Value.absent()
          : Value(customHourlyRateMulti),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeviceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deviceTypeId: serializer.fromJson<int>(json['deviceTypeId']),
      customHourlyRate: serializer.fromJson<double?>(json['customHourlyRate']),
      customHourlyRateMulti:
          serializer.fromJson<double?>(json['customHourlyRateMulti']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      active: serializer.fromJson<bool>(json['active']),
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
      'deviceTypeId': serializer.toJson<int>(deviceTypeId),
      'customHourlyRate': serializer.toJson<double?>(customHourlyRate),
      'customHourlyRateMulti':
          serializer.toJson<double?>(customHourlyRateMulti),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeviceRow copyWith(
          {int? id,
          String? name,
          int? deviceTypeId,
          Value<double?> customHourlyRate = const Value.absent(),
          Value<double?> customHourlyRateMulti = const Value.absent(),
          String? status,
          Value<String?> notes = const Value.absent(),
          bool? active,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DeviceRow(
        id: id ?? this.id,
        name: name ?? this.name,
        deviceTypeId: deviceTypeId ?? this.deviceTypeId,
        customHourlyRate: customHourlyRate.present
            ? customHourlyRate.value
            : this.customHourlyRate,
        customHourlyRateMulti: customHourlyRateMulti.present
            ? customHourlyRateMulti.value
            : this.customHourlyRateMulti,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DeviceRow copyWithCompanion(DevicesCompanion data) {
    return DeviceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deviceTypeId: data.deviceTypeId.present
          ? data.deviceTypeId.value
          : this.deviceTypeId,
      customHourlyRate: data.customHourlyRate.present
          ? data.customHourlyRate.value
          : this.customHourlyRate,
      customHourlyRateMulti: data.customHourlyRateMulti.present
          ? data.customHourlyRateMulti.value
          : this.customHourlyRateMulti,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceTypeId: $deviceTypeId, ')
          ..write('customHourlyRate: $customHourlyRate, ')
          ..write('customHourlyRateMulti: $customHourlyRateMulti, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, deviceTypeId, customHourlyRate,
      customHourlyRateMulti, status, notes, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.deviceTypeId == this.deviceTypeId &&
          other.customHourlyRate == this.customHourlyRate &&
          other.customHourlyRateMulti == this.customHourlyRateMulti &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DevicesCompanion extends UpdateCompanion<DeviceRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> deviceTypeId;
  final Value<double?> customHourlyRate;
  final Value<double?> customHourlyRateMulti;
  final Value<String> status;
  final Value<String?> notes;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceTypeId = const Value.absent(),
    this.customHourlyRate = const Value.absent(),
    this.customHourlyRateMulti = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int deviceTypeId,
    this.customHourlyRate = const Value.absent(),
    this.customHourlyRateMulti = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        deviceTypeId = Value(deviceTypeId);
  static Insertable<DeviceRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? deviceTypeId,
    Expression<double>? customHourlyRate,
    Expression<double>? customHourlyRateMulti,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deviceTypeId != null) 'device_type_id': deviceTypeId,
      if (customHourlyRate != null) 'custom_hourly_rate': customHourlyRate,
      if (customHourlyRateMulti != null)
        'custom_hourly_rate_multi': customHourlyRateMulti,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DevicesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? deviceTypeId,
      Value<double?>? customHourlyRate,
      Value<double?>? customHourlyRateMulti,
      Value<String>? status,
      Value<String?>? notes,
      Value<bool>? active,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceTypeId: deviceTypeId ?? this.deviceTypeId,
      customHourlyRate: customHourlyRate ?? this.customHourlyRate,
      customHourlyRateMulti:
          customHourlyRateMulti ?? this.customHourlyRateMulti,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      active: active ?? this.active,
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
    if (deviceTypeId.present) {
      map['device_type_id'] = Variable<int>(deviceTypeId.value);
    }
    if (customHourlyRate.present) {
      map['custom_hourly_rate'] = Variable<double>(customHourlyRate.value);
    }
    if (customHourlyRateMulti.present) {
      map['custom_hourly_rate_multi'] =
          Variable<double>(customHourlyRateMulti.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceTypeId: $deviceTypeId, ')
          ..write('customHourlyRate: $customHourlyRate, ')
          ..write('customHourlyRateMulti: $customHourlyRateMulti, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalVisitsMeta =
      const VerificationMeta('totalVisits');
  @override
  late final GeneratedColumn<int> totalVisits = GeneratedColumn<int>(
      'total_visits', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSpentMeta =
      const VerificationMeta('totalSpent');
  @override
  late final GeneratedColumn<double> totalSpent = GeneratedColumn<double>(
      'total_spent', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _loyaltyPointsMeta =
      const VerificationMeta('loyaltyPoints');
  @override
  late final GeneratedColumn<int> loyaltyPoints = GeneratedColumn<int>(
      'loyalty_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _customerLevelMeta =
      const VerificationMeta('customerLevel');
  @override
  late final GeneratedColumn<String> customerLevel = GeneratedColumn<String>(
      'customer_level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Regular'));
  static const VerificationMeta _isVipMeta = const VerificationMeta('isVip');
  @override
  late final GeneratedColumn<bool> isVip = GeneratedColumn<bool>(
      'is_vip', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_vip" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        email,
        notes,
        totalVisits,
        totalSpent,
        loyaltyPoints,
        customerLevel,
        isVip,
        active,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<CustomerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('total_visits')) {
      context.handle(
          _totalVisitsMeta,
          totalVisits.isAcceptableOrUnknown(
              data['total_visits']!, _totalVisitsMeta));
    }
    if (data.containsKey('total_spent')) {
      context.handle(
          _totalSpentMeta,
          totalSpent.isAcceptableOrUnknown(
              data['total_spent']!, _totalSpentMeta));
    }
    if (data.containsKey('loyalty_points')) {
      context.handle(
          _loyaltyPointsMeta,
          loyaltyPoints.isAcceptableOrUnknown(
              data['loyalty_points']!, _loyaltyPointsMeta));
    }
    if (data.containsKey('customer_level')) {
      context.handle(
          _customerLevelMeta,
          customerLevel.isAcceptableOrUnknown(
              data['customer_level']!, _customerLevelMeta));
    }
    if (data.containsKey('is_vip')) {
      context.handle(
          _isVipMeta, isVip.isAcceptableOrUnknown(data['is_vip']!, _isVipMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {phone},
      ];
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      totalVisits: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_visits'])!,
      totalSpent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_spent'])!,
      loyaltyPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}loyalty_points'])!,
      customerLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_level'])!,
      isVip: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_vip'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? notes;
  final int totalVisits;
  final double totalSpent;
  final int loyaltyPoints;
  final String customerLevel;
  final bool isVip;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CustomerRow(
      {required this.id,
      required this.name,
      required this.phone,
      this.email,
      this.notes,
      required this.totalVisits,
      required this.totalSpent,
      required this.loyaltyPoints,
      required this.customerLevel,
      required this.isVip,
      required this.active,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['total_visits'] = Variable<int>(totalVisits);
    map['total_spent'] = Variable<double>(totalSpent);
    map['loyalty_points'] = Variable<int>(loyaltyPoints);
    map['customer_level'] = Variable<String>(customerLevel);
    map['is_vip'] = Variable<bool>(isVip);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      totalVisits: Value(totalVisits),
      totalSpent: Value(totalSpent),
      loyaltyPoints: Value(loyaltyPoints),
      customerLevel: Value(customerLevel),
      isVip: Value(isVip),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      notes: serializer.fromJson<String?>(json['notes']),
      totalVisits: serializer.fromJson<int>(json['totalVisits']),
      totalSpent: serializer.fromJson<double>(json['totalSpent']),
      loyaltyPoints: serializer.fromJson<int>(json['loyaltyPoints']),
      customerLevel: serializer.fromJson<String>(json['customerLevel']),
      isVip: serializer.fromJson<bool>(json['isVip']),
      active: serializer.fromJson<bool>(json['active']),
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
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String?>(email),
      'notes': serializer.toJson<String?>(notes),
      'totalVisits': serializer.toJson<int>(totalVisits),
      'totalSpent': serializer.toJson<double>(totalSpent),
      'loyaltyPoints': serializer.toJson<int>(loyaltyPoints),
      'customerLevel': serializer.toJson<String>(customerLevel),
      'isVip': serializer.toJson<bool>(isVip),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomerRow copyWith(
          {int? id,
          String? name,
          String? phone,
          Value<String?> email = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          int? totalVisits,
          double? totalSpent,
          int? loyaltyPoints,
          String? customerLevel,
          bool? isVip,
          bool? active,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CustomerRow(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email.present ? email.value : this.email,
        notes: notes.present ? notes.value : this.notes,
        totalVisits: totalVisits ?? this.totalVisits,
        totalSpent: totalSpent ?? this.totalSpent,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
        customerLevel: customerLevel ?? this.customerLevel,
        isVip: isVip ?? this.isVip,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      notes: data.notes.present ? data.notes.value : this.notes,
      totalVisits:
          data.totalVisits.present ? data.totalVisits.value : this.totalVisits,
      totalSpent:
          data.totalSpent.present ? data.totalSpent.value : this.totalSpent,
      loyaltyPoints: data.loyaltyPoints.present
          ? data.loyaltyPoints.value
          : this.loyaltyPoints,
      customerLevel: data.customerLevel.present
          ? data.customerLevel.value
          : this.customerLevel,
      isVip: data.isVip.present ? data.isVip.value : this.isVip,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('notes: $notes, ')
          ..write('totalVisits: $totalVisits, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('customerLevel: $customerLevel, ')
          ..write('isVip: $isVip, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      phone,
      email,
      notes,
      totalVisits,
      totalSpent,
      loyaltyPoints,
      customerLevel,
      isVip,
      active,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.notes == this.notes &&
          other.totalVisits == this.totalVisits &&
          other.totalSpent == this.totalSpent &&
          other.loyaltyPoints == this.loyaltyPoints &&
          other.customerLevel == this.customerLevel &&
          other.isVip == this.isVip &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String?> email;
  final Value<String?> notes;
  final Value<int> totalVisits;
  final Value<double> totalSpent;
  final Value<int> loyaltyPoints;
  final Value<String> customerLevel;
  final Value<bool> isVip;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalVisits = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.customerLevel = const Value.absent(),
    this.isVip = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String phone,
    this.email = const Value.absent(),
    this.notes = const Value.absent(),
    this.totalVisits = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.customerLevel = const Value.absent(),
    this.isVip = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        phone = Value(phone);
  static Insertable<CustomerRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? notes,
    Expression<int>? totalVisits,
    Expression<double>? totalSpent,
    Expression<int>? loyaltyPoints,
    Expression<String>? customerLevel,
    Expression<bool>? isVip,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (notes != null) 'notes': notes,
      if (totalVisits != null) 'total_visits': totalVisits,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
      if (customerLevel != null) 'customer_level': customerLevel,
      if (isVip != null) 'is_vip': isVip,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CustomersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<String?>? email,
      Value<String?>? notes,
      Value<int>? totalVisits,
      Value<double>? totalSpent,
      Value<int>? loyaltyPoints,
      Value<String>? customerLevel,
      Value<bool>? isVip,
      Value<bool>? active,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      customerLevel: customerLevel ?? this.customerLevel,
      isVip: isVip ?? this.isVip,
      active: active ?? this.active,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (totalVisits.present) {
      map['total_visits'] = Variable<int>(totalVisits.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<double>(totalSpent.value);
    }
    if (loyaltyPoints.present) {
      map['loyalty_points'] = Variable<int>(loyaltyPoints.value);
    }
    if (customerLevel.present) {
      map['customer_level'] = Variable<String>(customerLevel.value);
    }
    if (isVip.present) {
      map['is_vip'] = Variable<bool>(isVip.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('notes: $notes, ')
          ..write('totalVisits: $totalVisits, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('customerLevel: $customerLevel, ')
          ..write('isVip: $isVip, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name},
      ];
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  const CategoryRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  CategoryRow copyWith({int? id, String? name}) => CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow && other.id == this.id && other.name == this.name);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  CategoriesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sellingPriceMeta =
      const VerificationMeta('sellingPrice');
  @override
  late final GeneratedColumn<double> sellingPrice = GeneratedColumn<double>(
      'selling_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stockQuantityMeta =
      const VerificationMeta('stockQuantity');
  @override
  late final GeneratedColumn<int> stockQuantity = GeneratedColumn<int>(
      'stock_quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minimumStockMeta =
      const VerificationMeta('minimumStock');
  @override
  late final GeneratedColumn<int> minimumStock = GeneratedColumn<int>(
      'minimum_stock', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _maximumStockMeta =
      const VerificationMeta('maximumStock');
  @override
  late final GeneratedColumn<int> maximumStock = GeneratedColumn<int>(
      'maximum_stock', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('قطعة'));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        categoryId,
        sku,
        barcode,
        costPrice,
        sellingPrice,
        stockQuantity,
        minimumStock,
        maximumStock,
        unit,
        active,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<ProductRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('selling_price')) {
      context.handle(
          _sellingPriceMeta,
          sellingPrice.isAcceptableOrUnknown(
              data['selling_price']!, _sellingPriceMeta));
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
          _stockQuantityMeta,
          stockQuantity.isAcceptableOrUnknown(
              data['stock_quantity']!, _stockQuantityMeta));
    }
    if (data.containsKey('minimum_stock')) {
      context.handle(
          _minimumStockMeta,
          minimumStock.isAcceptableOrUnknown(
              data['minimum_stock']!, _minimumStockMeta));
    }
    if (data.containsKey('maximum_stock')) {
      context.handle(
          _maximumStockMeta,
          maximumStock.isAcceptableOrUnknown(
              data['maximum_stock']!, _maximumStockMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price'])!,
      sellingPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}selling_price'])!,
      stockQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_quantity'])!,
      minimumStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minimum_stock'])!,
      maximumStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}maximum_stock']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final int id;
  final String name;
  final int categoryId;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int minimumStock;
  final int? maximumStock;
  final String unit;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductRow(
      {required this.id,
      required this.name,
      required this.categoryId,
      this.sku,
      this.barcode,
      required this.costPrice,
      required this.sellingPrice,
      required this.stockQuantity,
      required this.minimumStock,
      this.maximumStock,
      required this.unit,
      required this.active,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['cost_price'] = Variable<double>(costPrice);
    map['selling_price'] = Variable<double>(sellingPrice);
    map['stock_quantity'] = Variable<int>(stockQuantity);
    map['minimum_stock'] = Variable<int>(minimumStock);
    if (!nullToAbsent || maximumStock != null) {
      map['maximum_stock'] = Variable<int>(maximumStock);
    }
    map['unit'] = Variable<String>(unit);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: Value(categoryId),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      costPrice: Value(costPrice),
      sellingPrice: Value(sellingPrice),
      stockQuantity: Value(stockQuantity),
      minimumStock: Value(minimumStock),
      maximumStock: maximumStock == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumStock),
      unit: Value(unit),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      sellingPrice: serializer.fromJson<double>(json['sellingPrice']),
      stockQuantity: serializer.fromJson<int>(json['stockQuantity']),
      minimumStock: serializer.fromJson<int>(json['minimumStock']),
      maximumStock: serializer.fromJson<int?>(json['maximumStock']),
      unit: serializer.fromJson<String>(json['unit']),
      active: serializer.fromJson<bool>(json['active']),
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
      'categoryId': serializer.toJson<int>(categoryId),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'costPrice': serializer.toJson<double>(costPrice),
      'sellingPrice': serializer.toJson<double>(sellingPrice),
      'stockQuantity': serializer.toJson<int>(stockQuantity),
      'minimumStock': serializer.toJson<int>(minimumStock),
      'maximumStock': serializer.toJson<int?>(maximumStock),
      'unit': serializer.toJson<String>(unit),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductRow copyWith(
          {int? id,
          String? name,
          int? categoryId,
          Value<String?> sku = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          double? costPrice,
          double? sellingPrice,
          int? stockQuantity,
          int? minimumStock,
          Value<int?> maximumStock = const Value.absent(),
          String? unit,
          bool? active,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ProductRow(
        id: id ?? this.id,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        sku: sku.present ? sku.value : this.sku,
        barcode: barcode.present ? barcode.value : this.barcode,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        minimumStock: minimumStock ?? this.minimumStock,
        maximumStock:
            maximumStock.present ? maximumStock.value : this.maximumStock,
        unit: unit ?? this.unit,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      minimumStock: data.minimumStock.present
          ? data.minimumStock.value
          : this.minimumStock,
      maximumStock: data.maximumStock.present
          ? data.maximumStock.value
          : this.maximumStock,
      unit: data.unit.present ? data.unit.value : this.unit,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minimumStock: $minimumStock, ')
          ..write('maximumStock: $maximumStock, ')
          ..write('unit: $unit, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      categoryId,
      sku,
      barcode,
      costPrice,
      sellingPrice,
      stockQuantity,
      minimumStock,
      maximumStock,
      unit,
      active,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.costPrice == this.costPrice &&
          other.sellingPrice == this.sellingPrice &&
          other.stockQuantity == this.stockQuantity &&
          other.minimumStock == this.minimumStock &&
          other.maximumStock == this.maximumStock &&
          other.unit == this.unit &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> categoryId;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<double> costPrice;
  final Value<double> sellingPrice;
  final Value<int> stockQuantity;
  final Value<int> minimumStock;
  final Value<int?> maximumStock;
  final Value<String> unit;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minimumStock = const Value.absent(),
    this.maximumStock = const Value.absent(),
    this.unit = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int categoryId,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minimumStock = const Value.absent(),
    this.maximumStock = const Value.absent(),
    this.unit = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        categoryId = Value(categoryId);
  static Insertable<ProductRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<double>? costPrice,
    Expression<double>? sellingPrice,
    Expression<int>? stockQuantity,
    Expression<int>? minimumStock,
    Expression<int>? maximumStock,
    Expression<String>? unit,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (minimumStock != null) 'minimum_stock': minimumStock,
      if (maximumStock != null) 'maximum_stock': maximumStock,
      if (unit != null) 'unit': unit,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? categoryId,
      Value<String?>? sku,
      Value<String?>? barcode,
      Value<double>? costPrice,
      Value<double>? sellingPrice,
      Value<int>? stockQuantity,
      Value<int>? minimumStock,
      Value<int?>? maximumStock,
      Value<String>? unit,
      Value<bool>? active,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      unit: unit ?? this.unit,
      active: active ?? this.active,
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
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<double>(sellingPrice.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<int>(stockQuantity.value);
    }
    if (minimumStock.present) {
      map['minimum_stock'] = Variable<int>(minimumStock.value);
    }
    if (maximumStock.present) {
      map['maximum_stock'] = Variable<int>(maximumStock.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('costPrice: $costPrice, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minimumStock: $minimumStock, ')
          ..write('maximumStock: $maximumStock, ')
          ..write('unit: $unit, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PackagesTable extends Packages
    with TableInfo<$PackagesTable, PackageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PackagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _deviceTypeIdMeta =
      const VerificationMeta('deviceTypeId');
  @override
  late final GeneratedColumn<int> deviceTypeId = GeneratedColumn<int>(
      'device_type_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES device_types (id)'));
  static const VerificationMeta _fixedPriceMeta =
      const VerificationMeta('fixedPrice');
  @override
  late final GeneratedColumn<double> fixedPrice = GeneratedColumn<double>(
      'fixed_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(60));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, deviceTypeId, fixedPrice, durationMinutes, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packages';
  @override
  VerificationContext validateIntegrity(Insertable<PackageRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_type_id')) {
      context.handle(
          _deviceTypeIdMeta,
          deviceTypeId.isAcceptableOrUnknown(
              data['device_type_id']!, _deviceTypeIdMeta));
    } else if (isInserting) {
      context.missing(_deviceTypeIdMeta);
    }
    if (data.containsKey('fixed_price')) {
      context.handle(
          _fixedPriceMeta,
          fixedPrice.isAcceptableOrUnknown(
              data['fixed_price']!, _fixedPriceMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PackageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PackageRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      deviceTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_type_id'])!,
      fixedPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fixed_price'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PackagesTable createAlias(String alias) {
    return $PackagesTable(attachedDatabase, alias);
  }
}

class PackageRow extends DataClass implements Insertable<PackageRow> {
  final int id;
  final String name;
  final int deviceTypeId;
  final double fixedPrice;
  final int durationMinutes;
  final bool active;
  final DateTime createdAt;
  const PackageRow(
      {required this.id,
      required this.name,
      required this.deviceTypeId,
      required this.fixedPrice,
      required this.durationMinutes,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['device_type_id'] = Variable<int>(deviceTypeId);
    map['fixed_price'] = Variable<double>(fixedPrice);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PackagesCompanion toCompanion(bool nullToAbsent) {
    return PackagesCompanion(
      id: Value(id),
      name: Value(name),
      deviceTypeId: Value(deviceTypeId),
      fixedPrice: Value(fixedPrice),
      durationMinutes: Value(durationMinutes),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory PackageRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PackageRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deviceTypeId: serializer.fromJson<int>(json['deviceTypeId']),
      fixedPrice: serializer.fromJson<double>(json['fixedPrice']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'deviceTypeId': serializer.toJson<int>(deviceTypeId),
      'fixedPrice': serializer.toJson<double>(fixedPrice),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PackageRow copyWith(
          {int? id,
          String? name,
          int? deviceTypeId,
          double? fixedPrice,
          int? durationMinutes,
          bool? active,
          DateTime? createdAt}) =>
      PackageRow(
        id: id ?? this.id,
        name: name ?? this.name,
        deviceTypeId: deviceTypeId ?? this.deviceTypeId,
        fixedPrice: fixedPrice ?? this.fixedPrice,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  PackageRow copyWithCompanion(PackagesCompanion data) {
    return PackageRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deviceTypeId: data.deviceTypeId.present
          ? data.deviceTypeId.value
          : this.deviceTypeId,
      fixedPrice:
          data.fixedPrice.present ? data.fixedPrice.value : this.fixedPrice,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PackageRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceTypeId: $deviceTypeId, ')
          ..write('fixedPrice: $fixedPrice, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, deviceTypeId, fixedPrice, durationMinutes, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PackageRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.deviceTypeId == this.deviceTypeId &&
          other.fixedPrice == this.fixedPrice &&
          other.durationMinutes == this.durationMinutes &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class PackagesCompanion extends UpdateCompanion<PackageRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> deviceTypeId;
  final Value<double> fixedPrice;
  final Value<int> durationMinutes;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const PackagesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceTypeId = const Value.absent(),
    this.fixedPrice = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PackagesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int deviceTypeId,
    this.fixedPrice = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        deviceTypeId = Value(deviceTypeId);
  static Insertable<PackageRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? deviceTypeId,
    Expression<double>? fixedPrice,
    Expression<int>? durationMinutes,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deviceTypeId != null) 'device_type_id': deviceTypeId,
      if (fixedPrice != null) 'fixed_price': fixedPrice,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PackagesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? deviceTypeId,
      Value<double>? fixedPrice,
      Value<int>? durationMinutes,
      Value<bool>? active,
      Value<DateTime>? createdAt}) {
    return PackagesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceTypeId: deviceTypeId ?? this.deviceTypeId,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
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
    if (deviceTypeId.present) {
      map['device_type_id'] = Variable<int>(deviceTypeId.value);
    }
    if (fixedPrice.present) {
      map['fixed_price'] = Variable<double>(fixedPrice.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PackagesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceTypeId: $deviceTypeId, ')
          ..write('fixedPrice: $fixedPrice, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('active: $active, ')
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
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
      'device_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES devices (id)'));
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _pausedAtMeta =
      const VerificationMeta('pausedAt');
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
      'paused_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalPausedMinutesMeta =
      const VerificationMeta('totalPausedMinutes');
  @override
  late final GeneratedColumn<double> totalPausedMinutes =
      GeneratedColumn<double>('total_paused_minutes', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('single'));
  static const VerificationMeta _accumulatedCostMeta =
      const VerificationMeta('accumulatedCost');
  @override
  late final GeneratedColumn<double> accumulatedCost = GeneratedColumn<double>(
      'accumulated_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _singleCostMeta =
      const VerificationMeta('singleCost');
  @override
  late final GeneratedColumn<double> singleCost = GeneratedColumn<double>(
      'single_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _multiCostMeta =
      const VerificationMeta('multiCost');
  @override
  late final GeneratedColumn<double> multiCost = GeneratedColumn<double>(
      'multi_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _segmentStartAtMeta =
      const VerificationMeta('segmentStartAt');
  @override
  late final GeneratedColumn<DateTime> segmentStartAt =
      GeneratedColumn<DateTime>('segment_start_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _finalCostMeta =
      const VerificationMeta('finalCost');
  @override
  late final GeneratedColumn<double> finalCost = GeneratedColumn<double>(
      'final_cost', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _plannedMinutesMeta =
      const VerificationMeta('plannedMinutes');
  @override
  late final GeneratedColumn<int> plannedMinutes = GeneratedColumn<int>(
      'planned_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timeUpAtMeta =
      const VerificationMeta('timeUpAt');
  @override
  late final GeneratedColumn<DateTime> timeUpAt = GeneratedColumn<DateTime>(
      'time_up_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _packageIdMeta =
      const VerificationMeta('packageId');
  @override
  late final GeneratedColumn<int> packageId = GeneratedColumn<int>(
      'package_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES packages (id)'));
  static const VerificationMeta _fixedPriceMeta =
      const VerificationMeta('fixedPrice');
  @override
  late final GeneratedColumn<double> fixedPrice = GeneratedColumn<double>(
      'fixed_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        customerId,
        employeeId,
        startTime,
        pausedAt,
        totalPausedMinutes,
        mode,
        accumulatedCost,
        singleCost,
        multiCost,
        segmentStartAt,
        endTime,
        status,
        finalCost,
        plannedMinutes,
        timeUpAt,
        packageId,
        fixedPrice,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<SessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('paused_at')) {
      context.handle(_pausedAtMeta,
          pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta));
    }
    if (data.containsKey('total_paused_minutes')) {
      context.handle(
          _totalPausedMinutesMeta,
          totalPausedMinutes.isAcceptableOrUnknown(
              data['total_paused_minutes']!, _totalPausedMinutesMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    }
    if (data.containsKey('accumulated_cost')) {
      context.handle(
          _accumulatedCostMeta,
          accumulatedCost.isAcceptableOrUnknown(
              data['accumulated_cost']!, _accumulatedCostMeta));
    }
    if (data.containsKey('single_cost')) {
      context.handle(
          _singleCostMeta,
          singleCost.isAcceptableOrUnknown(
              data['single_cost']!, _singleCostMeta));
    }
    if (data.containsKey('multi_cost')) {
      context.handle(_multiCostMeta,
          multiCost.isAcceptableOrUnknown(data['multi_cost']!, _multiCostMeta));
    }
    if (data.containsKey('segment_start_at')) {
      context.handle(
          _segmentStartAtMeta,
          segmentStartAt.isAcceptableOrUnknown(
              data['segment_start_at']!, _segmentStartAtMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('final_cost')) {
      context.handle(_finalCostMeta,
          finalCost.isAcceptableOrUnknown(data['final_cost']!, _finalCostMeta));
    }
    if (data.containsKey('planned_minutes')) {
      context.handle(
          _plannedMinutesMeta,
          plannedMinutes.isAcceptableOrUnknown(
              data['planned_minutes']!, _plannedMinutesMeta));
    }
    if (data.containsKey('time_up_at')) {
      context.handle(_timeUpAtMeta,
          timeUpAt.isAcceptableOrUnknown(data['time_up_at']!, _timeUpAtMeta));
    }
    if (data.containsKey('package_id')) {
      context.handle(_packageIdMeta,
          packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta));
    }
    if (data.containsKey('fixed_price')) {
      context.handle(
          _fixedPriceMeta,
          fixedPrice.isAcceptableOrUnknown(
              data['fixed_price']!, _fixedPriceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_id']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      pausedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paused_at']),
      totalPausedMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_paused_minutes'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      accumulatedCost: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}accumulated_cost'])!,
      singleCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}single_cost'])!,
      multiCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}multi_cost'])!,
      segmentStartAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}segment_start_at']),
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      finalCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_cost']),
      plannedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_minutes']),
      timeUpAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}time_up_at']),
      packageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}package_id']),
      fixedPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fixed_price']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final int deviceId;
  final int? customerId;

  /// The employee who opened/is running this session — used to
  /// attribute revenue per employee (spec: daily revenue by employee).
  final int? employeeId;
  final DateTime startTime;
  final DateTime? pausedAt;
  final double totalPausedMinutes;
  final String mode;

  /// Cost already locked in from previous segments (before the current
  /// one). The live/final cost is always accumulatedCost + whatever the
  /// current segment has accrued so far.
  final double accumulatedCost;

  /// What this sitting billed at each rate, kept apart from
  /// [accumulatedCost] so the detail sheet can say what the single play
  /// and the multi play each cost instead of only their sum.
  ///
  /// Folded forward by the same freeze that stops a segment — never
  /// recomputed from history — so the two always add to
  /// [accumulatedCost] exactly, with no rounding to explain.
  final double singleCost;
  final double multiCost;

  /// When the CURRENT segment began. Null while paused (no segment is
  /// running, so nothing is accruing cost).
  final DateTime? segmentStartAt;
  final DateTime? endTime;
  final String status;
  final double? finalCost;

  /// The fixed duration the cashier picked from the quick buttons
  /// (60 / 30 / 15 / 7). Null = open-ended session that never times out.
  final int? plannedMinutes;

  /// Absolute wall-clock moment the paid time runs out. Billing is hard
  /// capped at it (see SessionDao._freezeCurrentSegment), and the moment
  /// it passes the session flips itself to 'timeup': the cost stops and
  /// the device returns to the waiting row without the cashier touching
  /// anything. Pause pushes it forward by the paused duration so a pause
  /// never burns the customer's paid minutes.
  final DateTime? timeUpAt;

  /// Set when the session was started "from a package" — billing then
  /// becomes the flat [fixedPrice] instead of per-second segment
  /// accrual (segmentStartAt stays null for the whole session).
  final int? packageId;
  final double? fixedPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SessionRow(
      {required this.id,
      required this.deviceId,
      this.customerId,
      this.employeeId,
      required this.startTime,
      this.pausedAt,
      required this.totalPausedMinutes,
      required this.mode,
      required this.accumulatedCost,
      required this.singleCost,
      required this.multiCost,
      this.segmentStartAt,
      this.endTime,
      required this.status,
      this.finalCost,
      this.plannedMinutes,
      this.timeUpAt,
      this.packageId,
      this.fixedPrice,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<int>(deviceId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    map['total_paused_minutes'] = Variable<double>(totalPausedMinutes);
    map['mode'] = Variable<String>(mode);
    map['accumulated_cost'] = Variable<double>(accumulatedCost);
    map['single_cost'] = Variable<double>(singleCost);
    map['multi_cost'] = Variable<double>(multiCost);
    if (!nullToAbsent || segmentStartAt != null) {
      map['segment_start_at'] = Variable<DateTime>(segmentStartAt);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || finalCost != null) {
      map['final_cost'] = Variable<double>(finalCost);
    }
    if (!nullToAbsent || plannedMinutes != null) {
      map['planned_minutes'] = Variable<int>(plannedMinutes);
    }
    if (!nullToAbsent || timeUpAt != null) {
      map['time_up_at'] = Variable<DateTime>(timeUpAt);
    }
    if (!nullToAbsent || packageId != null) {
      map['package_id'] = Variable<int>(packageId);
    }
    if (!nullToAbsent || fixedPrice != null) {
      map['fixed_price'] = Variable<double>(fixedPrice);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      startTime: Value(startTime),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      totalPausedMinutes: Value(totalPausedMinutes),
      mode: Value(mode),
      accumulatedCost: Value(accumulatedCost),
      singleCost: Value(singleCost),
      multiCost: Value(multiCost),
      segmentStartAt: segmentStartAt == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentStartAt),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      status: Value(status),
      finalCost: finalCost == null && nullToAbsent
          ? const Value.absent()
          : Value(finalCost),
      plannedMinutes: plannedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedMinutes),
      timeUpAt: timeUpAt == null && nullToAbsent
          ? const Value.absent()
          : Value(timeUpAt),
      packageId: packageId == null && nullToAbsent
          ? const Value.absent()
          : Value(packageId),
      fixedPrice: fixedPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedPrice),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      totalPausedMinutes:
          serializer.fromJson<double>(json['totalPausedMinutes']),
      mode: serializer.fromJson<String>(json['mode']),
      accumulatedCost: serializer.fromJson<double>(json['accumulatedCost']),
      singleCost: serializer.fromJson<double>(json['singleCost']),
      multiCost: serializer.fromJson<double>(json['multiCost']),
      segmentStartAt: serializer.fromJson<DateTime?>(json['segmentStartAt']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      finalCost: serializer.fromJson<double?>(json['finalCost']),
      plannedMinutes: serializer.fromJson<int?>(json['plannedMinutes']),
      timeUpAt: serializer.fromJson<DateTime?>(json['timeUpAt']),
      packageId: serializer.fromJson<int?>(json['packageId']),
      fixedPrice: serializer.fromJson<double?>(json['fixedPrice']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<int>(deviceId),
      'customerId': serializer.toJson<int?>(customerId),
      'employeeId': serializer.toJson<int?>(employeeId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'totalPausedMinutes': serializer.toJson<double>(totalPausedMinutes),
      'mode': serializer.toJson<String>(mode),
      'accumulatedCost': serializer.toJson<double>(accumulatedCost),
      'singleCost': serializer.toJson<double>(singleCost),
      'multiCost': serializer.toJson<double>(multiCost),
      'segmentStartAt': serializer.toJson<DateTime?>(segmentStartAt),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'status': serializer.toJson<String>(status),
      'finalCost': serializer.toJson<double?>(finalCost),
      'plannedMinutes': serializer.toJson<int?>(plannedMinutes),
      'timeUpAt': serializer.toJson<DateTime?>(timeUpAt),
      'packageId': serializer.toJson<int?>(packageId),
      'fixedPrice': serializer.toJson<double?>(fixedPrice),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessionRow copyWith(
          {int? id,
          int? deviceId,
          Value<int?> customerId = const Value.absent(),
          Value<int?> employeeId = const Value.absent(),
          DateTime? startTime,
          Value<DateTime?> pausedAt = const Value.absent(),
          double? totalPausedMinutes,
          String? mode,
          double? accumulatedCost,
          double? singleCost,
          double? multiCost,
          Value<DateTime?> segmentStartAt = const Value.absent(),
          Value<DateTime?> endTime = const Value.absent(),
          String? status,
          Value<double?> finalCost = const Value.absent(),
          Value<int?> plannedMinutes = const Value.absent(),
          Value<DateTime?> timeUpAt = const Value.absent(),
          Value<int?> packageId = const Value.absent(),
          Value<double?> fixedPrice = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SessionRow(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        customerId: customerId.present ? customerId.value : this.customerId,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        startTime: startTime ?? this.startTime,
        pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
        totalPausedMinutes: totalPausedMinutes ?? this.totalPausedMinutes,
        mode: mode ?? this.mode,
        accumulatedCost: accumulatedCost ?? this.accumulatedCost,
        singleCost: singleCost ?? this.singleCost,
        multiCost: multiCost ?? this.multiCost,
        segmentStartAt:
            segmentStartAt.present ? segmentStartAt.value : this.segmentStartAt,
        endTime: endTime.present ? endTime.value : this.endTime,
        status: status ?? this.status,
        finalCost: finalCost.present ? finalCost.value : this.finalCost,
        plannedMinutes:
            plannedMinutes.present ? plannedMinutes.value : this.plannedMinutes,
        timeUpAt: timeUpAt.present ? timeUpAt.value : this.timeUpAt,
        packageId: packageId.present ? packageId.value : this.packageId,
        fixedPrice: fixedPrice.present ? fixedPrice.value : this.fixedPrice,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      totalPausedMinutes: data.totalPausedMinutes.present
          ? data.totalPausedMinutes.value
          : this.totalPausedMinutes,
      mode: data.mode.present ? data.mode.value : this.mode,
      accumulatedCost: data.accumulatedCost.present
          ? data.accumulatedCost.value
          : this.accumulatedCost,
      singleCost:
          data.singleCost.present ? data.singleCost.value : this.singleCost,
      multiCost: data.multiCost.present ? data.multiCost.value : this.multiCost,
      segmentStartAt: data.segmentStartAt.present
          ? data.segmentStartAt.value
          : this.segmentStartAt,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      finalCost: data.finalCost.present ? data.finalCost.value : this.finalCost,
      plannedMinutes: data.plannedMinutes.present
          ? data.plannedMinutes.value
          : this.plannedMinutes,
      timeUpAt: data.timeUpAt.present ? data.timeUpAt.value : this.timeUpAt,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      fixedPrice:
          data.fixedPrice.present ? data.fixedPrice.value : this.fixedPrice,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('customerId: $customerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('startTime: $startTime, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('totalPausedMinutes: $totalPausedMinutes, ')
          ..write('mode: $mode, ')
          ..write('accumulatedCost: $accumulatedCost, ')
          ..write('singleCost: $singleCost, ')
          ..write('multiCost: $multiCost, ')
          ..write('segmentStartAt: $segmentStartAt, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('finalCost: $finalCost, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('timeUpAt: $timeUpAt, ')
          ..write('packageId: $packageId, ')
          ..write('fixedPrice: $fixedPrice, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        deviceId,
        customerId,
        employeeId,
        startTime,
        pausedAt,
        totalPausedMinutes,
        mode,
        accumulatedCost,
        singleCost,
        multiCost,
        segmentStartAt,
        endTime,
        status,
        finalCost,
        plannedMinutes,
        timeUpAt,
        packageId,
        fixedPrice,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.customerId == this.customerId &&
          other.employeeId == this.employeeId &&
          other.startTime == this.startTime &&
          other.pausedAt == this.pausedAt &&
          other.totalPausedMinutes == this.totalPausedMinutes &&
          other.mode == this.mode &&
          other.accumulatedCost == this.accumulatedCost &&
          other.singleCost == this.singleCost &&
          other.multiCost == this.multiCost &&
          other.segmentStartAt == this.segmentStartAt &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.finalCost == this.finalCost &&
          other.plannedMinutes == this.plannedMinutes &&
          other.timeUpAt == this.timeUpAt &&
          other.packageId == this.packageId &&
          other.fixedPrice == this.fixedPrice &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<int> deviceId;
  final Value<int?> customerId;
  final Value<int?> employeeId;
  final Value<DateTime> startTime;
  final Value<DateTime?> pausedAt;
  final Value<double> totalPausedMinutes;
  final Value<String> mode;
  final Value<double> accumulatedCost;
  final Value<double> singleCost;
  final Value<double> multiCost;
  final Value<DateTime?> segmentStartAt;
  final Value<DateTime?> endTime;
  final Value<String> status;
  final Value<double?> finalCost;
  final Value<int?> plannedMinutes;
  final Value<DateTime?> timeUpAt;
  final Value<int?> packageId;
  final Value<double?> fixedPrice;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.totalPausedMinutes = const Value.absent(),
    this.mode = const Value.absent(),
    this.accumulatedCost = const Value.absent(),
    this.singleCost = const Value.absent(),
    this.multiCost = const Value.absent(),
    this.segmentStartAt = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.finalCost = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.timeUpAt = const Value.absent(),
    this.packageId = const Value.absent(),
    this.fixedPrice = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required int deviceId,
    this.customerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.totalPausedMinutes = const Value.absent(),
    this.mode = const Value.absent(),
    this.accumulatedCost = const Value.absent(),
    this.singleCost = const Value.absent(),
    this.multiCost = const Value.absent(),
    this.segmentStartAt = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.finalCost = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.timeUpAt = const Value.absent(),
    this.packageId = const Value.absent(),
    this.fixedPrice = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<int>? deviceId,
    Expression<int>? customerId,
    Expression<int>? employeeId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? pausedAt,
    Expression<double>? totalPausedMinutes,
    Expression<String>? mode,
    Expression<double>? accumulatedCost,
    Expression<double>? singleCost,
    Expression<double>? multiCost,
    Expression<DateTime>? segmentStartAt,
    Expression<DateTime>? endTime,
    Expression<String>? status,
    Expression<double>? finalCost,
    Expression<int>? plannedMinutes,
    Expression<DateTime>? timeUpAt,
    Expression<int>? packageId,
    Expression<double>? fixedPrice,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (customerId != null) 'customer_id': customerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (startTime != null) 'start_time': startTime,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (totalPausedMinutes != null)
        'total_paused_minutes': totalPausedMinutes,
      if (mode != null) 'mode': mode,
      if (accumulatedCost != null) 'accumulated_cost': accumulatedCost,
      if (singleCost != null) 'single_cost': singleCost,
      if (multiCost != null) 'multi_cost': multiCost,
      if (segmentStartAt != null) 'segment_start_at': segmentStartAt,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (finalCost != null) 'final_cost': finalCost,
      if (plannedMinutes != null) 'planned_minutes': plannedMinutes,
      if (timeUpAt != null) 'time_up_at': timeUpAt,
      if (packageId != null) 'package_id': packageId,
      if (fixedPrice != null) 'fixed_price': fixedPrice,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SessionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? deviceId,
      Value<int?>? customerId,
      Value<int?>? employeeId,
      Value<DateTime>? startTime,
      Value<DateTime?>? pausedAt,
      Value<double>? totalPausedMinutes,
      Value<String>? mode,
      Value<double>? accumulatedCost,
      Value<double>? singleCost,
      Value<double>? multiCost,
      Value<DateTime?>? segmentStartAt,
      Value<DateTime?>? endTime,
      Value<String>? status,
      Value<double?>? finalCost,
      Value<int?>? plannedMinutes,
      Value<DateTime?>? timeUpAt,
      Value<int?>? packageId,
      Value<double?>? fixedPrice,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SessionsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      startTime: startTime ?? this.startTime,
      pausedAt: pausedAt ?? this.pausedAt,
      totalPausedMinutes: totalPausedMinutes ?? this.totalPausedMinutes,
      mode: mode ?? this.mode,
      accumulatedCost: accumulatedCost ?? this.accumulatedCost,
      singleCost: singleCost ?? this.singleCost,
      multiCost: multiCost ?? this.multiCost,
      segmentStartAt: segmentStartAt ?? this.segmentStartAt,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      finalCost: finalCost ?? this.finalCost,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      timeUpAt: timeUpAt ?? this.timeUpAt,
      packageId: packageId ?? this.packageId,
      fixedPrice: fixedPrice ?? this.fixedPrice,
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
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (totalPausedMinutes.present) {
      map['total_paused_minutes'] = Variable<double>(totalPausedMinutes.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (accumulatedCost.present) {
      map['accumulated_cost'] = Variable<double>(accumulatedCost.value);
    }
    if (singleCost.present) {
      map['single_cost'] = Variable<double>(singleCost.value);
    }
    if (multiCost.present) {
      map['multi_cost'] = Variable<double>(multiCost.value);
    }
    if (segmentStartAt.present) {
      map['segment_start_at'] = Variable<DateTime>(segmentStartAt.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (finalCost.present) {
      map['final_cost'] = Variable<double>(finalCost.value);
    }
    if (plannedMinutes.present) {
      map['planned_minutes'] = Variable<int>(plannedMinutes.value);
    }
    if (timeUpAt.present) {
      map['time_up_at'] = Variable<DateTime>(timeUpAt.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<int>(packageId.value);
    }
    if (fixedPrice.present) {
      map['fixed_price'] = Variable<double>(fixedPrice.value);
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
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('customerId: $customerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('startTime: $startTime, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('totalPausedMinutes: $totalPausedMinutes, ')
          ..write('mode: $mode, ')
          ..write('accumulatedCost: $accumulatedCost, ')
          ..write('singleCost: $singleCost, ')
          ..write('multiCost: $multiCost, ')
          ..write('segmentStartAt: $segmentStartAt, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('finalCost: $finalCost, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('timeUpAt: $timeUpAt, ')
          ..write('packageId: $packageId, ')
          ..write('fixedPrice: $fixedPrice, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionEventsTable extends SessionEvents
    with TableInfo<$SessionEventsTable, SessionEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sessions (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
      'at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, type, at, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_events';
  @override
  VerificationContext validateIntegrity(Insertable<SessionEventRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionEventRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      at: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $SessionEventsTable createAlias(String alias) {
    return $SessionEventsTable(attachedDatabase, alias);
  }
}

class SessionEventRow extends DataClass implements Insertable<SessionEventRow> {
  final int id;
  final int sessionId;

  /// start | pause | resume | screen_on | screen_off | mode | extend | timeup
  final String type;
  final DateTime at;

  /// The value an event carries when its type alone is not the answer — the
  /// mode it switched TO, the minutes an extension bought, the wall it
  /// pointed at.
  final String? note;
  const SessionEventRow(
      {required this.id,
      required this.sessionId,
      required this.type,
      required this.at,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['type'] = Variable<String>(type);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SessionEventsCompanion toCompanion(bool nullToAbsent) {
    return SessionEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      type: Value(type),
      at: Value(at),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory SessionEventRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionEventRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      type: serializer.fromJson<String>(json['type']),
      at: serializer.fromJson<DateTime>(json['at']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'type': serializer.toJson<String>(type),
      'at': serializer.toJson<DateTime>(at),
      'note': serializer.toJson<String?>(note),
    };
  }

  SessionEventRow copyWith(
          {int? id,
          int? sessionId,
          String? type,
          DateTime? at,
          Value<String?> note = const Value.absent()}) =>
      SessionEventRow(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        type: type ?? this.type,
        at: at ?? this.at,
        note: note.present ? note.value : this.note,
      );
  SessionEventRow copyWithCompanion(SessionEventsCompanion data) {
    return SessionEventRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      type: data.type.present ? data.type.value : this.type,
      at: data.at.present ? data.at.value : this.at,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionEventRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('at: $at, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, type, at, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionEventRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.type == this.type &&
          other.at == this.at &&
          other.note == this.note);
}

class SessionEventsCompanion extends UpdateCompanion<SessionEventRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> type;
  final Value<DateTime> at;
  final Value<String?> note;
  const SessionEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.type = const Value.absent(),
    this.at = const Value.absent(),
    this.note = const Value.absent(),
  });
  SessionEventsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String type,
    this.at = const Value.absent(),
    this.note = const Value.absent(),
  })  : sessionId = Value(sessionId),
        type = Value(type);
  static Insertable<SessionEventRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? type,
    Expression<DateTime>? at,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (type != null) 'type': type,
      if (at != null) 'at': at,
      if (note != null) 'note': note,
    });
  }

  SessionEventsCompanion copyWith(
      {Value<int>? id,
      Value<int>? sessionId,
      Value<String>? type,
      Value<DateTime>? at,
      Value<String?>? note}) {
    return SessionEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      at: at ?? this.at,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('type: $type, ')
          ..write('at: $at, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices
    with TableInfo<$InvoicesTable, InvoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sessions (id)'));
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _paidCashMeta =
      const VerificationMeta('paidCash');
  @override
  late final GeneratedColumn<double> paidCash = GeneratedColumn<double>(
      'paid_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _paidCardMeta =
      const VerificationMeta('paidCard');
  @override
  late final GeneratedColumn<double> paidCard = GeneratedColumn<double>(
      'paid_card', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        customerId,
        employeeId,
        subtotal,
        discount,
        total,
        paymentMethod,
        paidCash,
        paidCard,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(Insertable<InvoiceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('paid_cash')) {
      context.handle(_paidCashMeta,
          paidCash.isAcceptableOrUnknown(data['paid_cash']!, _paidCashMeta));
    }
    if (data.containsKey('paid_card')) {
      context.handle(_paidCardMeta,
          paidCard.isAcceptableOrUnknown(data['paid_card']!, _paidCardMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id']),
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_id']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      paidCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid_cash'])!,
      paidCard: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid_card'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class InvoiceRow extends DataClass implements Insertable<InvoiceRow> {
  final int id;
  final int? sessionId;
  final int? customerId;

  /// The employee who handled this sale — feeds "daily revenue by
  /// employee" on the Dashboard. Nullable so historical invoices from
  /// before this column existed still display fine (shown as "غير محدد").
  final int? employeeId;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;

  /// Split of what was actually handed over in each tender. Both > 0
  /// means a mixed payment; the shift-close drawer math reads paidCash,
  /// and receipts show the split.
  final double paidCash;
  final double paidCard;
  final DateTime createdAt;
  const InvoiceRow(
      {required this.id,
      this.sessionId,
      this.customerId,
      this.employeeId,
      required this.subtotal,
      required this.discount,
      required this.total,
      required this.paymentMethod,
      required this.paidCash,
      required this.paidCard,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['discount'] = Variable<double>(discount);
    map['total'] = Variable<double>(total);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['paid_cash'] = Variable<double>(paidCash);
    map['paid_card'] = Variable<double>(paidCard);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      subtotal: Value(subtotal),
      discount: Value(discount),
      total: Value(total),
      paymentMethod: Value(paymentMethod),
      paidCash: Value(paidCash),
      paidCard: Value(paidCard),
      createdAt: Value(createdAt),
    );
  }

  factory InvoiceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discount: serializer.fromJson<double>(json['discount']),
      total: serializer.fromJson<double>(json['total']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paidCash: serializer.fromJson<double>(json['paidCash']),
      paidCard: serializer.fromJson<double>(json['paidCard']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int?>(sessionId),
      'customerId': serializer.toJson<int?>(customerId),
      'employeeId': serializer.toJson<int?>(employeeId),
      'subtotal': serializer.toJson<double>(subtotal),
      'discount': serializer.toJson<double>(discount),
      'total': serializer.toJson<double>(total),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paidCash': serializer.toJson<double>(paidCash),
      'paidCard': serializer.toJson<double>(paidCard),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InvoiceRow copyWith(
          {int? id,
          Value<int?> sessionId = const Value.absent(),
          Value<int?> customerId = const Value.absent(),
          Value<int?> employeeId = const Value.absent(),
          double? subtotal,
          double? discount,
          double? total,
          String? paymentMethod,
          double? paidCash,
          double? paidCard,
          DateTime? createdAt}) =>
      InvoiceRow(
        id: id ?? this.id,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        customerId: customerId.present ? customerId.value : this.customerId,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        total: total ?? this.total,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paidCash: paidCash ?? this.paidCash,
        paidCard: paidCard ?? this.paidCard,
        createdAt: createdAt ?? this.createdAt,
      );
  InvoiceRow copyWithCompanion(InvoicesCompanion data) {
    return InvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      total: data.total.present ? data.total.value : this.total,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paidCash: data.paidCash.present ? data.paidCash.value : this.paidCash,
      paidCard: data.paidCard.present ? data.paidCard.value : this.paidCard,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('customerId: $customerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('total: $total, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paidCash: $paidCash, ')
          ..write('paidCard: $paidCard, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, customerId, employeeId,
      subtotal, discount, total, paymentMethod, paidCash, paidCard, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.customerId == this.customerId &&
          other.employeeId == this.employeeId &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.total == this.total &&
          other.paymentMethod == this.paymentMethod &&
          other.paidCash == this.paidCash &&
          other.paidCard == this.paidCard &&
          other.createdAt == this.createdAt);
}

class InvoicesCompanion extends UpdateCompanion<InvoiceRow> {
  final Value<int> id;
  final Value<int?> sessionId;
  final Value<int?> customerId;
  final Value<int?> employeeId;
  final Value<double> subtotal;
  final Value<double> discount;
  final Value<double> total;
  final Value<String> paymentMethod;
  final Value<double> paidCash;
  final Value<double> paidCard;
  final Value<DateTime> createdAt;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.total = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paidCash = const Value.absent(),
    this.paidCard = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InvoicesCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.total = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paidCash = const Value.absent(),
    this.paidCard = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<InvoiceRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? customerId,
    Expression<int>? employeeId,
    Expression<double>? subtotal,
    Expression<double>? discount,
    Expression<double>? total,
    Expression<String>? paymentMethod,
    Expression<double>? paidCash,
    Expression<double>? paidCard,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (customerId != null) 'customer_id': customerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (total != null) 'total': total,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paidCash != null) 'paid_cash': paidCash,
      if (paidCard != null) 'paid_card': paidCard,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InvoicesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? sessionId,
      Value<int?>? customerId,
      Value<int?>? employeeId,
      Value<double>? subtotal,
      Value<double>? discount,
      Value<double>? total,
      Value<String>? paymentMethod,
      Value<double>? paidCash,
      Value<double>? paidCard,
      Value<DateTime>? createdAt}) {
    return InvoicesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidCash: paidCash ?? this.paidCash,
      paidCard: paidCard ?? this.paidCard,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paidCash.present) {
      map['paid_cash'] = Variable<double>(paidCash.value);
    }
    if (paidCard.present) {
      map['paid_card'] = Variable<double>(paidCard.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('customerId: $customerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('total: $total, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paidCash: $paidCash, ')
          ..write('paidCard: $paidCard, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<int> invoiceId = GeneratedColumn<int>(
      'invoice_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES invoices (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        invoiceId,
        productId,
        description,
        quantity,
        unitPrice,
        total,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(Insertable<InvoiceItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}invoice_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_price'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }
}

class InvoiceItemRow extends DataClass implements Insertable<InvoiceItemRow> {
  final int id;
  final int invoiceId;
  final int? productId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  /// When this particular thing was asked for, which is not when it was
  /// billed. A café order is rung up when the customer orders it and folded
  /// into the session's one bill minutes or hours later — and once the drafts
  /// are folded away, the bill's own createdAt is all that is left, so the
  /// answer to "امتى طلب المياه" would become "at checkout".
  ///
  /// Null on rows written before v10; those fall back to their invoice's
  /// time, which is the truth the app used to tell anyway.
  final DateTime? createdAt;
  const InvoiceItemRow(
      {required this.id,
      required this.invoiceId,
      this.productId,
      required this.description,
      required this.quantity,
      required this.unitPrice,
      required this.total,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<int>(invoiceId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    map['description'] = Variable<String>(description);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['total'] = Variable<double>(total);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      description: Value(description),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      total: Value(total),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory InvoiceItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItemRow(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<int>(json['invoiceId']),
      productId: serializer.fromJson<int?>(json['productId']),
      description: serializer.fromJson<String>(json['description']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      total: serializer.fromJson<double>(json['total']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<int>(invoiceId),
      'productId': serializer.toJson<int?>(productId),
      'description': serializer.toJson<String>(description),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'total': serializer.toJson<double>(total),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  InvoiceItemRow copyWith(
          {int? id,
          int? invoiceId,
          Value<int?> productId = const Value.absent(),
          String? description,
          int? quantity,
          double? unitPrice,
          double? total,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      InvoiceItemRow(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        productId: productId.present ? productId.value : this.productId,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        total: total ?? this.total,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  InvoiceItemRow copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItemRow(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      description:
          data.description.present ? data.description.value : this.description,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      total: data.total.present ? data.total.value : this.total,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemRow(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('total: $total, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, invoiceId, productId, description,
      quantity, unitPrice, total, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItemRow &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.description == this.description &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.total == this.total &&
          other.createdAt == this.createdAt);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItemRow> {
  final Value<int> id;
  final Value<int> invoiceId;
  final Value<int?> productId;
  final Value<String> description;
  final Value<int> quantity;
  final Value<double> unitPrice;
  final Value<double> total;
  final Value<DateTime?> createdAt;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.description = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.total = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    this.id = const Value.absent(),
    required int invoiceId,
    this.productId = const Value.absent(),
    required String description,
    this.quantity = const Value.absent(),
    required double unitPrice,
    required double total,
    this.createdAt = const Value.absent(),
  })  : invoiceId = Value(invoiceId),
        description = Value(description),
        unitPrice = Value(unitPrice),
        total = Value(total);
  static Insertable<InvoiceItemRow> custom({
    Expression<int>? id,
    Expression<int>? invoiceId,
    Expression<int>? productId,
    Expression<String>? description,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? total,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (total != null) 'total': total,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InvoiceItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? invoiceId,
      Value<int?>? productId,
      Value<String>? description,
      Value<int>? quantity,
      Value<double>? unitPrice,
      Value<double>? total,
      Value<DateTime?>? createdAt}) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<int>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('total: $total, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _oldValueMeta =
      const VerificationMeta('oldValue');
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
      'old_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newValueMeta =
      const VerificationMeta('newValue');
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
      'new_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _performedByRoleMeta =
      const VerificationMeta('performedByRole');
  @override
  late final GeneratedColumn<String> performedByRole = GeneratedColumn<String>(
      'performed_by_role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        action,
        entityType,
        entityId,
        oldValue,
        newValue,
        reason,
        performedByRole,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLogRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    }
    if (data.containsKey('old_value')) {
      context.handle(_oldValueMeta,
          oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta));
    }
    if (data.containsKey('new_value')) {
      context.handle(_newValueMeta,
          newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('performed_by_role')) {
      context.handle(
          _performedByRoleMeta,
          performedByRole.isAcceptableOrUnknown(
              data['performed_by_role']!, _performedByRoleMeta));
    } else if (isInserting) {
      context.missing(_performedByRoleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id']),
      oldValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}old_value']),
      newValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_value']),
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      performedByRole: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}performed_by_role'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final int id;
  final String action;
  final String entityType;
  final int? entityId;
  final String? oldValue;
  final String? newValue;
  final String? reason;
  final String performedByRole;
  final DateTime createdAt;
  const AuditLogRow(
      {required this.id,
      required this.action,
      required this.entityType,
      this.entityId,
      this.oldValue,
      this.newValue,
      this.reason,
      required this.performedByRole,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<int>(entityId);
    }
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['performed_by_role'] = Variable<String>(performedByRole);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      action: Value(action),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      performedByRole: Value(performedByRole),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLogRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<int?>(json['entityId']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      reason: serializer.fromJson<String?>(json['reason']),
      performedByRole: serializer.fromJson<String>(json['performedByRole']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<int?>(entityId),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'reason': serializer.toJson<String?>(reason),
      'performedByRole': serializer.toJson<String>(performedByRole),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLogRow copyWith(
          {int? id,
          String? action,
          String? entityType,
          Value<int?> entityId = const Value.absent(),
          Value<String?> oldValue = const Value.absent(),
          Value<String?> newValue = const Value.absent(),
          Value<String?> reason = const Value.absent(),
          String? performedByRole,
          DateTime? createdAt}) =>
      AuditLogRow(
        id: id ?? this.id,
        action: action ?? this.action,
        entityType: entityType ?? this.entityType,
        entityId: entityId.present ? entityId.value : this.entityId,
        oldValue: oldValue.present ? oldValue.value : this.oldValue,
        newValue: newValue.present ? newValue.value : this.newValue,
        reason: reason.present ? reason.value : this.reason,
        performedByRole: performedByRole ?? this.performedByRole,
        createdAt: createdAt ?? this.createdAt,
      );
  AuditLogRow copyWithCompanion(AuditLogsCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      reason: data.reason.present ? data.reason.value : this.reason,
      performedByRole: data.performedByRole.present
          ? data.performedByRole.value
          : this.performedByRole,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('reason: $reason, ')
          ..write('performedByRole: $performedByRole, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, action, entityType, entityId, oldValue,
      newValue, reason, performedByRole, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.reason == this.reason &&
          other.performedByRole == this.performedByRole &&
          other.createdAt == this.createdAt);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> entityType;
  final Value<int?> entityId;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String?> reason;
  final Value<String> performedByRole;
  final Value<DateTime> createdAt;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.reason = const Value.absent(),
    this.performedByRole = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String entityType,
    this.entityId = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.reason = const Value.absent(),
    required String performedByRole,
    this.createdAt = const Value.absent(),
  })  : action = Value(action),
        entityType = Value(entityType),
        performedByRole = Value(performedByRole);
  static Insertable<AuditLogRow> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<int>? entityId,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? reason,
    Expression<String>? performedByRole,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (reason != null) 'reason': reason,
      if (performedByRole != null) 'performed_by_role': performedByRole,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AuditLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? action,
      Value<String>? entityType,
      Value<int?>? entityId,
      Value<String?>? oldValue,
      Value<String?>? newValue,
      Value<String?>? reason,
      Value<String>? performedByRole,
      Value<DateTime>? createdAt}) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      reason: reason ?? this.reason,
      performedByRole: performedByRole ?? this.performedByRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (performedByRole.present) {
      map['performed_by_role'] = Variable<String>(performedByRole.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('reason: $reason, ')
          ..write('performedByRole: $performedByRole, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _openingCashMeta =
      const VerificationMeta('openingCash');
  @override
  late final GeneratedColumn<double> openingCash = GeneratedColumn<double>(
      'opening_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _expectedCashMeta =
      const VerificationMeta('expectedCash');
  @override
  late final GeneratedColumn<double> expectedCash = GeneratedColumn<double>(
      'expected_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _actualCashMeta =
      const VerificationMeta('actualCash');
  @override
  late final GeneratedColumn<double> actualCash = GeneratedColumn<double>(
      'actual_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _differenceMeta =
      const VerificationMeta('difference');
  @override
  late final GeneratedColumn<double> difference = GeneratedColumn<double>(
      'difference', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        employeeId,
        openedAt,
        closedAt,
        openingCash,
        expectedCash,
        actualCash,
        difference,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(Insertable<ShiftRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
          _openingCashMeta,
          openingCash.isAcceptableOrUnknown(
              data['opening_cash']!, _openingCashMeta));
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
          _expectedCashMeta,
          expectedCash.isAcceptableOrUnknown(
              data['expected_cash']!, _expectedCashMeta));
    }
    if (data.containsKey('actual_cash')) {
      context.handle(
          _actualCashMeta,
          actualCash.isAcceptableOrUnknown(
              data['actual_cash']!, _actualCashMeta));
    }
    if (data.containsKey('difference')) {
      context.handle(
          _differenceMeta,
          difference.isAcceptableOrUnknown(
              data['difference']!, _differenceMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at'])!,
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at'])!,
      openingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opening_cash'])!,
      expectedCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}expected_cash'])!,
      actualCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_cash'])!,
      difference: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difference'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final int id;
  final int? employeeId;
  final DateTime openedAt;
  final DateTime closedAt;
  final double openingCash;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final String? notes;
  const ShiftRow(
      {required this.id,
      this.employeeId,
      required this.openedAt,
      required this.closedAt,
      required this.openingCash,
      required this.expectedCash,
      required this.actualCash,
      required this.difference,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['opened_at'] = Variable<DateTime>(openedAt);
    map['closed_at'] = Variable<DateTime>(closedAt);
    map['opening_cash'] = Variable<double>(openingCash);
    map['expected_cash'] = Variable<double>(expectedCash);
    map['actual_cash'] = Variable<double>(actualCash);
    map['difference'] = Variable<double>(difference);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      openedAt: Value(openedAt),
      closedAt: Value(closedAt),
      openingCash: Value(openingCash),
      expectedCash: Value(expectedCash),
      actualCash: Value(actualCash),
      difference: Value(difference),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory ShiftRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
      openingCash: serializer.fromJson<double>(json['openingCash']),
      expectedCash: serializer.fromJson<double>(json['expectedCash']),
      actualCash: serializer.fromJson<double>(json['actualCash']),
      difference: serializer.fromJson<double>(json['difference']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int?>(employeeId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime>(closedAt),
      'openingCash': serializer.toJson<double>(openingCash),
      'expectedCash': serializer.toJson<double>(expectedCash),
      'actualCash': serializer.toJson<double>(actualCash),
      'difference': serializer.toJson<double>(difference),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  ShiftRow copyWith(
          {int? id,
          Value<int?> employeeId = const Value.absent(),
          DateTime? openedAt,
          DateTime? closedAt,
          double? openingCash,
          double? expectedCash,
          double? actualCash,
          double? difference,
          Value<String?> notes = const Value.absent()}) =>
      ShiftRow(
        id: id ?? this.id,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        openedAt: openedAt ?? this.openedAt,
        closedAt: closedAt ?? this.closedAt,
        openingCash: openingCash ?? this.openingCash,
        expectedCash: expectedCash ?? this.expectedCash,
        actualCash: actualCash ?? this.actualCash,
        difference: difference ?? this.difference,
        notes: notes.present ? notes.value : this.notes,
      );
  ShiftRow copyWithCompanion(ShiftsCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      openingCash:
          data.openingCash.present ? data.openingCash.value : this.openingCash,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      actualCash:
          data.actualCash.present ? data.actualCash.value : this.actualCash,
      difference:
          data.difference.present ? data.difference.value : this.difference,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openingCash: $openingCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('actualCash: $actualCash, ')
          ..write('difference: $difference, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, employeeId, openedAt, closedAt,
      openingCash, expectedCash, actualCash, difference, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.openingCash == this.openingCash &&
          other.expectedCash == this.expectedCash &&
          other.actualCash == this.actualCash &&
          other.difference == this.difference &&
          other.notes == this.notes);
}

class ShiftsCompanion extends UpdateCompanion<ShiftRow> {
  final Value<int> id;
  final Value<int?> employeeId;
  final Value<DateTime> openedAt;
  final Value<DateTime> closedAt;
  final Value<double> openingCash;
  final Value<double> expectedCash;
  final Value<double> actualCash;
  final Value<double> difference;
  final Value<String?> notes;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.actualCash = const Value.absent(),
    this.difference = const Value.absent(),
    this.notes = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.actualCash = const Value.absent(),
    this.difference = const Value.absent(),
    this.notes = const Value.absent(),
  });
  static Insertable<ShiftRow> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<double>? openingCash,
    Expression<double>? expectedCash,
    Expression<double>? actualCash,
    Expression<double>? difference,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (openingCash != null) 'opening_cash': openingCash,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (actualCash != null) 'actual_cash': actualCash,
      if (difference != null) 'difference': difference,
      if (notes != null) 'notes': notes,
    });
  }

  ShiftsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? employeeId,
      Value<DateTime>? openedAt,
      Value<DateTime>? closedAt,
      Value<double>? openingCash,
      Value<double>? expectedCash,
      Value<double>? actualCash,
      Value<double>? difference,
      Value<String?>? notes}) {
    return ShiftsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCash: openingCash ?? this.openingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<double>(openingCash.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<double>(expectedCash.value);
    }
    if (actualCash.present) {
      map['actual_cash'] = Variable<double>(actualCash.value);
    }
    if (difference.present) {
      map['difference'] = Variable<double>(difference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openingCash: $openingCash, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('actualCash: $actualCash, ')
          ..write('difference: $difference, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, category, amount, description, employeeId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<ExpenseRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final int id;
  final String category;
  final double amount;
  final String? description;
  final int? employeeId;
  final DateTime createdAt;
  const ExpenseRow(
      {required this.id,
      required this.category,
      required this.amount,
      this.description,
      this.employeeId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      category: Value(category),
      amount: Value(amount),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      createdAt: Value(createdAt),
    );
  }

  factory ExpenseRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      description: serializer.fromJson<String?>(json['description']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'description': serializer.toJson<String?>(description),
      'employeeId': serializer.toJson<int?>(employeeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExpenseRow copyWith(
          {int? id,
          String? category,
          double? amount,
          Value<String?> description = const Value.absent(),
          Value<int?> employeeId = const Value.absent(),
          DateTime? createdAt}) =>
      ExpenseRow(
        id: id ?? this.id,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        description: description.present ? description.value : this.description,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        createdAt: createdAt ?? this.createdAt,
      );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      description:
          data.description.present ? data.description.value : this.description,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('employeeId: $employeeId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, category, amount, description, employeeId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.employeeId == this.employeeId &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<int> id;
  final Value<String> category;
  final Value<double> amount;
  final Value<String?> description;
  final Value<int?> employeeId;
  final Value<DateTime> createdAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required double amount,
    this.description = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : category = Value(category),
        amount = Value(amount);
  static Insertable<ExpenseRow> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? description,
    Expression<int>? employeeId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (employeeId != null) 'employee_id': employeeId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpensesCompanion copyWith(
      {Value<int>? id,
      Value<String>? category,
      Value<double>? amount,
      Value<String?>? description,
      Value<int?>? employeeId,
      Value<DateTime>? createdAt}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('employeeId: $employeeId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EmployeeFeatureOverridesTable extends EmployeeFeatureOverrides
    with TableInfo<$EmployeeFeatureOverridesTable, EmployeeFeatureOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeeFeatureOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _featureKeyMeta =
      const VerificationMeta('featureKey');
  @override
  late final GeneratedColumn<String> featureKey = GeneratedColumn<String>(
      'feature_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visibleMeta =
      const VerificationMeta('visible');
  @override
  late final GeneratedColumn<bool> visible = GeneratedColumn<bool>(
      'visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("visible" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [id, employeeId, featureKey, visible];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employee_feature_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<EmployeeFeatureOverrideRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('feature_key')) {
      context.handle(
          _featureKeyMeta,
          featureKey.isAcceptableOrUnknown(
              data['feature_key']!, _featureKeyMeta));
    } else if (isInserting) {
      context.missing(_featureKeyMeta);
    }
    if (data.containsKey('visible')) {
      context.handle(_visibleMeta,
          visible.isAcceptableOrUnknown(data['visible']!, _visibleMeta));
    } else if (isInserting) {
      context.missing(_visibleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {employeeId, featureKey},
      ];
  @override
  EmployeeFeatureOverrideRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeFeatureOverrideRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      featureKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feature_key'])!,
      visible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}visible'])!,
    );
  }

  @override
  $EmployeeFeatureOverridesTable createAlias(String alias) {
    return $EmployeeFeatureOverridesTable(attachedDatabase, alias);
  }
}

class EmployeeFeatureOverrideRow extends DataClass
    implements Insertable<EmployeeFeatureOverrideRow> {
  final int id;
  final int employeeId;
  final String featureKey;
  final bool visible;
  const EmployeeFeatureOverrideRow(
      {required this.id,
      required this.employeeId,
      required this.featureKey,
      required this.visible});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    map['feature_key'] = Variable<String>(featureKey);
    map['visible'] = Variable<bool>(visible);
    return map;
  }

  EmployeeFeatureOverridesCompanion toCompanion(bool nullToAbsent) {
    return EmployeeFeatureOverridesCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      featureKey: Value(featureKey),
      visible: Value(visible),
    );
  }

  factory EmployeeFeatureOverrideRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeFeatureOverrideRow(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      featureKey: serializer.fromJson<String>(json['featureKey']),
      visible: serializer.fromJson<bool>(json['visible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'featureKey': serializer.toJson<String>(featureKey),
      'visible': serializer.toJson<bool>(visible),
    };
  }

  EmployeeFeatureOverrideRow copyWith(
          {int? id, int? employeeId, String? featureKey, bool? visible}) =>
      EmployeeFeatureOverrideRow(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        featureKey: featureKey ?? this.featureKey,
        visible: visible ?? this.visible,
      );
  EmployeeFeatureOverrideRow copyWithCompanion(
      EmployeeFeatureOverridesCompanion data) {
    return EmployeeFeatureOverrideRow(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      featureKey:
          data.featureKey.present ? data.featureKey.value : this.featureKey,
      visible: data.visible.present ? data.visible.value : this.visible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeFeatureOverrideRow(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('featureKey: $featureKey, ')
          ..write('visible: $visible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, employeeId, featureKey, visible);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeFeatureOverrideRow &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.featureKey == this.featureKey &&
          other.visible == this.visible);
}

class EmployeeFeatureOverridesCompanion
    extends UpdateCompanion<EmployeeFeatureOverrideRow> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<String> featureKey;
  final Value<bool> visible;
  const EmployeeFeatureOverridesCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.featureKey = const Value.absent(),
    this.visible = const Value.absent(),
  });
  EmployeeFeatureOverridesCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    required String featureKey,
    required bool visible,
  })  : employeeId = Value(employeeId),
        featureKey = Value(featureKey),
        visible = Value(visible);
  static Insertable<EmployeeFeatureOverrideRow> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<String>? featureKey,
    Expression<bool>? visible,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (featureKey != null) 'feature_key': featureKey,
      if (visible != null) 'visible': visible,
    });
  }

  EmployeeFeatureOverridesCompanion copyWith(
      {Value<int>? id,
      Value<int>? employeeId,
      Value<String>? featureKey,
      Value<bool>? visible}) {
    return EmployeeFeatureOverridesCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      featureKey: featureKey ?? this.featureKey,
      visible: visible ?? this.visible,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (featureKey.present) {
      map['feature_key'] = Variable<String>(featureKey.value);
    }
    if (visible.present) {
      map['visible'] = Variable<bool>(visible.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeFeatureOverridesCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('featureKey: $featureKey, ')
          ..write('visible: $visible')
          ..write(')'))
        .toString();
  }
}

class $ReservationsTable extends Reservations
    with TableInfo<$ReservationsTable, ReservationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
      'device_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES devices (id)'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Pending'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        customerId,
        deviceId,
        startTime,
        endTime,
        status,
        employeeId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reservations';
  @override
  VerificationContext validateIntegrity(Insertable<ReservationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReservationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReservationRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReservationsTable createAlias(String alias) {
    return $ReservationsTable(attachedDatabase, alias);
  }
}

class ReservationRow extends DataClass implements Insertable<ReservationRow> {
  final int id;
  final int customerId;
  final int deviceId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  /// Who booked it — attributed to the employee who created it so a
  /// started session inherits the same employee for revenue reporting.
  final int? employeeId;
  final DateTime createdAt;
  const ReservationRow(
      {required this.id,
      required this.customerId,
      required this.deviceId,
      required this.startTime,
      required this.endTime,
      required this.status,
      this.employeeId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['customer_id'] = Variable<int>(customerId);
    map['device_id'] = Variable<int>(deviceId);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReservationsCompanion toCompanion(bool nullToAbsent) {
    return ReservationsCompanion(
      id: Value(id),
      customerId: Value(customerId),
      deviceId: Value(deviceId),
      startTime: Value(startTime),
      endTime: Value(endTime),
      status: Value(status),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      createdAt: Value(createdAt),
    );
  }

  factory ReservationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReservationRow(
      id: serializer.fromJson<int>(json['id']),
      customerId: serializer.fromJson<int>(json['customerId']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'customerId': serializer.toJson<int>(customerId),
      'deviceId': serializer.toJson<int>(deviceId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'status': serializer.toJson<String>(status),
      'employeeId': serializer.toJson<int?>(employeeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReservationRow copyWith(
          {int? id,
          int? customerId,
          int? deviceId,
          DateTime? startTime,
          DateTime? endTime,
          String? status,
          Value<int?> employeeId = const Value.absent(),
          DateTime? createdAt}) =>
      ReservationRow(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        deviceId: deviceId ?? this.deviceId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        createdAt: createdAt ?? this.createdAt,
      );
  ReservationRow copyWithCompanion(ReservationsCompanion data) {
    return ReservationRow(
      id: data.id.present ? data.id.value : this.id,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReservationRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('employeeId: $employeeId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, customerId, deviceId, startTime, endTime,
      status, employeeId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReservationRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.deviceId == this.deviceId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.employeeId == this.employeeId &&
          other.createdAt == this.createdAt);
}

class ReservationsCompanion extends UpdateCompanion<ReservationRow> {
  final Value<int> id;
  final Value<int> customerId;
  final Value<int> deviceId;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<String> status;
  final Value<int?> employeeId;
  final Value<DateTime> createdAt;
  const ReservationsCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReservationsCompanion.insert({
    this.id = const Value.absent(),
    required int customerId,
    required int deviceId,
    required DateTime startTime,
    required DateTime endTime,
    this.status = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : customerId = Value(customerId),
        deviceId = Value(deviceId),
        startTime = Value(startTime),
        endTime = Value(endTime);
  static Insertable<ReservationRow> custom({
    Expression<int>? id,
    Expression<int>? customerId,
    Expression<int>? deviceId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? status,
    Expression<int>? employeeId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (deviceId != null) 'device_id': deviceId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (employeeId != null) 'employee_id': employeeId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReservationsCompanion copyWith(
      {Value<int>? id,
      Value<int>? customerId,
      Value<int>? deviceId,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<String>? status,
      Value<int?>? employeeId,
      Value<DateTime>? createdAt}) {
    return ReservationsCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      deviceId: deviceId ?? this.deviceId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReservationsCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('employeeId: $employeeId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OffersTable extends Offers with TableInfo<$OffersTable, OfferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OffersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _discountTypeMeta =
      const VerificationMeta('discountType');
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
      'discount_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _discountValueMeta =
      const VerificationMeta('discountValue');
  @override
  late final GeneratedColumn<double> discountValue = GeneratedColumn<double>(
      'discount_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startHourMeta =
      const VerificationMeta('startHour');
  @override
  late final GeneratedColumn<int> startHour = GeneratedColumn<int>(
      'start_hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _endHourMeta =
      const VerificationMeta('endHour');
  @override
  late final GeneratedColumn<int> endHour = GeneratedColumn<int>(
      'end_hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(23));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        discountType,
        discountValue,
        startHour,
        endHour,
        active,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offers';
  @override
  VerificationContext validateIntegrity(Insertable<OfferRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
          _discountTypeMeta,
          discountType.isAcceptableOrUnknown(
              data['discount_type']!, _discountTypeMeta));
    } else if (isInserting) {
      context.missing(_discountTypeMeta);
    }
    if (data.containsKey('discount_value')) {
      context.handle(
          _discountValueMeta,
          discountValue.isAcceptableOrUnknown(
              data['discount_value']!, _discountValueMeta));
    }
    if (data.containsKey('start_hour')) {
      context.handle(_startHourMeta,
          startHour.isAcceptableOrUnknown(data['start_hour']!, _startHourMeta));
    }
    if (data.containsKey('end_hour')) {
      context.handle(_endHourMeta,
          endHour.isAcceptableOrUnknown(data['end_hour']!, _endHourMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfferRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      discountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_type'])!,
      discountValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount_value'])!,
      startHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_hour'])!,
      endHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_hour'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OffersTable createAlias(String alias) {
    return $OffersTable(attachedDatabase, alias);
  }
}

class OfferRow extends DataClass implements Insertable<OfferRow> {
  final int id;
  final String name;
  final String discountType;
  final double discountValue;
  final int startHour;
  final int endHour;
  final bool active;
  final DateTime createdAt;
  const OfferRow(
      {required this.id,
      required this.name,
      required this.discountType,
      required this.discountValue,
      required this.startHour,
      required this.endHour,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['discount_type'] = Variable<String>(discountType);
    map['discount_value'] = Variable<double>(discountValue);
    map['start_hour'] = Variable<int>(startHour);
    map['end_hour'] = Variable<int>(endHour);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OffersCompanion toCompanion(bool nullToAbsent) {
    return OffersCompanion(
      id: Value(id),
      name: Value(name),
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      startHour: Value(startHour),
      endHour: Value(endHour),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory OfferRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfferRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      discountType: serializer.fromJson<String>(json['discountType']),
      discountValue: serializer.fromJson<double>(json['discountValue']),
      startHour: serializer.fromJson<int>(json['startHour']),
      endHour: serializer.fromJson<int>(json['endHour']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'discountType': serializer.toJson<String>(discountType),
      'discountValue': serializer.toJson<double>(discountValue),
      'startHour': serializer.toJson<int>(startHour),
      'endHour': serializer.toJson<int>(endHour),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfferRow copyWith(
          {int? id,
          String? name,
          String? discountType,
          double? discountValue,
          int? startHour,
          int? endHour,
          bool? active,
          DateTime? createdAt}) =>
      OfferRow(
        id: id ?? this.id,
        name: name ?? this.name,
        discountType: discountType ?? this.discountType,
        discountValue: discountValue ?? this.discountValue,
        startHour: startHour ?? this.startHour,
        endHour: endHour ?? this.endHour,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  OfferRow copyWithCompanion(OffersCompanion data) {
    return OfferRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      startHour: data.startHour.present ? data.startHour.value : this.startHour,
      endHour: data.endHour.present ? data.endHour.value : this.endHour,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfferRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('startHour: $startHour, ')
          ..write('endHour: $endHour, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, discountType, discountValue,
      startHour, endHour, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfferRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.startHour == this.startHour &&
          other.endHour == this.endHour &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class OffersCompanion extends UpdateCompanion<OfferRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> discountType;
  final Value<double> discountValue;
  final Value<int> startHour;
  final Value<int> endHour;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const OffersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.startHour = const Value.absent(),
    this.endHour = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OffersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String discountType,
    this.discountValue = const Value.absent(),
    this.startHour = const Value.absent(),
    this.endHour = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        discountType = Value(discountType);
  static Insertable<OfferRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? discountType,
    Expression<double>? discountValue,
    Expression<int>? startHour,
    Expression<int>? endHour,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (startHour != null) 'start_hour': startHour,
      if (endHour != null) 'end_hour': endHour,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OffersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? discountType,
      Value<double>? discountValue,
      Value<int>? startHour,
      Value<int>? endHour,
      Value<bool>? active,
      Value<DateTime>? createdAt}) {
    return OffersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
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
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (startHour.present) {
      map['start_hour'] = Variable<int>(startHour.value);
    }
    if (endHour.present) {
      map['end_hour'] = Variable<int>(endHour.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OffersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('startHour: $startHour, ')
          ..write('endHour: $endHour, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LoyaltySettingsTable extends LoyaltySettings
    with TableInfo<$LoyaltySettingsTable, LoyaltySettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoyaltySettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pointsPerCurrencyMeta =
      const VerificationMeta('pointsPerCurrency');
  @override
  late final GeneratedColumn<double> pointsPerCurrency =
      GeneratedColumn<double>('points_per_currency', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _minimumRedeemPointsMeta =
      const VerificationMeta('minimumRedeemPoints');
  @override
  late final GeneratedColumn<int> minimumRedeemPoints = GeneratedColumn<int>(
      'minimum_redeem_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _pointValueEGPMeta =
      const VerificationMeta('pointValueEGP');
  @override
  late final GeneratedColumn<double> pointValueEGP = GeneratedColumn<double>(
      'point_value_e_g_p', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, pointsPerCurrency, minimumRedeemPoints, pointValueEGP, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loyalty_settings';
  @override
  VerificationContext validateIntegrity(Insertable<LoyaltySettingsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('points_per_currency')) {
      context.handle(
          _pointsPerCurrencyMeta,
          pointsPerCurrency.isAcceptableOrUnknown(
              data['points_per_currency']!, _pointsPerCurrencyMeta));
    }
    if (data.containsKey('minimum_redeem_points')) {
      context.handle(
          _minimumRedeemPointsMeta,
          minimumRedeemPoints.isAcceptableOrUnknown(
              data['minimum_redeem_points']!, _minimumRedeemPointsMeta));
    }
    if (data.containsKey('point_value_e_g_p')) {
      context.handle(
          _pointValueEGPMeta,
          pointValueEGP.isAcceptableOrUnknown(
              data['point_value_e_g_p']!, _pointValueEGPMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoyaltySettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoyaltySettingsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pointsPerCurrency: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}points_per_currency'])!,
      minimumRedeemPoints: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}minimum_redeem_points'])!,
      pointValueEGP: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}point_value_e_g_p'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LoyaltySettingsTable createAlias(String alias) {
    return $LoyaltySettingsTable(attachedDatabase, alias);
  }
}

class LoyaltySettingsRow extends DataClass
    implements Insertable<LoyaltySettingsRow> {
  final int id;
  final double pointsPerCurrency;
  final int minimumRedeemPoints;
  final double pointValueEGP;
  final DateTime updatedAt;
  const LoyaltySettingsRow(
      {required this.id,
      required this.pointsPerCurrency,
      required this.minimumRedeemPoints,
      required this.pointValueEGP,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['points_per_currency'] = Variable<double>(pointsPerCurrency);
    map['minimum_redeem_points'] = Variable<int>(minimumRedeemPoints);
    map['point_value_e_g_p'] = Variable<double>(pointValueEGP);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LoyaltySettingsCompanion toCompanion(bool nullToAbsent) {
    return LoyaltySettingsCompanion(
      id: Value(id),
      pointsPerCurrency: Value(pointsPerCurrency),
      minimumRedeemPoints: Value(minimumRedeemPoints),
      pointValueEGP: Value(pointValueEGP),
      updatedAt: Value(updatedAt),
    );
  }

  factory LoyaltySettingsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoyaltySettingsRow(
      id: serializer.fromJson<int>(json['id']),
      pointsPerCurrency: serializer.fromJson<double>(json['pointsPerCurrency']),
      minimumRedeemPoints:
          serializer.fromJson<int>(json['minimumRedeemPoints']),
      pointValueEGP: serializer.fromJson<double>(json['pointValueEGP']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pointsPerCurrency': serializer.toJson<double>(pointsPerCurrency),
      'minimumRedeemPoints': serializer.toJson<int>(minimumRedeemPoints),
      'pointValueEGP': serializer.toJson<double>(pointValueEGP),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LoyaltySettingsRow copyWith(
          {int? id,
          double? pointsPerCurrency,
          int? minimumRedeemPoints,
          double? pointValueEGP,
          DateTime? updatedAt}) =>
      LoyaltySettingsRow(
        id: id ?? this.id,
        pointsPerCurrency: pointsPerCurrency ?? this.pointsPerCurrency,
        minimumRedeemPoints: minimumRedeemPoints ?? this.minimumRedeemPoints,
        pointValueEGP: pointValueEGP ?? this.pointValueEGP,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LoyaltySettingsRow copyWithCompanion(LoyaltySettingsCompanion data) {
    return LoyaltySettingsRow(
      id: data.id.present ? data.id.value : this.id,
      pointsPerCurrency: data.pointsPerCurrency.present
          ? data.pointsPerCurrency.value
          : this.pointsPerCurrency,
      minimumRedeemPoints: data.minimumRedeemPoints.present
          ? data.minimumRedeemPoints.value
          : this.minimumRedeemPoints,
      pointValueEGP: data.pointValueEGP.present
          ? data.pointValueEGP.value
          : this.pointValueEGP,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoyaltySettingsRow(')
          ..write('id: $id, ')
          ..write('pointsPerCurrency: $pointsPerCurrency, ')
          ..write('minimumRedeemPoints: $minimumRedeemPoints, ')
          ..write('pointValueEGP: $pointValueEGP, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, pointsPerCurrency, minimumRedeemPoints, pointValueEGP, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoyaltySettingsRow &&
          other.id == this.id &&
          other.pointsPerCurrency == this.pointsPerCurrency &&
          other.minimumRedeemPoints == this.minimumRedeemPoints &&
          other.pointValueEGP == this.pointValueEGP &&
          other.updatedAt == this.updatedAt);
}

class LoyaltySettingsCompanion extends UpdateCompanion<LoyaltySettingsRow> {
  final Value<int> id;
  final Value<double> pointsPerCurrency;
  final Value<int> minimumRedeemPoints;
  final Value<double> pointValueEGP;
  final Value<DateTime> updatedAt;
  const LoyaltySettingsCompanion({
    this.id = const Value.absent(),
    this.pointsPerCurrency = const Value.absent(),
    this.minimumRedeemPoints = const Value.absent(),
    this.pointValueEGP = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LoyaltySettingsCompanion.insert({
    this.id = const Value.absent(),
    this.pointsPerCurrency = const Value.absent(),
    this.minimumRedeemPoints = const Value.absent(),
    this.pointValueEGP = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<LoyaltySettingsRow> custom({
    Expression<int>? id,
    Expression<double>? pointsPerCurrency,
    Expression<int>? minimumRedeemPoints,
    Expression<double>? pointValueEGP,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pointsPerCurrency != null) 'points_per_currency': pointsPerCurrency,
      if (minimumRedeemPoints != null)
        'minimum_redeem_points': minimumRedeemPoints,
      if (pointValueEGP != null) 'point_value_e_g_p': pointValueEGP,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LoyaltySettingsCompanion copyWith(
      {Value<int>? id,
      Value<double>? pointsPerCurrency,
      Value<int>? minimumRedeemPoints,
      Value<double>? pointValueEGP,
      Value<DateTime>? updatedAt}) {
    return LoyaltySettingsCompanion(
      id: id ?? this.id,
      pointsPerCurrency: pointsPerCurrency ?? this.pointsPerCurrency,
      minimumRedeemPoints: minimumRedeemPoints ?? this.minimumRedeemPoints,
      pointValueEGP: pointValueEGP ?? this.pointValueEGP,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pointsPerCurrency.present) {
      map['points_per_currency'] = Variable<double>(pointsPerCurrency.value);
    }
    if (minimumRedeemPoints.present) {
      map['minimum_redeem_points'] = Variable<int>(minimumRedeemPoints.value);
    }
    if (pointValueEGP.present) {
      map['point_value_e_g_p'] = Variable<double>(pointValueEGP.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoyaltySettingsCompanion(')
          ..write('id: $id, ')
          ..write('pointsPerCurrency: $pointsPerCurrency, ')
          ..write('minimumRedeemPoints: $minimumRedeemPoints, ')
          ..write('pointValueEGP: $pointValueEGP, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String? value;
  final DateTime updatedAt;
  const AppSettingRow({required this.key, this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRow copyWith(
          {String? key,
          Value<String?> value = const Value.absent(),
          DateTime? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
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
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String?> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSettingRow> custom({
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

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String?>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _systemMeta = const VerificationMeta('system');
  @override
  late final GeneratedColumn<bool> system = GeneratedColumn<bool>(
      'system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, name, kind, system, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AccountRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('system')) {
      context.handle(_systemMeta,
          system.isAcceptableOrUnknown(data['system']!, _systemMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      system: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}system'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;
  final String code;
  final String name;
  final String kind;
  final bool system;
  final DateTime createdAt;
  const AccountRow(
      {required this.id,
      required this.code,
      required this.name,
      required this.kind,
      required this.system,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['system'] = Variable<bool>(system);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      kind: Value(kind),
      system: Value(system),
      createdAt: Value(createdAt),
    );
  }

  factory AccountRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      system: serializer.fromJson<bool>(json['system']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'system': serializer.toJson<bool>(system),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AccountRow copyWith(
          {int? id,
          String? code,
          String? name,
          String? kind,
          bool? system,
          DateTime? createdAt}) =>
      AccountRow(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        system: system ?? this.system,
        createdAt: createdAt ?? this.createdAt,
      );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      system: data.system.present ? data.system.value : this.system,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('system: $system, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, kind, system, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.system == this.system &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> kind;
  final Value<bool> system;
  final Value<DateTime> createdAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.system = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    required String kind,
    this.system = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : code = Value(code),
        name = Value(name),
        kind = Value(kind);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? system,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (system != null) 'system': system,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? code,
      Value<String>? name,
      Value<String>? kind,
      Value<bool>? system,
      Value<DateTime>? createdAt}) {
    return AccountsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      system: system ?? this.system,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (system.present) {
      map['system'] = Variable<bool>(system.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('system: $system, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AccountEntriesTable extends AccountEntries
    with TableInfo<$AccountEntriesTable, AccountEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
      'source_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, accountId, amount, direction, source, sourceId, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_entries';
  @override
  VerificationContext validateIntegrity(Insertable<AccountEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountEntriesTable createAlias(String alias) {
    return $AccountEntriesTable(attachedDatabase, alias);
  }
}

class AccountEntryRow extends DataClass implements Insertable<AccountEntryRow> {
  final int id;
  final int accountId;
  final double amount;
  final String direction;
  final String source;
  final int? sourceId;
  final String? note;
  final DateTime createdAt;
  const AccountEntryRow(
      {required this.id,
      required this.accountId,
      required this.amount,
      required this.direction,
      required this.source,
      this.sourceId,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    map['amount'] = Variable<double>(amount);
    map['direction'] = Variable<String>(direction);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<int>(sourceId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountEntriesCompanion toCompanion(bool nullToAbsent) {
    return AccountEntriesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      amount: Value(amount),
      direction: Value(direction),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory AccountEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountEntryRow(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      amount: serializer.fromJson<double>(json['amount']),
      direction: serializer.fromJson<String>(json['direction']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<int?>(json['sourceId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'amount': serializer.toJson<double>(amount),
      'direction': serializer.toJson<String>(direction),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<int?>(sourceId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AccountEntryRow copyWith(
          {int? id,
          int? accountId,
          double? amount,
          String? direction,
          String? source,
          Value<int?> sourceId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      AccountEntryRow(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        amount: amount ?? this.amount,
        direction: direction ?? this.direction,
        source: source ?? this.source,
        sourceId: sourceId.present ? sourceId.value : this.sourceId,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  AccountEntryRow copyWithCompanion(AccountEntriesCompanion data) {
    return AccountEntryRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      direction: data.direction.present ? data.direction.value : this.direction,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntryRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, accountId, amount, direction, source, sourceId, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountEntryRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.direction == this.direction &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class AccountEntriesCompanion extends UpdateCompanion<AccountEntryRow> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<double> amount;
  final Value<String> direction;
  final Value<String> source;
  final Value<int?> sourceId;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const AccountEntriesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.direction = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    required double amount,
    required String direction,
    required String source,
    this.sourceId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : accountId = Value(accountId),
        amount = Value(amount),
        direction = Value(direction),
        source = Value(source);
  static Insertable<AccountEntryRow> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<double>? amount,
    Expression<String>? direction,
    Expression<String>? source,
    Expression<int>? sourceId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (direction != null) 'direction': direction,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? accountId,
      Value<double>? amount,
      Value<String>? direction,
      Value<String>? source,
      Value<int?>? sourceId,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return AccountEntriesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntriesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RefundsTable extends Refunds with TableInfo<$RefundsTable, RefundRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<int> invoiceId = GeneratedColumn<int>(
      'invoice_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES invoices (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _restockedMeta =
      const VerificationMeta('restocked');
  @override
  late final GeneratedColumn<bool> restocked = GeneratedColumn<bool>(
      'restocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("restocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        invoiceId,
        amount,
        quantity,
        reason,
        employeeId,
        restocked,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refunds';
  @override
  VerificationContext validateIntegrity(Insertable<RefundRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('restocked')) {
      context.handle(_restockedMeta,
          restocked.isAcceptableOrUnknown(data['restocked']!, _restockedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RefundRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RefundRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}invoice_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      restocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}restocked'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RefundsTable createAlias(String alias) {
    return $RefundsTable(attachedDatabase, alias);
  }
}

class RefundRow extends DataClass implements Insertable<RefundRow> {
  final int id;
  final int invoiceId;
  final double amount;
  final double quantity;
  final String? reason;
  final int? employeeId;
  final bool restocked;
  final DateTime createdAt;
  const RefundRow(
      {required this.id,
      required this.invoiceId,
      required this.amount,
      required this.quantity,
      this.reason,
      this.employeeId,
      required this.restocked,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<int>(invoiceId);
    map['amount'] = Variable<double>(amount);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['restocked'] = Variable<bool>(restocked);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RefundsCompanion toCompanion(bool nullToAbsent) {
    return RefundsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      amount: Value(amount),
      quantity: Value(quantity),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      restocked: Value(restocked),
      createdAt: Value(createdAt),
    );
  }

  factory RefundRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RefundRow(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<int>(json['invoiceId']),
      amount: serializer.fromJson<double>(json['amount']),
      quantity: serializer.fromJson<double>(json['quantity']),
      reason: serializer.fromJson<String?>(json['reason']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      restocked: serializer.fromJson<bool>(json['restocked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<int>(invoiceId),
      'amount': serializer.toJson<double>(amount),
      'quantity': serializer.toJson<double>(quantity),
      'reason': serializer.toJson<String?>(reason),
      'employeeId': serializer.toJson<int?>(employeeId),
      'restocked': serializer.toJson<bool>(restocked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RefundRow copyWith(
          {int? id,
          int? invoiceId,
          double? amount,
          double? quantity,
          Value<String?> reason = const Value.absent(),
          Value<int?> employeeId = const Value.absent(),
          bool? restocked,
          DateTime? createdAt}) =>
      RefundRow(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        amount: amount ?? this.amount,
        quantity: quantity ?? this.quantity,
        reason: reason.present ? reason.value : this.reason,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        restocked: restocked ?? this.restocked,
        createdAt: createdAt ?? this.createdAt,
      );
  RefundRow copyWithCompanion(RefundsCompanion data) {
    return RefundRow(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      amount: data.amount.present ? data.amount.value : this.amount,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      reason: data.reason.present ? data.reason.value : this.reason,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      restocked: data.restocked.present ? data.restocked.value : this.restocked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RefundRow(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amount: $amount, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('employeeId: $employeeId, ')
          ..write('restocked: $restocked, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, invoiceId, amount, quantity, reason,
      employeeId, restocked, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefundRow &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.amount == this.amount &&
          other.quantity == this.quantity &&
          other.reason == this.reason &&
          other.employeeId == this.employeeId &&
          other.restocked == this.restocked &&
          other.createdAt == this.createdAt);
}

class RefundsCompanion extends UpdateCompanion<RefundRow> {
  final Value<int> id;
  final Value<int> invoiceId;
  final Value<double> amount;
  final Value<double> quantity;
  final Value<String?> reason;
  final Value<int?> employeeId;
  final Value<bool> restocked;
  final Value<DateTime> createdAt;
  const RefundsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.amount = const Value.absent(),
    this.quantity = const Value.absent(),
    this.reason = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.restocked = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RefundsCompanion.insert({
    this.id = const Value.absent(),
    required int invoiceId,
    required double amount,
    this.quantity = const Value.absent(),
    this.reason = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.restocked = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : invoiceId = Value(invoiceId),
        amount = Value(amount);
  static Insertable<RefundRow> custom({
    Expression<int>? id,
    Expression<int>? invoiceId,
    Expression<double>? amount,
    Expression<double>? quantity,
    Expression<String>? reason,
    Expression<int>? employeeId,
    Expression<bool>? restocked,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (amount != null) 'amount': amount,
      if (quantity != null) 'quantity': quantity,
      if (reason != null) 'reason': reason,
      if (employeeId != null) 'employee_id': employeeId,
      if (restocked != null) 'restocked': restocked,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RefundsCompanion copyWith(
      {Value<int>? id,
      Value<int>? invoiceId,
      Value<double>? amount,
      Value<double>? quantity,
      Value<String?>? reason,
      Value<int?>? employeeId,
      Value<bool>? restocked,
      Value<DateTime>? createdAt}) {
    return RefundsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      employeeId: employeeId ?? this.employeeId,
      restocked: restocked ?? this.restocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<int>(invoiceId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (restocked.present) {
      map['restocked'] = Variable<bool>(restocked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amount: $amount, ')
          ..write('quantity: $quantity, ')
          ..write('reason: $reason, ')
          ..write('employeeId: $employeeId, ')
          ..write('restocked: $restocked, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StockCountsTable extends StockCounts
    with TableInfo<$StockCountsTable, StockCountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _appliedMeta =
      const VerificationMeta('applied');
  @override
  late final GeneratedColumn<bool> applied = GeneratedColumn<bool>(
      'applied', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("applied" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _appliedAtMeta =
      const VerificationMeta('appliedAt');
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
      'applied_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, employeeId, note, applied, createdAt, appliedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_counts';
  @override
  VerificationContext validateIntegrity(Insertable<StockCountRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('applied')) {
      context.handle(_appliedMeta,
          applied.isAcceptableOrUnknown(data['applied']!, _appliedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('applied_at')) {
      context.handle(_appliedAtMeta,
          appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockCountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockCountRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      applied: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}applied'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      appliedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}applied_at']),
    );
  }

  @override
  $StockCountsTable createAlias(String alias) {
    return $StockCountsTable(attachedDatabase, alias);
  }
}

class StockCountRow extends DataClass implements Insertable<StockCountRow> {
  final int id;
  final int? employeeId;
  final String? note;
  final bool applied;
  final DateTime createdAt;
  final DateTime? appliedAt;
  const StockCountRow(
      {required this.id,
      this.employeeId,
      this.note,
      required this.applied,
      required this.createdAt,
      this.appliedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['applied'] = Variable<bool>(applied);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<DateTime>(appliedAt);
    }
    return map;
  }

  StockCountsCompanion toCompanion(bool nullToAbsent) {
    return StockCountsCompanion(
      id: Value(id),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      applied: Value(applied),
      createdAt: Value(createdAt),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
    );
  }

  factory StockCountRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockCountRow(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      note: serializer.fromJson<String?>(json['note']),
      applied: serializer.fromJson<bool>(json['applied']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int?>(employeeId),
      'note': serializer.toJson<String?>(note),
      'applied': serializer.toJson<bool>(applied),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
    };
  }

  StockCountRow copyWith(
          {int? id,
          Value<int?> employeeId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? applied,
          DateTime? createdAt,
          Value<DateTime?> appliedAt = const Value.absent()}) =>
      StockCountRow(
        id: id ?? this.id,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        note: note.present ? note.value : this.note,
        applied: applied ?? this.applied,
        createdAt: createdAt ?? this.createdAt,
        appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
      );
  StockCountRow copyWithCompanion(StockCountsCompanion data) {
    return StockCountRow(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      note: data.note.present ? data.note.value : this.note,
      applied: data.applied.present ? data.applied.value : this.applied,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockCountRow(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('note: $note, ')
          ..write('applied: $applied, ')
          ..write('createdAt: $createdAt, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, employeeId, note, applied, createdAt, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockCountRow &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.note == this.note &&
          other.applied == this.applied &&
          other.createdAt == this.createdAt &&
          other.appliedAt == this.appliedAt);
}

class StockCountsCompanion extends UpdateCompanion<StockCountRow> {
  final Value<int> id;
  final Value<int?> employeeId;
  final Value<String?> note;
  final Value<bool> applied;
  final Value<DateTime> createdAt;
  final Value<DateTime?> appliedAt;
  const StockCountsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.note = const Value.absent(),
    this.applied = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.appliedAt = const Value.absent(),
  });
  StockCountsCompanion.insert({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.note = const Value.absent(),
    this.applied = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.appliedAt = const Value.absent(),
  });
  static Insertable<StockCountRow> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<String>? note,
    Expression<bool>? applied,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? appliedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (note != null) 'note': note,
      if (applied != null) 'applied': applied,
      if (createdAt != null) 'created_at': createdAt,
      if (appliedAt != null) 'applied_at': appliedAt,
    });
  }

  StockCountsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? employeeId,
      Value<String?>? note,
      Value<bool>? applied,
      Value<DateTime>? createdAt,
      Value<DateTime?>? appliedAt}) {
    return StockCountsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      note: note ?? this.note,
      applied: applied ?? this.applied,
      createdAt: createdAt ?? this.createdAt,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (applied.present) {
      map['applied'] = Variable<bool>(applied.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockCountsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('note: $note, ')
          ..write('applied: $applied, ')
          ..write('createdAt: $createdAt, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }
}

class $StockCountItemsTable extends StockCountItems
    with TableInfo<$StockCountItemsTable, StockCountItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockCountItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _stockCountIdMeta =
      const VerificationMeta('stockCountId');
  @override
  late final GeneratedColumn<int> stockCountId = GeneratedColumn<int>(
      'stock_count_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stock_counts (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _systemQtyMeta =
      const VerificationMeta('systemQty');
  @override
  late final GeneratedColumn<int> systemQty = GeneratedColumn<int>(
      'system_qty', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _countedQtyMeta =
      const VerificationMeta('countedQty');
  @override
  late final GeneratedColumn<int> countedQty = GeneratedColumn<int>(
      'counted_qty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _differenceMeta =
      const VerificationMeta('difference');
  @override
  late final GeneratedColumn<int> difference = GeneratedColumn<int>(
      'difference', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _countedMeta =
      const VerificationMeta('counted');
  @override
  late final GeneratedColumn<bool> counted = GeneratedColumn<bool>(
      'counted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("counted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        stockCountId,
        productId,
        productName,
        systemQty,
        countedQty,
        difference,
        counted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_count_items';
  @override
  VerificationContext validateIntegrity(Insertable<StockCountItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stock_count_id')) {
      context.handle(
          _stockCountIdMeta,
          stockCountId.isAcceptableOrUnknown(
              data['stock_count_id']!, _stockCountIdMeta));
    } else if (isInserting) {
      context.missing(_stockCountIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('system_qty')) {
      context.handle(_systemQtyMeta,
          systemQty.isAcceptableOrUnknown(data['system_qty']!, _systemQtyMeta));
    } else if (isInserting) {
      context.missing(_systemQtyMeta);
    }
    if (data.containsKey('counted_qty')) {
      context.handle(
          _countedQtyMeta,
          countedQty.isAcceptableOrUnknown(
              data['counted_qty']!, _countedQtyMeta));
    }
    if (data.containsKey('difference')) {
      context.handle(
          _differenceMeta,
          difference.isAcceptableOrUnknown(
              data['difference']!, _differenceMeta));
    }
    if (data.containsKey('counted')) {
      context.handle(_countedMeta,
          counted.isAcceptableOrUnknown(data['counted']!, _countedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockCountItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockCountItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      stockCountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_count_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      systemQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}system_qty'])!,
      countedQty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}counted_qty'])!,
      difference: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difference'])!,
      counted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}counted'])!,
    );
  }

  @override
  $StockCountItemsTable createAlias(String alias) {
    return $StockCountItemsTable(attachedDatabase, alias);
  }
}

class StockCountItemRow extends DataClass
    implements Insertable<StockCountItemRow> {
  final int id;
  final int stockCountId;
  final int productId;
  final String productName;
  final int systemQty;
  final int countedQty;
  final int difference;

  /// True only once the cashier actually typed a number for THIS product.
  /// [applyCount] writes back only the rows flagged here, so counting one
  /// product can never zero out the stock of everything else (the old
  /// code wrote countedQty for every row, and every untouched row was 0).
  final bool counted;
  const StockCountItemRow(
      {required this.id,
      required this.stockCountId,
      required this.productId,
      required this.productName,
      required this.systemQty,
      required this.countedQty,
      required this.difference,
      required this.counted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stock_count_id'] = Variable<int>(stockCountId);
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    map['system_qty'] = Variable<int>(systemQty);
    map['counted_qty'] = Variable<int>(countedQty);
    map['difference'] = Variable<int>(difference);
    map['counted'] = Variable<bool>(counted);
    return map;
  }

  StockCountItemsCompanion toCompanion(bool nullToAbsent) {
    return StockCountItemsCompanion(
      id: Value(id),
      stockCountId: Value(stockCountId),
      productId: Value(productId),
      productName: Value(productName),
      systemQty: Value(systemQty),
      countedQty: Value(countedQty),
      difference: Value(difference),
      counted: Value(counted),
    );
  }

  factory StockCountItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockCountItemRow(
      id: serializer.fromJson<int>(json['id']),
      stockCountId: serializer.fromJson<int>(json['stockCountId']),
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      systemQty: serializer.fromJson<int>(json['systemQty']),
      countedQty: serializer.fromJson<int>(json['countedQty']),
      difference: serializer.fromJson<int>(json['difference']),
      counted: serializer.fromJson<bool>(json['counted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stockCountId': serializer.toJson<int>(stockCountId),
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'systemQty': serializer.toJson<int>(systemQty),
      'countedQty': serializer.toJson<int>(countedQty),
      'difference': serializer.toJson<int>(difference),
      'counted': serializer.toJson<bool>(counted),
    };
  }

  StockCountItemRow copyWith(
          {int? id,
          int? stockCountId,
          int? productId,
          String? productName,
          int? systemQty,
          int? countedQty,
          int? difference,
          bool? counted}) =>
      StockCountItemRow(
        id: id ?? this.id,
        stockCountId: stockCountId ?? this.stockCountId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        systemQty: systemQty ?? this.systemQty,
        countedQty: countedQty ?? this.countedQty,
        difference: difference ?? this.difference,
        counted: counted ?? this.counted,
      );
  StockCountItemRow copyWithCompanion(StockCountItemsCompanion data) {
    return StockCountItemRow(
      id: data.id.present ? data.id.value : this.id,
      stockCountId: data.stockCountId.present
          ? data.stockCountId.value
          : this.stockCountId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      systemQty: data.systemQty.present ? data.systemQty.value : this.systemQty,
      countedQty:
          data.countedQty.present ? data.countedQty.value : this.countedQty,
      difference:
          data.difference.present ? data.difference.value : this.difference,
      counted: data.counted.present ? data.counted.value : this.counted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockCountItemRow(')
          ..write('id: $id, ')
          ..write('stockCountId: $stockCountId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('systemQty: $systemQty, ')
          ..write('countedQty: $countedQty, ')
          ..write('difference: $difference, ')
          ..write('counted: $counted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stockCountId, productId, productName,
      systemQty, countedQty, difference, counted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockCountItemRow &&
          other.id == this.id &&
          other.stockCountId == this.stockCountId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.systemQty == this.systemQty &&
          other.countedQty == this.countedQty &&
          other.difference == this.difference &&
          other.counted == this.counted);
}

class StockCountItemsCompanion extends UpdateCompanion<StockCountItemRow> {
  final Value<int> id;
  final Value<int> stockCountId;
  final Value<int> productId;
  final Value<String> productName;
  final Value<int> systemQty;
  final Value<int> countedQty;
  final Value<int> difference;
  final Value<bool> counted;
  const StockCountItemsCompanion({
    this.id = const Value.absent(),
    this.stockCountId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.systemQty = const Value.absent(),
    this.countedQty = const Value.absent(),
    this.difference = const Value.absent(),
    this.counted = const Value.absent(),
  });
  StockCountItemsCompanion.insert({
    this.id = const Value.absent(),
    required int stockCountId,
    required int productId,
    required String productName,
    required int systemQty,
    this.countedQty = const Value.absent(),
    this.difference = const Value.absent(),
    this.counted = const Value.absent(),
  })  : stockCountId = Value(stockCountId),
        productId = Value(productId),
        productName = Value(productName),
        systemQty = Value(systemQty);
  static Insertable<StockCountItemRow> custom({
    Expression<int>? id,
    Expression<int>? stockCountId,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<int>? systemQty,
    Expression<int>? countedQty,
    Expression<int>? difference,
    Expression<bool>? counted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stockCountId != null) 'stock_count_id': stockCountId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (systemQty != null) 'system_qty': systemQty,
      if (countedQty != null) 'counted_qty': countedQty,
      if (difference != null) 'difference': difference,
      if (counted != null) 'counted': counted,
    });
  }

  StockCountItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? stockCountId,
      Value<int>? productId,
      Value<String>? productName,
      Value<int>? systemQty,
      Value<int>? countedQty,
      Value<int>? difference,
      Value<bool>? counted}) {
    return StockCountItemsCompanion(
      id: id ?? this.id,
      stockCountId: stockCountId ?? this.stockCountId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      systemQty: systemQty ?? this.systemQty,
      countedQty: countedQty ?? this.countedQty,
      difference: difference ?? this.difference,
      counted: counted ?? this.counted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stockCountId.present) {
      map['stock_count_id'] = Variable<int>(stockCountId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (systemQty.present) {
      map['system_qty'] = Variable<int>(systemQty.value);
    }
    if (countedQty.present) {
      map['counted_qty'] = Variable<int>(countedQty.value);
    }
    if (difference.present) {
      map['difference'] = Variable<int>(difference.value);
    }
    if (counted.present) {
      map['counted'] = Variable<bool>(counted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockCountItemsCompanion(')
          ..write('id: $id, ')
          ..write('stockCountId: $stockCountId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('systemQty: $systemQty, ')
          ..write('countedQty: $countedQty, ')
          ..write('difference: $difference, ')
          ..write('counted: $counted')
          ..write(')'))
        .toString();
  }
}

class $EmployeeTransactionsTable extends EmployeeTransactions
    with TableInfo<$EmployeeTransactionsTable, EmployeeTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeeTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, employeeId, kind, amount, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employee_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<EmployeeTransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeeTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeTransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmployeeTransactionsTable createAlias(String alias) {
    return $EmployeeTransactionsTable(attachedDatabase, alias);
  }
}

class EmployeeTransactionRow extends DataClass
    implements Insertable<EmployeeTransactionRow> {
  final int id;
  final int employeeId;
  final String kind;
  final double amount;
  final String? note;
  final DateTime createdAt;
  const EmployeeTransactionRow(
      {required this.id,
      required this.employeeId,
      required this.kind,
      required this.amount,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmployeeTransactionsCompanion toCompanion(bool nullToAbsent) {
    return EmployeeTransactionsCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      kind: Value(kind),
      amount: Value(amount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory EmployeeTransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeTransactionRow(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EmployeeTransactionRow copyWith(
          {int? id,
          int? employeeId,
          String? kind,
          double? amount,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      EmployeeTransactionRow(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  EmployeeTransactionRow copyWithCompanion(EmployeeTransactionsCompanion data) {
    return EmployeeTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeTransactionRow(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, employeeId, kind, amount, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeTransactionRow &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class EmployeeTransactionsCompanion
    extends UpdateCompanion<EmployeeTransactionRow> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<String> kind;
  final Value<double> amount;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const EmployeeTransactionsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmployeeTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    required String kind,
    required double amount,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : employeeId = Value(employeeId),
        kind = Value(kind),
        amount = Value(amount);
  static Insertable<EmployeeTransactionRow> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<String>? kind,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmployeeTransactionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? employeeId,
      Value<String>? kind,
      Value<double>? amount,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return EmployeeTransactionsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EmployeeAttendanceTable extends EmployeeAttendance
    with TableInfo<$EmployeeAttendanceTable, EmployeeAttendanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeeAttendanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _checkInMeta =
      const VerificationMeta('checkIn');
  @override
  late final GeneratedColumn<DateTime> checkIn = GeneratedColumn<DateTime>(
      'check_in', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _checkOutMeta =
      const VerificationMeta('checkOut');
  @override
  late final GeneratedColumn<DateTime> checkOut = GeneratedColumn<DateTime>(
      'check_out', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, employeeId, checkIn, checkOut, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employee_attendance';
  @override
  VerificationContext validateIntegrity(
      Insertable<EmployeeAttendanceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('check_in')) {
      context.handle(_checkInMeta,
          checkIn.isAcceptableOrUnknown(data['check_in']!, _checkInMeta));
    } else if (isInserting) {
      context.missing(_checkInMeta);
    }
    if (data.containsKey('check_out')) {
      context.handle(_checkOutMeta,
          checkOut.isAcceptableOrUnknown(data['check_out']!, _checkOutMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeeAttendanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeAttendanceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      checkIn: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}check_in'])!,
      checkOut: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}check_out']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmployeeAttendanceTable createAlias(String alias) {
    return $EmployeeAttendanceTable(attachedDatabase, alias);
  }
}

class EmployeeAttendanceRow extends DataClass
    implements Insertable<EmployeeAttendanceRow> {
  final int id;
  final int employeeId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final DateTime createdAt;
  const EmployeeAttendanceRow(
      {required this.id,
      required this.employeeId,
      required this.checkIn,
      this.checkOut,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    map['check_in'] = Variable<DateTime>(checkIn);
    if (!nullToAbsent || checkOut != null) {
      map['check_out'] = Variable<DateTime>(checkOut);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmployeeAttendanceCompanion toCompanion(bool nullToAbsent) {
    return EmployeeAttendanceCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      checkIn: Value(checkIn),
      checkOut: checkOut == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOut),
      createdAt: Value(createdAt),
    );
  }

  factory EmployeeAttendanceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeAttendanceRow(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      checkIn: serializer.fromJson<DateTime>(json['checkIn']),
      checkOut: serializer.fromJson<DateTime?>(json['checkOut']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'checkIn': serializer.toJson<DateTime>(checkIn),
      'checkOut': serializer.toJson<DateTime?>(checkOut),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EmployeeAttendanceRow copyWith(
          {int? id,
          int? employeeId,
          DateTime? checkIn,
          Value<DateTime?> checkOut = const Value.absent(),
          DateTime? createdAt}) =>
      EmployeeAttendanceRow(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut.present ? checkOut.value : this.checkOut,
        createdAt: createdAt ?? this.createdAt,
      );
  EmployeeAttendanceRow copyWithCompanion(EmployeeAttendanceCompanion data) {
    return EmployeeAttendanceRow(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      checkIn: data.checkIn.present ? data.checkIn.value : this.checkIn,
      checkOut: data.checkOut.present ? data.checkOut.value : this.checkOut,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeAttendanceRow(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('checkIn: $checkIn, ')
          ..write('checkOut: $checkOut, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, employeeId, checkIn, checkOut, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeAttendanceRow &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.checkIn == this.checkIn &&
          other.checkOut == this.checkOut &&
          other.createdAt == this.createdAt);
}

class EmployeeAttendanceCompanion
    extends UpdateCompanion<EmployeeAttendanceRow> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<DateTime> checkIn;
  final Value<DateTime?> checkOut;
  final Value<DateTime> createdAt;
  const EmployeeAttendanceCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.checkIn = const Value.absent(),
    this.checkOut = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmployeeAttendanceCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    required DateTime checkIn,
    this.checkOut = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : employeeId = Value(employeeId),
        checkIn = Value(checkIn);
  static Insertable<EmployeeAttendanceRow> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<DateTime>? checkIn,
    Expression<DateTime>? checkOut,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (checkIn != null) 'check_in': checkIn,
      if (checkOut != null) 'check_out': checkOut,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmployeeAttendanceCompanion copyWith(
      {Value<int>? id,
      Value<int>? employeeId,
      Value<DateTime>? checkIn,
      Value<DateTime?>? checkOut,
      Value<DateTime>? createdAt}) {
    return EmployeeAttendanceCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (checkIn.present) {
      map['check_in'] = Variable<DateTime>(checkIn.value);
    }
    if (checkOut.present) {
      map['check_out'] = Variable<DateTime>(checkOut.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeAttendanceCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('checkIn: $checkIn, ')
          ..write('checkOut: $checkOut, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $DeviceTypesTable deviceTypes = $DeviceTypesTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $PackagesTable packages = $PackagesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionEventsTable sessionEvents = $SessionEventsTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $EmployeeFeatureOverridesTable employeeFeatureOverrides =
      $EmployeeFeatureOverridesTable(this);
  late final $ReservationsTable reservations = $ReservationsTable(this);
  late final $OffersTable offers = $OffersTable(this);
  late final $LoyaltySettingsTable loyaltySettings =
      $LoyaltySettingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $AccountEntriesTable accountEntries = $AccountEntriesTable(this);
  late final $RefundsTable refunds = $RefundsTable(this);
  late final $StockCountsTable stockCounts = $StockCountsTable(this);
  late final $StockCountItemsTable stockCountItems =
      $StockCountItemsTable(this);
  late final $EmployeeTransactionsTable employeeTransactions =
      $EmployeeTransactionsTable(this);
  late final $EmployeeAttendanceTable employeeAttendance =
      $EmployeeAttendanceTable(this);
  late final EmployeeDao employeeDao = EmployeeDao(this as AppDatabase);
  late final DeviceDao deviceDao = DeviceDao(this as AppDatabase);
  late final CustomerDao customerDao = CustomerDao(this as AppDatabase);
  late final ProductDao productDao = ProductDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final InvoiceDao invoiceDao = InvoiceDao(this as AppDatabase);
  late final AuditLogDao auditLogDao = AuditLogDao(this as AppDatabase);
  late final ShiftDao shiftDao = ShiftDao(this as AppDatabase);
  late final ExpenseDao expenseDao = ExpenseDao(this as AppDatabase);
  late final EmployeeFeatureDao employeeFeatureDao =
      EmployeeFeatureDao(this as AppDatabase);
  late final ReservationDao reservationDao =
      ReservationDao(this as AppDatabase);
  late final PackageDao packageDao = PackageDao(this as AppDatabase);
  late final OfferDao offerDao = OfferDao(this as AppDatabase);
  late final LoyaltyDao loyaltyDao = LoyaltyDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final RefundDao refundDao = RefundDao(this as AppDatabase);
  late final StockCountDao stockCountDao = StockCountDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        employees,
        deviceTypes,
        devices,
        customers,
        categories,
        products,
        packages,
        sessions,
        sessionEvents,
        invoices,
        invoiceItems,
        auditLogs,
        shifts,
        expenses,
        employeeFeatureOverrides,
        reservations,
        offers,
        loyaltySettings,
        appSettings,
        accounts,
        accountEntries,
        refunds,
        stockCounts,
        stockCountItems,
        employeeTransactions,
        employeeAttendance
      ];
}

typedef $$EmployeesTableCreateCompanionBuilder = EmployeesCompanion Function({
  Value<int> id,
  required String name,
  required String phone,
  required String role,
  required String pinHash,
  Value<bool> isPartner,
  Value<double?> partnerShare,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$EmployeesTableUpdateCompanionBuilder = EmployeesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> phone,
  Value<String> role,
  Value<String> pinHash,
  Value<bool> isPartner,
  Value<double?> partnerShare,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$EmployeesTableReferences
    extends BaseReferences<_$AppDatabase, $EmployeesTable, EmployeeRow> {
  $$EmployeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
      _sessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessions,
              aliasName: 'employees__id__sessions__employee_id');

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvoicesTable, List<InvoiceRow>>
      _invoicesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoices,
              aliasName: 'employees__id__invoices__employee_id');

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShiftsTable, List<ShiftRow>> _shiftsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shifts,
          aliasName: 'employees__id__shifts__employee_id');

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager($_db, $_db.shifts)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpensesTable, List<ExpenseRow>>
      _expensesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.expenses,
              aliasName: 'employees__id__expenses__employee_id');

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EmployeeFeatureOverridesTable,
      List<EmployeeFeatureOverrideRow>> _employeeFeatureOverridesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.employeeFeatureOverrides,
          aliasName: 'employees__id__employee_feature_overrides__employee_id');

  $$EmployeeFeatureOverridesTableProcessedTableManager
      get employeeFeatureOverridesRefs {
    final manager = $$EmployeeFeatureOverridesTableTableManager(
            $_db, $_db.employeeFeatureOverrides)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_employeeFeatureOverridesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReservationsTable, List<ReservationRow>>
      _reservationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.reservations,
              aliasName: 'employees__id__reservations__employee_id');

  $$ReservationsTableProcessedTableManager get reservationsRefs {
    final manager = $$ReservationsTableTableManager($_db, $_db.reservations)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reservationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RefundsTable, List<RefundRow>> _refundsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.refunds,
          aliasName: 'employees__id__refunds__employee_id');

  $$RefundsTableProcessedTableManager get refundsRefs {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockCountsTable, List<StockCountRow>>
      _stockCountsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockCounts,
              aliasName: 'employees__id__stock_counts__employee_id');

  $$StockCountsTableProcessedTableManager get stockCountsRefs {
    final manager = $$StockCountsTableTableManager($_db, $_db.stockCounts)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockCountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EmployeeTransactionsTable,
      List<EmployeeTransactionRow>> _employeeTransactionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.employeeTransactions,
          aliasName: 'employees__id__employee_transactions__employee_id');

  $$EmployeeTransactionsTableProcessedTableManager
      get employeeTransactionsRefs {
    final manager =
        $$EmployeeTransactionsTableTableManager($_db, $_db.employeeTransactions)
            .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_employeeTransactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$EmployeeAttendanceTable,
      List<EmployeeAttendanceRow>> _employeeAttendanceRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.employeeAttendance,
          aliasName: 'employees__id__employee_attendance__employee_id');

  $$EmployeeAttendanceTableProcessedTableManager get employeeAttendanceRefs {
    final manager =
        $$EmployeeAttendanceTableTableManager($_db, $_db.employeeAttendance)
            .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_employeeAttendanceRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPartner => $composableBuilder(
      column: $table.isPartner, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get partnerShare => $composableBuilder(
      column: $table.partnerShare, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> sessionsRefs(
      Expression<bool> Function($$SessionsTableFilterComposer f) f) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> invoicesRefs(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> shiftsRefs(
      Expression<bool> Function($$ShiftsTableFilterComposer f) f) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableFilterComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expensesRefs(
      Expression<bool> Function($$ExpensesTableFilterComposer f) f) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> employeeFeatureOverridesRefs(
      Expression<bool> Function($$EmployeeFeatureOverridesTableFilterComposer f)
          f) {
    final $$EmployeeFeatureOverridesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.employeeFeatureOverrides,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EmployeeFeatureOverridesTableFilterComposer(
                  $db: $db,
                  $table: $db.employeeFeatureOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> reservationsRefs(
      Expression<bool> Function($$ReservationsTableFilterComposer f) f) {
    final $$ReservationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reservations,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReservationsTableFilterComposer(
              $db: $db,
              $table: $db.reservations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> refundsRefs(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockCountsRefs(
      Expression<bool> Function($$StockCountsTableFilterComposer f) f) {
    final $$StockCountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockCounts,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountsTableFilterComposer(
              $db: $db,
              $table: $db.stockCounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> employeeTransactionsRefs(
      Expression<bool> Function($$EmployeeTransactionsTableFilterComposer f)
          f) {
    final $$EmployeeTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.employeeTransactions,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeeTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.employeeTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> employeeAttendanceRefs(
      Expression<bool> Function($$EmployeeAttendanceTableFilterComposer f) f) {
    final $$EmployeeAttendanceTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.employeeAttendance,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeeAttendanceTableFilterComposer(
              $db: $db,
              $table: $db.employeeAttendance,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinHash => $composableBuilder(
      column: $table.pinHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPartner => $composableBuilder(
      column: $table.isPartner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get partnerShare => $composableBuilder(
      column: $table.partnerShare,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableAnnotationComposer({
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get isPartner =>
      $composableBuilder(column: $table.isPartner, builder: (column) => column);

  GeneratedColumn<double> get partnerShare => $composableBuilder(
      column: $table.partnerShare, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
      Expression<T> Function($$SessionsTableAnnotationComposer a) f) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> invoicesRefs<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> shiftsRefs<T extends Object>(
      Expression<T> Function($$ShiftsTableAnnotationComposer a) f) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableAnnotationComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
      Expression<T> Function($$ExpensesTableAnnotationComposer a) f) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> employeeFeatureOverridesRefs<T extends Object>(
      Expression<T> Function(
              $$EmployeeFeatureOverridesTableAnnotationComposer a)
          f) {
    final $$EmployeeFeatureOverridesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.employeeFeatureOverrides,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EmployeeFeatureOverridesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.employeeFeatureOverrides,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> reservationsRefs<T extends Object>(
      Expression<T> Function($$ReservationsTableAnnotationComposer a) f) {
    final $$ReservationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reservations,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReservationsTableAnnotationComposer(
              $db: $db,
              $table: $db.reservations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> refundsRefs<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockCountsRefs<T extends Object>(
      Expression<T> Function($$StockCountsTableAnnotationComposer a) f) {
    final $$StockCountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockCounts,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockCounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> employeeTransactionsRefs<T extends Object>(
      Expression<T> Function($$EmployeeTransactionsTableAnnotationComposer a)
          f) {
    final $$EmployeeTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.employeeTransactions,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EmployeeTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.employeeTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> employeeAttendanceRefs<T extends Object>(
      Expression<T> Function($$EmployeeAttendanceTableAnnotationComposer a) f) {
    final $$EmployeeAttendanceTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.employeeAttendance,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$EmployeeAttendanceTableAnnotationComposer(
                  $db: $db,
                  $table: $db.employeeAttendance,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$EmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeesTable,
    EmployeeRow,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (EmployeeRow, $$EmployeesTableReferences),
    EmployeeRow,
    PrefetchHooks Function(
        {bool sessionsRefs,
        bool invoicesRefs,
        bool shiftsRefs,
        bool expensesRefs,
        bool employeeFeatureOverridesRefs,
        bool reservationsRefs,
        bool refundsRefs,
        bool stockCountsRefs,
        bool employeeTransactionsRefs,
        bool employeeAttendanceRefs})> {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> pinHash = const Value.absent(),
            Value<bool> isPartner = const Value.absent(),
            Value<double?> partnerShare = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EmployeesCompanion(
            id: id,
            name: name,
            phone: phone,
            role: role,
            pinHash: pinHash,
            isPartner: isPartner,
            partnerShare: partnerShare,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String phone,
            required String role,
            required String pinHash,
            Value<bool> isPartner = const Value.absent(),
            Value<double?> partnerShare = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EmployeesCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            role: role,
            pinHash: pinHash,
            isPartner: isPartner,
            partnerShare: partnerShare,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sessionsRefs = false,
              invoicesRefs = false,
              shiftsRefs = false,
              expensesRefs = false,
              employeeFeatureOverridesRefs = false,
              reservationsRefs = false,
              refundsRefs = false,
              stockCountsRefs = false,
              employeeTransactionsRefs = false,
              employeeAttendanceRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionsRefs) db.sessions,
                if (invoicesRefs) db.invoices,
                if (shiftsRefs) db.shifts,
                if (expensesRefs) db.expenses,
                if (employeeFeatureOverridesRefs) db.employeeFeatureOverrides,
                if (reservationsRefs) db.reservations,
                if (refundsRefs) db.refunds,
                if (stockCountsRefs) db.stockCounts,
                if (employeeTransactionsRefs) db.employeeTransactions,
                if (employeeAttendanceRefs) db.employeeAttendance
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            SessionRow>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._sessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .sessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (invoicesRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            InvoiceRow>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._invoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .invoicesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (shiftsRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            ShiftRow>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._shiftsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .shiftsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (expensesRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            ExpenseRow>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._expensesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .expensesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (employeeFeatureOverridesRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            EmployeeFeatureOverrideRow>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._employeeFeatureOverridesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .employeeFeatureOverridesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (reservationsRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            ReservationRow>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._reservationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .reservationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (refundsRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            RefundRow>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._refundsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .refundsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (stockCountsRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            StockCountRow>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._stockCountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .stockCountsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (employeeTransactionsRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            EmployeeTransactionRow>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._employeeTransactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .employeeTransactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (employeeAttendanceRefs)
                    await $_getPrefetchedData<EmployeeRow, $EmployeesTable,
                            EmployeeAttendanceRow>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._employeeAttendanceRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .employeeAttendanceRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EmployeesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmployeesTable,
    EmployeeRow,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (EmployeeRow, $$EmployeesTableReferences),
    EmployeeRow,
    PrefetchHooks Function(
        {bool sessionsRefs,
        bool invoicesRefs,
        bool shiftsRefs,
        bool expensesRefs,
        bool employeeFeatureOverridesRefs,
        bool reservationsRefs,
        bool refundsRefs,
        bool stockCountsRefs,
        bool employeeTransactionsRefs,
        bool employeeAttendanceRefs})>;
typedef $$DeviceTypesTableCreateCompanionBuilder = DeviceTypesCompanion
    Function({
  Value<int> id,
  required String name,
  Value<double> defaultHourlyRate,
  Value<double> defaultHourlyRateMulti,
});
typedef $$DeviceTypesTableUpdateCompanionBuilder = DeviceTypesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<double> defaultHourlyRate,
  Value<double> defaultHourlyRateMulti,
});

final class $$DeviceTypesTableReferences
    extends BaseReferences<_$AppDatabase, $DeviceTypesTable, DeviceTypeRow> {
  $$DeviceTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DevicesTable, List<DeviceRow>> _devicesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.devices,
          aliasName: 'device_types__id__devices__device_type_id');

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager($_db, $_db.devices)
        .filter((f) => f.deviceTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PackagesTable, List<PackageRow>>
      _packagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.packages,
              aliasName: 'device_types__id__packages__device_type_id');

  $$PackagesTableProcessedTableManager get packagesRefs {
    final manager = $$PackagesTableTableManager($_db, $_db.packages)
        .filter((f) => f.deviceTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_packagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DeviceTypesTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceTypesTable> {
  $$DeviceTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get defaultHourlyRate => $composableBuilder(
      column: $table.defaultHourlyRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get defaultHourlyRateMulti => $composableBuilder(
      column: $table.defaultHourlyRateMulti,
      builder: (column) => ColumnFilters(column));

  Expression<bool> devicesRefs(
      Expression<bool> Function($$DevicesTableFilterComposer f) f) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.deviceTypeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableFilterComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> packagesRefs(
      Expression<bool> Function($$PackagesTableFilterComposer f) f) {
    final $$PackagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.packages,
        getReferencedColumn: (t) => t.deviceTypeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PackagesTableFilterComposer(
              $db: $db,
              $table: $db.packages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DeviceTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceTypesTable> {
  $$DeviceTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get defaultHourlyRate => $composableBuilder(
      column: $table.defaultHourlyRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get defaultHourlyRateMulti => $composableBuilder(
      column: $table.defaultHourlyRateMulti,
      builder: (column) => ColumnOrderings(column));
}

class $$DeviceTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceTypesTable> {
  $$DeviceTypesTableAnnotationComposer({
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

  GeneratedColumn<double> get defaultHourlyRate => $composableBuilder(
      column: $table.defaultHourlyRate, builder: (column) => column);

  GeneratedColumn<double> get defaultHourlyRateMulti => $composableBuilder(
      column: $table.defaultHourlyRateMulti, builder: (column) => column);

  Expression<T> devicesRefs<T extends Object>(
      Expression<T> Function($$DevicesTableAnnotationComposer a) f) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.deviceTypeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableAnnotationComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> packagesRefs<T extends Object>(
      Expression<T> Function($$PackagesTableAnnotationComposer a) f) {
    final $$PackagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.packages,
        getReferencedColumn: (t) => t.deviceTypeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PackagesTableAnnotationComposer(
              $db: $db,
              $table: $db.packages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DeviceTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeviceTypesTable,
    DeviceTypeRow,
    $$DeviceTypesTableFilterComposer,
    $$DeviceTypesTableOrderingComposer,
    $$DeviceTypesTableAnnotationComposer,
    $$DeviceTypesTableCreateCompanionBuilder,
    $$DeviceTypesTableUpdateCompanionBuilder,
    (DeviceTypeRow, $$DeviceTypesTableReferences),
    DeviceTypeRow,
    PrefetchHooks Function({bool devicesRefs, bool packagesRefs})> {
  $$DeviceTypesTableTableManager(_$AppDatabase db, $DeviceTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> defaultHourlyRate = const Value.absent(),
            Value<double> defaultHourlyRateMulti = const Value.absent(),
          }) =>
              DeviceTypesCompanion(
            id: id,
            name: name,
            defaultHourlyRate: defaultHourlyRate,
            defaultHourlyRateMulti: defaultHourlyRateMulti,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double> defaultHourlyRate = const Value.absent(),
            Value<double> defaultHourlyRateMulti = const Value.absent(),
          }) =>
              DeviceTypesCompanion.insert(
            id: id,
            name: name,
            defaultHourlyRate: defaultHourlyRate,
            defaultHourlyRateMulti: defaultHourlyRateMulti,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DeviceTypesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({devicesRefs = false, packagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (devicesRefs) db.devices,
                if (packagesRefs) db.packages
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (devicesRefs)
                    await $_getPrefetchedData<DeviceTypeRow, $DeviceTypesTable,
                            DeviceRow>(
                        currentTable: table,
                        referencedTable:
                            $$DeviceTypesTableReferences._devicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DeviceTypesTableReferences(db, table, p0)
                                .devicesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.deviceTypeId == item.id),
                        typedResults: items),
                  if (packagesRefs)
                    await $_getPrefetchedData<DeviceTypeRow, $DeviceTypesTable,
                            PackageRow>(
                        currentTable: table,
                        referencedTable:
                            $$DeviceTypesTableReferences._packagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DeviceTypesTableReferences(db, table, p0)
                                .packagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.deviceTypeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DeviceTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeviceTypesTable,
    DeviceTypeRow,
    $$DeviceTypesTableFilterComposer,
    $$DeviceTypesTableOrderingComposer,
    $$DeviceTypesTableAnnotationComposer,
    $$DeviceTypesTableCreateCompanionBuilder,
    $$DeviceTypesTableUpdateCompanionBuilder,
    (DeviceTypeRow, $$DeviceTypesTableReferences),
    DeviceTypeRow,
    PrefetchHooks Function({bool devicesRefs, bool packagesRefs})>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  Value<int> id,
  required String name,
  required int deviceTypeId,
  Value<double?> customHourlyRate,
  Value<double?> customHourlyRateMulti,
  Value<String> status,
  Value<String?> notes,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> deviceTypeId,
  Value<double?> customHourlyRate,
  Value<double?> customHourlyRateMulti,
  Value<String> status,
  Value<String?> notes,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, DeviceRow> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DeviceTypesTable _deviceTypeIdTable(_$AppDatabase db) =>
      db.deviceTypes.createAlias('devices__device_type_id__device_types__id');

  $$DeviceTypesTableProcessedTableManager get deviceTypeId {
    final $_column = $_itemColumn<int>('device_type_id')!;

    final manager = $$DeviceTypesTableTableManager($_db, $_db.deviceTypes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
      _sessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessions,
              aliasName: 'devices__id__sessions__device_id');

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReservationsTable, List<ReservationRow>>
      _reservationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.reservations,
              aliasName: 'devices__id__reservations__device_id');

  $$ReservationsTableProcessedTableManager get reservationsRefs {
    final manager = $$ReservationsTableTableManager($_db, $_db.reservations)
        .filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reservationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customHourlyRate => $composableBuilder(
      column: $table.customHourlyRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customHourlyRateMulti => $composableBuilder(
      column: $table.customHourlyRateMulti,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$DeviceTypesTableFilterComposer get deviceTypeId {
    final $$DeviceTypesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceTypeId,
        referencedTable: $db.deviceTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DeviceTypesTableFilterComposer(
              $db: $db,
              $table: $db.deviceTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> sessionsRefs(
      Expression<bool> Function($$SessionsTableFilterComposer f) f) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.deviceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reservationsRefs(
      Expression<bool> Function($$ReservationsTableFilterComposer f) f) {
    final $$ReservationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reservations,
        getReferencedColumn: (t) => t.deviceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReservationsTableFilterComposer(
              $db: $db,
              $table: $db.reservations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customHourlyRate => $composableBuilder(
      column: $table.customHourlyRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customHourlyRateMulti => $composableBuilder(
      column: $table.customHourlyRateMulti,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$DeviceTypesTableOrderingComposer get deviceTypeId {
    final $$DeviceTypesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceTypeId,
        referencedTable: $db.deviceTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DeviceTypesTableOrderingComposer(
              $db: $db,
              $table: $db.deviceTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
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

  GeneratedColumn<double> get customHourlyRate => $composableBuilder(
      column: $table.customHourlyRate, builder: (column) => column);

  GeneratedColumn<double> get customHourlyRateMulti => $composableBuilder(
      column: $table.customHourlyRateMulti, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DeviceTypesTableAnnotationComposer get deviceTypeId {
    final $$DeviceTypesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceTypeId,
        referencedTable: $db.deviceTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DeviceTypesTableAnnotationComposer(
              $db: $db,
              $table: $db.deviceTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> sessionsRefs<T extends Object>(
      Expression<T> Function($$SessionsTableAnnotationComposer a) f) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.deviceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> reservationsRefs<T extends Object>(
      Expression<T> Function($$ReservationsTableAnnotationComposer a) f) {
    final $$ReservationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reservations,
        getReferencedColumn: (t) => t.deviceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReservationsTableAnnotationComposer(
              $db: $db,
              $table: $db.reservations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesTable,
    DeviceRow,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (DeviceRow, $$DevicesTableReferences),
    DeviceRow,
    PrefetchHooks Function(
        {bool deviceTypeId, bool sessionsRefs, bool reservationsRefs})> {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> deviceTypeId = const Value.absent(),
            Value<double?> customHourlyRate = const Value.absent(),
            Value<double?> customHourlyRateMulti = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DevicesCompanion(
            id: id,
            name: name,
            deviceTypeId: deviceTypeId,
            customHourlyRate: customHourlyRate,
            customHourlyRateMulti: customHourlyRateMulti,
            status: status,
            notes: notes,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int deviceTypeId,
            Value<double?> customHourlyRate = const Value.absent(),
            Value<double?> customHourlyRateMulti = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            id: id,
            name: name,
            deviceTypeId: deviceTypeId,
            customHourlyRate: customHourlyRate,
            customHourlyRateMulti: customHourlyRateMulti,
            status: status,
            notes: notes,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DevicesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {deviceTypeId = false,
              sessionsRefs = false,
              reservationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionsRefs) db.sessions,
                if (reservationsRefs) db.reservations
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (deviceTypeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.deviceTypeId,
                    referencedTable:
                        $$DevicesTableReferences._deviceTypeIdTable(db),
                    referencedColumn:
                        $$DevicesTableReferences._deviceTypeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<DeviceRow, $DevicesTable,
                            SessionRow>(
                        currentTable: table,
                        referencedTable:
                            $$DevicesTableReferences._sessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DevicesTableReferences(db, table, p0)
                                .sessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.deviceId == item.id),
                        typedResults: items),
                  if (reservationsRefs)
                    await $_getPrefetchedData<DeviceRow, $DevicesTable,
                            ReservationRow>(
                        currentTable: table,
                        referencedTable:
                            $$DevicesTableReferences._reservationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DevicesTableReferences(db, table, p0)
                                .reservationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.deviceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DevicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DevicesTable,
    DeviceRow,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (DeviceRow, $$DevicesTableReferences),
    DeviceRow,
    PrefetchHooks Function(
        {bool deviceTypeId, bool sessionsRefs, bool reservationsRefs})>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  required String name,
  required String phone,
  Value<String?> email,
  Value<String?> notes,
  Value<int> totalVisits,
  Value<double> totalSpent,
  Value<int> loyaltyPoints,
  Value<String> customerLevel,
  Value<bool> isVip,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> phone,
  Value<String?> email,
  Value<String?> notes,
  Value<int> totalVisits,
  Value<double> totalSpent,
  Value<int> loyaltyPoints,
  Value<String> customerLevel,
  Value<bool> isVip,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
      _sessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessions,
              aliasName: 'customers__id__sessions__customer_id');

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvoicesTable, List<InvoiceRow>>
      _invoicesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoices,
              aliasName: 'customers__id__invoices__customer_id');

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReservationsTable, List<ReservationRow>>
      _reservationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.reservations,
              aliasName: 'customers__id__reservations__customer_id');

  $$ReservationsTableProcessedTableManager get reservationsRefs {
    final manager = $$ReservationsTableTableManager($_db, $_db.reservations)
        .filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reservationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalVisits => $composableBuilder(
      column: $table.totalVisits, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalSpent => $composableBuilder(
      column: $table.totalSpent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get loyaltyPoints => $composableBuilder(
      column: $table.loyaltyPoints, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerLevel => $composableBuilder(
      column: $table.customerLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVip => $composableBuilder(
      column: $table.isVip, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> sessionsRefs(
      Expression<bool> Function($$SessionsTableFilterComposer f) f) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> invoicesRefs(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reservationsRefs(
      Expression<bool> Function($$ReservationsTableFilterComposer f) f) {
    final $$ReservationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reservations,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReservationsTableFilterComposer(
              $db: $db,
              $table: $db.reservations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalVisits => $composableBuilder(
      column: $table.totalVisits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalSpent => $composableBuilder(
      column: $table.totalSpent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get loyaltyPoints => $composableBuilder(
      column: $table.loyaltyPoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerLevel => $composableBuilder(
      column: $table.customerLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVip => $composableBuilder(
      column: $table.isVip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get totalVisits => $composableBuilder(
      column: $table.totalVisits, builder: (column) => column);

  GeneratedColumn<double> get totalSpent => $composableBuilder(
      column: $table.totalSpent, builder: (column) => column);

  GeneratedColumn<int> get loyaltyPoints => $composableBuilder(
      column: $table.loyaltyPoints, builder: (column) => column);

  GeneratedColumn<String> get customerLevel => $composableBuilder(
      column: $table.customerLevel, builder: (column) => column);

  GeneratedColumn<bool> get isVip =>
      $composableBuilder(column: $table.isVip, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
      Expression<T> Function($$SessionsTableAnnotationComposer a) f) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> invoicesRefs<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> reservationsRefs<T extends Object>(
      Expression<T> Function($$ReservationsTableAnnotationComposer a) f) {
    final $$ReservationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reservations,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReservationsTableAnnotationComposer(
              $db: $db,
              $table: $db.reservations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    CustomerRow,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (CustomerRow, $$CustomersTableReferences),
    CustomerRow,
    PrefetchHooks Function(
        {bool sessionsRefs, bool invoicesRefs, bool reservationsRefs})> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> totalVisits = const Value.absent(),
            Value<double> totalSpent = const Value.absent(),
            Value<int> loyaltyPoints = const Value.absent(),
            Value<String> customerLevel = const Value.absent(),
            Value<bool> isVip = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            email: email,
            notes: notes,
            totalVisits: totalVisits,
            totalSpent: totalSpent,
            loyaltyPoints: loyaltyPoints,
            customerLevel: customerLevel,
            isVip: isVip,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String phone,
            Value<String?> email = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> totalVisits = const Value.absent(),
            Value<double> totalSpent = const Value.absent(),
            Value<int> loyaltyPoints = const Value.absent(),
            Value<String> customerLevel = const Value.absent(),
            Value<bool> isVip = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            email: email,
            notes: notes,
            totalVisits: totalVisits,
            totalSpent: totalSpent,
            loyaltyPoints: loyaltyPoints,
            customerLevel: customerLevel,
            isVip: isVip,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CustomersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sessionsRefs = false,
              invoicesRefs = false,
              reservationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionsRefs) db.sessions,
                if (invoicesRefs) db.invoices,
                if (reservationsRefs) db.reservations
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<CustomerRow, $CustomersTable,
                            SessionRow>(
                        currentTable: table,
                        referencedTable:
                            $$CustomersTableReferences._sessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomersTableReferences(db, table, p0)
                                .sessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.customerId == item.id),
                        typedResults: items),
                  if (invoicesRefs)
                    await $_getPrefetchedData<CustomerRow, $CustomersTable,
                            InvoiceRow>(
                        currentTable: table,
                        referencedTable:
                            $$CustomersTableReferences._invoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomersTableReferences(db, table, p0)
                                .invoicesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.customerId == item.id),
                        typedResults: items),
                  if (reservationsRefs)
                    await $_getPrefetchedData<CustomerRow, $CustomersTable,
                            ReservationRow>(
                        currentTable: table,
                        referencedTable: $$CustomersTableReferences
                            ._reservationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomersTableReferences(db, table, p0)
                                .reservationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.customerId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    CustomerRow,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (CustomerRow, $$CustomersTableReferences),
    CustomerRow,
    PrefetchHooks Function(
        {bool sessionsRefs, bool invoicesRefs, bool reservationsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<ProductRow>>
      _productsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.products,
              aliasName: 'categories__id__products__category_id');

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> productsRefs(
      Expression<bool> Function($$ProductsTableFilterComposer f) f) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  Expression<T> productsRefs<T extends Object>(
      Expression<T> Function($$ProductsTableAnnotationComposer a) f) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, $$CategoriesTableReferences),
    CategoryRow,
    PrefetchHooks Function({bool productsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<CategoryRow, $CategoriesTable,
                            ProductRow>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._productsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .productsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, $$CategoriesTableReferences),
    CategoryRow,
    PrefetchHooks Function({bool productsRefs})>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String name,
  required int categoryId,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> costPrice,
  Value<double> sellingPrice,
  Value<int> stockQuantity,
  Value<int> minimumStock,
  Value<int?> maximumStock,
  Value<String> unit,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> categoryId,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> costPrice,
  Value<double> sellingPrice,
  Value<int> stockQuantity,
  Value<int> minimumStock,
  Value<int?> maximumStock,
  Value<String> unit,
  Value<bool> active,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('products__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItemRow>>
      _invoiceItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoiceItems,
              aliasName: 'products__id__invoice_items__product_id');

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager($_db, $_db.invoiceItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockCountItemsTable, List<StockCountItemRow>>
      _stockCountItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockCountItems,
              aliasName: 'products__id__stock_count_items__product_id');

  $$StockCountItemsTableProcessedTableManager get stockCountItemsRefs {
    final manager =
        $$StockCountItemsTableTableManager($_db, $_db.stockCountItems)
            .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_stockCountItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minimumStock => $composableBuilder(
      column: $table.minimumStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maximumStock => $composableBuilder(
      column: $table.maximumStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> invoiceItemsRefs(
      Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableFilterComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockCountItemsRefs(
      Expression<bool> Function($$StockCountItemsTableFilterComposer f) f) {
    final $$StockCountItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockCountItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountItemsTableFilterComposer(
              $db: $db,
              $table: $db.stockCountItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minimumStock => $composableBuilder(
      column: $table.minimumStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maximumStock => $composableBuilder(
      column: $table.maximumStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
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

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get sellingPrice => $composableBuilder(
      column: $table.sellingPrice, builder: (column) => column);

  GeneratedColumn<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => column);

  GeneratedColumn<int> get minimumStock => $composableBuilder(
      column: $table.minimumStock, builder: (column) => column);

  GeneratedColumn<int> get maximumStock => $composableBuilder(
      column: $table.maximumStock, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> invoiceItemsRefs<T extends Object>(
      Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockCountItemsRefs<T extends Object>(
      Expression<T> Function($$StockCountItemsTableAnnotationComposer a) f) {
    final $$StockCountItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockCountItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockCountItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, $$ProductsTableReferences),
    ProductRow,
    PrefetchHooks Function(
        {bool categoryId, bool invoiceItemsRefs, bool stockCountItemsRefs})> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<double> sellingPrice = const Value.absent(),
            Value<int> stockQuantity = const Value.absent(),
            Value<int> minimumStock = const Value.absent(),
            Value<int?> maximumStock = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            name: name,
            categoryId: categoryId,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            stockQuantity: stockQuantity,
            minimumStock: minimumStock,
            maximumStock: maximumStock,
            unit: unit,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int categoryId,
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<double> sellingPrice = const Value.absent(),
            Value<int> stockQuantity = const Value.absent(),
            Value<int> minimumStock = const Value.absent(),
            Value<int?> maximumStock = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            name: name,
            categoryId: categoryId,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            stockQuantity: stockQuantity,
            minimumStock: minimumStock,
            maximumStock: maximumStock,
            unit: unit,
            active: active,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              invoiceItemsRefs = false,
              stockCountItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (invoiceItemsRefs) db.invoiceItems,
                if (stockCountItemsRefs) db.stockCountItems
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ProductsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ProductsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoiceItemsRefs)
                    await $_getPrefetchedData<ProductRow, $ProductsTable,
                            InvoiceItemRow>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._invoiceItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .invoiceItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (stockCountItemsRefs)
                    await $_getPrefetchedData<ProductRow, $ProductsTable,
                            StockCountItemRow>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._stockCountItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .stockCountItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, $$ProductsTableReferences),
    ProductRow,
    PrefetchHooks Function(
        {bool categoryId, bool invoiceItemsRefs, bool stockCountItemsRefs})>;
typedef $$PackagesTableCreateCompanionBuilder = PackagesCompanion Function({
  Value<int> id,
  required String name,
  required int deviceTypeId,
  Value<double> fixedPrice,
  Value<int> durationMinutes,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$PackagesTableUpdateCompanionBuilder = PackagesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> deviceTypeId,
  Value<double> fixedPrice,
  Value<int> durationMinutes,
  Value<bool> active,
  Value<DateTime> createdAt,
});

final class $$PackagesTableReferences
    extends BaseReferences<_$AppDatabase, $PackagesTable, PackageRow> {
  $$PackagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DeviceTypesTable _deviceTypeIdTable(_$AppDatabase db) =>
      db.deviceTypes.createAlias('packages__device_type_id__device_types__id');

  $$DeviceTypesTableProcessedTableManager get deviceTypeId {
    final $_column = $_itemColumn<int>('device_type_id')!;

    final manager = $$DeviceTypesTableTableManager($_db, $_db.deviceTypes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
      _sessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessions,
              aliasName: 'packages__id__sessions__package_id');

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.packageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PackagesTableFilterComposer
    extends Composer<_$AppDatabase, $PackagesTable> {
  $$PackagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fixedPrice => $composableBuilder(
      column: $table.fixedPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$DeviceTypesTableFilterComposer get deviceTypeId {
    final $$DeviceTypesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceTypeId,
        referencedTable: $db.deviceTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DeviceTypesTableFilterComposer(
              $db: $db,
              $table: $db.deviceTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> sessionsRefs(
      Expression<bool> Function($$SessionsTableFilterComposer f) f) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.packageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PackagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PackagesTable> {
  $$PackagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fixedPrice => $composableBuilder(
      column: $table.fixedPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$DeviceTypesTableOrderingComposer get deviceTypeId {
    final $$DeviceTypesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceTypeId,
        referencedTable: $db.deviceTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DeviceTypesTableOrderingComposer(
              $db: $db,
              $table: $db.deviceTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PackagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PackagesTable> {
  $$PackagesTableAnnotationComposer({
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

  GeneratedColumn<double> get fixedPrice => $composableBuilder(
      column: $table.fixedPrice, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DeviceTypesTableAnnotationComposer get deviceTypeId {
    final $$DeviceTypesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceTypeId,
        referencedTable: $db.deviceTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DeviceTypesTableAnnotationComposer(
              $db: $db,
              $table: $db.deviceTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> sessionsRefs<T extends Object>(
      Expression<T> Function($$SessionsTableAnnotationComposer a) f) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.packageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PackagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PackagesTable,
    PackageRow,
    $$PackagesTableFilterComposer,
    $$PackagesTableOrderingComposer,
    $$PackagesTableAnnotationComposer,
    $$PackagesTableCreateCompanionBuilder,
    $$PackagesTableUpdateCompanionBuilder,
    (PackageRow, $$PackagesTableReferences),
    PackageRow,
    PrefetchHooks Function({bool deviceTypeId, bool sessionsRefs})> {
  $$PackagesTableTableManager(_$AppDatabase db, $PackagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PackagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PackagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PackagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> deviceTypeId = const Value.absent(),
            Value<double> fixedPrice = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PackagesCompanion(
            id: id,
            name: name,
            deviceTypeId: deviceTypeId,
            fixedPrice: fixedPrice,
            durationMinutes: durationMinutes,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int deviceTypeId,
            Value<double> fixedPrice = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PackagesCompanion.insert(
            id: id,
            name: name,
            deviceTypeId: deviceTypeId,
            fixedPrice: fixedPrice,
            durationMinutes: durationMinutes,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PackagesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {deviceTypeId = false, sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: <
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
                      dynamic>>(state) {
                if (deviceTypeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.deviceTypeId,
                    referencedTable:
                        $$PackagesTableReferences._deviceTypeIdTable(db),
                    referencedColumn:
                        $$PackagesTableReferences._deviceTypeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<PackageRow, $PackagesTable,
                            SessionRow>(
                        currentTable: table,
                        referencedTable:
                            $$PackagesTableReferences._sessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PackagesTableReferences(db, table, p0)
                                .sessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.packageId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PackagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PackagesTable,
    PackageRow,
    $$PackagesTableFilterComposer,
    $$PackagesTableOrderingComposer,
    $$PackagesTableAnnotationComposer,
    $$PackagesTableCreateCompanionBuilder,
    $$PackagesTableUpdateCompanionBuilder,
    (PackageRow, $$PackagesTableReferences),
    PackageRow,
    PrefetchHooks Function({bool deviceTypeId, bool sessionsRefs})>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required int deviceId,
  Value<int?> customerId,
  Value<int?> employeeId,
  Value<DateTime> startTime,
  Value<DateTime?> pausedAt,
  Value<double> totalPausedMinutes,
  Value<String> mode,
  Value<double> accumulatedCost,
  Value<double> singleCost,
  Value<double> multiCost,
  Value<DateTime?> segmentStartAt,
  Value<DateTime?> endTime,
  Value<String> status,
  Value<double?> finalCost,
  Value<int?> plannedMinutes,
  Value<DateTime?> timeUpAt,
  Value<int?> packageId,
  Value<double?> fixedPrice,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<int> deviceId,
  Value<int?> customerId,
  Value<int?> employeeId,
  Value<DateTime> startTime,
  Value<DateTime?> pausedAt,
  Value<double> totalPausedMinutes,
  Value<String> mode,
  Value<double> accumulatedCost,
  Value<double> singleCost,
  Value<double> multiCost,
  Value<DateTime?> segmentStartAt,
  Value<DateTime?> endTime,
  Value<String> status,
  Value<double?> finalCost,
  Value<int?> plannedMinutes,
  Value<DateTime?> timeUpAt,
  Value<int?> packageId,
  Value<double?> fixedPrice,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DevicesTable _deviceIdTable(_$AppDatabase db) =>
      db.devices.createAlias('sessions__device_id__devices__id');

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<int>('device_id')!;

    final manager = $$DevicesTableTableManager($_db, $_db.devices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CustomersTable _customerIdTable(_$AppDatabase db) =>
      db.customers.createAlias('sessions__customer_id__customers__id');

  $$CustomersTableProcessedTableManager? get customerId {
    final $_column = $_itemColumn<int>('customer_id');
    if ($_column == null) return null;
    final manager = $$CustomersTableTableManager($_db, $_db.customers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('sessions__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PackagesTable _packageIdTable(_$AppDatabase db) =>
      db.packages.createAlias('sessions__package_id__packages__id');

  $$PackagesTableProcessedTableManager? get packageId {
    final $_column = $_itemColumn<int>('package_id');
    if ($_column == null) return null;
    final manager = $$PackagesTableTableManager($_db, $_db.packages)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionEventsTable, List<SessionEventRow>>
      _sessionEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessionEvents,
              aliasName: 'sessions__id__session_events__session_id');

  $$SessionEventsTableProcessedTableManager get sessionEventsRefs {
    final manager = $$SessionEventsTableTableManager($_db, $_db.sessionEvents)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvoicesTable, List<InvoiceRow>>
      _invoicesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoices,
              aliasName: 'sessions__id__invoices__session_id');

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
      column: $table.pausedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalPausedMinutes => $composableBuilder(
      column: $table.totalPausedMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accumulatedCost => $composableBuilder(
      column: $table.accumulatedCost,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get singleCost => $composableBuilder(
      column: $table.singleCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get multiCost => $composableBuilder(
      column: $table.multiCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get segmentStartAt => $composableBuilder(
      column: $table.segmentStartAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalCost => $composableBuilder(
      column: $table.finalCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedMinutes => $composableBuilder(
      column: $table.plannedMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timeUpAt => $composableBuilder(
      column: $table.timeUpAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fixedPrice => $composableBuilder(
      column: $table.fixedPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableFilterComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableFilterComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PackagesTableFilterComposer get packageId {
    final $$PackagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.packageId,
        referencedTable: $db.packages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PackagesTableFilterComposer(
              $db: $db,
              $table: $db.packages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> sessionEventsRefs(
      Expression<bool> Function($$SessionEventsTableFilterComposer f) f) {
    final $$SessionEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessionEvents,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionEventsTableFilterComposer(
              $db: $db,
              $table: $db.sessionEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> invoicesRefs(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
      column: $table.pausedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalPausedMinutes => $composableBuilder(
      column: $table.totalPausedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accumulatedCost => $composableBuilder(
      column: $table.accumulatedCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get singleCost => $composableBuilder(
      column: $table.singleCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get multiCost => $composableBuilder(
      column: $table.multiCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get segmentStartAt => $composableBuilder(
      column: $table.segmentStartAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalCost => $composableBuilder(
      column: $table.finalCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedMinutes => $composableBuilder(
      column: $table.plannedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timeUpAt => $composableBuilder(
      column: $table.timeUpAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fixedPrice => $composableBuilder(
      column: $table.fixedPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableOrderingComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableOrderingComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PackagesTableOrderingComposer get packageId {
    final $$PackagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.packageId,
        referencedTable: $db.packages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PackagesTableOrderingComposer(
              $db: $db,
              $table: $db.packages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<double> get totalPausedMinutes => $composableBuilder(
      column: $table.totalPausedMinutes, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<double> get accumulatedCost => $composableBuilder(
      column: $table.accumulatedCost, builder: (column) => column);

  GeneratedColumn<double> get singleCost => $composableBuilder(
      column: $table.singleCost, builder: (column) => column);

  GeneratedColumn<double> get multiCost =>
      $composableBuilder(column: $table.multiCost, builder: (column) => column);

  GeneratedColumn<DateTime> get segmentStartAt => $composableBuilder(
      column: $table.segmentStartAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get finalCost =>
      $composableBuilder(column: $table.finalCost, builder: (column) => column);

  GeneratedColumn<int> get plannedMinutes => $composableBuilder(
      column: $table.plannedMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get timeUpAt =>
      $composableBuilder(column: $table.timeUpAt, builder: (column) => column);

  GeneratedColumn<double> get fixedPrice => $composableBuilder(
      column: $table.fixedPrice, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableAnnotationComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PackagesTableAnnotationComposer get packageId {
    final $$PackagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.packageId,
        referencedTable: $db.packages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PackagesTableAnnotationComposer(
              $db: $db,
              $table: $db.packages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> sessionEventsRefs<T extends Object>(
      Expression<T> Function($$SessionEventsTableAnnotationComposer a) f) {
    final $$SessionEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sessionEvents,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessionEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> invoicesRefs<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    SessionRow,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (SessionRow, $$SessionsTableReferences),
    SessionRow,
    PrefetchHooks Function(
        {bool deviceId,
        bool customerId,
        bool employeeId,
        bool packageId,
        bool sessionEventsRefs,
        bool invoicesRefs})> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> deviceId = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> pausedAt = const Value.absent(),
            Value<double> totalPausedMinutes = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<double> accumulatedCost = const Value.absent(),
            Value<double> singleCost = const Value.absent(),
            Value<double> multiCost = const Value.absent(),
            Value<DateTime?> segmentStartAt = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double?> finalCost = const Value.absent(),
            Value<int?> plannedMinutes = const Value.absent(),
            Value<DateTime?> timeUpAt = const Value.absent(),
            Value<int?> packageId = const Value.absent(),
            Value<double?> fixedPrice = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            deviceId: deviceId,
            customerId: customerId,
            employeeId: employeeId,
            startTime: startTime,
            pausedAt: pausedAt,
            totalPausedMinutes: totalPausedMinutes,
            mode: mode,
            accumulatedCost: accumulatedCost,
            singleCost: singleCost,
            multiCost: multiCost,
            segmentStartAt: segmentStartAt,
            endTime: endTime,
            status: status,
            finalCost: finalCost,
            plannedMinutes: plannedMinutes,
            timeUpAt: timeUpAt,
            packageId: packageId,
            fixedPrice: fixedPrice,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int deviceId,
            Value<int?> customerId = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> pausedAt = const Value.absent(),
            Value<double> totalPausedMinutes = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<double> accumulatedCost = const Value.absent(),
            Value<double> singleCost = const Value.absent(),
            Value<double> multiCost = const Value.absent(),
            Value<DateTime?> segmentStartAt = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double?> finalCost = const Value.absent(),
            Value<int?> plannedMinutes = const Value.absent(),
            Value<DateTime?> timeUpAt = const Value.absent(),
            Value<int?> packageId = const Value.absent(),
            Value<double?> fixedPrice = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            deviceId: deviceId,
            customerId: customerId,
            employeeId: employeeId,
            startTime: startTime,
            pausedAt: pausedAt,
            totalPausedMinutes: totalPausedMinutes,
            mode: mode,
            accumulatedCost: accumulatedCost,
            singleCost: singleCost,
            multiCost: multiCost,
            segmentStartAt: segmentStartAt,
            endTime: endTime,
            status: status,
            finalCost: finalCost,
            plannedMinutes: plannedMinutes,
            timeUpAt: timeUpAt,
            packageId: packageId,
            fixedPrice: fixedPrice,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SessionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {deviceId = false,
              customerId = false,
              employeeId = false,
              packageId = false,
              sessionEventsRefs = false,
              invoicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionEventsRefs) db.sessionEvents,
                if (invoicesRefs) db.invoices
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (deviceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.deviceId,
                    referencedTable:
                        $$SessionsTableReferences._deviceIdTable(db),
                    referencedColumn:
                        $$SessionsTableReferences._deviceIdTable(db).id,
                  ) as T;
                }
                if (customerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.customerId,
                    referencedTable:
                        $$SessionsTableReferences._customerIdTable(db),
                    referencedColumn:
                        $$SessionsTableReferences._customerIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$SessionsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$SessionsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }
                if (packageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.packageId,
                    referencedTable:
                        $$SessionsTableReferences._packageIdTable(db),
                    referencedColumn:
                        $$SessionsTableReferences._packageIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionEventsRefs)
                    await $_getPrefetchedData<SessionRow, $SessionsTable,
                            SessionEventRow>(
                        currentTable: table,
                        referencedTable: $$SessionsTableReferences
                            ._sessionEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SessionsTableReferences(db, table, p0)
                                .sessionEventsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items),
                  if (invoicesRefs)
                    await $_getPrefetchedData<SessionRow, $SessionsTable,
                            InvoiceRow>(
                        currentTable: table,
                        referencedTable:
                            $$SessionsTableReferences._invoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SessionsTableReferences(db, table, p0)
                                .invoicesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    SessionRow,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (SessionRow, $$SessionsTableReferences),
    SessionRow,
    PrefetchHooks Function(
        {bool deviceId,
        bool customerId,
        bool employeeId,
        bool packageId,
        bool sessionEventsRefs,
        bool invoicesRefs})>;
typedef $$SessionEventsTableCreateCompanionBuilder = SessionEventsCompanion
    Function({
  Value<int> id,
  required int sessionId,
  required String type,
  Value<DateTime> at,
  Value<String?> note,
});
typedef $$SessionEventsTableUpdateCompanionBuilder = SessionEventsCompanion
    Function({
  Value<int> id,
  Value<int> sessionId,
  Value<String> type,
  Value<DateTime> at,
  Value<String?> note,
});

final class $$SessionEventsTableReferences extends BaseReferences<_$AppDatabase,
    $SessionEventsTable, SessionEventRow> {
  $$SessionEventsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('session_events__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SessionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionEventsTable> {
  $$SessionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionEventsTable> {
  $$SessionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableOrderingComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionEventsTable> {
  $$SessionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionEventsTable,
    SessionEventRow,
    $$SessionEventsTableFilterComposer,
    $$SessionEventsTableOrderingComposer,
    $$SessionEventsTableAnnotationComposer,
    $$SessionEventsTableCreateCompanionBuilder,
    $$SessionEventsTableUpdateCompanionBuilder,
    (SessionEventRow, $$SessionEventsTableReferences),
    SessionEventRow,
    PrefetchHooks Function({bool sessionId})> {
  $$SessionEventsTableTableManager(_$AppDatabase db, $SessionEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sessionId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              SessionEventsCompanion(
            id: id,
            sessionId: sessionId,
            type: type,
            at: at,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sessionId,
            required String type,
            Value<DateTime> at = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              SessionEventsCompanion.insert(
            id: id,
            sessionId: sessionId,
            type: type,
            at: at,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SessionEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$SessionEventsTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$SessionEventsTableReferences._sessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SessionEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionEventsTable,
    SessionEventRow,
    $$SessionEventsTableFilterComposer,
    $$SessionEventsTableOrderingComposer,
    $$SessionEventsTableAnnotationComposer,
    $$SessionEventsTableCreateCompanionBuilder,
    $$SessionEventsTableUpdateCompanionBuilder,
    (SessionEventRow, $$SessionEventsTableReferences),
    SessionEventRow,
    PrefetchHooks Function({bool sessionId})>;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  Value<int> id,
  Value<int?> sessionId,
  Value<int?> customerId,
  Value<int?> employeeId,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> total,
  Value<String> paymentMethod,
  Value<double> paidCash,
  Value<double> paidCard,
  Value<DateTime> createdAt,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<int> id,
  Value<int?> sessionId,
  Value<int?> customerId,
  Value<int?> employeeId,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> total,
  Value<String> paymentMethod,
  Value<double> paidCash,
  Value<double> paidCard,
  Value<DateTime> createdAt,
});

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, InvoiceRow> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('invoices__session_id__sessions__id');

  $$SessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CustomersTable _customerIdTable(_$AppDatabase db) =>
      db.customers.createAlias('invoices__customer_id__customers__id');

  $$CustomersTableProcessedTableManager? get customerId {
    final $_column = $_itemColumn<int>('customer_id');
    if ($_column == null) return null;
    final manager = $$CustomersTableTableManager($_db, $_db.customers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('invoices__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItemRow>>
      _invoiceItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoiceItems,
              aliasName: 'invoices__id__invoice_items__invoice_id');

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager($_db, $_db.invoiceItems)
        .filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RefundsTable, List<RefundRow>> _refundsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.refunds,
          aliasName: 'invoices__id__refunds__invoice_id');

  $$RefundsTableProcessedTableManager get refundsRefs {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paidCash => $composableBuilder(
      column: $table.paidCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paidCard => $composableBuilder(
      column: $table.paidCard, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableFilterComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> invoiceItemsRefs(
      Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableFilterComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> refundsRefs(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paidCash => $composableBuilder(
      column: $table.paidCash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paidCard => $composableBuilder(
      column: $table.paidCard, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableOrderingComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableOrderingComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<double> get paidCash =>
      $composableBuilder(column: $table.paidCash, builder: (column) => column);

  GeneratedColumn<double> get paidCard =>
      $composableBuilder(column: $table.paidCard, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> invoiceItemsRefs<T extends Object>(
      Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> refundsRefs<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InvoicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvoicesTable,
    InvoiceRow,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (InvoiceRow, $$InvoicesTableReferences),
    InvoiceRow,
    PrefetchHooks Function(
        {bool sessionId,
        bool customerId,
        bool employeeId,
        bool invoiceItemsRefs,
        bool refundsRefs})> {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> sessionId = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<double> paidCash = const Value.absent(),
            Value<double> paidCard = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InvoicesCompanion(
            id: id,
            sessionId: sessionId,
            customerId: customerId,
            employeeId: employeeId,
            subtotal: subtotal,
            discount: discount,
            total: total,
            paymentMethod: paymentMethod,
            paidCash: paidCash,
            paidCard: paidCard,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> sessionId = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<double> paidCash = const Value.absent(),
            Value<double> paidCard = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InvoicesCompanion.insert(
            id: id,
            sessionId: sessionId,
            customerId: customerId,
            employeeId: employeeId,
            subtotal: subtotal,
            discount: discount,
            total: total,
            paymentMethod: paymentMethod,
            paidCash: paidCash,
            paidCard: paidCard,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$InvoicesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {sessionId = false,
              customerId = false,
              employeeId = false,
              invoiceItemsRefs = false,
              refundsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (invoiceItemsRefs) db.invoiceItems,
                if (refundsRefs) db.refunds
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$InvoicesTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._sessionIdTable(db).id,
                  ) as T;
                }
                if (customerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.customerId,
                    referencedTable:
                        $$InvoicesTableReferences._customerIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._customerIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$InvoicesTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoiceItemsRefs)
                    await $_getPrefetchedData<InvoiceRow, $InvoicesTable,
                            InvoiceItemRow>(
                        currentTable: table,
                        referencedTable: $$InvoicesTableReferences
                            ._invoiceItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .invoiceItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items),
                  if (refundsRefs)
                    await $_getPrefetchedData<InvoiceRow, $InvoicesTable,
                            RefundRow>(
                        currentTable: table,
                        referencedTable:
                            $$InvoicesTableReferences._refundsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .refundsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InvoicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvoicesTable,
    InvoiceRow,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (InvoiceRow, $$InvoicesTableReferences),
    InvoiceRow,
    PrefetchHooks Function(
        {bool sessionId,
        bool customerId,
        bool employeeId,
        bool invoiceItemsRefs,
        bool refundsRefs})>;
typedef $$InvoiceItemsTableCreateCompanionBuilder = InvoiceItemsCompanion
    Function({
  Value<int> id,
  required int invoiceId,
  Value<int?> productId,
  required String description,
  Value<int> quantity,
  required double unitPrice,
  required double total,
  Value<DateTime?> createdAt,
});
typedef $$InvoiceItemsTableUpdateCompanionBuilder = InvoiceItemsCompanion
    Function({
  Value<int> id,
  Value<int> invoiceId,
  Value<int?> productId,
  Value<String> description,
  Value<int> quantity,
  Value<double> unitPrice,
  Value<double> total,
  Value<DateTime?> createdAt,
});

final class $$InvoiceItemsTableReferences
    extends BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItemRow> {
  $$InvoiceItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('invoice_items__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<int>('invoice_id')!;

    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('invoice_items__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<int>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoiceItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvoiceItemsTable,
    InvoiceItemRow,
    $$InvoiceItemsTableFilterComposer,
    $$InvoiceItemsTableOrderingComposer,
    $$InvoiceItemsTableAnnotationComposer,
    $$InvoiceItemsTableCreateCompanionBuilder,
    $$InvoiceItemsTableUpdateCompanionBuilder,
    (InvoiceItemRow, $$InvoiceItemsTableReferences),
    InvoiceItemRow,
    PrefetchHooks Function({bool invoiceId, bool productId})> {
  $$InvoiceItemsTableTableManager(_$AppDatabase db, $InvoiceItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> invoiceId = const Value.absent(),
            Value<int?> productId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> unitPrice = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
          }) =>
              InvoiceItemsCompanion(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            description: description,
            quantity: quantity,
            unitPrice: unitPrice,
            total: total,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int invoiceId,
            Value<int?> productId = const Value.absent(),
            required String description,
            Value<int> quantity = const Value.absent(),
            required double unitPrice,
            required double total,
            Value<DateTime?> createdAt = const Value.absent(),
          }) =>
              InvoiceItemsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            description: description,
            quantity: quantity,
            unitPrice: unitPrice,
            total: total,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InvoiceItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({invoiceId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$InvoiceItemsTableReferences._invoiceIdTable(db),
                    referencedColumn:
                        $$InvoiceItemsTableReferences._invoiceIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$InvoiceItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$InvoiceItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$InvoiceItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvoiceItemsTable,
    InvoiceItemRow,
    $$InvoiceItemsTableFilterComposer,
    $$InvoiceItemsTableOrderingComposer,
    $$InvoiceItemsTableAnnotationComposer,
    $$InvoiceItemsTableCreateCompanionBuilder,
    $$InvoiceItemsTableUpdateCompanionBuilder,
    (InvoiceItemRow, $$InvoiceItemsTableReferences),
    InvoiceItemRow,
    PrefetchHooks Function({bool invoiceId, bool productId})>;
typedef $$AuditLogsTableCreateCompanionBuilder = AuditLogsCompanion Function({
  Value<int> id,
  required String action,
  required String entityType,
  Value<int?> entityId,
  Value<String?> oldValue,
  Value<String?> newValue,
  Value<String?> reason,
  required String performedByRole,
  Value<DateTime> createdAt,
});
typedef $$AuditLogsTableUpdateCompanionBuilder = AuditLogsCompanion Function({
  Value<int> id,
  Value<String> action,
  Value<String> entityType,
  Value<int?> entityId,
  Value<String?> oldValue,
  Value<String?> newValue,
  Value<String?> reason,
  Value<String> performedByRole,
  Value<DateTime> createdAt,
});

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldValue => $composableBuilder(
      column: $table.oldValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newValue => $composableBuilder(
      column: $table.newValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get performedByRole => $composableBuilder(
      column: $table.performedByRole,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldValue => $composableBuilder(
      column: $table.oldValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newValue => $composableBuilder(
      column: $table.newValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get performedByRole => $composableBuilder(
      column: $table.performedByRole,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get performedByRole => $composableBuilder(
      column: $table.performedByRole, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLogRow,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLogRow, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLogRow>),
    AuditLogRow,
    PrefetchHooks Function()> {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<int?> entityId = const Value.absent(),
            Value<String?> oldValue = const Value.absent(),
            Value<String?> newValue = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<String> performedByRole = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AuditLogsCompanion(
            id: id,
            action: action,
            entityType: entityType,
            entityId: entityId,
            oldValue: oldValue,
            newValue: newValue,
            reason: reason,
            performedByRole: performedByRole,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String action,
            required String entityType,
            Value<int?> entityId = const Value.absent(),
            Value<String?> oldValue = const Value.absent(),
            Value<String?> newValue = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            required String performedByRole,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AuditLogsCompanion.insert(
            id: id,
            action: action,
            entityType: entityType,
            entityId: entityId,
            oldValue: oldValue,
            newValue: newValue,
            reason: reason,
            performedByRole: performedByRole,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AuditLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLogRow,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLogRow, BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLogRow>),
    AuditLogRow,
    PrefetchHooks Function()>;
typedef $$ShiftsTableCreateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<int?> employeeId,
  Value<DateTime> openedAt,
  Value<DateTime> closedAt,
  Value<double> openingCash,
  Value<double> expectedCash,
  Value<double> actualCash,
  Value<double> difference,
  Value<String?> notes,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<int?> employeeId,
  Value<DateTime> openedAt,
  Value<DateTime> closedAt,
  Value<double> openingCash,
  Value<double> expectedCash,
  Value<double> actualCash,
  Value<double> difference,
  Value<String?> notes,
});

final class $$ShiftsTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftsTable, ShiftRow> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('shifts__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get expectedCash => $composableBuilder(
      column: $table.expectedCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualCash => $composableBuilder(
      column: $table.actualCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get expectedCash => $composableBuilder(
      column: $table.expectedCash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actualCash => $composableBuilder(
      column: $table.actualCash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<double> get openingCash => $composableBuilder(
      column: $table.openingCash, builder: (column) => column);

  GeneratedColumn<double> get expectedCash => $composableBuilder(
      column: $table.expectedCash, builder: (column) => column);

  GeneratedColumn<double> get actualCash => $composableBuilder(
      column: $table.actualCash, builder: (column) => column);

  GeneratedColumn<double> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShiftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftsTable,
    ShiftRow,
    $$ShiftsTableFilterComposer,
    $$ShiftsTableOrderingComposer,
    $$ShiftsTableAnnotationComposer,
    $$ShiftsTableCreateCompanionBuilder,
    $$ShiftsTableUpdateCompanionBuilder,
    (ShiftRow, $$ShiftsTableReferences),
    ShiftRow,
    PrefetchHooks Function({bool employeeId})> {
  $$ShiftsTableTableManager(_$AppDatabase db, $ShiftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<DateTime> closedAt = const Value.absent(),
            Value<double> openingCash = const Value.absent(),
            Value<double> expectedCash = const Value.absent(),
            Value<double> actualCash = const Value.absent(),
            Value<double> difference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              ShiftsCompanion(
            id: id,
            employeeId: employeeId,
            openedAt: openedAt,
            closedAt: closedAt,
            openingCash: openingCash,
            expectedCash: expectedCash,
            actualCash: actualCash,
            difference: difference,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> openedAt = const Value.absent(),
            Value<DateTime> closedAt = const Value.absent(),
            Value<double> openingCash = const Value.absent(),
            Value<double> expectedCash = const Value.absent(),
            Value<double> actualCash = const Value.absent(),
            Value<double> difference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              ShiftsCompanion.insert(
            id: id,
            employeeId: employeeId,
            openedAt: openedAt,
            closedAt: closedAt,
            openingCash: openingCash,
            expectedCash: expectedCash,
            actualCash: actualCash,
            difference: difference,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ShiftsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$ShiftsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$ShiftsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ShiftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShiftsTable,
    ShiftRow,
    $$ShiftsTableFilterComposer,
    $$ShiftsTableOrderingComposer,
    $$ShiftsTableAnnotationComposer,
    $$ShiftsTableCreateCompanionBuilder,
    $$ShiftsTableUpdateCompanionBuilder,
    (ShiftRow, $$ShiftsTableReferences),
    ShiftRow,
    PrefetchHooks Function({bool employeeId})>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  required String category,
  required double amount,
  Value<String?> description,
  Value<int?> employeeId,
  Value<DateTime> createdAt,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<String> category,
  Value<double> amount,
  Value<String?> description,
  Value<int?> employeeId,
  Value<DateTime> createdAt,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('expenses__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    ExpenseRow,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (ExpenseRow, $$ExpensesTableReferences),
    ExpenseRow,
    PrefetchHooks Function({bool employeeId})> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            category: category,
            amount: amount,
            description: description,
            employeeId: employeeId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String category,
            required double amount,
            Value<String?> description = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            category: category,
            amount: amount,
            description: description,
            employeeId: employeeId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ExpensesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$ExpensesTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$ExpensesTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    ExpenseRow,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (ExpenseRow, $$ExpensesTableReferences),
    ExpenseRow,
    PrefetchHooks Function({bool employeeId})>;
typedef $$EmployeeFeatureOverridesTableCreateCompanionBuilder
    = EmployeeFeatureOverridesCompanion Function({
  Value<int> id,
  required int employeeId,
  required String featureKey,
  required bool visible,
});
typedef $$EmployeeFeatureOverridesTableUpdateCompanionBuilder
    = EmployeeFeatureOverridesCompanion Function({
  Value<int> id,
  Value<int> employeeId,
  Value<String> featureKey,
  Value<bool> visible,
});

final class $$EmployeeFeatureOverridesTableReferences extends BaseReferences<
    _$AppDatabase, $EmployeeFeatureOverridesTable, EmployeeFeatureOverrideRow> {
  $$EmployeeFeatureOverridesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) => db.employees
      .createAlias('employee_feature_overrides__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EmployeeFeatureOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeeFeatureOverridesTable> {
  $$EmployeeFeatureOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get featureKey => $composableBuilder(
      column: $table.featureKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get visible => $composableBuilder(
      column: $table.visible, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeFeatureOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeeFeatureOverridesTable> {
  $$EmployeeFeatureOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get featureKey => $composableBuilder(
      column: $table.featureKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get visible => $composableBuilder(
      column: $table.visible, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeFeatureOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeeFeatureOverridesTable> {
  $$EmployeeFeatureOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get featureKey => $composableBuilder(
      column: $table.featureKey, builder: (column) => column);

  GeneratedColumn<bool> get visible =>
      $composableBuilder(column: $table.visible, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeFeatureOverridesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeeFeatureOverridesTable,
    EmployeeFeatureOverrideRow,
    $$EmployeeFeatureOverridesTableFilterComposer,
    $$EmployeeFeatureOverridesTableOrderingComposer,
    $$EmployeeFeatureOverridesTableAnnotationComposer,
    $$EmployeeFeatureOverridesTableCreateCompanionBuilder,
    $$EmployeeFeatureOverridesTableUpdateCompanionBuilder,
    (EmployeeFeatureOverrideRow, $$EmployeeFeatureOverridesTableReferences),
    EmployeeFeatureOverrideRow,
    PrefetchHooks Function({bool employeeId})> {
  $$EmployeeFeatureOverridesTableTableManager(
      _$AppDatabase db, $EmployeeFeatureOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeeFeatureOverridesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeeFeatureOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeeFeatureOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<String> featureKey = const Value.absent(),
            Value<bool> visible = const Value.absent(),
          }) =>
              EmployeeFeatureOverridesCompanion(
            id: id,
            employeeId: employeeId,
            featureKey: featureKey,
            visible: visible,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int employeeId,
            required String featureKey,
            required bool visible,
          }) =>
              EmployeeFeatureOverridesCompanion.insert(
            id: id,
            employeeId: employeeId,
            featureKey: featureKey,
            visible: visible,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeeFeatureOverridesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable: $$EmployeeFeatureOverridesTableReferences
                        ._employeeIdTable(db),
                    referencedColumn: $$EmployeeFeatureOverridesTableReferences
                        ._employeeIdTable(db)
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
        ));
}

typedef $$EmployeeFeatureOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $EmployeeFeatureOverridesTable,
        EmployeeFeatureOverrideRow,
        $$EmployeeFeatureOverridesTableFilterComposer,
        $$EmployeeFeatureOverridesTableOrderingComposer,
        $$EmployeeFeatureOverridesTableAnnotationComposer,
        $$EmployeeFeatureOverridesTableCreateCompanionBuilder,
        $$EmployeeFeatureOverridesTableUpdateCompanionBuilder,
        (EmployeeFeatureOverrideRow, $$EmployeeFeatureOverridesTableReferences),
        EmployeeFeatureOverrideRow,
        PrefetchHooks Function({bool employeeId})>;
typedef $$ReservationsTableCreateCompanionBuilder = ReservationsCompanion
    Function({
  Value<int> id,
  required int customerId,
  required int deviceId,
  required DateTime startTime,
  required DateTime endTime,
  Value<String> status,
  Value<int?> employeeId,
  Value<DateTime> createdAt,
});
typedef $$ReservationsTableUpdateCompanionBuilder = ReservationsCompanion
    Function({
  Value<int> id,
  Value<int> customerId,
  Value<int> deviceId,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<String> status,
  Value<int?> employeeId,
  Value<DateTime> createdAt,
});

final class $$ReservationsTableReferences
    extends BaseReferences<_$AppDatabase, $ReservationsTable, ReservationRow> {
  $$ReservationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomersTable _customerIdTable(_$AppDatabase db) =>
      db.customers.createAlias('reservations__customer_id__customers__id');

  $$CustomersTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<int>('customer_id')!;

    final manager = $$CustomersTableTableManager($_db, $_db.customers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DevicesTable _deviceIdTable(_$AppDatabase db) =>
      db.devices.createAlias('reservations__device_id__devices__id');

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<int>('device_id')!;

    final manager = $$DevicesTableTableManager($_db, $_db.devices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('reservations__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReservationsTableFilterComposer
    extends Composer<_$AppDatabase, $ReservationsTable> {
  $$ReservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableFilterComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableFilterComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReservationsTable> {
  $$ReservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableOrderingComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableOrderingComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReservationsTable> {
  $$ReservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableAnnotationComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReservationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReservationsTable,
    ReservationRow,
    $$ReservationsTableFilterComposer,
    $$ReservationsTableOrderingComposer,
    $$ReservationsTableAnnotationComposer,
    $$ReservationsTableCreateCompanionBuilder,
    $$ReservationsTableUpdateCompanionBuilder,
    (ReservationRow, $$ReservationsTableReferences),
    ReservationRow,
    PrefetchHooks Function({bool customerId, bool deviceId, bool employeeId})> {
  $$ReservationsTableTableManager(_$AppDatabase db, $ReservationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> customerId = const Value.absent(),
            Value<int> deviceId = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ReservationsCompanion(
            id: id,
            customerId: customerId,
            deviceId: deviceId,
            startTime: startTime,
            endTime: endTime,
            status: status,
            employeeId: employeeId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int customerId,
            required int deviceId,
            required DateTime startTime,
            required DateTime endTime,
            Value<String> status = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ReservationsCompanion.insert(
            id: id,
            customerId: customerId,
            deviceId: deviceId,
            startTime: startTime,
            endTime: endTime,
            status: status,
            employeeId: employeeId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReservationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {customerId = false, deviceId = false, employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (customerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.customerId,
                    referencedTable:
                        $$ReservationsTableReferences._customerIdTable(db),
                    referencedColumn:
                        $$ReservationsTableReferences._customerIdTable(db).id,
                  ) as T;
                }
                if (deviceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.deviceId,
                    referencedTable:
                        $$ReservationsTableReferences._deviceIdTable(db),
                    referencedColumn:
                        $$ReservationsTableReferences._deviceIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$ReservationsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$ReservationsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReservationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReservationsTable,
    ReservationRow,
    $$ReservationsTableFilterComposer,
    $$ReservationsTableOrderingComposer,
    $$ReservationsTableAnnotationComposer,
    $$ReservationsTableCreateCompanionBuilder,
    $$ReservationsTableUpdateCompanionBuilder,
    (ReservationRow, $$ReservationsTableReferences),
    ReservationRow,
    PrefetchHooks Function({bool customerId, bool deviceId, bool employeeId})>;
typedef $$OffersTableCreateCompanionBuilder = OffersCompanion Function({
  Value<int> id,
  required String name,
  required String discountType,
  Value<double> discountValue,
  Value<int> startHour,
  Value<int> endHour,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$OffersTableUpdateCompanionBuilder = OffersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> discountType,
  Value<double> discountValue,
  Value<int> startHour,
  Value<int> endHour,
  Value<bool> active,
  Value<DateTime> createdAt,
});

class $$OffersTableFilterComposer
    extends Composer<_$AppDatabase, $OffersTable> {
  $$OffersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountType => $composableBuilder(
      column: $table.discountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountValue => $composableBuilder(
      column: $table.discountValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startHour => $composableBuilder(
      column: $table.startHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endHour => $composableBuilder(
      column: $table.endHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$OffersTableOrderingComposer
    extends Composer<_$AppDatabase, $OffersTable> {
  $$OffersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountType => $composableBuilder(
      column: $table.discountType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountValue => $composableBuilder(
      column: $table.discountValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startHour => $composableBuilder(
      column: $table.startHour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endHour => $composableBuilder(
      column: $table.endHour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$OffersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OffersTable> {
  $$OffersTableAnnotationComposer({
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

  GeneratedColumn<String> get discountType => $composableBuilder(
      column: $table.discountType, builder: (column) => column);

  GeneratedColumn<double> get discountValue => $composableBuilder(
      column: $table.discountValue, builder: (column) => column);

  GeneratedColumn<int> get startHour =>
      $composableBuilder(column: $table.startHour, builder: (column) => column);

  GeneratedColumn<int> get endHour =>
      $composableBuilder(column: $table.endHour, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OffersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OffersTable,
    OfferRow,
    $$OffersTableFilterComposer,
    $$OffersTableOrderingComposer,
    $$OffersTableAnnotationComposer,
    $$OffersTableCreateCompanionBuilder,
    $$OffersTableUpdateCompanionBuilder,
    (OfferRow, BaseReferences<_$AppDatabase, $OffersTable, OfferRow>),
    OfferRow,
    PrefetchHooks Function()> {
  $$OffersTableTableManager(_$AppDatabase db, $OffersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OffersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OffersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OffersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> discountType = const Value.absent(),
            Value<double> discountValue = const Value.absent(),
            Value<int> startHour = const Value.absent(),
            Value<int> endHour = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              OffersCompanion(
            id: id,
            name: name,
            discountType: discountType,
            discountValue: discountValue,
            startHour: startHour,
            endHour: endHour,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String discountType,
            Value<double> discountValue = const Value.absent(),
            Value<int> startHour = const Value.absent(),
            Value<int> endHour = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              OffersCompanion.insert(
            id: id,
            name: name,
            discountType: discountType,
            discountValue: discountValue,
            startHour: startHour,
            endHour: endHour,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OffersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OffersTable,
    OfferRow,
    $$OffersTableFilterComposer,
    $$OffersTableOrderingComposer,
    $$OffersTableAnnotationComposer,
    $$OffersTableCreateCompanionBuilder,
    $$OffersTableUpdateCompanionBuilder,
    (OfferRow, BaseReferences<_$AppDatabase, $OffersTable, OfferRow>),
    OfferRow,
    PrefetchHooks Function()>;
typedef $$LoyaltySettingsTableCreateCompanionBuilder = LoyaltySettingsCompanion
    Function({
  Value<int> id,
  Value<double> pointsPerCurrency,
  Value<int> minimumRedeemPoints,
  Value<double> pointValueEGP,
  Value<DateTime> updatedAt,
});
typedef $$LoyaltySettingsTableUpdateCompanionBuilder = LoyaltySettingsCompanion
    Function({
  Value<int> id,
  Value<double> pointsPerCurrency,
  Value<int> minimumRedeemPoints,
  Value<double> pointValueEGP,
  Value<DateTime> updatedAt,
});

class $$LoyaltySettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LoyaltySettingsTable> {
  $$LoyaltySettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pointsPerCurrency => $composableBuilder(
      column: $table.pointsPerCurrency,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minimumRedeemPoints => $composableBuilder(
      column: $table.minimumRedeemPoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pointValueEGP => $composableBuilder(
      column: $table.pointValueEGP, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LoyaltySettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoyaltySettingsTable> {
  $$LoyaltySettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pointsPerCurrency => $composableBuilder(
      column: $table.pointsPerCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minimumRedeemPoints => $composableBuilder(
      column: $table.minimumRedeemPoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pointValueEGP => $composableBuilder(
      column: $table.pointValueEGP,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LoyaltySettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoyaltySettingsTable> {
  $$LoyaltySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get pointsPerCurrency => $composableBuilder(
      column: $table.pointsPerCurrency, builder: (column) => column);

  GeneratedColumn<int> get minimumRedeemPoints => $composableBuilder(
      column: $table.minimumRedeemPoints, builder: (column) => column);

  GeneratedColumn<double> get pointValueEGP => $composableBuilder(
      column: $table.pointValueEGP, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LoyaltySettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoyaltySettingsTable,
    LoyaltySettingsRow,
    $$LoyaltySettingsTableFilterComposer,
    $$LoyaltySettingsTableOrderingComposer,
    $$LoyaltySettingsTableAnnotationComposer,
    $$LoyaltySettingsTableCreateCompanionBuilder,
    $$LoyaltySettingsTableUpdateCompanionBuilder,
    (
      LoyaltySettingsRow,
      BaseReferences<_$AppDatabase, $LoyaltySettingsTable, LoyaltySettingsRow>
    ),
    LoyaltySettingsRow,
    PrefetchHooks Function()> {
  $$LoyaltySettingsTableTableManager(
      _$AppDatabase db, $LoyaltySettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoyaltySettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoyaltySettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoyaltySettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> pointsPerCurrency = const Value.absent(),
            Value<int> minimumRedeemPoints = const Value.absent(),
            Value<double> pointValueEGP = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LoyaltySettingsCompanion(
            id: id,
            pointsPerCurrency: pointsPerCurrency,
            minimumRedeemPoints: minimumRedeemPoints,
            pointValueEGP: pointValueEGP,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> pointsPerCurrency = const Value.absent(),
            Value<int> minimumRedeemPoints = const Value.absent(),
            Value<double> pointValueEGP = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LoyaltySettingsCompanion.insert(
            id: id,
            pointsPerCurrency: pointsPerCurrency,
            minimumRedeemPoints: minimumRedeemPoints,
            pointValueEGP: pointValueEGP,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoyaltySettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LoyaltySettingsTable,
    LoyaltySettingsRow,
    $$LoyaltySettingsTableFilterComposer,
    $$LoyaltySettingsTableOrderingComposer,
    $$LoyaltySettingsTableAnnotationComposer,
    $$LoyaltySettingsTableCreateCompanionBuilder,
    $$LoyaltySettingsTableUpdateCompanionBuilder,
    (
      LoyaltySettingsRow,
      BaseReferences<_$AppDatabase, $LoyaltySettingsTable, LoyaltySettingsRow>
    ),
    LoyaltySettingsRow,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  Value<String?> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String?> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
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
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
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
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
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
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSettingRow,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSettingRow,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String code,
  required String name,
  required String kind,
  Value<bool> system,
  Value<DateTime> createdAt,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<String> name,
  Value<String> kind,
  Value<bool> system,
  Value<DateTime> createdAt,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountEntriesTable, List<AccountEntryRow>>
      _accountEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.accountEntries,
              aliasName: 'accounts__id__account_entries__account_id');

  $$AccountEntriesTableProcessedTableManager get accountEntriesRefs {
    final manager = $$AccountEntriesTableTableManager($_db, $_db.accountEntries)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get system => $composableBuilder(
      column: $table.system, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> accountEntriesRefs(
      Expression<bool> Function($$AccountEntriesTableFilterComposer f) f) {
    final $$AccountEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.accountEntries,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountEntriesTableFilterComposer(
              $db: $db,
              $table: $db.accountEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get system => $composableBuilder(
      column: $table.system, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get system =>
      $composableBuilder(column: $table.system, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> accountEntriesRefs<T extends Object>(
      Expression<T> Function($$AccountEntriesTableAnnotationComposer a) f) {
    final $$AccountEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.accountEntries,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.accountEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    AccountRow,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (AccountRow, $$AccountsTableReferences),
    AccountRow,
    PrefetchHooks Function({bool accountEntriesRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<bool> system = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            code: code,
            name: name,
            kind: kind,
            system: system,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String code,
            required String name,
            required String kind,
            Value<bool> system = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            code: code,
            name: name,
            kind: kind,
            system: system,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({accountEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accountEntriesRefs) db.accountEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountEntriesRefs)
                    await $_getPrefetchedData<AccountRow, $AccountsTable,
                            AccountEntryRow>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._accountEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .accountEntriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    AccountRow,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (AccountRow, $$AccountsTableReferences),
    AccountRow,
    PrefetchHooks Function({bool accountEntriesRefs})>;
typedef $$AccountEntriesTableCreateCompanionBuilder = AccountEntriesCompanion
    Function({
  Value<int> id,
  required int accountId,
  required double amount,
  required String direction,
  required String source,
  Value<int?> sourceId,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$AccountEntriesTableUpdateCompanionBuilder = AccountEntriesCompanion
    Function({
  Value<int> id,
  Value<int> accountId,
  Value<double> amount,
  Value<String> direction,
  Value<String> source,
  Value<int?> sourceId,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$AccountEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $AccountEntriesTable, AccountEntryRow> {
  $$AccountEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('account_entries__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AccountEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AccountEntriesTable> {
  $$AccountEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountEntriesTable> {
  $$AccountEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountEntriesTable> {
  $$AccountEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountEntriesTable,
    AccountEntryRow,
    $$AccountEntriesTableFilterComposer,
    $$AccountEntriesTableOrderingComposer,
    $$AccountEntriesTableAnnotationComposer,
    $$AccountEntriesTableCreateCompanionBuilder,
    $$AccountEntriesTableUpdateCompanionBuilder,
    (AccountEntryRow, $$AccountEntriesTableReferences),
    AccountEntryRow,
    PrefetchHooks Function({bool accountId})> {
  $$AccountEntriesTableTableManager(
      _$AppDatabase db, $AccountEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int?> sourceId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountEntriesCompanion(
            id: id,
            accountId: accountId,
            amount: amount,
            direction: direction,
            source: source,
            sourceId: sourceId,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int accountId,
            required double amount,
            required String direction,
            required String source,
            Value<int?> sourceId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AccountEntriesCompanion.insert(
            id: id,
            accountId: accountId,
            amount: amount,
            direction: direction,
            source: source,
            sourceId: sourceId,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AccountEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$AccountEntriesTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$AccountEntriesTableReferences._accountIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AccountEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountEntriesTable,
    AccountEntryRow,
    $$AccountEntriesTableFilterComposer,
    $$AccountEntriesTableOrderingComposer,
    $$AccountEntriesTableAnnotationComposer,
    $$AccountEntriesTableCreateCompanionBuilder,
    $$AccountEntriesTableUpdateCompanionBuilder,
    (AccountEntryRow, $$AccountEntriesTableReferences),
    AccountEntryRow,
    PrefetchHooks Function({bool accountId})>;
typedef $$RefundsTableCreateCompanionBuilder = RefundsCompanion Function({
  Value<int> id,
  required int invoiceId,
  required double amount,
  Value<double> quantity,
  Value<String?> reason,
  Value<int?> employeeId,
  Value<bool> restocked,
  Value<DateTime> createdAt,
});
typedef $$RefundsTableUpdateCompanionBuilder = RefundsCompanion Function({
  Value<int> id,
  Value<int> invoiceId,
  Value<double> amount,
  Value<double> quantity,
  Value<String?> reason,
  Value<int?> employeeId,
  Value<bool> restocked,
  Value<DateTime> createdAt,
});

final class $$RefundsTableReferences
    extends BaseReferences<_$AppDatabase, $RefundsTable, RefundRow> {
  $$RefundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias('refunds__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<int>('invoice_id')!;

    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('refunds__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RefundsTableFilterComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get restocked => $composableBuilder(
      column: $table.restocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get restocked => $composableBuilder(
      column: $table.restocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get restocked =>
      $composableBuilder(column: $table.restocked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RefundsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RefundsTable,
    RefundRow,
    $$RefundsTableFilterComposer,
    $$RefundsTableOrderingComposer,
    $$RefundsTableAnnotationComposer,
    $$RefundsTableCreateCompanionBuilder,
    $$RefundsTableUpdateCompanionBuilder,
    (RefundRow, $$RefundsTableReferences),
    RefundRow,
    PrefetchHooks Function({bool invoiceId, bool employeeId})> {
  $$RefundsTableTableManager(_$AppDatabase db, $RefundsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> invoiceId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<bool> restocked = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RefundsCompanion(
            id: id,
            invoiceId: invoiceId,
            amount: amount,
            quantity: quantity,
            reason: reason,
            employeeId: employeeId,
            restocked: restocked,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int invoiceId,
            required double amount,
            Value<double> quantity = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<bool> restocked = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RefundsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            amount: amount,
            quantity: quantity,
            reason: reason,
            employeeId: employeeId,
            restocked: restocked,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RefundsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({invoiceId = false, employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$RefundsTableReferences._invoiceIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._invoiceIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$RefundsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RefundsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RefundsTable,
    RefundRow,
    $$RefundsTableFilterComposer,
    $$RefundsTableOrderingComposer,
    $$RefundsTableAnnotationComposer,
    $$RefundsTableCreateCompanionBuilder,
    $$RefundsTableUpdateCompanionBuilder,
    (RefundRow, $$RefundsTableReferences),
    RefundRow,
    PrefetchHooks Function({bool invoiceId, bool employeeId})>;
typedef $$StockCountsTableCreateCompanionBuilder = StockCountsCompanion
    Function({
  Value<int> id,
  Value<int?> employeeId,
  Value<String?> note,
  Value<bool> applied,
  Value<DateTime> createdAt,
  Value<DateTime?> appliedAt,
});
typedef $$StockCountsTableUpdateCompanionBuilder = StockCountsCompanion
    Function({
  Value<int> id,
  Value<int?> employeeId,
  Value<String?> note,
  Value<bool> applied,
  Value<DateTime> createdAt,
  Value<DateTime?> appliedAt,
});

final class $$StockCountsTableReferences
    extends BaseReferences<_$AppDatabase, $StockCountsTable, StockCountRow> {
  $$StockCountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias('stock_counts__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$StockCountItemsTable, List<StockCountItemRow>>
      _stockCountItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockCountItems,
              aliasName: 'stock_counts__id__stock_count_items__stock_count_id');

  $$StockCountItemsTableProcessedTableManager get stockCountItemsRefs {
    final manager = $$StockCountItemsTableTableManager(
            $_db, $_db.stockCountItems)
        .filter((f) => f.stockCountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_stockCountItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StockCountsTableFilterComposer
    extends Composer<_$AppDatabase, $StockCountsTable> {
  $$StockCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get applied => $composableBuilder(
      column: $table.applied, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
      column: $table.appliedAt, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> stockCountItemsRefs(
      Expression<bool> Function($$StockCountItemsTableFilterComposer f) f) {
    final $$StockCountItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockCountItems,
        getReferencedColumn: (t) => t.stockCountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountItemsTableFilterComposer(
              $db: $db,
              $table: $db.stockCountItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StockCountsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockCountsTable> {
  $$StockCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get applied => $composableBuilder(
      column: $table.applied, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
      column: $table.appliedAt, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockCountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockCountsTable> {
  $$StockCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get applied =>
      $composableBuilder(column: $table.applied, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> stockCountItemsRefs<T extends Object>(
      Expression<T> Function($$StockCountItemsTableAnnotationComposer a) f) {
    final $$StockCountItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockCountItems,
        getReferencedColumn: (t) => t.stockCountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockCountItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StockCountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StockCountsTable,
    StockCountRow,
    $$StockCountsTableFilterComposer,
    $$StockCountsTableOrderingComposer,
    $$StockCountsTableAnnotationComposer,
    $$StockCountsTableCreateCompanionBuilder,
    $$StockCountsTableUpdateCompanionBuilder,
    (StockCountRow, $$StockCountsTableReferences),
    StockCountRow,
    PrefetchHooks Function({bool employeeId, bool stockCountItemsRefs})> {
  $$StockCountsTableTableManager(_$AppDatabase db, $StockCountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockCountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> applied = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> appliedAt = const Value.absent(),
          }) =>
              StockCountsCompanion(
            id: id,
            employeeId: employeeId,
            note: note,
            applied: applied,
            createdAt: createdAt,
            appliedAt: appliedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> applied = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> appliedAt = const Value.absent(),
          }) =>
              StockCountsCompanion.insert(
            id: id,
            employeeId: employeeId,
            note: note,
            applied: applied,
            createdAt: createdAt,
            appliedAt: appliedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockCountsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {employeeId = false, stockCountItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockCountItemsRefs) db.stockCountItems
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$StockCountsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$StockCountsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockCountItemsRefs)
                    await $_getPrefetchedData<StockCountRow, $StockCountsTable,
                            StockCountItemRow>(
                        currentTable: table,
                        referencedTable: $$StockCountsTableReferences
                            ._stockCountItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StockCountsTableReferences(db, table, p0)
                                .stockCountItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.stockCountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StockCountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StockCountsTable,
    StockCountRow,
    $$StockCountsTableFilterComposer,
    $$StockCountsTableOrderingComposer,
    $$StockCountsTableAnnotationComposer,
    $$StockCountsTableCreateCompanionBuilder,
    $$StockCountsTableUpdateCompanionBuilder,
    (StockCountRow, $$StockCountsTableReferences),
    StockCountRow,
    PrefetchHooks Function({bool employeeId, bool stockCountItemsRefs})>;
typedef $$StockCountItemsTableCreateCompanionBuilder = StockCountItemsCompanion
    Function({
  Value<int> id,
  required int stockCountId,
  required int productId,
  required String productName,
  required int systemQty,
  Value<int> countedQty,
  Value<int> difference,
  Value<bool> counted,
});
typedef $$StockCountItemsTableUpdateCompanionBuilder = StockCountItemsCompanion
    Function({
  Value<int> id,
  Value<int> stockCountId,
  Value<int> productId,
  Value<String> productName,
  Value<int> systemQty,
  Value<int> countedQty,
  Value<int> difference,
  Value<bool> counted,
});

final class $$StockCountItemsTableReferences extends BaseReferences<
    _$AppDatabase, $StockCountItemsTable, StockCountItemRow> {
  $$StockCountItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $StockCountsTable _stockCountIdTable(_$AppDatabase db) =>
      db.stockCounts
          .createAlias('stock_count_items__stock_count_id__stock_counts__id');

  $$StockCountsTableProcessedTableManager get stockCountId {
    final $_column = $_itemColumn<int>('stock_count_id')!;

    final manager = $$StockCountsTableTableManager($_db, $_db.stockCounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stockCountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('stock_count_items__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockCountItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StockCountItemsTable> {
  $$StockCountItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get systemQty => $composableBuilder(
      column: $table.systemQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get countedQty => $composableBuilder(
      column: $table.countedQty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get counted => $composableBuilder(
      column: $table.counted, builder: (column) => ColumnFilters(column));

  $$StockCountsTableFilterComposer get stockCountId {
    final $$StockCountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.stockCountId,
        referencedTable: $db.stockCounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountsTableFilterComposer(
              $db: $db,
              $table: $db.stockCounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockCountItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockCountItemsTable> {
  $$StockCountItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get systemQty => $composableBuilder(
      column: $table.systemQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get countedQty => $composableBuilder(
      column: $table.countedQty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get counted => $composableBuilder(
      column: $table.counted, builder: (column) => ColumnOrderings(column));

  $$StockCountsTableOrderingComposer get stockCountId {
    final $$StockCountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.stockCountId,
        referencedTable: $db.stockCounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountsTableOrderingComposer(
              $db: $db,
              $table: $db.stockCounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockCountItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockCountItemsTable> {
  $$StockCountItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<int> get systemQty =>
      $composableBuilder(column: $table.systemQty, builder: (column) => column);

  GeneratedColumn<int> get countedQty => $composableBuilder(
      column: $table.countedQty, builder: (column) => column);

  GeneratedColumn<int> get difference => $composableBuilder(
      column: $table.difference, builder: (column) => column);

  GeneratedColumn<bool> get counted =>
      $composableBuilder(column: $table.counted, builder: (column) => column);

  $$StockCountsTableAnnotationComposer get stockCountId {
    final $$StockCountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.stockCountId,
        referencedTable: $db.stockCounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockCountsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockCounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockCountItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StockCountItemsTable,
    StockCountItemRow,
    $$StockCountItemsTableFilterComposer,
    $$StockCountItemsTableOrderingComposer,
    $$StockCountItemsTableAnnotationComposer,
    $$StockCountItemsTableCreateCompanionBuilder,
    $$StockCountItemsTableUpdateCompanionBuilder,
    (StockCountItemRow, $$StockCountItemsTableReferences),
    StockCountItemRow,
    PrefetchHooks Function({bool stockCountId, bool productId})> {
  $$StockCountItemsTableTableManager(
      _$AppDatabase db, $StockCountItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockCountItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockCountItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockCountItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> stockCountId = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<int> systemQty = const Value.absent(),
            Value<int> countedQty = const Value.absent(),
            Value<int> difference = const Value.absent(),
            Value<bool> counted = const Value.absent(),
          }) =>
              StockCountItemsCompanion(
            id: id,
            stockCountId: stockCountId,
            productId: productId,
            productName: productName,
            systemQty: systemQty,
            countedQty: countedQty,
            difference: difference,
            counted: counted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int stockCountId,
            required int productId,
            required String productName,
            required int systemQty,
            Value<int> countedQty = const Value.absent(),
            Value<int> difference = const Value.absent(),
            Value<bool> counted = const Value.absent(),
          }) =>
              StockCountItemsCompanion.insert(
            id: id,
            stockCountId: stockCountId,
            productId: productId,
            productName: productName,
            systemQty: systemQty,
            countedQty: countedQty,
            difference: difference,
            counted: counted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockCountItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({stockCountId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (stockCountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.stockCountId,
                    referencedTable:
                        $$StockCountItemsTableReferences._stockCountIdTable(db),
                    referencedColumn: $$StockCountItemsTableReferences
                        ._stockCountIdTable(db)
                        .id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$StockCountItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$StockCountItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StockCountItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StockCountItemsTable,
    StockCountItemRow,
    $$StockCountItemsTableFilterComposer,
    $$StockCountItemsTableOrderingComposer,
    $$StockCountItemsTableAnnotationComposer,
    $$StockCountItemsTableCreateCompanionBuilder,
    $$StockCountItemsTableUpdateCompanionBuilder,
    (StockCountItemRow, $$StockCountItemsTableReferences),
    StockCountItemRow,
    PrefetchHooks Function({bool stockCountId, bool productId})>;
typedef $$EmployeeTransactionsTableCreateCompanionBuilder
    = EmployeeTransactionsCompanion Function({
  Value<int> id,
  required int employeeId,
  required String kind,
  required double amount,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$EmployeeTransactionsTableUpdateCompanionBuilder
    = EmployeeTransactionsCompanion Function({
  Value<int> id,
  Value<int> employeeId,
  Value<String> kind,
  Value<double> amount,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$EmployeeTransactionsTableReferences extends BaseReferences<
    _$AppDatabase, $EmployeeTransactionsTable, EmployeeTransactionRow> {
  $$EmployeeTransactionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) => db.employees
      .createAlias('employee_transactions__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EmployeeTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeeTransactionsTable> {
  $$EmployeeTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeeTransactionsTable> {
  $$EmployeeTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeeTransactionsTable> {
  $$EmployeeTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeeTransactionsTable,
    EmployeeTransactionRow,
    $$EmployeeTransactionsTableFilterComposer,
    $$EmployeeTransactionsTableOrderingComposer,
    $$EmployeeTransactionsTableAnnotationComposer,
    $$EmployeeTransactionsTableCreateCompanionBuilder,
    $$EmployeeTransactionsTableUpdateCompanionBuilder,
    (EmployeeTransactionRow, $$EmployeeTransactionsTableReferences),
    EmployeeTransactionRow,
    PrefetchHooks Function({bool employeeId})> {
  $$EmployeeTransactionsTableTableManager(
      _$AppDatabase db, $EmployeeTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeeTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeeTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeeTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EmployeeTransactionsCompanion(
            id: id,
            employeeId: employeeId,
            kind: kind,
            amount: amount,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int employeeId,
            required String kind,
            required double amount,
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EmployeeTransactionsCompanion.insert(
            id: id,
            employeeId: employeeId,
            kind: kind,
            amount: amount,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeeTransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable: $$EmployeeTransactionsTableReferences
                        ._employeeIdTable(db),
                    referencedColumn: $$EmployeeTransactionsTableReferences
                        ._employeeIdTable(db)
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
        ));
}

typedef $$EmployeeTransactionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $EmployeeTransactionsTable,
        EmployeeTransactionRow,
        $$EmployeeTransactionsTableFilterComposer,
        $$EmployeeTransactionsTableOrderingComposer,
        $$EmployeeTransactionsTableAnnotationComposer,
        $$EmployeeTransactionsTableCreateCompanionBuilder,
        $$EmployeeTransactionsTableUpdateCompanionBuilder,
        (EmployeeTransactionRow, $$EmployeeTransactionsTableReferences),
        EmployeeTransactionRow,
        PrefetchHooks Function({bool employeeId})>;
typedef $$EmployeeAttendanceTableCreateCompanionBuilder
    = EmployeeAttendanceCompanion Function({
  Value<int> id,
  required int employeeId,
  required DateTime checkIn,
  Value<DateTime?> checkOut,
  Value<DateTime> createdAt,
});
typedef $$EmployeeAttendanceTableUpdateCompanionBuilder
    = EmployeeAttendanceCompanion Function({
  Value<int> id,
  Value<int> employeeId,
  Value<DateTime> checkIn,
  Value<DateTime?> checkOut,
  Value<DateTime> createdAt,
});

final class $$EmployeeAttendanceTableReferences extends BaseReferences<
    _$AppDatabase, $EmployeeAttendanceTable, EmployeeAttendanceRow> {
  $$EmployeeAttendanceTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) => db.employees
      .createAlias('employee_attendance__employee_id__employees__id');

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EmployeeAttendanceTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeeAttendanceTable> {
  $$EmployeeAttendanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get checkIn => $composableBuilder(
      column: $table.checkIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get checkOut => $composableBuilder(
      column: $table.checkOut, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeAttendanceTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeeAttendanceTable> {
  $$EmployeeAttendanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get checkIn => $composableBuilder(
      column: $table.checkIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get checkOut => $composableBuilder(
      column: $table.checkOut, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeAttendanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeeAttendanceTable> {
  $$EmployeeAttendanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get checkIn =>
      $composableBuilder(column: $table.checkIn, builder: (column) => column);

  GeneratedColumn<DateTime> get checkOut =>
      $composableBuilder(column: $table.checkOut, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EmployeeAttendanceTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeeAttendanceTable,
    EmployeeAttendanceRow,
    $$EmployeeAttendanceTableFilterComposer,
    $$EmployeeAttendanceTableOrderingComposer,
    $$EmployeeAttendanceTableAnnotationComposer,
    $$EmployeeAttendanceTableCreateCompanionBuilder,
    $$EmployeeAttendanceTableUpdateCompanionBuilder,
    (EmployeeAttendanceRow, $$EmployeeAttendanceTableReferences),
    EmployeeAttendanceRow,
    PrefetchHooks Function({bool employeeId})> {
  $$EmployeeAttendanceTableTableManager(
      _$AppDatabase db, $EmployeeAttendanceTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeeAttendanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeeAttendanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeeAttendanceTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<DateTime> checkIn = const Value.absent(),
            Value<DateTime?> checkOut = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EmployeeAttendanceCompanion(
            id: id,
            employeeId: employeeId,
            checkIn: checkIn,
            checkOut: checkOut,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int employeeId,
            required DateTime checkIn,
            Value<DateTime?> checkOut = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EmployeeAttendanceCompanion.insert(
            id: id,
            employeeId: employeeId,
            checkIn: checkIn,
            checkOut: checkOut,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeeAttendanceTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable: $$EmployeeAttendanceTableReferences
                        ._employeeIdTable(db),
                    referencedColumn: $$EmployeeAttendanceTableReferences
                        ._employeeIdTable(db)
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
        ));
}

typedef $$EmployeeAttendanceTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmployeeAttendanceTable,
    EmployeeAttendanceRow,
    $$EmployeeAttendanceTableFilterComposer,
    $$EmployeeAttendanceTableOrderingComposer,
    $$EmployeeAttendanceTableAnnotationComposer,
    $$EmployeeAttendanceTableCreateCompanionBuilder,
    $$EmployeeAttendanceTableUpdateCompanionBuilder,
    (EmployeeAttendanceRow, $$EmployeeAttendanceTableReferences),
    EmployeeAttendanceRow,
    PrefetchHooks Function({bool employeeId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$DeviceTypesTableTableManager get deviceTypes =>
      $$DeviceTypesTableTableManager(_db, _db.deviceTypes);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db, _db.packages);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionEventsTableTableManager get sessionEvents =>
      $$SessionEventsTableTableManager(_db, _db.sessionEvents);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$EmployeeFeatureOverridesTableTableManager get employeeFeatureOverrides =>
      $$EmployeeFeatureOverridesTableTableManager(
          _db, _db.employeeFeatureOverrides);
  $$ReservationsTableTableManager get reservations =>
      $$ReservationsTableTableManager(_db, _db.reservations);
  $$OffersTableTableManager get offers =>
      $$OffersTableTableManager(_db, _db.offers);
  $$LoyaltySettingsTableTableManager get loyaltySettings =>
      $$LoyaltySettingsTableTableManager(_db, _db.loyaltySettings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$AccountEntriesTableTableManager get accountEntries =>
      $$AccountEntriesTableTableManager(_db, _db.accountEntries);
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db, _db.refunds);
  $$StockCountsTableTableManager get stockCounts =>
      $$StockCountsTableTableManager(_db, _db.stockCounts);
  $$StockCountItemsTableTableManager get stockCountItems =>
      $$StockCountItemsTableTableManager(_db, _db.stockCountItems);
  $$EmployeeTransactionsTableTableManager get employeeTransactions =>
      $$EmployeeTransactionsTableTableManager(_db, _db.employeeTransactions);
  $$EmployeeAttendanceTableTableManager get employeeAttendance =>
      $$EmployeeAttendanceTableTableManager(_db, _db.employeeAttendance);
}
