import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> checkLocationServicesEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await checkLocationServicesEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    }

    // High accuracy queries for precise positioning of civic reports
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
