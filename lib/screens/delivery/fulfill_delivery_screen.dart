import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../models/order_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../../services/offline_queue_service.dart';
import 'rider_delivery_map_screen.dart';

class FulfillDeliveryScreen extends StatefulWidget {
  final OrderModel order;
  const FulfillDeliveryScreen({super.key, required this.order});

  @override
  State<FulfillDeliveryScreen> createState() => _FulfillDeliveryScreenState();
}

class _FulfillDeliveryScreenState extends State<FulfillDeliveryScreen> {
  static const String _font = 'Plus Jakarta Sans';

  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final MessagingService _messagingService = MessagingService();
  final OfflineQueueService _offlineQueue = OfflineQueueService();

  late int droppedOff;
  late int emptyCollected;
  bool paymentConfirmed = true;
  bool isSubmitting = false;
  late String paymentMethod;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _recipientCtrl = TextEditingController();
  Uint8List? _podPhotoBytes;
  DateTime? _podTime;

  @override
  void initState() {
    super.initState();
    droppedOff = widget.order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    emptyCollected = droppedOff;
    paymentMethod = widget.order.paymentMethod == PaymentMethod.gcash ? 'gcash' : 'cash';
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _callCustomer() async {
    final phone = widget.order.customerPhone.trim();
    if (phone.isEmpty) return;
    final telUri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  Future<void> _messageCustomer() async {
    final phone = widget.order.customerPhone.trim();
    if (phone.isEmpty) return;
    final smsUri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (shot == null) return;
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      setState(() {
        _podPhotoBytes = bytes;
        _podTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _submitFulfillment() async {
    if (!paymentConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please certify drop-off and payment verification below.')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      String? podUrl;
      if (_podPhotoBytes != null) {
        podUrl = await _cloudinary.uploadImage(
          _podPhotoBytes!,
          filename: 'proof_of_delivery.jpg',
          folder: 'proof_of_delivery',
        );
      }
      await _firestoreService.fulfillDelivery(
        orderId: widget.order.id,
        customerId: widget.order.customerId ?? '',
        gallonsDelivered: droppedOff,
        emptyReturned: emptyCollected,
        paymentMethod: paymentMethod,
        proofOfDeliveryUrl: podUrl,
        recipientName: _recipientCtrl.text.trim().isEmpty ? null : _recipientCtrl.text.trim(),
      );
      // Best-effort — a delivery chat that fails to lock here still gets
      // synced read-only the next time anyone opens it (see
      // getOrCreateDeliveryConversation), so this is never load-bearing.
      unawaited(_messagingService.lockDeliveryConversationAsCompleted(widget.order.id));
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Delivery Completed Successfully!')));
    } catch (e) {
      try {
        await _offlineQueue.queue(
          orderId: widget.order.id,
          customerId: widget.order.customerId ?? '',
          gallonsDelivered: droppedOff,
          emptyReturned: emptyCollected,
          paymentMethod: paymentMethod,
          recipientName: _recipientCtrl.text.trim().isEmpty ? null : _recipientCtrl.text.trim(),
          photoBytes: _podPhotoBytes,
          orderNumber: widget.order.orderNumber,
          customerName: widget.order.customerName,
          deliveryAddress: widget.order.deliveryAddress,
        );
        if (!mounted) return;
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Saved offline — will sync automatically once back online.'),
            backgroundColor: AppColors.primarySky,
          ),
        );
      } catch (queueError) {
        if (!mounted) return;
        setState(() => isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to complete delivery: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _fmtTime(DateTime t) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${t.month}/${t.day}/${t.year} at ${p(t.hour)}:${p(t.minute)}';
  }

  Widget _buildSectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
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
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Responsive tablet constraint
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Banner
                  _buildStatusBanner(),
                  const SizedBox(height: 14),

                  // 2. Customer Information
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 14),

                  // 3. Map Navigation Card
                  _buildMapNavigationCard(),
                  const SizedBox(height: 14),

                  // 4. Order Summary
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 14),

                  // 5. Delivery Details (Quantities)
                  _buildDeliveryDetailsCard(),
                  const SizedBox(height: 14),

                  // 6. Recipient (Optional)
                  _buildRecipientCard(),
                  const SizedBox(height: 14),

                  // 7. Proof of Delivery Photo
                  _buildProofOfDeliveryCard(),
                  const SizedBox(height: 14),

                  // Certification checkbox
                  _buildCertificationCheckbox(),
                  const SizedBox(height: 18),

                  // 8. Complete Delivery Button
                  _buildCompleteDeliveryButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 1. HEADER & STATUS
  // ========================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: 64,
      iconTheme: const IconThemeData(color: AppColors.textLight),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fulfill Delivery',
            style: TextStyle(
              fontFamily: _font,
              color: AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Order #${widget.order.orderNumber}',
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emerald200),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 18, color: AppColors.emerald700),
              SizedBox(width: 8),
              Text(
                'Out for Delivery',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald700,
                ),
              ),
            ],
          ),
          Text(
            'Assigned to you',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.emerald700,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 2. CUSTOMER INFORMATION
  // ========================================================
  Widget _buildCustomerInfoCard() {
    final String phone = widget.order.customerPhone.trim();
    final String address = (widget.order.deliveryAddress ?? '').trim();
    final String zone = widget.order.areaZone.trim().isEmpty ? '' : zoneLabel(widget.order.areaZone.trim());
    final String fullAddress = address.isNotEmpty ? (zone.isNotEmpty ? '$address, $zone' : address) : zone;
    final String? notes = widget.order.lastTransferReason;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.sky50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primarySky, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.customerName,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primarySky),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fullAddress.isEmpty ? 'No address specified' : fullAddress,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Call & Message buttons
              IconButton(
                onPressed: phone.isNotEmpty ? _callCustomer : null,
                icon: const Icon(Icons.phone, size: 20, color: AppColors.primarySky),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.sky50,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: phone.isNotEmpty ? _messageCustomer : null,
                icon: const Icon(Icons.chat_bubble, size: 18, color: AppColors.primarySky),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.sky50,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),

          // Optional Delivery Instructions Box
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_outlined, size: 16, color: AppColors.primarySky),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Instructions',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notes,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================
  // 3. MAP NAVIGATION (View on Map)
  // ========================================================
  Widget _buildMapNavigationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sky200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RiderDeliveryMapScreen(order: widget.order),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySky,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View on Map',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'See location and start navigation',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primarySky, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 4. ORDER SUMMARY
  // ========================================================
  Widget _buildOrderSummaryCard() {
    final totalUnits = widget.order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final isCOD = paymentMethod == 'cash';

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.primarySky, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$totalUnits items',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primarySky,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 10),

          // Items List
          ...widget.order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.sky50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_drink, color: AppColors.primarySky, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.quantity} × ₱${item.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Empty containers count row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.autorenew, color: AppColors.slate600, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Empty Containers (to collect)',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$emptyCollected',
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 10),

          // Payment Method & Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payment, size: 18, color: AppColors.slate500),
                  SizedBox(width: 8),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCOD ? AppColors.emerald50 : AppColors.sky50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCOD ? 'Cash (₱${widget.order.totalAmount.toStringAsFixed(2)})' : 'GCash Paid',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCOD ? AppColors.emerald700 : AppColors.primarySky,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 5. DELIVERY DETAILS (Quantities & Discrepancy)
  // ========================================================
  Widget _buildDeliveryDetailsCard() {
    final int unreturnedDiff = droppedOff - emptyCollected;
    final bool balanced = unreturnedDiff == 0;
    final Color diffColor = balanced ? AppColors.emerald700 : (unreturnedDiff > 0 ? AppColors.coralAlert : AppColors.primarySky);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: AppColors.primarySky, size: 18),
              SizedBox(width: 8),
              Text(
                'Delivery Details',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Gallons Delivered Counter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Gallons Delivered',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepBtn(
                            icon: Icons.remove,
                            onTap: () => setState(() => droppedOff = droppedOff > 0 ? droppedOff - 1 : 0),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$droppedOff',
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          _buildStepBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => droppedOff++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Empty Containers Collected Counter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Empties Collected',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepBtn(
                            icon: Icons.remove,
                            onTap: () => setState(() => emptyCollected = emptyCollected > 0 ? emptyCollected - 1 : 0),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$emptyCollected',
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          _buildStepBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => emptyCollected++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Discrepancy indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: balanced ? AppColors.emerald50 : AppColors.rose50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(balanced ? Icons.verified : Icons.warning_amber_rounded, size: 14, color: diffColor),
                const SizedBox(width: 6),
                Text(
                  balanced ? 'Bottle balance: 0 discrepancy' : 'Discrepancy: ${unreturnedDiff > 0 ? "-$unreturnedDiff deficit" : "+${-unreturnedDiff} surplus"}',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: diffColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: AppColors.primarySky),
        ),
      ),
    );
  }

  // ========================================================
  // 6. RECIPIENT (Optional)
  // ========================================================
  Widget _buildRecipientCard() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primarySky, size: 18),
              SizedBox(width: 8),
              Text(
                'Recipient',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '(Optional)',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recipientCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
            decoration: InputDecoration(
              hintText: 'Enter recipient name',
              hintStyle: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                color: AppColors.slate400,
              ),
              filled: true,
              fillColor: AppColors.slate50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primarySky, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Name of the person who received the delivery.',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 7. PROOF OF DELIVERY PHOTO
  // ========================================================
  Widget _buildProofOfDeliveryCard() {
    final hasPhoto = _podPhotoBytes != null;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera_outlined, color: AppColors.primarySky, size: 18),
              SizedBox(width: 8),
              Text(
                'Proof of Delivery Photo',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upload / Preview box
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasPhoto ? Colors.black : AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPhoto ? Colors.transparent : AppColors.slate300,
                  width: 1.5,
                ),
              ),
              child: hasPhoto
                  ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _podPhotoBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Captured: ${_fmtTime(_podTime ?? DateTime.now())}',
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.refresh, size: 14, color: AppColors.primarySky),
                        label: const Text('Retake Photo', style: TextStyle(color: AppColors.primarySky, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.sky50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primarySky, size: 22),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take a photo',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Capture the delivered items or recipient',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.photo_camera, size: 16),
                      label: const Text('Open Camera', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primarySky,
                        side: const BorderSide(color: AppColors.primarySky),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.access_time, size: 13, color: AppColors.slate400),
              SizedBox(width: 4),
              Text(
                'Photo will be timestamped automatically upon capture.',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CERTIFICATION CHECKBOX
  // ========================================================
  Widget _buildCertificationCheckbox() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => paymentConfirmed = !paymentConfirmed),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: paymentConfirmed ? AppColors.sky50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: paymentConfirmed ? AppColors.sky200 : AppColors.slate200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: paymentConfirmed ? AppColors.primarySky : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: paymentConfirmed ? null : Border.all(color: AppColors.slate400),
              ),
              child: paymentConfirmed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'I certify that $droppedOff delivered unit(s) and $emptyCollected empty container(s) have been verified and payment of ₱${widget.order.totalAmount.toStringAsFixed(2)} confirmed.',
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // 8. COMPLETE DELIVERY BUTTON
  // ========================================================
  Widget _buildCompleteDeliveryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (isSubmitting || !paymentConfirmed) ? null : _submitFulfillment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarySky,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: AppColors.slate400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isSubmitting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.check_circle, size: 20, color: Colors.white),
        label: Text(
          isSubmitting ? 'Submitting Drop-off...' : 'Complete Delivery',
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}