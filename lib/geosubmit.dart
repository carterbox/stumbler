/// Classes and functions for submitting data to the Mozilla Location Service.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final log = Logger('geosubmit');

/// Submit a report to the location service anonymously over https
void submitReport(Report report) async {
  final url = Uri.https('location.services.mozilla.com', 'v2/geosubmit');
  final response = await http.post(url, body: jsonEncode(report));
  log.info('geosubmit response status: ${response.statusCode}');
  log.fine('geosubmit response body:   ${response.body}');
}

/// A collection of position and beacon data
///
/// Each report must contain at least one entry in the bluetoothBeacons or
/// cellTowers array or two entries in the wifiAccessPoints array.
///
/// Almost all of the fields are optional. For Bluetooth and WiFi records the
/// macAddress field is required.
@immutable
class Report {
  /// The time of observation of the data
  ///
  /// Measured in milliseconds since the UNIX epoch. Can be omitted if the
  /// observation time is very recent. The age values in each section are
  /// relative to this timestamp.
  final int timestamp;

  final Position position;

  final List<WifiAccessPoint> wifiAccessPoints;

  const Report({
    required this.timestamp,
    required this.position,
    required this.wifiAccessPoints,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'position': position.toJson(),
        'wifiAccessPoints': wifiAccessPoints.map((element) {
          return element.toJson();
        }).toList(),
      };
}

/// Contains information about where and when the data was observed.
@immutable
class Position {
  /// The latitude of the observation (WSG 84).
  final int latitude;

  /// The longitude of the observation (WSG 84).
  final int longitude;

  /// The accuracy of the observed position in meters.
  final double? accuracy;

  /// The altitude at which the data was observed in meters above sea-level.
  final double? altitude;

  /// The accuracy of the altitude estimate in meters.
  final double? altitudeAccuracy;

  /// The heading field denotes the direction of travel of the device
  ///
  /// is specified in degrees, where 0° ≤ heading < 360°, counting clockwise
  /// relative to the true north.
  final double? heading;

  /// The air pressure in hPa (millibar).
  final double? pressure;

  /// The speed field denotes the magnitude of the horizontal component of the
  /// device’s current velocity and is specified in meters per second.
  final double? speed;

  /// The age of the position data (in milliseconds).
  final int? age;

  /// The source of the position information.
  ///
  /// If the field is omitted, 'gps' is assumed. The term gps is used to cover
  /// all types of satellite based positioning systems including Galileo and
  /// Glonass. Other possible values are 'manual' for a position entered
  /// manually into the system and 'fused' for a position obtained from a
  /// combination of other sensors or outside service queries.
  final String? source;

  static const Set<String> validSources = {'gps', 'manual', 'fused'};

  Position({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.heading,
    this.pressure,
    this.speed,
    this.age,
    this.source,
  }) {
    if (heading != null && (heading! < 0 || heading! > 360)) {
      throw Exception('Position heading is invalid!');
    }
    if (source != null && !validSources.contains(source!)) {
      throw Exception('Posiiton source is invalid!');
    }
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (altitude != null) 'altitude': altitude,
        if (altitudeAccuracy != null) 'altitudeAccuracy': altitudeAccuracy,
        if (heading != null) 'heading': heading,
        if (pressure != null) 'pressure': pressure,
        if (speed != null) 'speed': speed,
        if (age != null) 'age': age,
        if (source != null && source!.isNotEmpty) 'source': source,
      };
}

/// Contains information about a WIFI network
@immutable
class WifiAccessPoint {
  /// The BSSID of the Wifi network.
  ///
  /// Hidden Wifi networks must not be collected.
  final String macAddess;

  /// The number of milliseconds since this Wifi network was detected.
  final int? age;

  /// The channel is a number specified by the IEEE which represents a small
  /// band of frequencies.
  final int? channel;

  /// The frequency in MHz of the channel over which the client is communicating
  /// with the access point.
  final int? fequency;

  /// The Wifi radio type; one of 802.11a, 802.11b, 802.11g, 802.11n, 802.11ac.
  final String? radioType;

  /// The current signal to noise ratio measured in dB.
  final int? signaltToNoiseRatio;

  /// The received signal strength (RSSI) in dBm.
  final int? signalStrength;

  /// The SSID of the Wifi network.
  ///
  /// Wifi networks with a SSID ending in '_nomap' must not be collected.
  final String? ssid;

  static const Set<String> validRadioType = {
    '802.11a',
    '802.11b',
    '802.11g',
    '802.11n',
    '802.11ac'
  };

  WifiAccessPoint({
    required this.macAddess,
    this.age,
    this.channel,
    this.fequency,
    this.radioType,
    this.signalStrength,
    this.signaltToNoiseRatio,
    this.ssid,
  }) {
    if (radioType != null && !validRadioType.contains(radioType!)) {
      throw Exception('WifiAccessPoint radioType invalid!');
    }
  }

  Map<String, dynamic> toJson() {
    if (ssid != null && ssid!.isNotEmpty && !ssid!.endsWith('_nomap')) {
      return {
        'macAddress': macAddess,
        if (age != null) 'age': age,
        if (channel != null) 'channel': channel,
        if (fequency != null) 'fequency': fequency,
        if (radioType != null && radioType!.isNotEmpty) 'radioType': radioType,
        if (signalStrength != null) 'signalStrength': signalStrength,
        if (signaltToNoiseRatio != null)
          'signaltToNoiseRatio': signaltToNoiseRatio,
        'ssid': ssid,
      };
    }
    return {};
  }
}
