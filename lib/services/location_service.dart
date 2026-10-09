import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PreciseLocation {
  final double latitude;
  final double longitude;
  final String address;

  PreciseLocation({required this.latitude, required this.longitude, required this.address});
}

class LocationService {
  // Raw GPS fix only (permission-checked) — used to center the map picker
  // on the device's real position before the person fine-tunes the pin.
  Future<Position> getCurrentPosition() async {
    // Skipped on platforms (e.g. some web browsers) where this check isn't
    // supported — getCurrentPosition() below still fails clearly on its own
    // if location is genuinely unavailable, so this is a best-effort guard.
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
    } catch (_) {}

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable it in your browser/phone settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 20));
  }

  // Turns coordinates into a readable address via OpenStreetMap's free
  // Nominatim API (no key or billing needed — same reasoning as using
  // Cloudinary instead of Firebase Storage elsewhere in this app).
  Future<String> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=0',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['display_name'] as String?) ?? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    } catch (_) {
      // Reverse geocoding is a convenience, not a requirement — the raw
      // coordinates are still accurate even if we can't name the street.
      return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
  }
}
