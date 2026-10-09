import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/location_service.dart';

// A Shopee-style "pin on map" picker: the map pans freely while a pin stays
// fixed at the screen center, and confirming reverse-geocodes whatever
// coordinate is currently under that pin. Uses OpenStreetMap tiles — free,
// no API key or billing account needed, same reasoning as Cloudinary/Nominatim
// elsewhere in this app.
class LocationPickerMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerMapScreen({super.key, required this.initialLat, required this.initialLng});

  @override
  State<LocationPickerMapScreen> createState() => _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  late final MapController _mapController;
  late LatLng _center;
  final LocationService _locationService = LocationService();
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = LatLng(widget.initialLat, widget.initialLng);
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final address = await _locationService.reverseGeocode(_center.latitude, _center.longitude);
      if (!mounted) return;
      Navigator.pop(context, PreciseLocation(latitude: _center.latitude, longitude: _center.longitude, address: address));
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resolve that location: $e')),
      );
    }
  }

  void _zoomBy(double delta) {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + delta);
  }

  Future<void> _recenterOnGps() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      _mapController.move(LatLng(position.latitude, position.longitude), 19);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get your location: $e')),
      );
    }
  }

  Widget _roundButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(icon: Icon(icon), onPressed: onPressed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 18,
              maxZoom: 19.5,
              minZoom: 4,
              onPositionChanged: (position, hasGesture) {
                _center = position.center;
              },
            ),
            children: [
              // Standard OpenStreetMap tiles — genuinely free, no API key
              // or account required (CartoDB's basemaps now require one).
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aquaops.app',
                maxNativeZoom: 19,
              ),
            ],
          ),
          // Fixed center pin — the map moves underneath it, not the other way around.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 44, color: Color(0xFF0284C7)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _roundButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 110,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _roundButton(icon: Icons.add, onPressed: () => _zoomBy(1)),
                  const SizedBox(height: 8),
                  _roundButton(icon: Icons.remove, onPressed: () => _zoomBy(-1)),
                  const SizedBox(height: 8),
                  _roundButton(icon: Icons.my_location, onPressed: _recenterOnGps),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirming ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: _confirming
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm This Location', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
