import 'package:geolocator/geolocator.dart';

class CurrentLocationData {
  const CurrentLocationData({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  LocationService._();

  static Future<CurrentLocationData> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Turn on location services to sort posts by distance.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission is needed to show nearby test centres.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return CurrentLocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static double distanceInMiles({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const metersPerMile = 1609.344;
    final meters = Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
    return meters / metersPerMile;
  }

  static String formatDistanceMiles(double miles) {
    if (miles < 10) return '${miles.toStringAsFixed(1)} mi';
    return '${miles.round()} mi';
  }
}
