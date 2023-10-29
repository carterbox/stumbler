import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:stumbler/geosubmit.dart';

part 'database.g.dart';

class ReportTable extends Table {
  // Measured in milliseconds since the UNIX epoch.
  IntColumn get timestamp => integer()();

  // The Position converted to JSON
  TextColumn get position => text()();

  // The Wifi scan results converted to JSON
  TextColumn get wifiAccessPoints => text()();

  @override
  Set<Column> get primaryKey => {timestamp};
}

@DriftDatabase(tables: [ReportTable])
class ReportDatabase extends _$ReportDatabase {
  ReportDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'reports.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Store observations in a local database
Future<bool> insertReport(Report report) async {
  final database = ReportDatabase();
  await database.into(database.reportTable).insert(ReportTableCompanion(
        timestamp: Value(report.timestamp),
        position: Value(jsonEncode(report.position)),
        wifiAccessPoints: Value(jsonEncode(report.wifiAccessPoints)),
      ));
  await database.close();
  return true;
}

/// Get all of the reports from the database
Future<List<Report>> fetchReports() async {
  final database = ReportDatabase();
  final reports = await (database.select(database.reportTable)
        ..orderBy([
          (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
        ]))
      .get();
  await database.close();
  return reports
      .map<Report>((e) => Report(
            timestamp: e.timestamp,
            position: Position.fromJson(jsonDecode(e.position)),
            wifiAccessPoints: jsonDecode(e.wifiAccessPoints)
                .map<WifiAccessPoint>((w) => WifiAccessPoint.fromJson(w))
                .toList(growable: false),
          ))
      .toList(growable: false);
}

/// Remove a report from the database
Future<void> deleteReport(int timestamp) async {
  final database = ReportDatabase();
  await (database.delete(database.reportTable)
        ..where((t) => t.timestamp.isSmallerThanValue(timestamp)))
      .go();
  await database.close();
}
