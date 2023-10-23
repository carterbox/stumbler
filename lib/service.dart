import 'dart:async';
import 'dart:math';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:logging/logging.dart' as logging;
import 'package:location/location.dart';
import 'package:mozumbler/geosubmit.dart' as mls;
import 'package:system_clock/system_clock.dart';

final _logger = logging.Logger('mozumbler.service');

// this will be used as notification channel id
const notificationChannelId = 'mozumbler';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 000;

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     notificationChannelId, // id
//     'Stumbling Activity', // title
//     description: 'Whether the stumbling is currently active.', // description
//     importance: Importance.low, // importance must be at low or higher level
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       // this will be executed when app is in foreground or background in separated isolate
//       onStart: onStart,

//       // auto start service
//       autoStart: true,
//       autoStartOnBoot: false,
//       isForegroundMode: false,

//       notificationChannelId:
//           notificationChannelId, // this must match with notification channel you created above.
//       // initialNotificationTitle: 'Mozumbler',
//       initialNotificationContent: 'Initializing Mozumbler',
//       foregroundServiceNotificationId: notificationId,
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// @pragma('vm:entry-point')
// Future<void> onStart(ServiceInstance service) async {
//   // Only available for flutter 3.0.0 and later
//   DartPluginRegistrant.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // bring to foreground
//   Timer.periodic(const Duration(seconds: 6), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if (true) {
//         flutterLocalNotificationsPlugin.show(
//           notificationId,
//           'Mozumbler is active',
//           'Awesome ${DateTime.now()}',
//           const NotificationDetails(
//             android: AndroidNotificationDetails(
//               notificationChannelId,
//               'MY FOREGROUND SERVICE',
//               icon: 'ic_bg_service_small',
//               ongoing: true,
//             ),
//           ),
//         );
//       }
//     }
//   });
// }

Stream<List<WiFiAccessPoint>> streamWifiData() async* {
  final scanner = WiFiScan.instance;
  await for (final nearbyWiFi in scanner.onScannedResultsAvailable) {
    yield nearbyWiFi;
  }
}

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
  LocationData data,
  DateTime lastBootDate,
  DateTime reportDate,
) {
  final positionDate = lastBootDate
      .add(Duration(microseconds: data.elapsedRealtimeNanos! ~/ 1000));
  return mls.Position(
    latitude: data.latitude!,
    longitude: data.longitude!,
    accuracy: data.accuracy,
    altitude: data.altitude,
    speed: data.speed,
    heading: data.heading,
    source: 'fused',
    age: positionDate.difference(reportDate).inMilliseconds,
  );
}

Stream<LocationData?> streamLocationData() async* {
  final location = Location();

  bool serviceEnabled;
  PermissionStatus permissionGranted;

  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      yield null;
    }
  }

  permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      yield null;
    }
  }

  location.changeSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // meters
    interval: 6 * 1000, // milliseconds
  );

  await for (final result in location.onLocationChanged) {
    yield result;
  }
}

Stream<List<mls.Report>> streamMockWifiReports(ref) async* {
  List<mls.Report> reports = [];
  while (true) {
    await Future.delayed(Duration(seconds: Random().nextInt(90)));
    reports.add(mls.Report.fromMock());
    yield reports;
  }
}

Stream<List<mls.Report>> streamWifiReports(ref) async* {
  // Setup WiFi Scanner and request permissions

  final scanner = WiFiScan.instance;
  if (await scanner.canGetScannedResults() != CanGetScannedResults.yes) {
    yield* Stream.error("Permission to get Wifi Scan results not given.");
    return;
  }
  if (await scanner.canStartScan() != CanStartScan.yes) {
    yield* Stream.error("Permission to start Wifi Scan not given.");
    return;
  }

  // When the date when the system was last rebooted. Used to compute dates
  // when WiFi networks were last seen.
  final lastBootDate = DateTime.now().subtract(SystemClock.elapsedRealtime());
  List<mls.Report> reports = [];

  // Because of background data limits we only get position and WiFi scan
  // updates a few times per hour. Therefore, we only request a WiFi scan when
  // we have new position data and we only generate a report if the WiFi scan is
  // recent.
  _logger.info("Awaiting location stream.");
  await for (final bestPosition in streamLocationData()) {
    _logger.info("Location is received.");
    if (bestPosition == null) {
      yield* Stream.error("Permission to see location not given.");
      return;
    }
    await scanner.startScan();
    _logger.info("Awaiting Wifi scan result.");
    final bestWifi = await scanner.getScannedResults();
    _logger.info("Wifi scan completed.");
    if (bestWifi.isNotEmpty) {
      final positionDate = lastBootDate.add(
          Duration(microseconds: bestPosition.elapsedRealtimeNanos! ~/ 1000));
      final wifiDate =
          lastBootDate.add(Duration(microseconds: bestWifi[0].timestamp!));

      const tooOld = Duration(seconds: 30);
      if (positionDate.difference(wifiDate).abs() < tooOld) {
        _logger
            .info("Wifi scan from within the last $tooOld; creating a report.");
        final reportDate = DateTime.now();
        reports.add(mls.Report(
          timestamp: reportDate.millisecondsSinceEpoch,
          position: convertPositionData(bestPosition, lastBootDate, reportDate),
          wifiAccessPoints: bestWifi
              .map((e) => convertWifiData(e, lastBootDate, reportDate))
              .where((e) => (e.ssid != null &&
                  e.ssid!.isNotEmpty &&
                  !e.ssid!.endsWith('_nomap')))
              .toList(),
        ));
        yield reports;
      } else {
        _logger.info("Wifi scan is older than the last $tooOld.");
      }
    }
    _logger.info("Awaiting location stream.");
  }
}
