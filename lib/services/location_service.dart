import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/zones.dart';

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

  // The reverse of reverseGeocode(): turns a free-text address into
  // coordinates, for orders that only have a typed/picked text address and
  // no precise lat/lng on file. Same "best effort, never throws" philosophy
  // as reverseGeocode — returns null on any failure so callers can fall
  // back gracefully instead of crashing.
  Future<LatLng?> forwardGeocode(String address) async {
    if (address.trim().isEmpty) return null;
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(address)}&limit=1',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  // Real road-network distance (not straight-line) from the station to a
  // destination, via OSRM's free routing API — same service already used by
  // the Live Order Tracking map. Used for distance-based delivery fee
  // calculation. Never throws — returns null on any failure (network,
  // no route found) so callers can fall back to a base-fee-only charge
  // instead of blocking checkout.
  Future<double?> getRoadDistanceKm({required double destLat, required double destLng}) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$stationLng,$stationLat;'
      '$destLng,$destLat'
      '?overview=false',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final distanceMeters = (route['distance'] as num).toDouble();
      return distanceMeters / 1000;
    } catch (_) {
      return null;
    }
  }

  // Resolves a destination LatLng the same way across every screen that
  // needs one from an order/checkout's lat/lng-or-text-address shape:
  // prefer precise coordinates if present, else forward-geocode the text.
  Future<LatLng?> resolveDestination({double? lat, double? lng, String? address}) async {
    if (lat != null && lng != null) return LatLng(lat, lng);
    if (address != null && address.trim().isNotEmpty) {
      return forwardGeocode(address);
    }
    return null;
  }
}
