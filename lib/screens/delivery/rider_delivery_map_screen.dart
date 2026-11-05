import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../models/order_model.dart';
import '../../services/location_service.dart';
import 'fulfill_delivery_screen.dart';

class RiderDeliveryMapScreen extends StatefulWidget {
  final OrderModel order;

  const RiderDeliveryMapScreen({
    super.key,
    required this.order,
  });

  @override
  State<RiderDeliveryMapScreen> createState() => _RiderDeliveryMapScreenState();
}

class _RiderDeliveryMapScreenState extends State<RiderDeliveryMapScreen> {
  static const String _font = 'Plus Jakarta Sans';
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  static const LatLng _station = LatLng(stationLat, stationLng);
  // Default fallback center for San Pablo City
  static const LatLng _sanPabloCenter = LatLng(14.0683, 121.3256);

  LatLng? _riderPos;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  int? _etaMinutes;

  bool _loading = true;
  bool _locating = false;
  bool _isApproximateLocation = false;
  bool _navigationStarted = false;
  String? _statusMessage;

  // Keeps this screen's own position live without the rider having to tap
  // "recenter" themselves — ticks every 20s; every 3rd tick (~60s) also
  // re-fetches the OSRM route/ETA, since re-requesting the free public
  // OSRM instance every 20s is unnecessary (the road itself doesn't
  // change, only the rider's progress along it) and risks rate limits.
  Timer? _autoRefreshTimer;
  int _autoRefreshTicks = 0;

  @override
  void initState() {
    super.initState();
    _initializeRoute();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _autoRefresh());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _autoRefresh() async {
    if (!mounted || _loading) return;
    _autoRefreshTicks++;
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _riderPos = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // Silent — this is a background refresh, not a user-initiated action;
      // the manual recenter button still shows its own error if tapped.
      return;
    }
    if (_autoRefreshTicks % 3 == 0) {
      await _refreshRouteAndEta();
    }
  }

  Future<void> _refreshRouteAndEta() async {
    final start = _riderPos;
    final dest = _destination;
    if (start == null || dest == null) return;
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${dest.longitude},${dest.latitude}'
            '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = (geometry['coordinates'] as List)
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();
      final durationSeconds = (route['duration'] as num).toDouble();
      if (!mounted) return;
      setState(() {
        _routePoints = coords;
        _etaMinutes = (durationSeconds / 60).ceil();
      });
    } catch (_) {
      // Stale route/ETA is better than none — just keep what we had.
    }
  }

  Future<void> _initializeRoute() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Resolving delivery location...';
    });

    try {
      // 1. Get current rider GPS position
      try {
        final pos = await _locationService.getCurrentPosition();
        _riderPos = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        _riderPos = _station;
      }

      // 2. Resolve customer destination with multi-tier fallback
      LatLng? destination;
      bool approximate = false;

      // Tier A: Check if order already has saved coordinates
      if (widget.order.deliveryLat != null && widget.order.deliveryLng != null) {
        destination = LatLng(widget.order.deliveryLat!, widget.order.deliveryLng!);
      }

      // Tier B: Try geocoding full delivery address
      if (destination == null && widget.order.deliveryAddress != null && widget.order.deliveryAddress!.trim().isNotEmpty) {
        destination = await _locationService.resolveDestination(
          address: widget.order.deliveryAddress,
        );
      }

      // Tier C: Fallback to Barangay / Zone if specific street was unresolvable
      if (destination == null && widget.order.areaZone.trim().isNotEmpty) {
        final zoneName = zoneLabel(widget.order.areaZone);
        destination = await _locationService.resolveDestination(
          address: '$zoneName, San Pablo City, Laguna',
        );
        approximate = true;
      }

      // Tier D: Safe fallback to San Pablo City center
      if (destination == null) {
        destination = _sanPabloCenter;
        approximate = true;
      }

      _destination = destination;
      _isApproximateLocation = approximate;

      // 3. Request OSRM road route
      final start = _riderPos ?? _station;
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coords = (geometry['coordinates'] as List)
              .map((c) => LatLng((c as List)[1] as double, c[0] as double))
              .toList();
          final durationSeconds = (route['duration'] as num).toDouble();

          _routePoints = coords;
          _etaMinutes = (durationSeconds / 60).ceil();
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    }
  }

  void _fitRoute() {
    final dest = _destination ?? _sanPabloCenter;
    final rider = _riderPos ?? _station;

    final bounds = LatLngBounds.fromPoints(
      _routePoints.isNotEmpty ? _routePoints : [rider, dest],
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Future<void> _recenterRiderGps() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      final current = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _riderPos = current;
        _locating = false;
      });
      _mapController.move(current, 18);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your current GPS location.')),
      );
    }
  }

  // Stays entirely in-app — the live map above this button (with
  // auto-refreshing position/route from _autoRefresh) IS the navigation
  // view. This just forces an immediate refresh instead of waiting for
  // the next 20s tick, re-centers on the rider, and gives clear
  // confirmation that the customer can now see them moving. No hand-off
  // to an external maps app.
  Future<void> _startInAppNavigation() async {
    setState(() => _navigationStarted = true);
    await _autoRefresh();
    if (!mounted) return;
    if (_riderPos != null) {
      _mapController.move(_riderPos!, 17);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation started — the customer can now see your live location.')),
    );
  }

  Future<void> _callCustomer() async {
    final phone = widget.order.customerPhone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number not available.')),
      );
      return;
    }
    final telUri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dial $phone')),
      );
    }
  }

  Future<void> _messageCustomer() async {
    final phone = widget.order.customerPhone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number not available.')),
      );
      return;
    }
    final smsUri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open SMS for $phone')),
      );
    }
  }

  void _proceedToFulfillment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FulfillDeliveryScreen(order: widget.order),
      ),
    );
  }

  Widget _buildMapButton({
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
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
            )
                : Icon(icon, size: 20, color: AppColors.textLight),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final totalUnits = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          // 1. Edge-to-Edge Map View
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _destination ?? _station,
              initialZoom: 16,
              maxZoom: 19.5,
              minZoom: 4,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aquaops.app',
                maxNativeZoom: 19,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: AppColors.primarySky,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Rider Marker
                  if (_riderPos != null)
                    Marker(
                      point: _riderPos!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primarySky,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0x2E0284C7), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
                      ),
                    ),
                  // Destination Marker
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 50,
                      height: 50,
                      child: const FractionalTranslation(
                        translation: Offset(0, -0.4),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.coralAlert,
                          size: 42,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Floating Top Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildMapButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.slate200),
                          boxShadow: const [
                            BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${order.orderNumber}',
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            if (_etaMinutes != null) ...[
                              const SizedBox(width: 8),
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.slate400, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(
                                '~$_etaMinutes mins ETA',
                                style: const TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primarySky,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Status Pill in Map Center
          if (_loading || _statusMessage != null || _isApproximateLocation)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: const [
                      BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_loading) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage ?? 'Calculating route...',
                          style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ] else if (_isApproximateLocation) ...[
                        const Icon(Icons.info_outline, size: 14, color: AppColors.primarySky),
                        const SizedBox(width: 6),
                        const Text(
                          'Route to Barangay area (Address passed to GPS)',
                          style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // 4. Right Map Controls
          Positioned(
            right: 16,
            bottom: 270,
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
                      _buildMapButton(
                        icon: Icons.my_location,
                        onPressed: _recenterRiderGps,
                        isLoading: _locating,
                      ),
                      const SizedBox(height: 8),
                      _buildMapButton(
                        icon: Icons.zoom_out_map,
                        onPressed: _fitRoute,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Bottom Delivery Information & Action Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Color(0x1F0F172A), blurRadius: 20, offset: Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.slate200,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),

                      // Customer row & phone action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.deliveryAddress ?? 'No address provided',
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _callCustomer,
                                icon: const Icon(Icons.phone, color: AppColors.primarySky, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.sky50,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: _messageCustomer,
                                icon: const Icon(Icons.sms, color: AppColors.primarySky, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.sky50,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.slate100),
                      const SizedBox(height: 10),

                      // Manifest summary row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalUnits items • ₱${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.isPaid ? AppColors.emerald50 : AppColors.amber50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.isPaid ? 'Paid via ${order.paymentMethod.name.toUpperCase()}' : 'Cash on Delivery',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: order.isPaid ? AppColors.emerald700 : AppColors.amber700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Two Main Action Buttons
                      Row(
                        children: [
                          // 1. Launch Turn-by-Turn GPS navigation
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _navigationStarted ? null : _startInAppNavigation,
                                icon: Icon(_navigationStarted ? Icons.navigation : Icons.navigation_outlined, size: 18),
                                label: Text(
                                  _navigationStarted ? 'Navigating…' : 'Start Navigation',
                                  style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primarySky,
                                  side: const BorderSide(color: AppColors.primarySky, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 2. Open Fulfillment Screen
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _proceedToFulfillment,
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Fulfill Order', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primarySky,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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