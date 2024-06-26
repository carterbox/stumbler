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

/// Classes and functions for submitting data to the Mozilla Location Service.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final log = Logger('geosubmit');

/// Submit a report to the location service anonymously over https
void submitReports(List<Report> reports) async {
  final url = Uri.https('location.services.mozilla.com', '/v2/geosubmit');
  final reportsJson = jsonEncode(reports.map((e) => e.toValid()).toList());
  final response = await http.post(url, body: reportsJson);
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

  Report toValid() {
    return Report(
        timestamp: timestamp,
        position: position,
        wifiAccessPoints: wifiAccessPoints.where((e) {
          return (e.ssid != null &&
              e.ssid!.isNotEmpty &&
              !e.ssid!.endsWith('_nomap'));
        }).toList(growable: false));
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'position': position.toJson(),
        'wifiAccessPoints': wifiAccessPoints.map((element) {
          return element.toJson();
        }).toList(growable: false),
      };

  Report.fromJson(Map<String, dynamic> object)
      : timestamp = object['timestamp'],
        position = Position.fromJson(object['position']),
        wifiAccessPoints =
            object['wifiAccessPoints'].map<WifiAccessPoint>((element) {
          return WifiAccessPoint.fromJson(element);
        }).toList(growable: false);

  Map<String, dynamic> toSQLiteRow() => {
        'timestamp': timestamp,
        'position': jsonEncode(position),
        'wifiAccessPoints': jsonEncode(wifiAccessPoints),
      };

  Report.fromSQLiteRow(Map<String, dynamic> object)
      : timestamp = object['timestamp'],
        position = Position.fromJson(jsonDecode(object['position'])),
        wifiAccessPoints = jsonDecode(object['wifiAccessPoints'])
            .map<WifiAccessPoint>((element) {
          return WifiAccessPoint.fromJson(element);
        }).toList(growable: false);

  Report.fromMock()
      : timestamp = DateTime.now().millisecondsSinceEpoch,
        position = Position.fromMock(),
        wifiAccessPoints = List<WifiAccessPoint>.generate(
            Random().nextInt(10) + 1, (index) => WifiAccessPoint.fromMock());

  @override
  String toString() {
    return "Report at time $timestamp\n  with position: $position\n  with observations: ${wifiAccessPoints.map((e) => "\n    $e")}";
  }
}

/// Contains information about where and when the data was observed.
@immutable
class Position {
  /// The latitude of the observation (WSG 84).
  final double latitude;

  /// The longitude of the observation (WSG 84).
  final double longitude;

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

  Position.fromJson(Map<String, dynamic> object)
      : latitude = object['latitude'],
        longitude = object['longitude'],
        accuracy = object['accuracy'],
        altitude = object['altitude'],
        altitudeAccuracy = object['altitudeAccuracy'],
        heading = object['heading'],
        pressure = object['pressure'],
        speed = object['speed'],
        age = object['age'],
        source = object['source'];

  Position.fromMock()
      : latitude = (Random().nextDouble() * 180) - 90,
        longitude = (Random().nextDouble() * 360) - 180,
        accuracy = null,
        altitude = null,
        altitudeAccuracy = null,
        heading = null,
        pressure = null,
        speed = null,
        age = Random().nextBool() ? null : Random().nextInt(100) - 50,
        source = null;

  @override
  String toString() {
    return "Position @ $latitude, $longitude at time $age";
  }
}

/// Contains information about a WIFI network
@immutable
class WifiAccessPoint {
  /// The BSSID of the Wifi network.
  final String macAddress;

  /// The number of milliseconds since this Wifi network was detected.
  final int? age;

  /// The channel is a number specified by the IEEE which represents a small
  /// band of frequencies.
  final int? channel;

  /// The frequency in MHz of the channel over which the client is communicating
  /// with the access point.
  final int? frequency;

  /// The Wifi radio type; one of 802.11a, 802.11b, 802.11g, 802.11n, 802.11ac.
  final String? radioType;

  /// The current signal to noise ratio measured in dB.
  final int? signalToNoiseRatio;

  /// The received signal strength (RSSI) in dBm.
  final int? signalStrength;

  /// The SSID of the Wifi network.
  ///
  /// Hidden Wifi networks must not be collected.
  /// Wifi networks with a SSID ending in '_nomap' must not be collected.
  final String? ssid;

  static const Set<String> validRadioType = {
    '802.11a',
    '802.11b',
    '802.11g',
    '802.11n',
    '802.11ac',
    '802.11ax', // Adding this newer standard because it exists
  };

  WifiAccessPoint({
    required this.macAddress,
    this.age,
    this.channel,
    this.frequency,
    this.radioType,
    this.signalStrength,
    this.signalToNoiseRatio,
    this.ssid,
  }) {
    if (radioType != null && !validRadioType.contains(radioType!)) {
      throw Exception('WifiAccessPoint radioType $radioType is invalid!');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      if (age != null) 'age': age,
      if (channel != null) 'channel': channel,
      if (frequency != null) 'frequency': frequency,
      if (radioType != null && radioType!.isNotEmpty) 'radioType': radioType,
      if (signalStrength != null) 'signalStrength': signalStrength,
      if (signalToNoiseRatio != null) 'signalToNoiseRatio': signalToNoiseRatio,
      if (ssid != null) 'ssid': ssid,
    };
  }

  WifiAccessPoint.fromJson(Map<String, dynamic> object)
      : macAddress = object['macAddress'],
        age = object['age'],
        channel = object['channel'],
        frequency = object['frequency'],
        radioType = object['radioType'],
        signalStrength = object['signalStrength'],
        signalToNoiseRatio = object['signalToNoiseRatio'],
        ssid = object['ssid'];

  WifiAccessPoint.fromMock()
      : macAddress =
            ('${Random().nextInt(256).toRadixString(16).toUpperCase()}:'
                '${Random().nextInt(256).toRadixString(16).toUpperCase()}:'
                '${Random().nextInt(256).toRadixString(16).toUpperCase()}:'
                '${Random().nextInt(256).toRadixString(16).toUpperCase()}:'
                '${Random().nextInt(256).toRadixString(16).toUpperCase()}:'
                '${Random().nextInt(256).toRadixString(16).toUpperCase()}'),
        age = Random().nextBool() ? null : Random().nextInt(100) - 50,
        channel = null,
        frequency = null,
        radioType = Random().nextBool() ? null : '802.11a',
        signalStrength = null,
        signalToNoiseRatio = null,
        ssid = Random().nextBool() ? null : 'mock_nomap';

  @override
  String toString() {
    return "WifiAccessPoint $macAddress at time $age";
  }
}
