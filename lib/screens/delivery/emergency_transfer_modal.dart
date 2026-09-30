import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class _AquaColors {
  static const Color primary = Color(0xFF006194);
  static const Color cyanElectric = Color(0xFF06B6D4);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color coralAlert = Color(0xFFF43F5E);
  static const Color amber600 = Color(0xFFD97706);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceCanvas = Color(0xFFF8FAFC);
  static const Color surfaceIce = Color(0xFFF0F9FF);
  static const Color surfaceFrost = Color(0xFFE0F2FE);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color textMain = Color(0xFF131B2E);
  static const Color textVariant = Color(0xFF3F4850);
  static const Color outline = Color(0xFF707881);
}

class EmergencyTransferModal extends StatefulWidget {
  const EmergencyTransferModal({super.key});

  @override
  State<EmergencyTransferModal> createState() => _EmergencyTransferModalState();
}

class _EmergencyTransferModalState extends State<EmergencyTransferModal> {
  final FirestoreService _firestoreService = FirestoreService();
  String _reason = 'Bike Breakdown';
  String? _sourceRiderId;
  String? _targetRiderId;
  bool _isTransferring = false;
  bool _isDone = false;
  int _transferredCount = 0;

  final List<Map<String, dynamic>> _reasons = const [
    {'label': 'Bike Breakdown', 'icon': Icons.build_circle},
    {'label': 'Heavy Rain / Flood', 'icon': Icons.thunderstorm},
    {'label': 'Rider Medical', 'icon': Icons.medical_services},
    {'label': 'Overcapacity', 'icon': Icons.inventory_2},
  ];

  Future<void> _confirmTransfer(UserModel source, UserModel target) async {
    setState(() => _isTransferring = true);
    try {
      final count = await _firestoreService.transferRiderOrders(
        fromRiderId: source.id,
        toRiderId: target.id,
        toRiderName: target.name,
        reason: _reason,
      );
      if (!mounted) return;
      setState(() {
        _isTransferring = false;
        _isDone = true;
        _transferredCount = count;
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 390,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _AquaColors.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _AquaColors.primary.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 16))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [_AquaColors.coralAlert, _AquaColors.cyanElectric, _AquaColors.secondaryContainer])),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
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
                                child: Text('Need at least 2 rider accounts to transfer a route.', style: TextStyle(color: _AquaColors.textVariant)),
                              );
                            }
                            if (ridersWithLoad.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('No rider currently has active deliveries to transfer.', style: TextStyle(color: _AquaColors.textVariant)),
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

                            if (_isDone) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  children: [
                                    const Icon(Icons.check_circle, size: 40, color: _AquaColors.secondary),
                                    const SizedBox(height: 12),
                                    Text('$_transferredCount order${_transferredCount == 1 ? '' : 's'} transferred to ${target?.name ?? 'the new rider'}!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: _AquaColors.coralAlert.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.swap_horiz, color: _AquaColors.coralAlert, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Emergency Route Transfer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _AquaColors.textMain, letterSpacing: -0.5)),
                                          SizedBox(height: 4),
                                          Text('Reassign a rider\'s active delivery queue to someone else (e.g. bike breakdown, heavy rainfall, flat tire).', style: TextStyle(fontSize: 11, color: _AquaColors.textVariant, height: 1.4)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text('TRIGGER REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _AquaColors.textVariant, letterSpacing: 1)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _reasons.map((r) {
                                    final bool active = _reason == r['label'];
                                    return InkWell(
                                      onTap: () => setState(() => _reason = r['label'] as String),
                                      borderRadius: BorderRadius.circular(100),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: active ? _AquaColors.coralAlert : _AquaColors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(r['icon'] as IconData, size: 14, color: active ? _AquaColors.surfaceLowest : _AquaColors.textMain),
                                            const SizedBox(width: 4),
                                            Text(r['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? _AquaColors.surfaceLowest : _AquaColors.textMain)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                                const Text('Source Rider (Current Queue)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: _AquaColors.surfaceCanvas, borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(width: 32, height: 32, decoration: const BoxDecoration(color: _AquaColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.two_wheeler, size: 20, color: _AquaColors.primary)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                isExpanded: true,
                                                value: source.id,
                                                items: ridersWithLoad.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name} (${activeCountFor(r.id)} stops)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _AquaColors.textMain)))).toList(),
                                                onChanged: (v) => setState(() {
                                                  _sourceRiderId = v;
                                                  if (_targetRiderId == v) _targetRiderId = null;
                                                }),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: _AquaColors.surfaceLowest, borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.local_shipping, size: 16, color: _AquaColors.primary),
                                                const SizedBox(width: 6),
                                                Text('$sourcePendingStops Pending Stops', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.primary)),
                                              ],
                                            ),
                                            Text('₱${sourceCod.toStringAsFixed(0)} COD', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Center(
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(color: _AquaColors.cyanElectric.withValues(alpha: 0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.south, size: 18, color: _AquaColors.primary),
                                    ),
                                  ),
                                ),
                                const Text('Target Rider (New Assignee)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                const SizedBox(height: 6),
                                if (target == null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: _AquaColors.surfaceIce, borderRadius: BorderRadius.circular(12)),
                                    child: const Text('No other rider account available.', style: TextStyle(fontSize: 12, color: _AquaColors.textVariant)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: _AquaColors.surfaceIce, borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 32, height: 32, decoration: BoxDecoration(color: _AquaColors.secondaryContainer.withValues(alpha: 0.4), shape: BoxShape.circle), child: const Icon(Icons.directions_bike, size: 20, color: _AquaColors.secondary)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value: target.id,
                                                  items: targetCandidates.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _AquaColors.textMain)))).toList(),
                                                  onChanged: (v) => setState(() => _targetRiderId = v),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: _AquaColors.surfaceLowest, borderRadius: BorderRadius.circular(6)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(target.assignedArea == null || target.assignedArea!.isEmpty ? 'No area assigned' : target.assignedArea!, style: const TextStyle(fontSize: 11, color: _AquaColors.textVariant)),
                                              Text('${activeCountFor(target.id)} active stop${activeCountFor(target.id) == 1 ? '' : 's'} already', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _AquaColors.textMain)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 10,
                                      child: TextButton(
                                        onPressed: _isTransferring ? null : () => Navigator.pop(context),
                                        style: TextButton.styleFrom(backgroundColor: _AquaColors.surfaceContainer, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                        child: const Text('Cancel', style: TextStyle(color: _AquaColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 15,
                                      child: ElevatedButton(
                                        onPressed: (_isTransferring || target == null) ? null : () => _confirmTransfer(source, target),
                                        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 0),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [_AquaColors.coralAlert, _AquaColors.amber600]),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            alignment: Alignment.center,
                                            child: _isTransferring
                                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                                                      SizedBox(width: 6),
                                                      Text('Transfer Queue Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
