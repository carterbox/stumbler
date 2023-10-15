import 'dart:async';
import 'dart:math';

// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:wifi_scan/wifi_scan.dart';
import 'package:location/location.dart';
import 'package:mozumbler/geosubmit.dart';
// import 'package:system_clock/system_clock.dart';

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

Stream<List<WiFiAccessPoint>> streamWifiData(ref) async* {
  final scanner = WiFiScan.instance;
  await for (final nearbyWiFi in scanner.onScannedResultsAvailable) {
    yield nearbyWiFi;
  }
}

Stream<LocationData?> streamLocationData(ref) async* {
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
    distanceFilter: 5, // meters
    interval: 6 * 1000, // milliseconds
  );

  await for (final result in location.onLocationChanged) {
    yield result;
  }
}

Stream<List<Report>> streamMockWifiReports(ref) async* {
  List<Report> reports = [];
  while (true) {
    await Future.delayed(Duration(seconds: Random().nextInt(90)));
    reports.add(Report.fromMock());
    yield reports;
  }
}

// Stream<List<Report>> streamWifiReports(ref) async* {
//   // When the date when the system was last rebooted. Used to compute dates
//   // when WiFi networks were last seen.
//   final bootTime = DateTime.now().subtract(SystemClock.elapsedRealtime());
//   List<Report> reports = [];
// }
