import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_scan/wifi_scan.dart';

Stream<List<WiFiAccessPoint>> streamWifiData(ref) async* {
  final scanner = WiFiScan.instance;
  await for (final nearbyWiFi in scanner.onScannedResultsAvailable) {
    yield nearbyWiFi;
  }
}

class APList extends ConsumerWidget {
  const APList({super.key, required this.scanProvider, required this.bootTime});

  final StreamProvider<List<WiFiAccessPoint>> scanProvider;
  final DateTime bootTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyWiFi = ref.watch(scanProvider);
    return nearbyWiFi.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text(error.toString()),
      data: (List<WiFiAccessPoint> accessPoints) {
        return ListView.builder(
          itemCount: accessPoints.length,
          prototypeItem: Card(
              child: ListTile(
            title: Text(accessPoints.first.ssid),
            subtitle: Text(accessPoints.first.bssid),
            isThreeLine: true,
          )),
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(accessPoints[index].ssid.isNotEmpty
                    ? accessPoints[index].ssid
                    : '[Hidden Network]'),
                subtitle: Text(
                    '${accessPoints[index].bssid}\n${bootTime.add(Duration(microseconds: accessPoints[index].timestamp!))}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
// FIXME: Add time since boot
