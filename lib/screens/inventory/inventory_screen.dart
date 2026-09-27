// lib/screens/inventory/inventory_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header.dart';
import '../../main.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeTab = 'inventory';

  List<Map<String, dynamic>> items = [
    {'sku': 'WTR-RND-001', 'title': '5-Gal Round Purified Water', 'val': 145, 'max': 200, 'unit': 'Gal', 'min': 30, 'color': AppColors.primaryLight, 'icon': Icons.water_drop},
    {'sku': 'WTR-SLM-002', 'title': '5-Gal Slim Alkaline Water', 'val': 82, 'max': 150, 'unit': 'Gal', 'min': 20, 'color': AppColors.cyanElectric, 'icon': Icons.opacity},
    {'sku': 'PKG-CAP-001', 'title': 'Non-Spill Blue Gallon Caps', 'val': 24, 'max': 500, 'unit': 'pcs', 'min': 50, 'color': AppColors.coralAlert, 'icon': Icons.adjust},
    {'sku': 'PKG-SEL-002', 'title': 'Tamper-Proof Shrink Seals', 'val': 190, 'max': 300, 'unit': 'pcs', 'min': 50, 'color': AppColors.primaryLight, 'icon': Icons.lock_open},
  ];

  void _onNavTapped(int index) {
    if (currentUserRoleNotifier.value == 'owner') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/owner_dashboard');
      if (index == 1) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 2) Navigator.pushReplacementNamed(context, '/dispatch');
      if (index == 3) return;
      if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
    } else {
      if (index == 0) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 1) return;
      if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
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
                      currentIndex: isOwner ? 3 : 1,
                      onTap: _onNavTapped,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: AppColors.primaryLight,
                      unselectedItemColor: AppColors.textSecondary,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
                      items: isOwner ? const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
                        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                      ] : const [
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Station POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
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

  void _showRestockModal(int index) {
    final item = items[index];
    final TextEditingController restockController = TextEditingController(text: '100');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Dialog(
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                elevation: 24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Restock ${item['title']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Current stock: ${item['val']} ${item['unit']}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 32),
                      Text("Quantity to Add (${item['unit']}):", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: restockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          contentPadding: const EdgeInsets.all(20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight), child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 16),
                          Expanded(child: CustomButton(label: 'Restock', onPressed: () {
                            setState(() {
                              int add = int.tryParse(restockController.text) ?? 0;
                              items[index]['val'] += add;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory Restocked successfully.')));
                          }))
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textMain = isDark ? Colors.white : AppColors.textLight;
    final isOwner = currentUserRoleNotifier.value == 'owner';

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
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      children: [
                        Expanded(child: InkWell(onTap: () => setState(() => _activeTab = 'inventory'), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(gradient: _activeTab == 'inventory' ? AppColors.vividGradient : null, borderRadius: BorderRadius.circular(100), boxShadow: _activeTab == 'inventory' ? [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.3), blurRadius: 16)] : []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2, size: 18, color: _activeTab == 'inventory' ? Colors.white : AppColors.textSecondary), const SizedBox(width: 6), Text('Stock Inventory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _activeTab == 'inventory' ? Colors.white : AppColors.textSecondary))])))),
                        Expanded(child: InkWell(onTap: () => setState(() => _activeTab = 'machinery'), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(gradient: _activeTab == 'machinery' ? AppColors.vividGradient : null, borderRadius: BorderRadius.circular(100), boxShadow: _activeTab == 'machinery' ? [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.3), blurRadius: 16)] : []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.precision_manufacturing, size: 18, color: _activeTab == 'machinery' ? Colors.white : AppColors.textSecondary), const SizedBox(width: 6), Text('Machinery Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _activeTab == 'machinery' ? Colors.white : AppColors.textSecondary)), const SizedBox(width: 4), Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.coralAlert, shape: BoxShape.circle))])))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_activeTab == 'inventory') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.smart_toy, color: AppColors.cyanElectric, size: 24)),
                          const SizedBox(width: 12),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('Packaging Engine', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)), SizedBox(width: 8), Text('LIVE SYNC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryLight))]), Text('Automated deduction active: 1 non-spill cap & 1 tamper seal logged per bottle filled.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))]))
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL VOLUME', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)), Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle), child: const Icon(Icons.water_drop, size: 16, color: AppColors.primaryLight))]), const SizedBox(height: 8), const Text.rich(TextSpan(children: [TextSpan(text: '233', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)), TextSpan(text: ' / 350 Gal', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])), const SizedBox(height: 8), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('66% Cap', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight)), Text('Optimal', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))]), const SizedBox(height: 4), Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.66, child: Container(decoration: BoxDecoration(gradient: AppColors.vividGradient, borderRadius: BorderRadius.circular(100)))))]) )),
                        const SizedBox(width: 12),
                        Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('WARNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert, letterSpacing: 1)), Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFFFFDAD6), shape: BoxShape.circle), child: const Icon(Icons.warning, size: 16, color: AppColors.coralAlert))]), const SizedBox(height: 8), const Text.rich(TextSpan(children: [TextSpan(text: '1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.coralAlert)), TextSpan(text: ' Line Critical', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])), const SizedBox(height: 8), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Blue Caps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coralAlert)), Text('< 30 left', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))]), const SizedBox(height: 4), Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.14, child: Container(decoration: BoxDecoration(color: AppColors.coralAlert, borderRadius: BorderRadius.circular(100)))))]) )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Text('Tracked Supply Lines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textMain)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDAE2FD), borderRadius: BorderRadius.circular(100)), child: const Text('5 Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)))]), const Row(children: [Icon(Icons.filter_list, size: 16, color: AppColors.primaryLight), SizedBox(width: 4), Text('Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight))])]),
                    const SizedBox(height: 16),
                    ...items.map((item) => _buildInvCard(item['sku'], item['title'], item['val'], item['max'], item['unit'], item['color'], item['icon'], isDark, items.indexOf(item))),
                  ] else ...[
                    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(24)), child: const Row(children: [Icon(Icons.access_time, size: 24, color: Color(0xFFD97706)), SizedBox(width: 16), Expanded(child: Text('Preventive maintenance schedule keeps filtration components, pumps, and UV sterilizers operating at 100% water safety standards.', style: TextStyle(fontSize: 14, color: Color(0xFF78350F), height: 1.5)))]))
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(isDark, isOwner),
    );
  }

  Widget _buildInvCard(String sku, String title, int val, int max, String unit, Color color, IconData icon, bool isDark, int index) {
    double pct = val / max;
    bool isCrit = val < 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: isCrit ? [BoxShadow(color: AppColors.coralAlert.withValues(alpha: 0.15), blurRadius: 20)] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: isCrit ? const Color(0xFFFFDAD6) : const Color(0xFFF0F9FF), shape: BoxShape.circle), child: Icon(icon, color: color, size: 26)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      if (isCrit) const Row(children: [Icon(Icons.emergency, size: 14, color: AppColors.coralAlert), SizedBox(width: 4), Text('Threshold Breach (< 50)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert))])
                      else const Text('Station Filter Bank A • RO UV', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  )
                ],
              ),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isCrit ? const Color(0xFFFFDAD6) : const Color(0xFF6CF8BB), borderRadius: BorderRadius.circular(100)), child: Text(isCrit ? 'Critical' : 'In Stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCrit ? const Color(0xFF93000A) : const Color(0xFF00714D))))
            ],
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text.rich(TextSpan(children: [TextSpan(text: '$val ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isCrit ? AppColors.coralAlert : AppColors.textLight)), TextSpan(text: isCrit ? 'pcs left' : '/ $max $unit', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))])), Expanded(child: Text(isCrit ? 'Immediate Action' : '${(pct * 100).toStringAsFixed(1)}% Ready', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? AppColors.coralAlert : AppColors.primaryLight), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 6),
          Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: pct, child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100))))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(isCrit ? Icons.timer : Icons.verified, size: 15, color: isCrit ? AppColors.textSecondary : AppColors.accentTeal), const SizedBox(width: 4), Text(isCrit ? 'Est. 4 hours remaining' : 'Purity: 0 ppm (Ultra)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
              InkWell(
                onTap: () => _showRestockModal(index),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isCrit ? AppColors.coralAlert : const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(100), boxShadow: isCrit ? [BoxShadow(color: AppColors.coralAlert.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))] : []), child: Row(children: [Icon(isCrit ? Icons.priority_high : Icons.add_circle, size: 16, color: isCrit ? Colors.white : AppColors.primaryLight), const SizedBox(width: 4), Text(isCrit ? 'Restock Now' : 'Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? Colors.white : AppColors.primaryLight))])),
              )
            ],
          )
        ],
      ),
    );
  }
}