import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../main.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_feed.dart';
import '../customer/customer_map_screen.dart';
import '../customer/customer_main_screen.dart';
import '../delivery/fulfill_delivery_screen.dart';
import '../refund/owner_request_screen.dart';

class _ChipDef {
  final String key;
  final String label;
  final IconData? icon;
  final Color iconColor;

  const _ChipDef(this.key, this.label, this.icon, this.iconColor);
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const String _font = 'Plus Jakarta Sans';
  final NotificationReadStore _store = NotificationReadStore.instance;
  String _filter = 'all';

  TextStyle _ts({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      AppTypography.ts(
        size: size,
        weight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  List<_ChipDef> _chipsFor(UserRole role) {
    return switch (role) {
      UserRole.owner => const [
        _ChipDef('delivery', 'Delivery', Icons.local_shipping_outlined, AppColors.primarySky),
        _ChipDef('orders', 'Orders & POS', Icons.receipt_long_outlined, AppColors.tealAccent),
        _ChipDef('system', 'System', Icons.tune_rounded, AppColors.tertiary),
      ],
      UserRole.staff => const [
        _ChipDef('orders', 'POS', Icons.point_of_sale_outlined, AppColors.tealAccent),
        _ChipDef('system', 'Inventory', Icons.inventory_2_outlined, AppColors.tertiary),
      ],
      UserRole.rider => const [
        _ChipDef('delivery', 'Delivery', Icons.local_shipping_outlined, AppColors.primarySky),
      ],
      UserRole.customer => const [
        _ChipDef('delivery', 'Delivery', Icons.local_shipping_outlined, AppColors.primarySky),
        _ChipDef('orders', 'Orders', Icons.receipt_long_outlined, AppColors.tealAccent),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = AuthService().currentUserId;
    final double topInset = MediaQuery.of(context).padding.top;

    return ValueListenableBuilder<String>(
      valueListenable: currentUserRoleNotifier,
      builder: (context, rawRole, _) {
        final String feedRole = normalizeNotificationRole(rawRole);
        final UserRole typedRole = UserRole.fromString(rawRole);

        if (uid != null) _store.ensureLoaded(uid);

        return Scaffold(
          backgroundColor: AppColors.surfaceCanvas, // Standard #F8FAFC
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Exactly 800px width
              child: Column(
                children: [
                  _buildHeader(context, topInset),
                  Expanded(
                    child: uid == null
                        ? _stateBlock(Icons.lock_outline, 'Not signed in', 'Sign in to view your notification stream.')
                        : ListenableBuilder(
                      listenable: _store,
                      builder: (context, _) => NotificationFeed(
                        role: feedRole,
                        uid: uid,
                        builder: (context, items, loading, error) =>
                            _buildBody(context, uid, typedRole, items, loading, error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double topInset) {
    return Container(
      height: 64 + topInset,
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceCanvas,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateBlock(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: AppColors.primarySky),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _ts(size: 16, weight: FontWeight.w700, color: AppColors.textLight),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _ts(size: 12, weight: FontWeight.w400, color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      String uid,
      UserRole role,
      List<AppNotification> items,
      bool loading,
      bool error,
      ) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final bool ready = _store.isLoadedFor(uid);

    if (!ready || (items.isEmpty && loading)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primarySky));
    }
    if (items.isEmpty && error) {
      return _stateBlock(Icons.error_outline, 'Unable to load notifications', 'Please check your connection and try again later.');
    }
    if (items.isEmpty) {
      return _stateBlock(Icons.notifications_none, 'No notifications yet', 'New alerts and operational updates will appear here.');
    }

    final chips = _chipsFor(role);
    final String active = (_filter == 'all' || chips.any((c) => c.key == _filter)) ? _filter : 'all';
    final List<AppNotification> filtered = active == 'all' ? items : items.where((n) => n.category.name == active).toList();
    final int unreadCount = items.where((n) => !_store.isRead(n.id)).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24 + bottomInset),
      children: [
        _buildTopBar(uid, items, unreadCount),
        _buildFilterRow(chips, active, items.length),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _stateBlock(Icons.filter_list_off, 'Nothing here', 'There are no notifications in this category.'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++)
                  _buildCard(context, uid, role, filtered[i]),
              ],
            ),
          ),
        if (unreadCount == 0 && filtered.isNotEmpty) _buildFooter(),
      ],
    );
  }

  Widget _buildTopBar(String uid, List<AppNotification> items, int unreadCount) {
    final bool allRead = unreadCount == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allRead ? AppColors.slate100 : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  allRead ? 'All caught up' : '$unreadCount unread',
                  style: _ts(
                    size: 12,
                    weight: FontWeight.w700,
                    color: allRead ? AppColors.slate600 : AppColors.primarySky,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Across your updates',
                style: _ts(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (!allRead)
            TextButton.icon(
              onPressed: () => _store.markAllRead(uid, items.map((n) => n.id)),
              icon: const Icon(Icons.done_all, size: 16, color: AppColors.primarySky),
              label: Text(
                'Mark all read',
                style: _ts(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.primarySky,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(List<_ChipDef> chips, String active, int totalCount) {
    final all = <_ChipDef>[const _ChipDef('all', 'All', null, Colors.white), ...chips];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < all.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _buildChip(all[i], active == all[i].key, totalCount),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(_ChipDef def, bool isActive, int totalCount) {
    final Color fg = isActive ? Colors.white : AppColors.textSecondary;

    return InkWell(
      onTap: () => setState(() => _filter = def.key),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySky : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? AppColors.primarySky : AppColors.slate200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (def.icon != null) ...[
              Icon(def.icon, size: 15, color: isActive ? Colors.white : def.iconColor),
              const SizedBox(width: 6),
            ],
            Text(
              def.label,
              style: _ts(
                size: 12,
                weight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
            if (def.key == 'all') ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.25) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$totalCount',
                  style: _ts(size: 10, weight: FontWeight.w800, color: fg, height: 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _destinationFor(UserRole role, AppNotification n) {
    final bool isRefund = n.id.startsWith('refund_request:') || n.id.startsWith('cust_refund:');
    if (isRefund) {
      if (role == UserRole.owner || role == UserRole.staff) return const OwnerRequestScreen();
      if (role != UserRole.rider) return const CustomerMainScreen(initialTab: 1);
      return null;
    }
    final OrderModel? order = n.trackOrder;
    if (order == null) {
      if ((role == UserRole.owner || role == UserRole.staff) && n.category == NotificationCategory.system) {
        return shellAt(ShellTab.stock);
      }
      return null;
    }
    final bool orderActive = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
    if (role == UserRole.rider) {
      if (orderActive && order.assignedRiderId == AuthService().currentUserId) {
        return FulfillDeliveryScreen(order: order);
      }
      return shellAt(ShellTab.queue);
    }
    if (role == UserRole.owner || role == UserRole.staff) {
      return shellAt(ShellTab.queue);
    }
    if (order.status == OrderStatus.outForDelivery) {
      return CustomerMapScreen(order: order);
    }
    return const CustomerMainScreen(initialTab: 1);
  }

  Widget _buildCard(BuildContext context, String uid, UserRole role, AppNotification n) {
    final bool read = _store.isRead(n.id);
    final String timeText = n.timeLabel ?? notificationTimeText(n.sortTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: read ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: read ? AppColors.slate200 : AppColors.slate200.withValues(alpha: 0.9),
        ),
        boxShadow: read
            ? null
            : const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _store.markRead(uid, n.id);
            final destination = _destinationFor(role, n);
            if (destination != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: n.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, size: 20, color: n.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _ts(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AppColors.textLight,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (!read) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySky,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            read ? Icons.history : Icons.schedule,
                            size: 12,
                            color: read ? AppColors.slate400 : AppColors.primarySky,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: _ts(
                              size: 11,
                              weight: FontWeight.w500,
                              color: read ? AppColors.slate400 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.message,
                        style: _ts(
                          size: 13,
                          weight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      if (n.tag != null || n.trackOrder != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (n.tag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  n.tag!,
                                  style: _ts(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: AppColors.slate600,
                                  ),
                                ),
                              ),
                            if (n.tag != null && n.trackOrder != null)
                              const SizedBox(width: 8),
                            if (n.trackOrder != null)
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  _store.markRead(uid, n.id);
                                  final destination = _destinationFor(role, n);
                                  if (destination != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me_outlined, size: 14, color: AppColors.primarySky),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Track Live Map →',
                                        style: _ts(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: AppColors.primarySky,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
            child: const Icon(Icons.done_all, size: 18, color: AppColors.primarySky),
          ),
          const SizedBox(height: 6),
          Text(
            "You're all caught up!",
            textAlign: TextAlign.center,
            style: _ts(size: 14, weight: FontWeight.w700, color: AppColors.textLight),
          ),
          const SizedBox(height: 2),
          Text(
            'All updates and alerts are synchronized.',
            textAlign: TextAlign.center,
            style: _ts(size: 11, weight: FontWeight.w400, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}