// Stumbler
// Copyright (C) 2023 Daniel Ching
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, write to the Free Software Foundation,
// Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

// Defines a Drift database for storing Mozilla Location Service [Report]
library;

import 'dart:convert';
import 'dart:io';

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
Future<bool> insertReport(ReportDatabase database, Report report) async {
  await database.into(database.reportTable).insert(
        ReportTableCompanion(
          timestamp: Value(report.timestamp),
          position: Value(jsonEncode(report.position)),
          wifiAccessPoints: Value(jsonEncode(report.wifiAccessPoints)),
        ),
        onConflict: DoNothing(),
      );
  return true;
}

/// Get all of the reports from the database
Future<List<Report>> fetchReports(ReportDatabase database) async {
  final reports = await (database.select(database.reportTable)
        ..orderBy([
          (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
        ]))
      .get();
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
Future<void> deleteReport(ReportDatabase database, int timestamp) async {
  await (database.delete(database.reportTable)
        ..where((t) => t.timestamp.isSmallerThanValue(timestamp)))
      .go();
}
