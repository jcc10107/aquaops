import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class _AquaColors {
  static const Color coralAlert = Color(0xFFF43F5E);
}

class EmergencyTransferModal extends StatefulWidget {
  const EmergencyTransferModal({super.key});

  @override
  State<EmergencyTransferModal> createState() => _EmergencyTransferModalState();
}

class _EmergencyTransferModalState extends State<EmergencyTransferModal> {
  static const double _maxWidth = 450;

  final FirestoreService _firestoreService = FirestoreService();
  String _reason = 'Bike Breakdown';
  String? _sourceRiderId;
  String? _targetRiderId;
  bool _isTransferring = false;
  bool _isDone = false;
  String _queueScope = 'all';
  bool _notifyDispatch = true;

  final List<Map<String, dynamic>> _reasons = const [
    {'label': 'Bike Breakdown', 'icon': Icons.build_circle},
    {'label': 'Heavy Rain / Flood', 'icon': Icons.thunderstorm},
    {'label': 'Rider Medical', 'icon': Icons.medical_services},
    {'label': 'Overcapacity', 'icon': Icons.inventory_2},
  ];

  Future<void> _confirmTransfer(UserModel source, UserModel target) async {
    setState(() => _isTransferring = true);
    try {
      await _firestoreService.transferRiderOrders(
        fromRiderId: source.id,
        toRiderId: target.id,
        toRiderName: target.name,
        reason: _reason,
      );
      if (!mounted) return;
      setState(() {
        _isTransferring = false;
        _isDone = true;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTransferring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to transfer: $e'), backgroundColor: _AquaColors.coralAlert),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: SizedBox(
                      height: 64,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Transform.translate(
                              offset: const Offset(-4, 0),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Route Transfer',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.45, height: 1.25),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, size: 6, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 4),
                                      Text('Live Queue Reassignment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706), height: 1.45)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      child: StreamBuilder<List<UserModel>>(
                        stream: _firestoreService.getRidersStream(),
                        builder: (context, ridersSnapshot) {
                          return StreamBuilder<List<OrderModel>>(
                            stream: _firestoreService.getActiveOrdersStream(),
                            builder: (context, ordersSnapshot) {
                              final riders = ridersSnapshot.data ?? const <UserModel>[];
                              final activeOrders = ordersSnapshot.data ?? const <OrderModel>[];

                              int activeCountFor(String riderId) => activeOrders.where((o) => o.assignedRiderId == riderId).length;
                              double codFor(String riderId) => activeOrders
                                  .where((o) => o.assignedRiderId == riderId && o.paymentMethod == PaymentMethod.cash)
                                  .fold<double>(0, (s, o) => s + o.totalAmount);

                              final ridersWithLoad = riders.where((r) => activeCountFor(r.id) > 0).toList();

                              if (riders.length < 2) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text('Need at least 2 rider accounts to transfer a route.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                );
                              }
                              if (ridersWithLoad.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text('No rider currently has active deliveries to transfer.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                );
                              }

                              _sourceRiderId ??= ridersWithLoad.first.id;
                              final source = ridersWithLoad.firstWhere((r) => r.id == _sourceRiderId, orElse: () => ridersWithLoad.first);
                              final targetCandidates = riders.where((r) => r.id != source.id).toList();
                              _targetRiderId ??= targetCandidates.isEmpty ? null : targetCandidates.first.id;
                              final target = targetCandidates.isEmpty
                                  ? null
                                  : targetCandidates.firstWhere((r) => r.id == _targetRiderId, orElse: () => targetCandidates.first);

                              final sourcePendingStops = activeCountFor(source.id);
                              final sourceCod = codFor(source.id);

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.priority_high, size: 15, color: Color(0xFF0284C7)),
                                          SizedBox(width: 6),
                                          Text('TRIGGER REASON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.55)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFBEB),
                                          border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.8)),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: const Text('REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309), letterSpacing: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LayoutBuilder(builder: (context, constraints) {
                                    final itemWidth = (constraints.maxWidth - 8) / 2;
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _reasons.map((r) {
                                        final bool active = _reason == r['label'];
                                        Color iconColor = active ? Colors.white : const Color(0xFF334155);
                                        if (!active) {
                                          if (r['label'] == 'Heavy Rain / Flood') iconColor = const Color(0xFF006194);
                                          if (r['label'] == 'Rider Medical') iconColor = const Color(0xFFF43F5E);
                                          if (r['label'] == 'Overcapacity') iconColor = const Color(0xFF0051D5);
                                        }
                                        return SizedBox(
                                          width: itemWidth,
                                          child: InkWell(
                                            onTap: () => setState(() => _reason = r['label'] as String),
                                            borderRadius: BorderRadius.circular(100),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: active ? const Color(0xFFF59E0B) : Colors.white,
                                                borderRadius: BorderRadius.circular(100),
                                                border: Border.all(color: active ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                                                boxShadow: active
                                                    ? [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2))]
                                                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1))],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(r['icon'] as IconData, size: 16, color: iconColor),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      r['label'] as String,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        height: 1.33,
                                                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                                        color: active ? Colors.white : const Color(0xFF334155),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Flexible(
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle, size: 8, color: Color(0xFFF59E0B)),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text('SOURCE RIDER (CURRENT QUEUE)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.55)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFBEB),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: const Text('Stalled Route', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFF1F5F9)),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFBEB),
                                                border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.6)),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.two_wheeler, size: 22, color: Color(0xFFD97706)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  isDense: false,
                                                  value: source.id,
                                                  icon: Container(
                                                    width: 32,
                                                    height: 32,
                                                    alignment: Alignment.center,
                                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                                                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 20),
                                                  ),
                                                  selectedItemBuilder: (context) {
                                                    return ridersWithLoad.map((r) => Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Flexible(
                                                              child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text('#RD-${r.id.substring(0,3).toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.location_on, size: 13, color: Color(0xFFF43F5E)),
                                                            const SizedBox(width: 2),
                                                            Expanded(
                                                              child: Text(
                                                                r.assignedArea ?? 'Barangay San Antonio',
                                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    )).toList();
                                                  },
                                                  items: ridersWithLoad.map((r) => DropdownMenuItem(
                                                    value: r.id,
                                                    child: Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                  )).toList(),
                                                  onChanged: (v) => setState(() {
                                                    _sourceRiderId = v;
                                                    if (_targetRiderId == v) _targetRiderId = null;
                                                  }),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC).withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFF1F5F9)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.local_shipping, size: 15, color: Color(0xFF0284C7)),
                                                  const SizedBox(width: 6),
                                                  Text('$sourcePendingStops Pending Stops', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerRight,
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.water_drop, size: 13, color: Color(0xFF0EA5E9)),
                                                      const SizedBox(width: 4),
                                                      const Text('5 Gallons', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                      const SizedBox(width: 8),
                                                      const Text('•', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                      const SizedBox(width: 8),
                                                      Text('₱${sourceCod.toStringAsFixed(2)} COD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                                    ],
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
                                  Center(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 4))],
                                      ),
                                      child: const Icon(Icons.arrow_downward, size: 18, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Flexible(
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                                            SizedBox(width: 6),
                                            Flexible(
                                              child: Text('TARGET RIDER (NEW ASSIGNEE)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.55)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          border: Border.all(color: const Color(0xFFA7F3D0)),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.auto_awesome, size: 12, color: Color(0xFF047857)),
                                            SizedBox(width: 4),
                                            Text('Optimal Match', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (target == null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFD1FAE5)),
                                      ),
                                      child: const Text('No other rider account available.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFD1FAE5)),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.6)),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.directions_bike, size: 22, color: Color(0xFF059669)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    isExpanded: true,
                                                    isDense: false,
                                                    value: target.id,
                                                    icon: Container(
                                                      width: 32,
                                                      height: 32,
                                                      alignment: Alignment.center,
                                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                                                      child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 20),
                                                    ),
                                                    selectedItemBuilder: (context) {
                                                      return targetCandidates.map((r) => Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Flexible(
                                                                child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFFECFDF5),
                                                                  border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.8)),
                                                                  borderRadius: BorderRadius.circular(100),
                                                                ),
                                                                child: const Text('Online', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.location_on, size: 13, color: Color(0xFFF43F5E)),
                                                              const SizedBox(width: 2),
                                                              Expanded(
                                                                child: Text(
                                                                  r.assignedArea ?? 'Barangay San Isidro',
                                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      )).toList();
                                                    },
                                                    items: targetCandidates.map((r) => DropdownMenuItem(
                                                      value: r.id,
                                                      child: Text(r.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                    )).toList(),
                                                    onChanged: (v) => setState(() => _targetRiderId = v),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC).withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFF1F5F9)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.near_me, size: 15, color: Color(0xFF059669)),
                                                    SizedBox(width: 6),
                                                    Text('1.2 km away (4 mins)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                                                  ],
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.centerRight,
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.inventory_2, size: 13, color: Color(0xFF0284C7)),
                                                        const SizedBox(width: 6),
                                                        const Text('Capacity:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                        const SizedBox(width: 4),
                                                        Text('${activeCountFor(target.id)} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  const Row(
                                    children: [
                                      Icon(Icons.tune, size: 15, color: Color(0xFF0284C7)),
                                      SizedBox(width: 6),
                                      Text('QUEUE TRANSFER SCOPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.55)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _queueScope = 'all'),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: _queueScope == 'all' ? const Color(0xFFFFFBEB).withValues(alpha: 0.5) : Colors.white,
                                              border: Border.all(color: _queueScope == 'all' ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1))],
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Icon(
                                                    _queueScope == 'all' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                                    size: 16,
                                                    color: _queueScope == 'all' ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('All Stops ($sourcePendingStops)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                      const SizedBox(height: 2),
                                                      const Text('Full queue handoff', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _queueScope = 'split'),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: _queueScope == 'split' ? const Color(0xFFFFFBEB).withValues(alpha: 0.5) : Colors.white,
                                              border: Border.all(color: _queueScope == 'split' ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1))],
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Icon(
                                                    _queueScope == 'split' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                                    size: 16,
                                                    color: _queueScope == 'split' ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Split Queue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                                      SizedBox(height: 2),
                                                      Text('Transfer stop #2 only', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Row(
                                    children: [
                                      Icon(Icons.notifications_active, size: 15, color: Color(0xFFD97706)),
                                      SizedBox(width: 6),
                                      Text('DISPATCH NOTIFICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.55)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _notifyDispatch = !_notifyDispatch),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFBEB),
                                              border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.6)),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.send_to_mobile, size: 20, color: Color(0xFFD97706)),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Instant Rider & Dispatch Push Notification', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25)),
                                                SizedBox(height: 2),
                                                Text('Notify standby rider and station dispatch immediately', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.25)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            _notifyDispatch ? Icons.check_box : Icons.check_box_outline_blank,
                                            size: 20,
                                            color: _notifyDispatch ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 10,
                                        child: SizedBox(
                                          height: 48,
                                          child: TextButton(
                                            onPressed: (_isTransferring || _isDone) ? null : () => Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: const BorderSide(color: Color(0xFFE2E8F0))),
                                            ),
                                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w700)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 18,
                                        child: SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: (_isTransferring || _isDone || target == null) ? null : () => _confirmTransfer(source, target),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFF59E0B),
                                              disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                              padding: EdgeInsets.zero,
                                              elevation: 0,
                                              shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                            ),
                                            child: _isTransferring
                                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                                                SizedBox(width: 6),
                                                Text('Transfer Queue Now', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.verified_user, size: 15, color: Color(0xFF059669)),
                                      SizedBox(width: 6),
                                      Text('Live handoff verified by AquaOps Telematics', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}