// lib/screens/inventory/inventory_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header.dart';
import '../../main.dart';
import '../../models/inventory_model.dart';
import '../../services/firestore_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeTab = 'inventory';
  String _stockFilter = 'all';
  final FirestoreService _firestoreService = FirestoreService();

  Color _colorForItem(InventoryModel item) {
    final name = item.name.toLowerCase();
    if (item.category == 'packaging') {
      return name.contains('cap') ? AppColors.coralAlert : AppColors.primaryLight;
    }
    return (name.contains('alkaline') || name.contains('slim')) ? AppColors.cyanElectric : AppColors.primaryLight;
  }

  IconData _iconForItem(InventoryModel item) {
    final name = item.name.toLowerCase();
    if (item.category == 'packaging') {
      return name.contains('cap') ? Icons.adjust : Icons.lock_open;
    }
    return (name.contains('alkaline') || name.contains('slim')) ? Icons.opacity : Icons.water_drop;
  }

  void _onNavTapped(int index) {
    if (currentUserRoleNotifier.value == 'owner') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/owner_dashboard');
      if (index == 1) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 2) Navigator.pushReplacementNamed(context, '/dispatch');
      if (index == 3) return;
      if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
    } else {
      if (index == 0) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 1) Navigator.pushReplacementNamed(context, '/dispatch');
      if (index == 2) return;
      if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
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
                      currentIndex: isOwner ? 3 : 2,
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
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
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

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'critical':
        return AppColors.coralAlert;
      case 'warning':
        return const Color(0xFFD97706);
      default:
        return AppColors.secondaryLight;
    }
  }

  void _showAddMaintenanceAlertDialog() {
    final TextEditingController equipmentController = TextEditingController();
    final TextEditingController taskController = TextEditingController();
    String urgency = 'routine';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Dialog(
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  elevation: 24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Schedule Maintenance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: equipmentController,
                            decoration: InputDecoration(
                              labelText: 'Equipment name',
                              filled: true,
                              fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: taskController,
                            decoration: InputDecoration(
                              labelText: 'Task (e.g. Filter replacement)',
                              filled: true,
                              fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: ['routine', 'warning', 'critical'].map((u) {
                              final selected = urgency == u;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => urgency = u),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected ? _urgencyColor(u) : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(u, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: dueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setDialogState(() => dueDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryLight),
                                  const SizedBox(width: 12),
                                  Text('Due ${dueDate.month}/${dueDate.day}/${dueDate.year}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext), style: OutlinedButton.styleFrom(side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight), child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                              const SizedBox(width: 16),
                              Expanded(child: CustomButton(label: 'Schedule', onPressed: () async {
                                if (equipmentController.text.trim().isEmpty || taskController.text.trim().isEmpty) return;
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(dialogContext);
                                try {
                                  await _firestoreService.addMaintenanceAlert(MaintenanceAlertModel(
                                    id: '',
                                    equipmentName: equipmentController.text.trim(),
                                    taskType: taskController.text.trim(),
                                    urgency: urgency,
                                    dueDate: dueDate,
                                  ));
                                  messenger.showSnackBar(const SnackBar(content: Text('Maintenance scheduled.')));
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
                                }
                              }))
                            ],
                          )
                        ],
                      ),
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

  Widget _buildMaintenanceCard(MaintenanceAlertModel alert, bool isDark) {
    final color = _urgencyColor(alert.urgency);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        border: alert.isOverdue ? Border.all(color: AppColors.coralAlert.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.precision_manufacturing, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(alert.equipmentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: alert.isCompleted ? AppColors.textSecondary : AppColors.textLight, decoration: alert.isCompleted ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
                      child: Text(alert.urgency, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(alert.taskType, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  alert.isCompleted
                      ? 'Completed'
                      : (alert.isOverdue ? 'Overdue • Due ${alert.dueDate.month}/${alert.dueDate.day}/${alert.dueDate.year}' : 'Due ${alert.dueDate.month}/${alert.dueDate.day}/${alert.dueDate.year}'),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: alert.isOverdue ? AppColors.coralAlert : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _firestoreService.setMaintenanceAlertCompleted(alert.id, !alert.isCompleted);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: alert.isCompleted ? const Color(0xFFF0F9FF) : const Color(0xFF6CF8BB), borderRadius: BorderRadius.circular(100)),
              child: Text(alert.isCompleted ? 'Reopen' : 'Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: alert.isCompleted ? AppColors.primaryLight : const Color(0xFF00714D))),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestockModal(InventoryModel item) {
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
                      Text("Restock ${item.name}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Current stock: ${item.currentStock} ${item.unit}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 32),
                      Text("Quantity to Add (${item.unit}):", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          Expanded(child: CustomButton(label: 'Restock', onPressed: () async {
                            final add = int.tryParse(restockController.text) ?? 0;
                            final messenger = ScaffoldMessenger.of(this.context);
                            Navigator.pop(context);
                            if (add == 0) return;
                            try {
                              await _firestoreService.restockItem(item.id, add);
                              if (!mounted) return;
                              messenger.showSnackBar(const SnackBar(content: Text('Inventory Restocked successfully.')));
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('Restock failed: $e'), backgroundColor: AppColors.error));
                            }
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
                    StreamBuilder<List<InventoryModel>>(
                      stream: _firestoreService.getInventoryStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('Failed to load inventory: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final invItems = snapshot.data!;
                        final waterItems = invItems.where((i) => i.category == 'water');
                        final totalWaterStock = waterItems.fold<int>(0, (sum, i) => sum + i.currentStock);
                        final totalWaterCapacity = waterItems.fold<int>(0, (sum, i) => sum + i.maxCapacity);
                        final waterPct = totalWaterCapacity == 0 ? 0.0 : totalWaterStock / totalWaterCapacity;
                        final criticalItems = invItems.where((i) => i.isLowStock).toList();
                        final filteredInvItems = _stockFilter == 'all' ? invItems : invItems.where((i) => i.category == _stockFilter).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL VOLUME', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)), Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle), child: const Icon(Icons.water_drop, size: 16, color: AppColors.primaryLight))]),
                                  const SizedBox(height: 8),
                                  Text.rich(TextSpan(children: [TextSpan(text: '$totalWaterStock', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)), TextSpan(text: ' / $totalWaterCapacity Gal', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))])),
                                  const SizedBox(height: 8),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${(waterPct * 100).toStringAsFixed(0)}% Cap', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight)), const Text('Optimal', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
                                  const SizedBox(height: 4),
                                  Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: waterPct.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(gradient: AppColors.vividGradient, borderRadius: BorderRadius.circular(100))))),
                                ]) )),
                                const SizedBox(width: 12),
                                Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('WARNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert, letterSpacing: 1)), Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFFFFDAD6), shape: BoxShape.circle), child: const Icon(Icons.warning, size: 16, color: AppColors.coralAlert))]),
                                  const SizedBox(height: 8),
                                  Text.rich(TextSpan(children: [TextSpan(text: '${criticalItems.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.coralAlert)), const TextSpan(text: ' Line Critical', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])),
                                  const SizedBox(height: 8),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Expanded(child: Text(criticalItems.isEmpty ? 'All clear' : criticalItems.first.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coralAlert))),
                                    Text(criticalItems.isEmpty ? '' : '< ${criticalItems.first.minimumThreshold} left', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: criticalItems.isEmpty ? 0.0 : (criticalItems.first.currentStock / (criticalItems.first.maxCapacity == 0 ? 1 : criticalItems.first.maxCapacity)).clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: AppColors.coralAlert, borderRadius: BorderRadius.circular(100))))),
                                ]) )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Row(children: [Text('Tracked Supply Lines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textMain)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDAE2FD), borderRadius: BorderRadius.circular(100)), child: Text('${filteredInvItems.length} Items', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)))]),
                              PopupMenuButton<String>(
                                initialValue: _stockFilter,
                                onSelected: (value) => setState(() => _stockFilter = value),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'all', child: Text('All Categories')),
                                  PopupMenuItem(value: 'water', child: Text('Water')),
                                  PopupMenuItem(value: 'packaging', child: Text('Packaging')),
                                ],
                                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.filter_list, size: 16, color: AppColors.primaryLight), const SizedBox(width: 4), Text(_stockFilter == 'all' ? 'Filter' : (_stockFilter == 'water' ? 'Water' : 'Packaging'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight))]),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            if (filteredInvItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text('No items in this category.', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ),
                            ...filteredInvItems.map((item) => _buildInvCard(item, isDark)),
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(24)), child: const Row(children: [Icon(Icons.access_time, size: 24, color: Color(0xFFD97706)), SizedBox(width: 16), Expanded(child: Text('Preventive maintenance schedule keeps filtration components, pumps, and UV sterilizers operating at 100% water safety standards.', style: TextStyle(fontSize: 14, color: Color(0xFF78350F), height: 1.5)))])),
                    const SizedBox(height: 16),
                    if (isOwner)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _showAddMaintenanceAlertDialog,
                          icon: const Icon(Icons.add, size: 16, color: AppColors.primaryLight),
                          label: const Text('Schedule Maintenance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primaryLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                        ),
                      ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<MaintenanceAlertModel>>(
                      stream: _firestoreService.getMaintenanceAlertsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('Failed to load alerts: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final alerts = snapshot.data!;
                        if (alerts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('No maintenance scheduled.', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                          );
                        }
                        return Column(children: alerts.map((a) => _buildMaintenanceCard(a, isDark)).toList());
                      },
                    ),
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

  Widget _buildInvCard(InventoryModel item, bool isDark) {
    final int val = item.currentStock;
    final int max = item.maxCapacity;
    final String unit = item.unit;
    final String title = item.name;
    final Color color = _colorForItem(item);
    final IconData icon = _iconForItem(item);
    final double pct = max == 0 ? 0.0 : (val / max).clamp(0.0, 1.0);
    final bool isCrit = item.isLowStock;

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
                      if (isCrit) Row(children: [const Icon(Icons.emergency, size: 14, color: AppColors.coralAlert), const SizedBox(width: 4), Text('Threshold Breach (< ${item.minimumThreshold})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert))])
                      else Text(item.category == 'water' ? 'Station Filter Bank A • RO UV' : 'Packaging & Consumables', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
              Row(children: [Icon(isCrit ? Icons.timer : Icons.verified, size: 15, color: isCrit ? AppColors.textSecondary : AppColors.accentTeal), const SizedBox(width: 4), Text(isCrit ? 'Below minimum threshold' : (item.category == 'water' ? 'Purity: 0 ppm (Ultra)' : 'Stock healthy'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))]),
              InkWell(
                onTap: () => _showRestockModal(item),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isCrit ? AppColors.coralAlert : const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(100), boxShadow: isCrit ? [BoxShadow(color: AppColors.coralAlert.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))] : []), child: Row(children: [Icon(isCrit ? Icons.priority_high : Icons.add_circle, size: 16, color: isCrit ? Colors.white : AppColors.primaryLight), const SizedBox(width: 4), Text(isCrit ? 'Restock Now' : 'Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? Colors.white : AppColors.primaryLight))])),
              )
            ],
          )
        ],
      ),
    );
  }
}