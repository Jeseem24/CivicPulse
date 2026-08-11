import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationSettingsTarget { none, app, locationServices }

class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.settingsTarget = LocationSettingsTarget.none});

  final String message;
  final LocationSettingsTarget settingsTarget;

  @override
  String toString() => message;
}

class LocationService {
  Future<bool> checkLocationServicesEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  Future<LocationPermission> ensurePermission() async {
    if (!await checkLocationServicesEnabled()) {
      throw const LocationFailure(
        'Turn on Location on your phone, then try again.',
        settingsTarget: LocationSettingsTarget.locationServices,
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Location permission is required to place and view civic reports.',
        settingsTarget: LocationSettingsTarget.app,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location permission is blocked. Allow it from the app settings.',
        settingsTarget: LocationSettingsTarget.app,
      );
    }

    return permission;
  }

  Future<Position> getCurrentPosition() async {
    await ensurePermission();

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
    } on TimeoutException {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) return lastKnownPosition;
      throw const LocationFailure(
        'A GPS fix could not be obtained. Move near a window and try again.',
      );
    }
  }

  Future<bool> openSettingsFor(Object error) async {
    if (error is! LocationFailure) return false;
    switch (error.settingsTarget) {
      case LocationSettingsTarget.app:
        return Geolocator.openAppSettings();
      case LocationSettingsTarget.locationServices:
        return Geolocator.openLocationSettings();
      case LocationSettingsTarget.none:
        return false;
    }
  }
}
