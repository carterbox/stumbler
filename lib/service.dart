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

/// Defines the actual stumbling service and logic
library;

import 'dart:async';

import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stumbler/database.dart';
import 'package:stumbler/geosubmit.dart' as mls;
import 'package:system_clock/system_clock.dart';
import 'package:wifi_scan/wifi_scan.dart';

const generateReportTaskKey = "io.github.carterbox.stumbler.generateReport";

Future<bool> isMozumberServiceActive() async {
  return ForegroundServiceHandler.foregroundServiceIsStarted();
}

Future<void> stopStumblerService() async {
  debugPrint('Stopping Mozumber service.');
  await ForegroundServiceHandler.stopForegroundService();
}

Future<void> startStumblerService() async {
  debugPrint('Starting Mozumber service.');
  await ForegroundServiceHandler.notification
      .setPriority(AndroidNotificationPriority.LOW);
  await ForegroundServiceHandler.notification.setTitle('WiFi stumbling active');
  await ForegroundServiceHandler.notification.setText(
      'The stumbler service is recording your location and local WiFi broadcasts.');
  await ForegroundServiceHandler.setServiceIntervalSeconds(30 * 60);
  await ForegroundServiceHandler.setServiceFunction(generateWifiReport);
  await ForegroundServiceHandler.startForegroundService();
}

// void scheduleSingleReport() {
//   debugPrint("Single report scheduled with work manager.");
//   Workmanager().registerOneOffTask(generateReportTaskKey, generateReportTaskKey,
//       constraints: Constraints(
//         networkType: NetworkType.not_required,
//         requiresBatteryNotLow: true,
//         requiresDeviceIdle: false,
//       ));
// }

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) {
//     DartPluginRegistrant.ensureInitialized();
//     WidgetsFlutterBinding.ensureInitialized();
//     print("Native called background task: $task");
//     switch (task) {
//       case generateReportTaskKey:
//         return generateWifiReport();
//     }
//     return Future.value(false);
//   });
// }

const Map<WiFiStandards, String?> standardMap = {
  WiFiStandards.ac: '802.11ac',
  WiFiStandards.ad: '802.11ad',
  WiFiStandards.ax: '802.11ax',
  WiFiStandards.legacy: '802.11g',
  WiFiStandards.n: '802.11n',
  WiFiStandards.unkown: null,
};

mls.WifiAccessPoint convertWifiData(
  WiFiAccessPoint data,
  DateTime lastBootDate,
  DateTime reportDate,
) {
  final seenDate = lastBootDate.add(Duration(microseconds: data.timestamp!));
  return mls.WifiAccessPoint(
    macAddress: data.bssid,
    frequency: data.centerFrequency0,
    radioType: standardMap[data.standard],
    signalStrength: data.level,
    ssid: data.ssid,
    age: seenDate.difference(reportDate).inMilliseconds,
  );
}

mls.Position convertPositionData(
  Position data,
  DateTime lastBootDate,
  DateTime reportDate,
) {
  return mls.Position(
    latitude: data.latitude,
    longitude: data.longitude,
    accuracy: data.accuracy,
    altitude: data.altitude,
    altitudeAccuracy: data.altitudeAccuracy,
    speed: data.speed,
    heading: data.heading,
    source: 'fused',
    age: data.timestamp?.difference(reportDate).inMilliseconds,
  );
}

Future<bool> getLocationAndNetworkPermission() async {
  final scanner = WiFiScan.instance;
  if (await scanner.canGetScannedResults(askPermissions: true) !=
      CanGetScannedResults.yes) {
    return false;
  }
  if (await scanner.canStartScan(askPermissions: true) != CanStartScan.yes) {
    return false;
  }

  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return true;
}

Future<bool> generateMockReport() async {
  return insertReport(mls.Report.fromMock());
}

Future<bool> generateWifiReport() async {
  await ForegroundServiceHandler.getWakeLock();

  final wirelessService = WiFiScan.instance;

  if (await wirelessService.canGetScannedResults(askPermissions: false) !=
      CanGetScannedResults.yes) {
    debugPrint("App does not have permission to get Wifi scan results.");
  }
  if (await wirelessService.canStartScan(askPermissions: false) !=
      CanStartScan.yes) {
    debugPrint("App does not have permission to start a WiFi scan.");
  }

  debugPrint("Awaiting Wifi scan result.");
  if (!await wirelessService.startScan()) {
    debugPrint("Wifi scan not started.");
    return false;
  }

  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  debugPrint("Awaiting location stream.");
  final bestPosition = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  debugPrint("Location is received.");

  // Wait for the scan to happen, so we get new results instead of old ones
  // await Future.delayed(const Duration(seconds: 1));

  final bestWifi = await wirelessService.onScannedResultsAvailable.first;
  debugPrint("Wifi scan completed.");

  if (bestWifi.isEmpty) {
    debugPrint("No Wifi networks in range.");
    return false;
  }

  final reportDate = bestPosition.timestamp ?? DateTime.now();
  // When the date when the system was last rebooted. Used to compute dates
  // when WiFi networks were last seen.
  final lastBootDate = DateTime.now().subtract(SystemClock.elapsedRealtime());

  int tooOld = const Duration(minutes: 1).inMilliseconds;

  final report = mls.Report(
    timestamp: reportDate.millisecondsSinceEpoch,
    position: convertPositionData(
      bestPosition,
      lastBootDate,
      reportDate,
    ),
    wifiAccessPoints: bestWifi
        .map((e) => convertWifiData(e, lastBootDate, reportDate))
        .where((e) => (e.ssid != null &&
            e.ssid!.isNotEmpty &&
            !e.ssid!.endsWith('_nomap')))
        .where((e) => (e.age != null) && (e.age!.abs() <= tooOld))
        .toList(),
  );

  if (report.wifiAccessPoints.isEmpty) {
    debugPrint("Wifi scan has no valid observations.");
    return false;
  }

  await insertReport(report);

  ForegroundServiceHandler.releaseWakeLock();
  return true;
}
