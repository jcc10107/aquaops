// lib/widgets/notification_bell.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

class NotificationBell extends StatefulWidget {
  final bool isDark;
  const NotificationBell({super.key, this.isDark = false});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final FirestoreService _firestoreService = FirestoreService();
  int _seenCount = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryModel>>(
      stream: _firestoreService.getInventoryStream(),
      builder: (context, invSnapshot) {
        return StreamBuilder<List<MaintenanceAlertModel>>(
          stream: _firestoreService.getMaintenanceAlertsStream(),
          builder: (context, alertSnapshot) {
            return StreamBuilder<List<OrderModel>>(
              stream: _firestoreService.getActiveOrdersStream(),
              builder: (context, orderSnapshot) {
                final lowStock = (invSnapshot.data ?? const <InventoryModel>[]).where((i) => i.isLowStock).toList();
                final overdueAlerts = (alertSnapshot.data ?? const <MaintenanceAlertModel>[]).where((a) => a.isOverdue).toList();
                final unassigned = (orderSnapshot.data ?? const <OrderModel>[]).where((o) => o.assignedRiderId == null).toList();

                final entries = <(IconData, Color, String, String)>[
                  for (final i in lowStock)
                    (Icons.inventory_2, AppColors.coralAlert, 'Low Stock Alert', '${i.name} is below minimum threshold (${i.currentStock} left).'),
                  for (final a in overdueAlerts)
                    (Icons.build, const Color(0xFFD97706), 'Maintenance Overdue', '${a.equipmentName} — ${a.taskType} is overdue.'),
                  for (final o in unassigned)
                    (Icons.local_shipping, AppColors.primary, 'Unassigned Delivery', 'Order ${o.orderNumber} for ${o.customerName} needs a rider.'),
                ];

                final showBadge = entries.length > _seenCount;
                final isDark = widget.isDark;

                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PopupMenuButton<void>(
                        offset: const Offset(0, 50),
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
                        elevation: 12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        icon: Icon(Icons.notifications_none, color: isDark ? Colors.grey[300] : AppColors.textVariant, size: 22),
                        onOpened: () => setState(() => _seenCount = entries.length),
                        itemBuilder: (context) => [
                          PopupMenuItem<void>(
                            enabled: false,
                            child: Text('Alerts (${entries.length})', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                          ),
                          const PopupMenuDivider(),
                          if (entries.isEmpty)
                            PopupMenuItem<void>(enabled: false, child: Text('No alerts right now.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)))
                          else
                            ...entries.map((e) => PopupMenuItem<void>(
                              enabled: false,
                              child: SizedBox(
                                width: 260,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(e.$1, size: 16, color: e.$2),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.$3, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(e.$4, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        ],
                      ),
                      if (showBadge)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.coralAlert, Color(0xFFDC2626)]),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                '${entries.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
