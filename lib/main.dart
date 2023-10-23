import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mozumbler/geosubmit.dart';
import 'package:mozumbler/service.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
  // await initializeService();
}

final reportProvider = StreamProvider<List<Report>>(streamWifiReports);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReportListView(
              reportProvider: reportProvider,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportListView extends ConsumerWidget {
  const ReportListView({super.key, required this.reportProvider});

  final StreamProvider<List<Report>> reportProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportProvider);
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
        return ListView.builder(
          itemCount: reports.length,
          prototypeItem: ReportListItem(report: Report.fromMock()),
          itemBuilder: (context, index) {
            return ReportListItem(report: reports[index]);
          },
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
        title: const Text('Stumbling Report Details'),
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

class APList extends ConsumerWidget {
  const APList({super.key, required this.accessPoints});

  final List<WifiAccessPoint> accessPoints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
