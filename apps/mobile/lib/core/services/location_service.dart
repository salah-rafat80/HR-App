import 'package:geolocator/geolocator.dart';

class LocationFix {
  final double lat;
  final double lng;
  final double accuracy;

  const LocationFix({
    required this.lat,
    required this.lng,
    required this.accuracy,
  });
}

abstract class LocationService {
  Future<bool> isLocationServiceEnabled();
  Future<bool> requestPermission();
  Future<LocationFix?> getCurrentPosition();
}

class LocationServiceImpl implements LocationService {
  @override
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<LocationFix?> getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!pos.latitude.isFinite ||
          !pos.longitude.isFinite ||
          !pos.accuracy.isFinite ||
          pos.accuracy <= 0) {
        return null;
      }
      return LocationFix(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
      );
    } catch (_) {
      return null;
    }
  }
}
