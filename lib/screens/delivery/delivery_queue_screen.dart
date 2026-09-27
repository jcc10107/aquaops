import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_header.dart';
import '../../main.dart';
import 'rider_cash_out_modal.dart';
import 'emergency_transfer_modal.dart';

class DeliveryQueueScreen extends StatefulWidget {
  const DeliveryQueueScreen({super.key});
  @override
  State<DeliveryQueueScreen> createState() => _DeliveryQueueScreenState();
}

class _DeliveryQueueScreenState extends State<DeliveryQueueScreen> {
  String _area = 'all';
  String _selectedRider = 'Arnel Bautista (Barangay San Antonio)';

  final List<Map<String, dynamic>> _allDeliveries = [
    {'num': '#1', 'name': 'Juan dela Cruz', 'addr': 'Block 4 Lot 12, Dahlia St., Barangay San Antonio', 'area': 'sa', 'qty': '2x Round', 'amt': '₱70.00', 'pay': 'CASH'},
    {'num': '#2', 'name': 'Rosario Mercado', 'addr': '15 Sampaguita Ave., Barangay San Antonio', 'area': 'sa', 'qty': '3x Slim', 'amt': '₱120.00', 'pay': 'GCASH'},
  ];

  void _onNavTapped(int index) {
    if (currentUserRoleNotifier.value == 'owner') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/owner_dashboard');
      if (index == 1) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 2) return;
      if (index == 3) Navigator.pushReplacementNamed(context, '/inventory');
      if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
    } else {
      if (index == 0) return;
      if (index == 1) Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Widget _buildFloatingBottomNav(bool isDark, bool isOwner) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.95) : AppColors.surfaceLight.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, 12))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: isOwner ? 2 : 0,
                      onTap: _onNavTapped,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: AppColors.primaryLight,
                      unselectedItemColor: AppColors.textSecondary,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
                      items: isOwner
                          ? const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ]
                          : const [
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Routes'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCashOut(BuildContext context) {
    showDialog(context: context, builder: (context) => const RiderCashOutModal());
  }

  void _showEmergencyTransfer(BuildContext context) {
    showDialog(context: context, builder: (context) => const EmergencyTransferModal());
  }

  void _showFulfillDropoffModal(Map<String, dynamic> delivery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : AppColors.textLight;

    int emptyCollected = int.parse(delivery['qty'].split('x')[0]);
    bool paymentConfirmed = true;
    String paymentMethod = delivery['pay'].toLowerCase().contains('gcash') ? 'gcash' : 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final int droppedOff = int.parse(delivery['qty'].split('x')[0]);
            final int unreturnedDiff = droppedOff - emptyCollected;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 390,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 16))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            gradient: AppColors.vividGradient,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.water_drop, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Fulfill Drop-off', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(width: 6),
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6CF8BB), shape: BoxShape.circle)),
                                      ],
                                    ),
                                    Text(delivery['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE0F2FE))),
                                    Text('${delivery['num']} • Stop #5', style: const TextStyle(fontSize: 11, color: Color(0xFFE0F2FE))),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.inventory_2, size: 16, color: AppColors.primaryLight),
                                              SizedBox(width: 4),
                                              Text('CONTAINER TELEMATICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: unreturnedDiff == 0 ? AppColors.secondaryLight : AppColors.coralAlert,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle, size: 12, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(unreturnedDiff == 0 ? 'Balanced (0)' : 'Diff ($unreturnedDiff)', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                              child: Column(
                                                children: [
                                                  const Text('Delivered', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                  Text('$droppedOff', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                                  const Text('5-Gal Full', style: TextStyle(fontSize: 10, color: AppColors.borderLight)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                              child: Column(
                                                children: [
                                                  const Text('Collected', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => setStateModal(() => emptyCollected = emptyCollected > 0 ? emptyCollected - 1 : 0),
                                                        child: Container(
                                                          width: 26,
                                                          height: 26,
                                                          decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                                          child: const Icon(Icons.remove, size: 14, color: AppColors.primaryLight),
                                                        ),
                                                      ),
                                                      Container(width: 28, alignment: Alignment.center, child: Text('$emptyCollected', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textMain))),
                                                      InkWell(
                                                        onTap: () => setStateModal(() => emptyCollected++),
                                                        child: Container(
                                                          width: 26,
                                                          height: 26,
                                                          decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                                          child: const Icon(Icons.add, size: 14, color: AppColors.primaryLight),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  const Text('Empty Return', style: TextStyle(fontSize: 10, color: AppColors.borderLight)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.payments, size: 16, color: AppColors.primaryLight),
                                              SizedBox(width: 4),
                                              Text('PAYMENT COLLECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                          Text(delivery['amt'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setStateModal(() => paymentMethod = 'cash'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(color: paymentMethod == 'cash' ? AppColors.primaryLight : Colors.white, borderRadius: BorderRadius.circular(100)),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.payments, size: 16, color: paymentMethod == 'cash' ? Colors.white : AppColors.textLight),
                                                    const SizedBox(width: 4),
                                                    Text('Cash', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: paymentMethod == 'cash' ? Colors.white : AppColors.textLight)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setStateModal(() => paymentMethod = 'gcash'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                decoration: BoxDecoration(color: paymentMethod == 'gcash' ? AppColors.primaryLight : Colors.white, borderRadius: BorderRadius.circular(100)),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.account_balance_wallet, size: 16, color: paymentMethod == 'gcash' ? Colors.white : AppColors.cyanElectric),
                                                    const SizedBox(width: 4),
                                                    Text('GCash QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: paymentMethod == 'gcash' ? Colors.white : AppColors.textLight)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => setStateModal(() => paymentConfirmed = !paymentConfirmed),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                          child: Row(
                                            children: [
                                              Icon(paymentConfirmed ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.secondaryLight, size: 16),
                                              const SizedBox(width: 8),
                                              const Text('Confirm full payment received', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF2F3FF), borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.photo_camera, size: 16, color: AppColors.primaryLight),
                                              SizedBox(width: 4),
                                              Text('DIGITAL POD (PROOF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF6CF8BB), borderRadius: BorderRadius.circular(100)),
                                            child: const Text('Photo Attached', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00714D))),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 112,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                          image: const DecorationImage(
                                            image: NetworkImage(
                                              'https://lh3.googleusercontent.com/aida-public/AB6AXuBi5vkgqaCUO83dFyK3FQCUYF8wrcL9gs484aPBFcbn8l-IEdJGZWSGwDN87b0uLRZAvMLMbxz7fz3xsPofCpNE87wW0EkZC4AOH4od1LF894UuYA8e7P52uqaFIi0luSPfljDb5yrVGSk-xgsZB2ikC_PN1Wx6WHrz80eGQMs5odqA110HM2lnEg8SB3IVxDCeRgmCDPWsErTFhFt56723oH3r0abSLZ8ytwBunJqLhu-7BDuT6knQ',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                        child: const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Customer Remarks & Verification', style: TextStyle(fontSize: 10, color: AppColors.borderLight)),
                                                Icon(Icons.check, size: 14, color: AppColors.secondaryLight),
                                              ],
                                            ),
                                            Text('"Received in good condition. Caps sealed."', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textLight)),
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
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                        ),
                                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: paymentConfirmed
                                            ? () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery Completed!')));
                                        }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondaryLight,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                        ),
                                        icon: const Icon(Icons.verified, size: 18, color: Colors.white),
                                        label: const Text('Delivered', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
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
          },
        );
      },
    );
  }

  int _countForArea(String area) {
    if (area == 'all') return _allDeliveries.length;
    return _allDeliveries.where((d) => d['area'] == area).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textMain = isDark ? Colors.white : AppColors.textLight;
    final isOwner = currentUserRoleNotifier.value == 'owner';

    final filteredDeliveries = _allDeliveries.where((d) => _area == 'all' || d['area'] == _area).toList();

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      appBar: const CustomHeader(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Area-Based Delivery Queue & Dispatch', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  const Text('Ordered neighborhood routes, real-time drop-off verification & digital PoD', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEmergencyTransfer(context),
                          icon: const Icon(Icons.swap_horiz, size: 16, color: Color(0xFFD97706)),
                          label: const Text('Emergency Transfer', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: isDark ? const Color(0xFF451A03).withValues(alpha: 0.5) : const Color(0xFFFFFBEB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCashOut(context),
                          icon: const Icon(Icons.attach_money, size: 16, color: AppColors.secondaryLight),
                          label: const Text('Shift Cash-Out', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6CF8BB)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: isDark ? const Color(0xFF022C22).withValues(alpha: 0.5) : const Color(0xFFECFDF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterTab('all', 'All Areas', _countForArea('all'), isDark),
                                    const SizedBox(width: 8),
                                    _buildFilterTab('sa', 'Barangay San Antonio', _countForArea('sa'), isDark),
                                    const SizedBox(width: 8),
                                    _buildFilterTab('si', 'Barangay San Isidro', _countForArea('si'), isDark),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Rider: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(12)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    value: _selectedRider,
                                    icon: const Icon(Icons.expand_more, color: AppColors.textLight),
                                    items: ['Arnel Bautista (Barangay San Antonio)', 'Kuya Noel (Barangay San Isidro)']
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: AppColors.textLight))))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedRider = v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text('ACTIVE DELIVERY QUEUE (${filteredDeliveries.length} PENDING)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...filteredDeliveries.map((d) => _buildQueueCard(d, 'Arnel Bautista', textMain, isDark)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(isDark, isOwner),
    );
  }

  Widget _buildFilterTab(String val, String label, int count, bool isDark) {
    bool isActive = _area == val;
    return InkWell(
      onTap: () => setState(() => _area = val),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.vividGradient : null,
          color: isActive ? null : const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.white : AppColors.textLight)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.white, borderRadius: BorderRadius.circular(100)),
              child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> d, String rider, Color textMain, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyanElectric.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle), child: Center(child: Text(d['num'], style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textMain)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.coralAlert),
                          const SizedBox(width: 4),
                          Expanded(child: Text(d['addr'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), border: Border.all(color: AppColors.cyanElectric.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(100)),
                  child: const Text('OUT FOR DELIVERY', style: TextStyle(fontSize: 10, color: AppColors.cyanElectric, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order & Qty', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(d['qty'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount Due', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(d['amt'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Mode', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(d['pay'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assigned Rider', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(rider, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 14, color: AppColors.secondaryLight),
                  label: const Text('Call', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFulfillDropoffModal(d),
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                    label: const Text('Complete Drop-off & Verify Payment', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}