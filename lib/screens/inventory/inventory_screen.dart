import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/inventory_model.dart';
import '../../services/firestore_service.dart';
import '../../main.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _activeTab = 'inventory';
  String _stockFilter = 'all';
  final FirestoreService _firestoreService = FirestoreService();

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s;

  IconData _iconForItem(InventoryModel item) {
    final name = item.name.toLowerCase();
    if (item.category == 'packaging') {
      return name.contains('cap') ? Icons.adjust : Icons.lock_open;
    }
    return (name.contains('alkaline') || name.contains('slim')) ? Icons.opacity : Icons.water_drop;
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return AppColors.coralAlert;
      case 'warning':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF059669);
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

    showDialog(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              elevation: 0,
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, top: 4),
                        child: Text(
                          'Schedule Maintenance',
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: equipmentController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Equipment name',
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: taskController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Task (e.g. Filter replacement)',
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildUrgencyButton('Routine', urgency == 'Routine', const Color(0xFF059669), () => setDialogState(() => urgency = 'Routine'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildUrgencyButton('Warning', urgency == 'Warning', const Color(0xFFD97706), () => setDialogState(() => urgency = 'Warning'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildUrgencyButton('Critical', urgency == 'Critical', const Color(0xFFE11D48), () => setDialogState(() => urgency = 'Critical'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await _showCustomDatePicker(context, dueDate);
                          if (picked != null) setDialogState(() => dueDate = picked);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FE),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF0284C7)),
                              const SizedBox(width: 12),
                              Text(
                                'Due ${dueDate.month.toString().padLeft(2, '0')}/${dueDate.day.toString().padLeft(2, '0')}/${dueDate.year}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4FA),
                                foregroundColor: const Color(0xFF334155),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: Text("Cancel", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
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
                                  messenger.showSnackBar(SnackBar(content: Text('Maintenance scheduled.', style: GoogleFonts.plusJakartaSans())));
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppColors.error));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ).copyWith(elevation: WidgetStateProperty.resolveWith((states) => 4)),
                              child: Text("Schedule", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          elevation: 0,
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Restock ${item.name}",
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), height: 1.2, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Current stock: '),
                        TextSpan(text: '${item.currentStock} ${item.unit}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      ],
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Quantity to Add (${item.unit}):",
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155), letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: restockController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              hintText: 'Enter quantity',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                        Text(item.unit, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          child: Text("Cancel", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final add = int.tryParse(restockController.text) ?? 0;
                            final messenger = ScaffoldMessenger.of(this.context);
                            Navigator.pop(context);
                            if (add == 0) return;
                            try {
                              await _firestoreService.restockItem(item.id, add);
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('Inventory Restocked successfully.', style: GoogleFonts.plusJakartaSans())));
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('Restock failed: $e', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppColors.error));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ).copyWith(elevation: WidgetStateProperty.resolveWith((states) => 4)),
                          child: Text("Restock", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildMaintenanceCard(MaintenanceAlertModel alert) {
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
            width: 44,
            height: 44,
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
                    Expanded(
                        child: Text(
                          alert.equipmentName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: alert.isCompleted ? AppColors.textSecondary : AppColors.textLight,
                            decoration: alert.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
                      child: Text(_capitalize(alert.urgency), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(alert.taskType, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  alert.isCompleted
                      ? 'Completed'
                      : (alert.isOverdue
                      ? 'Overdue • Due ${alert.dueDate.month}/${alert.dueDate.day}/${alert.dueDate.year}'
                      : 'Due ${alert.dueDate.month}/${alert.dueDate.day}/${alert.dueDate.year}'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: alert.isOverdue ? AppColors.coralAlert : AppColors.textSecondary,
                  ),
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
                messenger.showSnackBar(SnackBar(content: Text('Failed: $e', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppColors.error));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: alert.isCompleted ? const Color(0xFFF0F9FF) : const Color(0xFF6CF8BB), borderRadius: BorderRadius.circular(100)),
              child: Text(
                alert.isCompleted ? 'Reopen' : 'Done',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: alert.isCompleted ? const Color(0xFF0284C7) : const Color(0xFF00714D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final options = [
      {'id': 'all', 'name': 'All Categories'},
      {'id': 'water', 'name': 'Water'},
      {'id': 'packaging', 'name': 'Packaging'},
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: const Color(0xFFF0F9FF),
        splashColor: const Color(0xFFE0F2FE),
        hoverColor: const Color(0xFFF0F9FF),
        focusColor: Colors.transparent,
        shadowColor: const Color(0xFF131B2E).withValues(alpha: 0.12),
      ),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _stockFilter,
            icon: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            isDense: true,
            selectedItemBuilder: (_) => options
                .map((o) => Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list, size: 14, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    o['name']! == 'All Categories' ? 'Filter' : o['name']!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                  ),
                ],
              ),
            ))
                .toList(),
            items: options.map((o) {
              final isSelected = o['id'] == _stockFilter;
              return DropdownMenuItem<String>(
                value: o['id'],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          o['name']!,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF131B2E),
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check, size: 16, color: Color(0xFF0284C7)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _stockFilter = v);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : AppColors.textLight;
    final isOwner = currentUserRoleNotifier.value == 'owner';
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 130 + bottomInset),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: InkWell(
                            onTap: () => setState(() => _activeTab = 'inventory'),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                    color: _activeTab == 'inventory' ? const Color(0xFF0284C7) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: _activeTab == 'inventory' ? [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.3), blurRadius: 16)] : []
                                ),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2, size: 18, color: _activeTab == 'inventory' ? Colors.white : AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text('Stock Inventory',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13, fontWeight: FontWeight.bold, color: _activeTab == 'inventory' ? Colors.white : AppColors.textSecondary))
                                    ]
                                )
                            )
                        )
                    ),
                    Expanded(
                        child: InkWell(
                            onTap: () => setState(() => _activeTab = 'machinery'),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                    color: _activeTab == 'machinery' ? const Color(0xFF0284C7) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: _activeTab == 'machinery' ? [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.3), blurRadius: 16)] : []
                                ),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.precision_manufacturing, size: 18, color: _activeTab == 'machinery' ? Colors.white : AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text('Machinery Alerts',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13, fontWeight: FontWeight.bold, color: _activeTab == 'machinery' ? Colors.white : AppColors.textSecondary)),
                                      const SizedBox(width: 4),
                                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.coralAlert, shape: BoxShape.circle))
                                    ]
                                )
                            )
                        )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_activeTab == 'inventory') ...[
                StreamBuilder<List<InventoryModel>>(
                  stream: _firestoreService.getInventoryStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Failed to load inventory: ${snapshot.error}', style: GoogleFonts.plusJakartaSans(color: AppColors.error)),
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
                            Expanded(
                                child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('TOTAL VOLUME', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
                                        Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle),
                                            child: const Icon(Icons.water_drop, size: 16, color: Color(0xFF0284C7)))
                                      ]),
                                      const SizedBox(height: 8),
                                      Text.rich(TextSpan(children: [
                                        TextSpan(
                                            text: '$totalWaterStock',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                        TextSpan(text: ' / $totalWaterCapacity Gal', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary))
                                      ])),
                                      const SizedBox(height: 8),
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('${(waterPct * 100).toStringAsFixed(0)}% Cap',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                                        Text('Optimal', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary))
                                      ]),
                                      const SizedBox(height: 4),
                                      Container(
                                          height: 8,
                                          decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)),
                                          child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: waterPct.clamp(0.0, 1.0),
                                              child: Container(decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(100))))),
                                    ]))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('WARNING',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert, letterSpacing: 1)),
                                        Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(color: Color(0xFFFFDAD6), shape: BoxShape.circle),
                                            child: const Icon(Icons.warning, size: 16, color: AppColors.coralAlert))
                                      ]),
                                      const SizedBox(height: 8),
                                      Text.rich(TextSpan(children: [
                                        TextSpan(
                                            text: '${criticalItems.length}',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.coralAlert)),
                                        TextSpan(text: ' Line Critical', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary))
                                      ])),
                                      const SizedBox(height: 8),
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Expanded(
                                            child: Text(criticalItems.isEmpty ? 'All clear' : criticalItems.first.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coralAlert))),
                                        Text(criticalItems.isEmpty ? '' : '< ${criticalItems.first.minimumThreshold} left',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Container(
                                          height: 8,
                                          decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)),
                                          child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: criticalItems.isEmpty
                                                  ? 0.0
                                                  : (criticalItems.first.currentStock / (criticalItems.first.maxCapacity == 0 ? 1 : criticalItems.first.maxCapacity))
                                                  .clamp(0.0, 1.0),
                                              child: Container(decoration: BoxDecoration(color: AppColors.coralAlert, borderRadius: BorderRadius.circular(100))))),
                                    ]))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Flexible(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text('Tracked Supply Lines', maxLines: 1, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: textMain)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(100)),
                                  child: Text('${filteredInvItems.length} Items',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))))
                            ]),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterDropdown(),
                        ]),
                        const SizedBox(height: 16),
                        if (filteredInvItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('No items in this category.', style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                          ),
                        ...filteredInvItems.map((item) => _buildInvCard(item)),
                      ],
                    );
                  },
                ),
              ] else ...[
                if (isOwner)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _showAddMaintenanceAlertDialog,
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFF0284C7)),
                      label: Text('Schedule Maintenance', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0284C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                    ),
                  ),
                const SizedBox(height: 16),
                StreamBuilder<List<MaintenanceAlertModel>>(
                  stream: _firestoreService.getMaintenanceAlertsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Failed to load alerts: ${snapshot.error}', style: GoogleFonts.plusJakartaSans(color: AppColors.error)),
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
                        child: Text('No maintenance scheduled.', style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      );
                    }
                    return Column(children: alerts.map((a) => _buildMaintenanceCard(a)).toList());
                  },
                ),
              ]
            ],
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
          boxShadow: isCrit ? [BoxShadow(color: AppColors.coralAlert.withValues(alpha: 0.15), blurRadius: 20)] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: isCrit ? const Color(0xFFFFDAD6) : const Color(0xFFF0F9FF), shape: BoxShape.circle),
                      child: Icon(icon, color: isCrit ? AppColors.coralAlert : const Color(0xFF0284C7), size: 26)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      if (isCrit)
                        Row(children: [
                          const Icon(Icons.emergency, size: 14, color: AppColors.coralAlert),
                          const SizedBox(width: 4),
                          Text('Threshold Breach (< ${item.minimumThreshold})',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coralAlert))
                        ])
                      else
                        Text(item.category == 'water' ? 'Station Filter Bank A • RO UV' : 'Packaging & Consumables',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  )
                ],
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isCrit ? const Color(0xFFFFDAD6) : const Color(0xFF6CF8BB), borderRadius: BorderRadius.circular(100)),
                  child: Text(isCrit ? 'Critical' : 'In Stock',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: isCrit ? const Color(0xFF93000A) : const Color(0xFF00714D))))
            ],
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: '$val ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: isCrit ? AppColors.coralAlert : AppColors.textLight)),
              TextSpan(text: isCrit ? 'pcs left' : '/ $max $unit', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary))
            ])),
            Expanded(
                child: Text(isCrit ? 'Immediate Action' : '${(pct * 100).toStringAsFixed(1)}% Ready',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? AppColors.coralAlert : const Color(0xFF0284C7)),
                    overflow: TextOverflow.ellipsis))
          ]),
          const SizedBox(height: 6),
          Container(
              height: 8,
              decoration: BoxDecoration(color: const Color(0xFFEAEDFF), borderRadius: BorderRadius.circular(100)),
              child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(decoration: BoxDecoration(color: isCrit ? AppColors.coralAlert : const Color(0xFF0284C7), borderRadius: BorderRadius.circular(100))))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(isCrit ? Icons.timer : Icons.verified, size: 15, color: isCrit ? AppColors.textSecondary : AppColors.accentTeal),
                const SizedBox(width: 4),
                Text(isCrit ? 'Below minimum threshold' : (item.category == 'water' ? 'Purity: 0 ppm (Ultra)' : 'Stock healthy'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary))
              ]),
              InkWell(
                onTap: () => _showRestockModal(item),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: isCrit ? AppColors.coralAlert : const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: isCrit ? [BoxShadow(color: AppColors.coralAlert.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))] : []),
                    child: Row(children: [
                      Icon(isCrit ? Icons.priority_high : Icons.add_circle, size: 16, color: isCrit ? Colors.white : const Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(isCrit ? 'Restock Now' : 'Restock',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? Colors.white : const Color(0xFF0284C7)))
                    ])),
              )
            ],
          )
        ],
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

  final List<String> _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  final List<String> _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _prevMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1));
  void _nextMonth() => setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1));

  String _formatSelectedDate() {
    return '${_shortDays[_selectedDate.weekday - 1]}, ${_monthNames[_selectedDate.month - 1].substring(0, 3)} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  List<Widget> _buildDaysGrid() {
    List<Widget> days = [];
    int daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    int firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    int offset = firstWeekday == 7 ? 0 : firstWeekday;
    int prevDaysInMonth = DateTime(_displayMonth.year, _displayMonth.month, 0).day;

    for (int i = offset - 1; i >= 0; i--) {
      days.add(Container(
        alignment: Alignment.center,
        child: Text(
          '${prevDaysInMonth - i}',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      DateTime loopDate = DateTime(_displayMonth.year, _displayMonth.month, i);
      bool isSelected = loopDate.year == _selectedDate.year && loopDate.month == _selectedDate.month && loopDate.day == _selectedDate.day;
      bool isToday = loopDate.year == DateTime.now().year && loopDate.month == DateTime.now().month && loopDate.day == DateTime.now().day;

      days.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = loopDate),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0284C7) : (isToday ? const Color(0xFFF0F9FF) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected ? Border.all(color: const Color(0xFFE0F2FE)) : null,
              boxShadow: isSelected ? const [BoxShadow(color: Color(0x4D0EA5E9), blurRadius: 8, offset: Offset(0, 3))] : null,
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$i',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : (isToday ? const Color(0xFF0284C7) : const Color(0xFF334155)),
                    fontSize: 14,
                  ),
                ),
                if (isToday && !isSelected)
                  Positioned(bottom: 4, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle))),
              ],
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SELECT DATE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 1.2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF0F9FF), border: Border.all(color: const Color(0xFFE0F2FE)), borderRadius: BorderRadius.circular(100)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('ACTIVE CYCLE', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7), letterSpacing: 0.8)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_formatSelectedDate(), style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 20, color: Color(0xFF64748B)),
                      ],
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: _prevMonth,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.chevron_left, size: 18, color: Color(0xFF334155)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _nextMonth,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((d) => SizedBox(width: 36, child: Center(child: Text(d, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))))))
                      .toList(),
                ),
              ),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 2,
                children: _buildDaysGrid(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Cancel", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ).copyWith(elevation: WidgetStateProperty.resolveWith((states) => 4)),
                      child: Text("Confirm", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}