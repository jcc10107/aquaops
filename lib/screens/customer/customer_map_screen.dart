import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/zones.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class CustomerMapScreen extends StatefulWidget {
  final OrderModel order;

  const CustomerMapScreen({
    super.key,
    required this.order,
  });

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  static const LatLng _station = LatLng(stationLat, stationLng);

  bool _loadingRoute = true;
  String? _routeError;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  double? _distanceKm;
  int? _etaMinutes;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadRoute();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    try {
      final destination = await _locationService.resolveDestination(
        lat: widget.order.deliveryLat,
        lng: widget.order.deliveryLng,
        address: widget.order.deliveryAddress,
      );

      if (destination == null) {
        if (!mounted) return;
        setState(() {
          _loadingRoute = false;
          _routeError = 'Exact delivery location unavailable';
        });
        return;
      }

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_station.longitude},${_station.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Routing service returned ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No route found');
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = (geometry['coordinates'] as List)
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();
      final distanceMeters = (route['distance'] as num).toDouble();
      final durationSeconds = (route['duration'] as num).toDouble();

      if (!mounted) return;
      setState(() {
        _destination = destination;
        _routePoints = coords;
        _distanceKm = distanceMeters / 1000;
        _etaMinutes = (durationSeconds / 60).ceil();
        _loadingRoute = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = 'Could not load the delivery route.';
      });
    }
  }

  void _fitRoute() {
    final destination = _destination;
    if (destination == null) {
      _mapController.move(_station, 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(
      _routePoints.isNotEmpty ? _routePoints : [_station, destination],
    );
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)));
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final int totalGallons = widget.order.items.fold(
      0,
          (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFC),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAFC).withValues(alpha: 0.96),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF131B2E),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Order Tracking',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF131B2E),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'REAL-TIME DELIVERY ROUTE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0284C7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 24,
                      right: 24,
                      bottom: 130,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Text(
                                          'ORDER',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF3F4850),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            widget.order.orderNumber,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF131B2E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9FF),
                                      borderRadius:
                                      BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                const Color(0xFF0284C7),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                    const Color(0xFF06B6D4)
                                                        .withValues(
                                                      alpha:
                                                      _pulseController.value,
                                                    ),
                                                    blurRadius: 6 *
                                                        _pulseController.value,
                                                    spreadRadius: 2 *
                                                        _pulseController.value,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _etaMinutes != null ? '~$_etaMinutes MINS ETA' : '— MINS ETA',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0284C7),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE0F2FE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.order.deliveryAddress ??
                                            'Unknown Address',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF3F4850),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMap(),
                        const SizedBox(height: 12),
                        _buildRiderCard(),
                        const SizedBox(height: 12),
                        _buildOrderManifest(totalGallons),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double mapWidth = constraints.maxWidth;
        final double mapHeight = mapWidth * 0.95;
        final destination = _destination;

        return Container(
          width: mapWidth,
          height: mapHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: StreamBuilder<OrderModel?>(
                    stream: _firestoreService.watchOrder(widget.order.id),
                    builder: (context, liveOrderSnapshot) {
                      final liveOrder = liveOrderSnapshot.data;
                      final riderLat = liveOrder?.riderLat;
                      final riderLng = liveOrder?.riderLng;
                      final hasLiveRiderPosition = riderLat != null && riderLng != null;
                      final riderPoint = hasLiveRiderPosition ? LatLng(riderLat, riderLng) : null;

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: destination ?? _station,
                          initialZoom: 15,
                          maxZoom: 19,
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
                                Polyline(points: _routePoints, strokeWidth: 5, color: const Color(0xFF0284C7)),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _station,
                                width: 90,
                                height: 70,
                                child: _buildLocationMarker(
                                  label: 'Water Station',
                                  icon: Icons.water_drop,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                              if (destination != null)
                                Marker(
                                  point: destination,
                                  width: 90,
                                  height: 70,
                                  child: _buildLocationMarker(
                                    label: 'Client Home',
                                    icon: Icons.home,
                                    color: const Color(0xFF006C49),
                                  ),
                                ),
                              // Only shown once the rider's device has actually
                              // broadcast a real GPS fix — never the old fake
                              // midpoint placeholder, so a visible marker here
                              // always means a genuinely live position.
                              if (riderPoint != null)
                                Marker(
                                  point: riderPoint,
                                  width: 70,
                                  height: 70,
                                  child: _buildRiderMarker(),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_loadingRoute)
                  Container(
                    color: Colors.white.withValues(alpha: 0.85),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0284C7)),
                        SizedBox(height: 10),
                        Text('Calculating route…', style: TextStyle(fontSize: 12, color: Color(0xFF3F4850))),
                      ],
                    ),
                  )
                else if (_routeError != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(
                        _routeError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3F4850)),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'recenter',
                        onPressed: _fitRoute,
                        backgroundColor:
                        Colors.white.withValues(alpha: 0.94),
                        elevation: 4,
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF131B2E),
                                size: 18,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 40,
                              ),
                            ),
                            IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(
                                Icons.remove,
                                color: Color(0xFF131B2E),
                                size: 18,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF4EDEA3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _distanceKm != null
                              ? '${_distanceKm!.toStringAsFixed(1)} km route • Order ${widget.order.orderNumber}'
                              : (_routeError ?? 'Calculating route…'),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF131B2E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationMarker({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: color == const Color(0xFF006C49)
                ? const Color(0xFF006C49)
                : const Color(0xFF283044),
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt,
                  size: 14,
                  color: Color(0xFF14B8A6),
                ),
                const SizedBox(width: 4),
                Text(
                  'On Route',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0284C7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final double pulse = _pulseController.value;

                  return Container(
                    width: 48 + (16 * pulse),
                    height: 48 + (16 * pulse),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(
                        alpha: 0.3 * (1 - pulse),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
    );
  }

  Widget _buildRiderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'AB',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arnel Bautista',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF131B2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Delivery Rider',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF3F4850),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'ACTIVE RUN',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0284C7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.chat_bubble,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Send Message',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 4,
                shadowColor: const Color(0x590284C7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderManifest(int totalGallons) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Order Manifest',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF131B2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FFBBE),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.order.paymentMethod == PaymentMethod.gcash
                      ? 'Paid • GCash'
                      : 'Cash on Delivery',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF002113),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.order.items.map(
                (item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0F2FE),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}x',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF131B2E),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₱${item.totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF131B2E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (totalGallons > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horizontal_circle,
                      size: 18,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Container Exchange Ready',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalGallons'
                              'x empty sanitized gallon bottles to surrender',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF3F4850),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Due',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF3F4850),
                  fontSize: 13,
                ),
              ),
              Text(
                '₱${widget.order.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0284C7),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
