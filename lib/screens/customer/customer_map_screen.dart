import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';

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
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 2.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 2.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
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
            constraints: const BoxConstraints(maxWidth: 450),
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
                                          '8-12 MINS ETA',
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
                  child: ClipRect(
                    child: Transform.scale(
                      scale: _zoomLevel,
                      child: CustomPaint(
                        painter: _MapPainter(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: mapWidth * 0.11,
                  top: mapHeight * 0.17,
                  child: _buildLocationMarker(
                    label: 'Hub San Antonio',
                    icon: Icons.water_drop,
                    color: const Color(0xFF0284C7),
                  ),
                ),
                Positioned(
                  left: mapWidth * 0.60,
                  top: mapHeight * 0.40,
                  child: _buildRiderMarker(),
                ),
                Positioned(
                  left: mapWidth * 0.82,
                  top: mapHeight * 0.63,
                  child: _buildLocationMarker(
                    label: 'Client Home',
                    icon: Icons.home,
                    color: const Color(0xFF006C49),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'recenter',
                        onPressed: _resetZoom,
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
                      FloatingActionButton.small(
                        heroTag: 'fit',
                        onPressed: _resetZoom,
                        backgroundColor:
                        Colors.white.withValues(alpha: 0.94),
                        elevation: 4,
                        child: const Icon(
                          Icons.polyline,
                          color: Color(0xFF707881),
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
                          '1.4 km remaining • Batch #04',
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
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: Column(
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
      ),
    );
  }

  Widget _buildRiderMarker() {
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: Column(
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
                  '28 km/h',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0284C7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• On Route',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF3F4850),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
      ),
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double designWidth = 400;
    const double designHeight = 380;

    final double scaleX = size.width / designWidth;
    final double scaleY = size.height / designHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFEAEDFF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Paint gridSubPaint = Paint()
      ..color = const Color(0xFFF2F3FF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < designWidth; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, designHeight),
        gridPaint,
      );

      canvas.drawLine(
        Offset(i + 20, 0),
        Offset(i + 20, designHeight),
        gridSubPaint,
      );
    }

    for (double i = 0; i < designHeight; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(designWidth, i),
        gridPaint,
      );

      canvas.drawLine(
        Offset(0, i + 20),
        Offset(designWidth, i + 20),
        gridSubPaint,
      );
    }

    final Paint riverBgPaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint riverDashPaint = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final Path riverPath = Path()
      ..moveTo(-20, 180)
      ..cubicTo(
        80,
        190,
        140,
        240,
        240,
        220,
      )
      ..cubicTo(
        310,
        205,
        350,
        260,
        420,
        250,
      );

    canvas.drawPath(
      riverPath,
      riverBgPaint,
    );

    double dashWidth = 10;
    double dashSpace = 6;
    double distance = 0;

    for (final PathMetric metric in riverPath.computeMetrics()) {
      while (distance < metric.length) {
        final Path segment = metric.extractPath(
          distance,
          distance + dashWidth,
        );

        canvas.drawPath(
          segment,
          riverDashPaint,
        );

        distance += dashWidth + dashSpace;
      }

      distance = 0;
    }

    final Paint roadPaint = Paint()
      ..color = const Color(0xFFDAE2FD)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(40, 0),
      const Offset(40, designHeight),
      roadPaint,
    );

    canvas.drawLine(
      const Offset(160, 0),
      const Offset(160, designHeight),
      roadPaint,
    );

    canvas.drawLine(
      const Offset(320, 0),
      const Offset(320, designHeight),
      roadPaint,
    );

    canvas.drawLine(
      const Offset(0, 80),
      const Offset(designWidth, 80),
      roadPaint,
    );

    canvas.drawLine(
      const Offset(0, 280),
      const Offset(designWidth, 280),
      roadPaint,
    );

    canvas.drawLine(
      const Offset(0, 360),
      const Offset(designWidth, 360),
      roadPaint,
    );

    final Paint highwayBgPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final Paint highwayPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final Path highwayPath = Path()
      ..moveTo(10, 60)
      ..quadraticBezierTo(
        140,
        110,
        220,
        160,
      )
      ..quadraticBezierTo(
        300,
        250,
        380,
        340,
      );

    canvas.drawPath(
      highwayPath,
      highwayBgPaint,
    );

    canvas.drawPath(
      highwayPath,
      highwayPaint,
    );

    final Paint routeGlowPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(
        alpha: 0.25,
      )
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Paint routeLinePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path routePath = Path()
      ..moveTo(64, 88)
      ..lineTo(112, 88)
      ..lineTo(160, 140)
      ..lineTo(228, 140)
      ..lineTo(280, 240)
      ..lineTo(332, 272);

    canvas.drawPath(
      routePath,
      routeGlowPaint,
    );

    distance = 0;
    dashWidth = 8;
    dashSpace = 5;

    for (final PathMetric metric in routePath.computeMetrics()) {
      while (distance < metric.length) {
        final Path segment = metric.extractPath(
          distance,
          distance + dashWidth,
        );

        canvas.drawPath(
          segment,
          routeLinePaint,
        );

        distance += dashWidth + dashSpace;
      }

      distance = 0;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}