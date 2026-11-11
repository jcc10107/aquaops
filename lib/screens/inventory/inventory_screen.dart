import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';
import '../../models/inventory_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeTab = 'inventory'; // 'inventory' | 'machinery'
  String _stockFilter = 'all'; // 'all' | 'water' | 'packaging' | 'low_stock'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s;

  IconData _iconForItem(InventoryModel item) {
    final name = item.name.toLowerCase();
    if (item.category == 'packaging') {
      return name.contains('cap') ? Icons.adjust : Icons.inventory_2_outlined;
    }
    return (name.contains('alkaline') || name.contains('slim'))
        ? Icons.opacity
        : Icons.water_drop_outlined;
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return AppColors.coralAlert;
      case 'warning':
        return AppColors.amber600;
      default:
        return AppColors.emerald600;
    }
  }

  Future<DateTime?> _showCustomDatePicker(BuildContext context, DateTime initialDate) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (ctx) => _CustomDatePickerModal(key: UniqueKey(), initialDate: initialDate),
    );
  }

  void _showAddMaintenanceAlertDialog() {
    final TextEditingController equipmentController = TextEditingController();
    final TextEditingController taskController = TextEditingController();
    String urgency = 'Routine';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    String? equipmentError;
    String? taskError;

    showDialog(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              elevation: 0,
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A0F172A), blurRadius: 16, offset: Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Schedule Maintenance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, size: 20, color: AppColors.slate400),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: equipmentController,
                        onChanged: (_) {
                          if (equipmentError != null) setDialogState(() => equipmentError = null);
                        },
                        style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                        decoration: InputDecoration(
                          labelText: 'Equipment Name',
                          hintText: 'e.g., UV Filtration Unit B',
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          errorText: equipmentError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: equipmentError != null ? AppColors.coralAlert : AppColors.slate200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: equipmentError != null ? AppColors.coralAlert : AppColors.primarySky, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: taskController,
                        onChanged: (_) {
                          if (taskError != null) setDialogState(() => taskError = null);
                        },
                        style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                        decoration: InputDecoration(
                          labelText: 'Task Description',
                          hintText: 'e.g., Filter membrane replacement',
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          errorText: taskError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: taskError != null ? AppColors.coralAlert : AppColors.slate200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: taskError != null ? AppColors.coralAlert : AppColors.primarySky, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Urgency Level',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildUrgencyButton('Routine', urgency == 'Routine', AppColors.emerald600, () => setDialogState(() => urgency = 'Routine'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildUrgencyButton('Warning', urgency == 'Warning', AppColors.amber600, () => setDialogState(() => urgency = 'Warning'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildUrgencyButton('Critical', urgency == 'Critical', AppColors.rose600, () => setDialogState(() => urgency = 'Critical'))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final picked = await _showCustomDatePicker(context, dueDate);
                          if (picked != null) setDialogState(() => dueDate = picked);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            border: Border.all(color: AppColors.slate200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primarySky),
                              const SizedBox(width: 10),
                              Text(
                                'Due Date: ${dueDate.month.toString().padLeft(2, '0')}/${dueDate.day.toString().padLeft(2, '0')}/${dueDate.year}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.slate200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Cancel", style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                setDialogState(() {
                                  equipmentError = equipmentController.text.trim().isEmpty ? 'Equipment name is required.' : null;
                                  taskError = taskController.text.trim().isEmpty ? 'Task description is required.' : null;
                                });
                                if (equipmentError != null || taskError != null) return;
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
                                  messenger.showSnackBar(const SnackBar(content: Text('Maintenance scheduled successfully.')));
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySky,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Schedule", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUrgencyButton(String label, bool isSelected, Color selectedColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.slate600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showRestockModal(InventoryModel item) {
    final TextEditingController restockController = TextEditingController(text: '100');

    showDialog(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          elevation: 0,
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A0F172A), blurRadius: 16, offset: Offset(0, 6))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Restock ${item.name}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20, color: AppColors.slate400),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Current: ${item.currentStock} ${item.unit} • Max: ${item.maxCapacity} ${item.unit}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Units to add",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      border: Border.all(color: AppColors.slate200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: restockController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            decoration: const InputDecoration(
                              hintText: 'Enter quantity',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                        Text(item.unit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate400)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.slate200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final add = int.tryParse(restockController.text) ?? 0;
                            final messenger = ScaffoldMessenger.of(this.context);
                            Navigator.pop(context);
                            if (add <= 0) return;
                            try {
                              await _firestoreService.restockItem(item.id, add);
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('Added $add ${item.unit} to ${item.name}.')));
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('Restock failed: $e'), backgroundColor: AppColors.error));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySky,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Add Stock", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<InventoryModel> items) {
    final waterItems = items.where((i) => i.category == 'water');
    final totalWaterStock = waterItems.fold<int>(0, (sum, i) => sum + i.currentStock);
    final totalWaterCapacity = waterItems.fold<int>(0, (sum, i) => sum + i.maxCapacity);
    final waterPct = totalWaterCapacity == 0 ? 0.0 : totalWaterStock / totalWaterCapacity;

    final lowStockItems = items.where((i) => i.isLowStock).toList();
    final bool hasAlerts = lowStockItems.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 480;

        Widget waterCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('WATER STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 0.8)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.sky50, borderRadius: BorderRadius.circular(6)),
                    child: Text('${(waterPct * 100).toStringAsFixed(0)}% Cap', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primarySky)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$totalWaterStock', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(width: 4),
                  Text('/ $totalWaterCapacity Gal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: waterPct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.slate100,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primarySky),
                ),
              ),
            ],
          ),
        );

        Widget attentionCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAlerts ? AppColors.coralAlert.withValues(alpha: 0.4) : AppColors.slate200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STOCK HEALTH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasAlerts ? AppColors.coralAlert : AppColors.slate500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasAlerts ? const Color(0xFFFEE2E2) : AppColors.emerald50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasAlerts ? 'Low Stock' : 'Optimal',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasAlerts ? AppColors.coralAlert : AppColors.emerald700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${lowStockItems.length}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: hasAlerts ? AppColors.coralAlert : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasAlerts ? 'Items need restock' : 'All lines healthy',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: items.isEmpty ? 0.0 : ((items.length - lowStockItems.length) / items.length).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.slate100,
                  valueColor: AlwaysStoppedAnimation<Color>(hasAlerts ? AppColors.coralAlert : AppColors.emerald600),
                ),
              ),
            ],
          ),
        );

        if (isSmallScreen) {
          return Column(
            children: [
              waterCard,
              const SizedBox(height: 10),
              attentionCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: waterCard),
            const SizedBox(width: 12),
            Expanded(child: attentionCard),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final bool isSelected = _stockFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _stockFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySky : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primarySky : AppColors.slate200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildInvCard(InventoryModel item) {
    final int val = item.currentStock;
    final int max = item.maxCapacity;
    final String unit = item.unit;
    final String title = item.name;
    final IconData icon = _iconForItem(item);
    final double pct = max == 0 ? 0.0 : (val / max).clamp(0.0, 1.0);
    final bool isCrit = item.isLowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCrit ? AppColors.coralAlert.withValues(alpha: 0.35) : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFFEE2E2) : AppColors.sky50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isCrit ? AppColors.coralAlert : AppColors.primarySky,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capitalize(item.category),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFFEE2E2) : AppColors.emerald50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCrit ? 'Low Stock' : 'Healthy',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCrit ? AppColors.coralAlert : AppColors.emerald700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$val',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCrit ? AppColors.coralAlert : AppColors.textLight,
                      ),
                    ),
                    TextSpan(
                      text: ' / $max $unit',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                isCrit ? '< ${item.minimumThreshold} min threshold' : '${(pct * 100).toStringAsFixed(0)}% available',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCrit ? AppColors.coralAlert : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(isCrit ? AppColors.coralAlert : AppColors.primarySky),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: () => _showRestockModal(item),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Restock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCrit ? AppColors.coralAlert : AppColors.primarySky,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(MaintenanceAlertModel alert) {
    final color = _urgencyColor(alert.urgency);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.isOverdue ? AppColors.coralAlert.withValues(alpha: 0.35) : AppColors.slate200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.build_circle_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.equipmentName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: alert.isCompleted ? AppColors.slate400 : AppColors.textLight,
                          decoration: alert.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _capitalize(alert.urgency),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(alert.taskType, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      alert.isOverdue ? Icons.error_outline : Icons.calendar_today,
                      size: 12,
                      color: alert.isOverdue ? AppColors.coralAlert : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.isCompleted
                          ? 'Completed'
                          : (alert.isOverdue
                          ? 'Overdue • Due ${alert.dueDate.month}/${alert.dueDate.day}/${alert.dueDate.year}'
                          : 'Due ${alert.dueDate.month}/${alert.dueDate.day}/${alert.dueDate.year}'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: alert.isOverdue ? FontWeight.bold : FontWeight.normal,
                        color: alert.isOverdue ? AppColors.coralAlert : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _firestoreService.setMaintenanceAlertCompleted(alert.id, !alert.isCompleted);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: alert.isCompleted ? AppColors.slate300 : AppColors.primarySky),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              alert.isCompleted ? 'Reopen' : 'Done',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: alert.isCompleted ? AppColors.slate500 : AppColors.primarySky,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<List<MaintenanceAlertModel>>(
        stream: _firestoreService.getMaintenanceAlertsStream(),
        builder: (context, snapshot) {
          final hasOverdue = (snapshot.data ?? const <MaintenanceAlertModel>[]).any((a) => a.isOverdue && !a.isCompleted);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeButton('Stock', Icons.inventory_2, 'inventory'),
              _modeButton('Machinery', Icons.precision_manufacturing, 'machinery', hasBadge: hasOverdue),
            ],
          );
        },
      ),
    );
  }

  Widget _modeButton(String label, IconData icon, String tabKey, {bool hasBadge = false}) {
    final bool selected = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primarySky : AppColors.slate500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? AppColors.primarySky : AppColors.slate500,
              ),
            ),
            if (hasBadge) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.coralAlert, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = UserRole.fromString(currentUserRoleNotifier.value);
    final isOwner = currentRole == UserRole.owner;
    final isStaff = currentRole == UserRole.staff;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header without redundant eyebrow text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.sky50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _activeTab == 'inventory' ? Icons.inventory_2 : Icons.precision_manufacturing,
                            color: AppColors.primarySky,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _activeTab == 'inventory' ? 'Stock Supplies' : 'Machinery Alerts',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight, height: 1.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildModeToggle(),
                ],
              ),
              const SizedBox(height: 24),

              // Tab 1: Inventory
              if (_activeTab == 'inventory')
                StreamBuilder<List<InventoryModel>>(
                  stream: _firestoreService.getInventoryStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Failed to load inventory: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final allItems = snapshot.data!;

                    final filteredItems = allItems.where((item) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      if (!matchesSearch) return false;

                      if (_stockFilter == 'all') return true;
                      if (_stockFilter == 'low_stock') return item.isLowStock;
                      return item.category == _stockFilter;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(allItems),
                        const SizedBox(height: 20),

                        // Search Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                            decoration: InputDecoration(
                              hintText: 'Search supplies by name...',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate400),
                              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate400),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: AppColors.slate400),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Chips Filter
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildFilterChip('All Items', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Water', 'water'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Packaging', 'packaging'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Low Stock', 'low_stock'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const Text(
                              'Tracked Supplies',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${filteredItems.length}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (filteredItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            alignment: Alignment.center,
                            child: Column(
                              children: const [
                                Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.slate300),
                                SizedBox(height: 8),
                                Text('No matching supplies found.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        else
                          ...filteredItems.map((item) => _buildInvCard(item)),
                      ],
                    );
                  },
                ),

              // Tab 2: Machinery Alerts
              if (_activeTab == 'machinery')
                StreamBuilder<List<MaintenanceAlertModel>>(
                  stream: _firestoreService.getMaintenanceAlertsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Failed to load alerts: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final alerts = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Active Equipment Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(100)),
                                  child: Text('${alerts.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600)),
                                ),
                              ],
                            ),
                            if (isOwner || isStaff)
                              OutlinedButton.icon(
                                onPressed: _showAddMaintenanceAlertDialog,
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primarySky,
                                  side: const BorderSide(color: AppColors.primarySky),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (alerts.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            alignment: Alignment.center,
                            child: Column(
                              children: const [
                                Icon(Icons.check_circle_outline, size: 40, color: AppColors.emerald600),
                                SizedBox(height: 8),
                                Text('No scheduled maintenance tasks.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                                SizedBox(height: 4),
                                Text('All plant machinery is in good standing.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        else
                          ...alerts.map((alert) => _buildMaintenanceCard(alert)),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  const _CustomDatePickerModal({super.key, required this.initialDate});

  @override
  State<_CustomDatePickerModal> createState() => _CustomDatePickerModalState();
}

class _CustomDatePickerModalState extends State<_CustomDatePickerModal> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _prevMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1));
  void _nextMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1));

  List<Widget> _buildDaysGrid() {
    List<Widget> days = [];
    int daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    int firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    int offset = firstWeekday == 7 ? 0 : firstWeekday;
    int prevDaysInMonth = DateTime(_displayMonth.year, _displayMonth.month, 0).day;

    for (int i = offset - 1; i >= 0; i--) {
      days.add(Center(
        child: Text('${prevDaysInMonth - i}', style: const TextStyle(color: AppColors.slate300, fontSize: 13)),
      ));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      DateTime loopDate = DateTime(_displayMonth.year, _displayMonth.month, i);
      bool isSelected = loopDate.year == _selectedDate.year &&
          loopDate.month == _selectedDate.month &&
          loopDate.day == _selectedDate.day;
      bool isToday = loopDate.year == DateTime.now().year &&
          loopDate.month == DateTime.now().month &&
          loopDate.day == DateTime.now().day;

      days.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = loopDate),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySky : (isToday ? AppColors.sky50 : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$i',
              style: TextStyle(
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isToday ? AppColors.primarySky : AppColors.textLight),
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 0,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
            boxShadow: const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((d) => SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildDaysGrid(),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text("Select", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}