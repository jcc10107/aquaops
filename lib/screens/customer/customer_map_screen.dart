import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/messaging_service.dart';
import '../messaging/chat_conversation_screen.dart';

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
  final MessagingService _messagingService = MessagingService();

  static const LatLng _station = LatLng(stationLat, stationLng);
  static const String _font = 'Plus Jakarta Sans';

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

  Future<void> _openDeliveryChat() async {
    try {
      final convo = await _messagingService.getOrCreateDeliveryConversation(order: widget.order);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatConversationScreen(conversation: convo)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e'), backgroundColor: AppColors.coralAlert),
      );
    }
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
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }

  String _getRiderName() {
    if (widget.order.assignedRiderName != null &&
        widget.order.assignedRiderName!.trim().isNotEmpty) {
      return widget.order.assignedRiderName!.trim();
    }
    return 'Arnel Bautista';
  }

  String _getRiderInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'AB';
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalGallons = widget.order.items.fold(
      0,
          (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummaryCard(),
                        const SizedBox(height: 14),
                        _buildMapSection(),
                        const SizedBox(height: 14),
                        _buildRiderCard(),
                        const SizedBox(height: 14),
                        _buildOrderManifestCard(totalGallons),
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

  Widget _buildHeader() {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: AppColors.sky50,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back, size: 20, color: AppColors.primarySky),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Order Tracking',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order #${widget.order.orderNumber} • Real-Time Route',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return _buildCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.sky50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primarySky),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${widget.order.orderNumber}',
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.sky200),
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
                            color: AppColors.primarySky,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyanElectric.withValues(
                                  alpha: _pulseController.value,
                                ),
                                blurRadius: 4 * _pulseController.value,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _etaMinutes != null ? '~$_etaMinutes MINS ETA' : 'ETA IN TRANSIT',
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySky,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primarySky),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.order.deliveryAddress ?? 'Delivery address not provided',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double mapWidth = constraints.maxWidth;
        final double mapHeight = (mapWidth * 0.72).clamp(280.0, 420.0);
        final destination = _destination;

        return Container(
          width: mapWidth,
          height: mapHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: StreamBuilder<OrderModel?>(
                    stream: _firestoreService.watchOrder(widget.order.id),
                    builder: (context, liveOrderSnapshot) {
                      final liveOrder = liveOrderSnapshot.data;
                      final riderLat = liveOrder?.riderLat;
                      final riderLng = liveOrder?.riderLng;
                      final hasLiveRider = riderLat != null && riderLng != null;
                      final riderPoint = hasLiveRider ? LatLng(riderLat, riderLng) : null;

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
                                Polyline(
                                  points: _routePoints,
                                  strokeWidth: 4.5,
                                  color: AppColors.primarySky,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _station,
                                width: 90,
                                height: 70,
                                child: _buildLocationMarker(
                                  label: 'Station',
                                  icon: Icons.water_drop,
                                  color: AppColors.primarySky,
                                ),
                              ),
                              if (destination != null)
                                Marker(
                                  point: destination,
                                  width: 90,
                                  height: 70,
                                  child: _buildLocationMarker(
                                    label: 'Your Home',
                                    icon: Icons.home,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              if (riderPoint != null)
                                Marker(
                                  point: riderPoint,
                                  width: 60,
                                  height: 60,
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
                        CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                        SizedBox(height: 8),
                        Text(
                          'Calculating route…',
                          style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else if (_routeError != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Text(
                        _routeError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                // Controls in Upper Right Stack
                Positioned(
                  right: 10,
                  top: 10,
                  child: Column(
                    children: [
                      _buildMapIconButton(
                        icon: Icons.my_location,
                        onPressed: _fitRoute,
                        color: AppColors.primarySky,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.slate200),
                          boxShadow: const [
                            BoxShadow(color: Color(0x140F172A), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(Icons.add, size: 18, color: AppColors.textLight),
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            Container(width: 24, height: 1, color: AppColors.slate100),
                            IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(Icons.remove, size: 18, color: AppColors.textLight),
                              constraints: const BoxConstraints(minWidth: 38, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Distance Label in Lower Left
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _distanceKm != null
                              ? '${_distanceKm!.toStringAsFixed(1)} km delivery route'
                              : (_routeError ?? 'Route in progress'),
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
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

  Widget _buildMapIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildRiderMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double pulse = _pulseController.value;
            return Container(
              width: 40 + (12 * pulse),
              height: 40 + (12 * pulse),
              decoration: BoxDecoration(
                color: AppColors.primarySky.withValues(alpha: 0.3 * (1 - pulse)),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySky,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildRiderCard() {
    final riderName = _getRiderName();
    final initials = _getRiderInitials(riderName);

    return _buildCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.sky50,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: _font,
                        color: AppColors.primarySky,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riderName,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Assigned Delivery Rider',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'On Delivery',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _openDeliveryChat,
              icon: const Icon(Icons.chat_outlined, size: 16),
              label: const Text(
                'Send Message',
                style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primarySky,
                side: const BorderSide(color: AppColors.slate200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderManifestCard(int totalGallons) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Manifest',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.order.paymentMethod == PaymentMethod.gcash
                      ? 'Paid • GCash'
                      : 'Cash on Delivery',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.order.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontFamily: _font,
                              color: AppColors.primarySky,
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
                            style: const TextStyle(
                              fontFamily: _font,
                              color: AppColors.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₱${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: _font,
                      color: AppColors.textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (totalGallons > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sky50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.sky200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horizontal_circle, size: 18, color: AppColors.primarySky),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$totalGallons sanitized empty container(s) to surrender upon delivery.',
                      style: const TextStyle(
                        fontFamily: _font,
                        color: AppColors.primarySky,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontFamily: _font,
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₱${widget.order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: _font,
                  color: AppColors.primarySky,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}