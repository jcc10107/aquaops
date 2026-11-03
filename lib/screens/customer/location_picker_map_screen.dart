import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../services/location_service.dart';

// An interactive "pin on map" picker: the map pans freely beneath a fixed
// center pin, and confirming reverse-geocodes the exact coordinate beneath the pin tip.
class LocationPickerMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerMapScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<LocationPickerMapScreen> createState() =>
      _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  static const String _font = 'Plus Jakarta Sans';
  late final MapController _mapController;
  late LatLng _center;
  final LocationService _locationService = LocationService();
  bool _confirming = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = LatLng(widget.initialLat, widget.initialLng);
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      final address = await _locationService.reverseGeocode(
        _center.latitude,
        _center.longitude,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        PreciseLocation(
          latitude: _center.latitude,
          longitude: _center.longitude,
          address: address,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not resolve this location. Please try again: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _zoomBy(double delta) {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + delta,
    );
  }

  Future<void> _recenterOnGps() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _locating = false);
      _mapController.move(LatLng(position.latitude, position.longitude), 18.5);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not obtain current GPS location.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _roundMapButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primarySky,
              ),
            )
                : Icon(icon, size: 20, color: AppColors.textLight),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          // 1. Edge-to-Edge Interactive Map
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aquaops.app',
                maxNativeZoom: 19,
              ),
            ],
          ),

          // 2. Fixed Center Pin (Anchor point perfectly aligned to center coordinate)
          IgnorePointer(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle ground shadow anchor dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Pin tip rests directly at the exact center
                  FractionalTranslation(
                    translation: const Offset(0, -0.5),
                    child: const Icon(
                      Icons.location_on,
                      size: 44,
                      color: AppColors.primarySky,
                      shadows: [
                        Shadow(
                          color: Color(0x330284C7),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Header (Back Button)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _roundMapButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Map Action Controls (Zoom in, Zoom out, GPS recenter)
          Positioned(
            right: 16,
            bottom: 210, // Positioned safely above the bottom sheet
            child: SafeArea(
              top: false,
              bottom: false,
              child: Align(
                alignment: Alignment.bottomRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roundMapButton(
                        icon: Icons.add,
                        onPressed: () => _zoomBy(1),
                      ),
                      const SizedBox(height: 8),
                      _roundMapButton(
                        icon: Icons.remove,
                        onPressed: () => _zoomBy(-1),
                      ),
                      const SizedBox(height: 10),
                      _roundMapButton(
                        icon: Icons.my_location,
                        onPressed: _recenterOnGps,
                        isLoading: _locating,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Dedicated Delivery Location Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F0F172A),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle Indicator
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppColors.slate200,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),

                        // Title & Icon Row
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.sky50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pin_drop,
                                size: 18,
                                color: AppColors.primarySky,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Choose delivery location',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Helper Instruction
                        const Padding(
                          padding: EdgeInsets.only(left: 42),
                          child: Text(
                            'Move the map until the pin is directly over your exact delivery address.',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Confirmation Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _confirming ? null : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySky,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _confirming
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Confirm This Location',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}