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

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stumbler/database.dart';
import 'package:stumbler/geosubmit.dart';
import 'package:stumbler/service.dart';

// Code generator for riverpod must be running by calling
//`dart run build_runner watch`; it puts code into this file.
part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Stumbler',
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: lightDynamic,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: darkDynamic,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const MyHomePage(title: 'Stumbler'),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Column(
        children: [
          Expanded(
            child: ReportListView(),
          ),
        ],
      ),
      floatingActionButton: const UploadButton(),
      // Column(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   crossAxisAlignment: CrossAxisAlignment.end,
      //   children: [

      //     // SizedBox(
      //     //   height: 8,
      //     // ),
      //     // StumbleButton(),
      //   ],
      // ),
    );
  }
}

/// A [FloatingActionButton] that triggers uploading the collected [Report]
class UploadButton extends ConsumerWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.large(
      onPressed: () {
        debugPrint("Upload button pressed");
        ref
            .read(reportListProvider.notifier)
            .upload(ref.read(databaseProvider));
      },
      tooltip: 'Upload scans to MLS',
      heroTag: 'upload',
      child: const Icon(Icons.upload),
    );
  }
}

/// A [FloatingActionButton] that triggers uploading the collected [Report]
class StumbleButton extends ConsumerWidget {
  const StumbleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.large(
      onPressed: () {
        debugPrint("Scan button pressed");
        ref.read(reportListProvider.notifier).scan(ref.read(databaseProvider));
      },
      tooltip: 'Start a WiFi scan',
      heroTag: 'stumble',
      child: const Icon(Icons.wifi_find),
    );
  }
}

@riverpod
ReportDatabase database(DatabaseRef ref) {
  final database = ReportDatabase();
  ref.onDispose(() async {
    await database.close();
  });
  return database;
}

@riverpod
class ReportList extends _$ReportList {
  @override
  Future<List<Report>> build() async {
    final database = ref.watch(databaseProvider);
    return fetchReports(database);
  }

  Future<void> refresh() async {
    // await insertReport(Report.fromMock());
    // scheduleSingleReport();
    ref.invalidateSelf();
    await future;
  }

  Future<void> upload(ReportDatabase database) async {
    submitReports(await fetchReports(database));
    deleteReport(database, DateTime.now().millisecondsSinceEpoch);
    ref.invalidateSelf();
    await future;
  }

  Future<void> scan(ReportDatabase database) async {
    if (await generateWifiReport(database)) {
      ref.invalidateSelf();
    }
    await future;
  }
}

/// [ListView] of [Report]. Tapping a [Report]'s [ListTile] opens a summary page.
class ReportListView extends ConsumerWidget {
  const ReportListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportListProvider);
    return reports.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Align(
        alignment: Alignment.topCenter,
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.error),
            title: Text(error.toString()),
          ),
        ),
      ),
      data: (List<Report> reports) {
        return RefreshIndicator(
          onRefresh: () async {
            debugPrint("Scan list refreshed");
            await ref
                .read(reportListProvider.notifier)
                .scan(ref.read(databaseProvider));
          },
          child: reports.isNotEmpty
              ? ListView.builder(
                  itemCount: reports.length,
                  prototypeItem: ReportListItem(report: Report.fromMock()),
                  itemBuilder: (context, index) {
                    return ReportListItem(report: reports[index]);
                  },
                )
              : ListView(
                  children: const <Widget>[
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.search_off),
                        title: Text("No reports; pull down to scan."),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// An [InkWell] wrapped [ListTile] which opens a [ReportDetailPage]
class ReportListItem extends StatelessWidget {
  const ReportListItem({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Card(
      // // clipBehavior is necessary because, without it, the InkWell's animation
      // // will extend beyond the rounded edges of the [Card] (see https://github.com/flutter/flutter/issues/109776)
      // // This comes with a small performance cost, and you should not set [clipBehavior]
      // // unless you need it.
      clipBehavior: Clip.hardEdge,
      child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReportDetailPage(report: report),
              ),
            );
          },
          child: LocationListTile(
            location: report.position,
            timestamp: report.timestamp,
          )),
    );
  }
}

/// A [ListTile] showing a summary of [Position] and a timestamp
class LocationListTile extends StatelessWidget {
  const LocationListTile({
    super.key,
    required this.location,
    required this.timestamp,
  });

  final Position location;
  final int timestamp;

  @override
  Widget build(BuildContext context) {
    String locationName = 'Nowhere';
    final String date =
        DateTime.fromMillisecondsSinceEpoch(timestamp + (location.age ?? 0))
            .toString();

    locationName = ('${location.latitude.toStringAsFixed(2)}, '
        '${location.longitude.toStringAsFixed(2)}');

    return ListTile(
      title: Text(locationName),
      subtitle: Text(date),
      isThreeLine: false,
    );
  }
}

/// A [Scaffold] showing the details of a [Report]
class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: Column(
        children: [
          PositionDetail(
            position: report.position,
          ),
          Expanded(
            child: APList(
              accessPoints: report.wifiAccessPoints,
            ),
          ),
        ],
      ),
    );
  }
}

class PositionDetail extends StatefulWidget {
  const PositionDetail({super.key, required this.position});

  final Position position;
  final zoomLevel = 19.0;

  @override
  State<PositionDetail> createState() => _PositionDetailState();
}

class _PositionDetailState extends State<PositionDetail> {
  late final MapController controller;
  late final GeoPoint center;

  @override
  void initState() {
    super.initState();
    center = GeoPoint(
      latitude: widget.position.latitude,
      longitude: widget.position.longitude,
    );
    controller = MapController.withPosition(
      initPosition: center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.618,
      child: OSMFlutter(
        controller: controller,
        osmOption: OSMOption(
            showZoomController: false,
            isPicker: false,
            enableRotationByGesture: false,
            showContributorBadgeForOSM: true,
            zoomOption: ZoomOption(
              initZoom: widget.zoomLevel,
              minZoomLevel: widget.zoomLevel,
              maxZoomLevel: widget.zoomLevel,
            ),
            staticPoints: [
              StaticPositionGeoPoint('', null, [center])
            ]),
        mapIsLoading: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// A [ListView] of [Card] each representing an [WifiAccessPoint]
class APList extends StatelessWidget {
  const APList({super.key, required this.accessPoints});

  final List<WifiAccessPoint> accessPoints;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: accessPoints.length,
      prototypeItem: const ListTile(
        title: Text("Some SSID"),
        subtitle: Text("00:00:00:00"),
        trailing: Text('0 s'),
        isThreeLine: false,
      ),
      itemBuilder: (context, index) {
        final String age = (accessPoints[index].age == null)
            ? 'unknown'
            : (accessPoints[index].age! / 1000).toStringAsFixed(3);
        return ListTile(
          title: Text((accessPoints[index].ssid != null &&
                  accessPoints[index].ssid!.isNotEmpty)
              ? accessPoints[index].ssid!
              : '[Hidden Network]'),
          subtitle: Text(accessPoints[index].macAddress.toUpperCase()),
          trailing: Text('$age s'),
          isThreeLine: false,
        );
      },
    );
  }
}
