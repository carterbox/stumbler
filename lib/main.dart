import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mozumbler/geosubmit.dart';
import 'package:mozumbler/service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Code generator for riverpod must be running by calling
//`dart run build_runner watch`; it puts code into this file.
part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  getLocationAndNetworkPermission();
  initializeMozumblerService();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mozumbler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Mozumbler'),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: const Column(
        children: [
          Expanded(
            child: ReportListView(),
          ),
        ],
      ),
    );
  }
}

@riverpod
class ReportList extends _$ReportList {
  @override
  Future<List<Report>> build() async {
    return fetchReports();
  }

  Future<void> refresh() async {
    await insertReport(Report.fromMock());
    ref.invalidateSelf();
    await future;
  }
}

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
            await ref.read(reportListProvider.notifier).refresh();
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
                        title: Text("No reports available."),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

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
            debugPrint('Card tapped.');
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

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Report Details'),
      ),
      body: Column(
        children: [
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

class APList extends StatelessWidget {
  const APList({super.key, required this.accessPoints});

  final List<WifiAccessPoint> accessPoints;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: accessPoints.length,
      prototypeItem: const Card(
          child: ListTile(
        title: Text("Some SSID"),
        subtitle: Text("00:00:00:00"),
        isThreeLine: true,
      )),
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text((accessPoints[index].ssid != null &&
                    accessPoints[index].ssid!.isNotEmpty)
                ? accessPoints[index].ssid!
                : '[Hidden Network]'),
            subtitle: Text(
                '${accessPoints[index].macAddress}\n${accessPoints[index].age ?? ""}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
