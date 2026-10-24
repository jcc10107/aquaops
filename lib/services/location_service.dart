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
  static const Map<String, String> _headers = {
    'User-Agent': 'AquaOps/1.0',
  };

  /// Raw GPS fix only (permission-checked).
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = true;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = true;
    }

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

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

  /// Fetches polyline road route coordinates between two points via OSRM.
  Future<List<LatLng>> fetchRouteCoordinates(LatLng start, LatLng end) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson',
    );
    try {
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return const [];

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return const [];

      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null) return const [];

      return coordinates.map((coord) {
        final pair = coord as List;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Reverse geocodes coordinates to a human-readable address.
  Future<String> reverseGeocode(double lat, double lng) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=0',
    );
    try {
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['display_name'] as String?) ?? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    } catch (_) {
      return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
  }

  /// Forward geocodes an address string to coordinates.
  Future<LatLng?> forwardGeocode(String address) async {
    if (address.trim().isEmpty) return null;
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(address)}&limit=1',
    );
    try {
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
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

  /// Calculates driving distance in kilometers between station and destination.
  Future<double?> getRoadDistanceKm({required double destLat, required double destLng}) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '$stationLng,$stationLat;'
          '$destLng,$destLat'
          '?overview=false',
    );
    try {
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
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

  /// Resolves destination coordinates from lat/lng or address fallback.
  Future<LatLng?> resolveDestination({double? lat, double? lng, String? address}) async {
    if (lat != null && lng != null) return LatLng(lat, lng);
    if (address != null && address.trim().isNotEmpty) {
      return forwardGeocode(address);
    }
    return null;
  }
}