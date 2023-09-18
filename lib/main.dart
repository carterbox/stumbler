import 'package:flutter/material.dart';
import 'package:mozumbler/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:mozumbler/wifi.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:system_clock/system_clock.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final locationProvider = StreamProvider<LocationData?>(streamLocationData);
final scanProvider = StreamProvider<List<WiFiAccessPoint>>(streamWifiData);

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
    // When the date when the system was last rebooted. Used to compute dates
    // when WiFi networks were last seen.
    final bootTime = DateTime.now().subtract(SystemClock.elapsedRealtime());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        children: [
          LocationCard(locationProvider: locationProvider),
          Expanded(
            child: APList(
              scanProvider: scanProvider,
              bootTime: bootTime,
            ),
          ),
        ],
      ),
    );
  }
}
