// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ReportTableTable extends ReportTable
    with TableInfo<$ReportTableTable, ReportTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wifiAccessPointsMeta =
      const VerificationMeta('wifiAccessPoints');
  @override
  late final GeneratedColumn<String> wifiAccessPoints = GeneratedColumn<String>(
      'wifi_access_points', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [timestamp, position, wifiAccessPoints];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'report_table';
  @override
  VerificationContext validateIntegrity(Insertable<ReportTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('wifi_access_points')) {
      context.handle(
          _wifiAccessPointsMeta,
          wifiAccessPoints.isAcceptableOrUnknown(
              data['wifi_access_points']!, _wifiAccessPointsMeta));
    } else if (isInserting) {
      context.missing(_wifiAccessPointsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {timestamp};
  @override
  ReportTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReportTableData(
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position'])!,
      wifiAccessPoints: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}wifi_access_points'])!,
    );
  }

  @override
  $ReportTableTable createAlias(String alias) {
    return $ReportTableTable(attachedDatabase, alias);
  }
}

class ReportTableData extends DataClass implements Insertable<ReportTableData> {
  final int timestamp;
  final String position;
  final String wifiAccessPoints;
  const ReportTableData(
      {required this.timestamp,
      required this.position,
      required this.wifiAccessPoints});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['timestamp'] = Variable<int>(timestamp);
    map['position'] = Variable<String>(position);
    map['wifi_access_points'] = Variable<String>(wifiAccessPoints);
    return map;
  }

  ReportTableCompanion toCompanion(bool nullToAbsent) {
    return ReportTableCompanion(
      timestamp: Value(timestamp),
      position: Value(position),
      wifiAccessPoints: Value(wifiAccessPoints),
    );
  }

  factory ReportTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReportTableData(
      timestamp: serializer.fromJson<int>(json['timestamp']),
      position: serializer.fromJson<String>(json['position']),
      wifiAccessPoints: serializer.fromJson<String>(json['wifiAccessPoints']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'timestamp': serializer.toJson<int>(timestamp),
      'position': serializer.toJson<String>(position),
      'wifiAccessPoints': serializer.toJson<String>(wifiAccessPoints),
    };
  }

  ReportTableData copyWith(
          {int? timestamp, String? position, String? wifiAccessPoints}) =>
      ReportTableData(
        timestamp: timestamp ?? this.timestamp,
        position: position ?? this.position,
        wifiAccessPoints: wifiAccessPoints ?? this.wifiAccessPoints,
      );
  @override
  String toString() {
    return (StringBuffer('ReportTableData(')
          ..write('timestamp: $timestamp, ')
          ..write('position: $position, ')
          ..write('wifiAccessPoints: $wifiAccessPoints')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(timestamp, position, wifiAccessPoints);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportTableData &&
          other.timestamp == this.timestamp &&
          other.position == this.position &&
          other.wifiAccessPoints == this.wifiAccessPoints);
}

class ReportTableCompanion extends UpdateCompanion<ReportTableData> {
  final Value<int> timestamp;
  final Value<String> position;
  final Value<String> wifiAccessPoints;
  const ReportTableCompanion({
    this.timestamp = const Value.absent(),
    this.position = const Value.absent(),
    this.wifiAccessPoints = const Value.absent(),
  });
  ReportTableCompanion.insert({
    this.timestamp = const Value.absent(),
    required String position,
    required String wifiAccessPoints,
  })  : position = Value(position),
        wifiAccessPoints = Value(wifiAccessPoints);
  static Insertable<ReportTableData> custom({
    Expression<int>? timestamp,
    Expression<String>? position,
    Expression<String>? wifiAccessPoints,
  }) {
    return RawValuesInsertable({
      if (timestamp != null) 'timestamp': timestamp,
      if (position != null) 'position': position,
      if (wifiAccessPoints != null) 'wifi_access_points': wifiAccessPoints,
    });
  }

  ReportTableCompanion copyWith(
      {Value<int>? timestamp,
      Value<String>? position,
      Value<String>? wifiAccessPoints}) {
    return ReportTableCompanion(
      timestamp: timestamp ?? this.timestamp,
      position: position ?? this.position,
      wifiAccessPoints: wifiAccessPoints ?? this.wifiAccessPoints,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (wifiAccessPoints.present) {
      map['wifi_access_points'] = Variable<String>(wifiAccessPoints.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportTableCompanion(')
          ..write('timestamp: $timestamp, ')
          ..write('position: $position, ')
          ..write('wifiAccessPoints: $wifiAccessPoints')
          ..write(')'))
        .toString();
  }
}

abstract class _$ReportDatabase extends GeneratedDatabase {
  _$ReportDatabase(QueryExecutor e) : super(e);
  late final $ReportTableTable reportTable = $ReportTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [reportTable];
}
