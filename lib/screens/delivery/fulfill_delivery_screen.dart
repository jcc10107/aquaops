import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class FulfillDeliveryScreen extends StatefulWidget {
  final OrderModel order;
  const FulfillDeliveryScreen({super.key, required this.order});

  @override
  State<FulfillDeliveryScreen> createState() => _FulfillDeliveryScreenState();
}

class _FulfillDeliveryScreenState extends State<FulfillDeliveryScreen> {
  static const Color _blue = Color(0xFF0284C7);
  static const Color _cyan = Color(0xFF00B4D8);
  static const Color _bg = Color(0xFFF6FAFC);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFF1F5F9);
  static const Color _emerald = Color(0xFF059669);
  static const Color _emeraldBg = Color(0xFFECFDF5);

  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();
  late int droppedOff;
  late int emptyCollected;
  bool paymentConfirmed = true;
  bool isSubmitting = false;
  late String paymentMethod;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _recipientCtrl = TextEditingController();
  XFile? _podPhoto;
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

  Future<void> _takePhoto() async {
    try {
      final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (shot == null) return;
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      setState(() {
        _podPhoto = shot;
        _podPhotoBytes = bytes;
        _podTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _submitFulfillment() async {
    setState(() => isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      String? podUrl;
      if (_podPhotoBytes != null) {
        podUrl = await _cloudinary.uploadImage(_podPhotoBytes!, filename: 'proof_of_delivery.jpg', folder: 'proof_of_delivery');
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
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Delivery Completed!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to complete delivery: $e'), backgroundColor: AppColors.error));
    }
  }

  String _fmtTime(DateTime t) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${p(t.month)}-${p(t.day)} ${p(t.hour)}:${p(t.minute)}:${p(t.second)} PHT';
  }

  Widget _card({required Widget child, CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: align, children: [child]),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: _slate400),
  );

  Widget _iconBubble(IconData icon, {Color color = _blue, Color? bg}) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(color: bg ?? color.withValues(alpha: 0.1), shape: BoxShape.circle),
    child: Icon(icon, size: 16, color: color),
  );

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
    customBorder: const CircleBorder(),
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: _slate100, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: _slate700),
    ),
  );

  Widget _statTile({
    required String title,
    required IconData icon,
    required Widget value,
    required String caption,
    Color iconColor = _blue,
    Color? iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _slate500))),
              _iconBubble(icon, color: iconColor, bg: iconBg),
            ],
          ),
          value,
          Text(caption.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _slate400)),
        ],
      ),
    );
  }

  Widget _paymentTab(String key, String label, IconData icon) {
    final selected = paymentMethod == key;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => paymentMethod = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? [BoxShadow(color: _blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : _blue),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : _blue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _blue),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, _cyan]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DELIVERY FULFILLMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white70)),
              SizedBox(height: 2),
              Text('Fulfill Drop-off', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customerCard() {
    final String phone = widget.order.customerPhone.trim();
    final String address = (widget.order.deliveryAddress ?? '').trim();
    final String zone = widget.order.areaZone.trim();
    final String location = address.isNotEmpty ? (zone.isNotEmpty ? '$address • $zone' : address) : zone;
    final String number = widget.order.orderNumber.startsWith('#') ? widget.order.orderNumber : '#${widget.order.orderNumber}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Customer & Order Details'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _blue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(widget.order.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _slate800))),
              if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _slate500)),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: _blue),
                  const SizedBox(width: 6),
                  Expanded(child: Text(location, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _slate500))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final int unreturnedDiff = droppedOff - emptyCollected;
    final bool balanced = unreturnedDiff == 0;
    final Color diffColor = balanced ? _emerald : (unreturnedDiff > 0 ? const Color(0xFFF43F5E) : _blue);
    final String diffLabel = balanced ? 'Balanced (0)' : (unreturnedDiff > 0 ? 'Deficit (-$unreturnedDiff)' : 'Surplus (+${-unreturnedDiff})');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _statTile(
          title: 'Delivered',
          icon: Icons.water_drop,
          value: Text('$droppedOff units', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _slate800)),
          caption: '5-Gal Full',
        ),
        _statTile(
          title: 'Empties Retrieved',
          icon: Icons.autorenew,
          value: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepBtn(Icons.remove, () => setState(() => emptyCollected = emptyCollected > 0 ? emptyCollected - 1 : 0)),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('$emptyCollected units', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _slate800)))),
              _stepBtn(Icons.add, () => setState(() => emptyCollected++)),
            ],
          ),
          caption: 'Empty Return',
        ),
        _statTile(
          title: 'Container Telematics',
          icon: balanced ? Icons.balance : Icons.warning_amber_rounded,
          iconColor: diffColor,
          iconBg: diffColor.withValues(alpha: 0.1),
          value: Text(diffLabel, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: diffColor)),
          caption: balanced ? 'Zero Bottle Discrepancy' : 'Bottle Discrepancy',
        ),
        _statTile(
          title: 'Payment Collected',
          icon: Icons.qr_code_2,
          value: Text('₱${widget.order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _blue)),
          caption: paymentMethod == 'gcash' ? 'GCash Collected' : 'Cash Collected',
        ),
      ],
    );
  }

  Widget _paymentTotalCard() {
    return _card(
      align: CrossAxisAlignment.center,
      child: Column(
        children: [
          _sectionLabel('Payment Collection (COD / GCash)'),
          const SizedBox(height: 4),
          Text('₱${widget.order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _blue, height: 1.1)),
          const SizedBox(height: 4),
          Text('Total Payable for $droppedOff ${droppedOff == 1 ? 'Gallon' : 'Gallons'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _slate500)),
        ],
      ),
    );
  }

  Widget _verificationCard() {
    final ref = widget.order.gcashReference;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _sectionLabel('Payment & Verification')),
              if (paymentConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _emeraldBg, borderRadius: BorderRadius.circular(100)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: _emerald),
                      SizedBox(width: 4),
                      Text('Payment Confirmed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _emerald)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: _slate100, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _paymentTab('cash', 'Cash', Icons.local_atm),
                const SizedBox(width: 4),
                _paymentTab('gcash', 'GCash QR', Icons.account_balance_wallet),
              ],
            ),
          ),
          if (ref != null && ref.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.sell,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const Text('Customer-provided ref:', style: TextStyle(fontSize: 12, color: _slate400)),
                  Text(ref, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: _slate800)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: Row(
              children: [
                const Icon(Icons.badge, size: 18, color: _blue),
                const SizedBox(width: 8),
                const Text('Recipient:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _recipientCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _slate800),
                    decoration: const InputDecoration(
                      hintText: 'Name of person who received',
                      hintStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _slate400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_recipientCtrl.text.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(100)),
                    child: const Text('Signed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _podCard() {
    final hasPhoto = _podPhoto != null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.photo_camera, size: 20, color: _blue),
                    SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PROOF OF DELIVERY (POD)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: _slate400)),
                          Text('Drop-off Photo Verification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _slate800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: hasPhoto ? _emeraldBg : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: hasPhoto ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPhoto)
                      const Icon(Icons.check_circle, size: 12, color: _emerald)
                    else
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(hasPhoto ? 'Photo Verified' : 'Pending Photo',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasPhoto ? const Color(0xFF047857) : const Color(0xFFD97706))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _takePhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 208,
                decoration: BoxDecoration(
                  color: hasPhoto ? const Color(0xFF0F172A) : _slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: hasPhoto ? null : Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: hasPhoto
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_podPhotoBytes!, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white24)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Color(0xFF34D399)),
                            SizedBox(width: 4),
                            Text('VERIFIED POD', style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'monospace', letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Text(
                        'TIMESTAMP: ${_fmtTime(_podTime ?? DateTime.now())}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFFCBD5E1), fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo, size: 24, color: _blue),
                    ),
                    const SizedBox(height: 8),
                    const Text('No photo captured yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _slate700)),
                    const SizedBox(height: 2),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Take a live photo of jugs at doorstep to verify delivery',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _slate400)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _takePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.photo_camera, size: 18, color: Colors.white),
              label: Text(hasPhoto ? 'Retake Photo' : 'Take Photo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          if (hasPhoto) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _emeraldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD1FAE5))),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_podPhotoBytes!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photo Proof Captured', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                        Text('Water jugs verified on doorstep', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _emerald)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _takePhoto,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _blue.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.refresh, size: 13, color: _blue),
                    label: const Text('Retake', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _blue)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _certifyBox() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => paymentConfirmed = !paymentConfirmed),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: paymentConfirmed ? _blue : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: paymentConfirmed ? null : Border.all(color: _slate400),
              ),
              child: paymentConfirmed ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'I certify that $droppedOff delivered ${droppedOff == 1 ? 'unit' : 'units'} and $emptyCollected empty ${emptyCollected == 1 ? 'container has' : 'containers have'} been physically verified, handed over, and payment of ₱${widget.order.totalAmount.toStringAsFixed(2)} confirmed.',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _slate700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final enabled = paymentConfirmed && !isSubmitting;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: enabled ? _submitFulfillment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              disabledBackgroundColor: _blue.withValues(alpha: 0.4),
              elevation: enabled ? 8 : 0,
              shadowColor: _blue.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            icon: isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.verified, size: 20, color: Colors.white),
            label: Text(isSubmitting ? 'Completing...' : 'Complete & Verify Drop-off',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _slate400)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: Color(0xFF131B2E)),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fulfill Drop-off', style: TextStyle(color: Color(0xFF131B2E), fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('ORDER FULFILLMENT PROTOCOL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Color(0xFF707881))),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _banner(),
                  const SizedBox(height: 14),
                  _customerCard(),
                  const SizedBox(height: 14),
                  _statsGrid(),
                  const SizedBox(height: 14),
                  _paymentTotalCard(),
                  const SizedBox(height: 14),
                  _verificationCard(),
                  const SizedBox(height: 14),
                  _podCard(),
                  const SizedBox(height: 14),
                  _certifyBox(),
                  const SizedBox(height: 16),
                  _actions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}