import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stumbler/database.dart';
import 'package:stumbler/geosubmit.dart';
import 'package:stumbler/service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

@riverpod
class StumblerStatus extends _$StumblerStatus {
  @override
  Future<bool> build() async {
    if (await getLocationAndNetworkPermission()) {
      return isMozumberServiceActive();
    }
    return false;
  }

  Future<void> toggleService() async {
    if (await future) {
      await stopStumblerService();
    } else {
      await startStumblerService();
    }
    await Future.delayed(const Duration(seconds: 1));
    ref.invalidateSelf();
  }
}

/// A [SwitchListTile] which controls whether the Stumber service is running
class StumblerControlButton extends ConsumerWidget {
  const StumblerControlButton({super.key});

  final title = const Text('Stumbler Control');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stumblerStatus = ref.watch(stumblerStatusProvider);
    return stumblerStatus.when(
      data: (bool isRunning) => SwitchListTile.adaptive(
        value: isRunning,
        onChanged: (bool newValue) {
          ref.read(stumblerStatusProvider.notifier).toggleService();
        },
        title: title,
        subtitle: isRunning
            ? const Text('The service is active.')
            : const Text('The service is not active.'),
      ),
      error: (error, stackTrace) => SwitchListTile.adaptive(
        value: false,
        onChanged: null,
        title: title,
        subtitle: const Text('There was an error with the service.'),
      ),
      loading: () => SwitchListTile.adaptive(
        value: false,
        onChanged: null,
        title: title,
        subtitle:
            const Text('Communication is being established with the service.'),
      ),
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
      bottomNavigationBar: const BottomAppBar(
        height: 96,
        child: StumblerControlButton(),
      ),
      floatingActionButton: const UploadButton(),
    );
  }
}

/// A [FloatingActionButton] that triggers uploading the collected [Report]
class UploadButton extends ConsumerWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        debugPrint("Upload button pressed");
        ref.read(reportListProvider.notifier).upload();
      },
      label: const Text('Upload'),
      icon: const Icon(Icons.upload),
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
    // await insertReport(Report.fromMock());
    // scheduleSingleReport();
    ref.invalidateSelf();
    await future;
  }

  Future<void> upload() async {
    deleteReport(DateTime.now().millisecondsSinceEpoch);
    ref.invalidateSelf();
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

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.618,
          child: Placeholder(),
        ),
        ListTile(
          title: Text(locationName),
          subtitle: Text(date),
          isThreeLine: false,
        ),
      ],
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

/// A [ListView] of [Card] each representing an [WifiAccessPoint]
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
        final String age = (accessPoints[index].age == null)
            ? 'unknown'
            : (accessPoints[index].age! / 1000).toStringAsFixed(3);
        return Card(
          child: ListTile(
            title: Text((accessPoints[index].ssid != null &&
                    accessPoints[index].ssid!.isNotEmpty)
                ? accessPoints[index].ssid!
                : '[Hidden Network]'),
            subtitle: Text(
                '${accessPoints[index].macAddress.toUpperCase()}\n$age seconds'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
