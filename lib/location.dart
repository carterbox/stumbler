import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';

Stream<LocationData?> streamLocationData(ref) async* {
  Location location = Location();

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
    interval: 6000, // milliseconds
  );

  await for (final result in location.onLocationChanged) {
    yield result;
  }
}

class LocationCard extends ConsumerWidget {
  const LocationCard({super.key, required this.locationProvider});

  final StreamProvider<LocationData?> locationProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveLocation = ref.watch(locationProvider);
    return liveLocation.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text(error.toString()),
      data: (LocationData? location) {
        String locationName;

        if (location == null) {
          locationName = 'Nowhere';
        } else {
          locationName = '${location.latitude}, ${location.longitude}';
        }

        return Center(
          child: Card(
            child: SizedBox(
              width: 300,
              height: 100,
              child: Center(child: Text(locationName)),
            ),
          ),
        );
      },
    );
  }
}
