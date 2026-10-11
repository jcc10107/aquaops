import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../main.dart';
import '../../widgets/notification_feed.dart';
import '../customer/customer_map_screen.dart';

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
  static const Color _bg = Color(0xFFF6FAFC);
  static const Color _primary = Color(0xFF0284C7);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tertiary = Color(0xFF0051D5);
  static const Color _frost = Color(0xFFE0F2FE);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _outline = Color(0xFF707881);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _mint = Color(0xFF6CF8BB);
  static const Color _mintText = Color(0xFF00714D);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _surfaceCanvas = Color(0xFFF8FAFC);

  final NotificationReadStore _store = NotificationReadStore.instance;
  String _filter = 'all';

  TextStyle _ts({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  List<_ChipDef> _chipsFor(String role) {
    switch (role) {
      case 'owner':
        return const [
          _ChipDef('delivery', 'Delivery', Icons.local_shipping, _primary),
          _ChipDef('orders', 'Orders & POS', Icons.receipt_long, _teal),
          _ChipDef('system', 'System', Icons.tune, _tertiary),
        ];
      case 'staff':
        return const [
          _ChipDef('orders', 'POS', Icons.point_of_sale, _teal),
          _ChipDef('system', 'Inventory', Icons.inventory_2, _tertiary),
        ];
      case 'rider':
        return const [
          _ChipDef('delivery', 'Delivery', Icons.local_shipping, _primary),
        ];
      default:
        return const [
          _ChipDef('delivery', 'Delivery', Icons.local_shipping, _primary),
          _ChipDef('orders', 'Orders', Icons.receipt_long, _teal),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final double topInset = MediaQuery.of(context).padding.top;

    return ValueListenableBuilder<String>(
      valueListenable: currentUserRoleNotifier,
      builder: (context, rawRole, _) {
        final String role = normalizeNotificationRole(rawRole);
        if (uid != null) _store.ensureLoaded(uid);

        return Scaffold(
          backgroundColor: _bg,
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  _buildHeader(context, topInset),
                  Expanded(
                    child: uid == null
                        ? _stateBlock(Icons.lock_outline, 'Not signed in', 'Sign in to see your notifications.')
                        : ListenableBuilder(
                      listenable: _store,
                      builder: (context, _) => NotificationFeed(
                        role: role,
                        uid: uid,
                        builder: (context, items, loading, error) => _buildBody(context, uid, role, items, loading, error),
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
      padding: EdgeInsets.only(top: topInset, left: 12, right: 12),
      decoration: const BoxDecoration(
        color: Color(0xF2F6FAFC),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: 'Go back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back, size: 24, color: _onSurface),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Notifications',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(size: 17, weight: FontWeight.w700, color: _onSurface, letterSpacing: -0.17),
              ),
            ),
          ),
          const SizedBox(width: 44, height: 44),
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
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: _frost, shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: _primary),
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: _ts(size: 17, weight: FontWeight.w700, color: _onSurface, letterSpacing: -0.17)),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: _ts(size: 11, weight: FontWeight.w400, color: _onSurfaceVariant, height: 1.45)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      String uid,
      String role,
      List<AppNotification> items,
      bool loading,
      bool error,
      ) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final bool ready = _store.isLoadedFor(uid);

    if (!ready || (items.isEmpty && loading)) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (items.isEmpty && error) {
      return _stateBlock(Icons.error_outline, 'Unable to load notifications', 'Please check your connection and try again later.');
    }
    if (items.isEmpty) {
      return _stateBlock(Icons.notifications_none, 'No notifications yet', 'New alerts and updates will appear here.');
    }

    final chips = _chipsFor(role);
    final String active = (_filter == 'all' || chips.any((c) => c.key == _filter)) ? _filter : 'all';
    final List<AppNotification> filtered = active == 'all' ? items : items.where((n) => n.category.name == active).toList();
    final int unreadCount = items.where((n) => !_store.isRead(n.id)).length;

    return ListView(
      padding: EdgeInsets.only(bottom: 24 + bottomInset),
      children: [
        _buildTopBar(uid, items, unreadCount),
        _buildFilterRow(chips, active, items.length),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _stateBlock(Icons.notifications_none, 'Nothing here', 'There are no notifications in this category.'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildCard(uid, filtered[i]),
                ],
              ],
            ),
          ),
        if (unreadCount == 0) _buildFooter(),
      ],
    );
  }

  Widget _buildTopBar(String uid, List<AppNotification> items, int unreadCount) {
    final bool allRead = unreadCount == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _frost, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.8), blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        allRead ? 'All read' : '$unreadCount Unread',
                        style: _ts(size: 11, weight: FontWeight.w700, color: _primary, height: 1.27, letterSpacing: 0.22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    "Today's Stream",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(size: 11, weight: FontWeight.w400, color: _onSurfaceVariant, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: allRead ? null : () => _store.markAllRead(uid, items.map((n) => n.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(allRead ? Icons.check : Icons.done_all, size: 17, color: allRead ? _secondary : _primary),
                  const SizedBox(width: 4),
                  Text(
                    allRead ? 'All read' : 'Mark all read',
                    style: _ts(size: 13, weight: FontWeight.w700, color: allRead ? _secondary : _primary, height: 1.23, letterSpacing: 0.13),
                  ),
                ],
              ),
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
            if (i > 0) const SizedBox(width: 4),
            _buildChip(all[i], active == all[i].key, totalCount),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(_ChipDef def, bool isActive, int totalCount) {
    final Color fg = isActive ? Colors.white : _onSurfaceVariant;
    return GestureDetector(
      onTap: () => setState(() => _filter = def.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive
              ? const [BoxShadow(color: Color(0x590284C7), blurRadius: 8, offset: Offset(0, 2))]
              : const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (def.icon != null) ...[
              Icon(def.icon, size: 15, color: isActive ? Colors.white : def.iconColor),
              const SizedBox(width: 6),
            ],
            Text(def.label, style: _ts(size: 11, weight: FontWeight.w700, color: fg, height: 1.27, letterSpacing: 0.22)),
            if (def.key == 'all') ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.2) : _slate200,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text('$totalCount', style: _ts(size: 10, weight: FontWeight.w700, color: fg, height: 1)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String uid, AppNotification n) {
    final bool read = _store.isRead(n.id);
    final String timeText = n.timeLabel ?? notificationTimeText(n.sortTime);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _store.markRead(uid, n.id),
      child: Opacity(
        opacity: read ? 0.9 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: read ? const Color(0xFFEDF2F7) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: read ? const Color(0xFFCBD5E1) : _slate200.withValues(alpha: 0.7)),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: n.iconBg,
                  shape: BoxShape.circle,
                  boxShadow: read ? null : [BoxShadow(color: n.iconColor.withValues(alpha: 0.3), blurRadius: 10)],
                ),
                child: Icon(n.icon, size: 22, color: n.iconColor),
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
                            style: _ts(size: 17, weight: FontWeight.w700, color: _onSurface, height: 1.41, letterSpacing: -0.17),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (read)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _surfaceCanvas,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _slate200.withValues(alpha: 0.7)),
                            ),
                            child: Text('Read', style: _ts(size: 10, weight: FontWeight.w800, color: _outline, height: 1.2, letterSpacing: 0.6)),
                          )
                        else
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 7),
                            decoration: BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.75), blurRadius: 8)],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(read ? Icons.history : Icons.schedule, size: 13, color: read ? _outline : _primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            timeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(size: 11, weight: FontWeight.w400, color: _onSurfaceVariant, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.message, style: _ts(size: 13, weight: FontWeight.w500, color: _onSurfaceVariant, height: 1.38)),
                    if (n.tag != null || n.trackOrder != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (n.trackOrder != null)
                            GestureDetector(
                              onTap: () {
                                _store.markRead(uid, n.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CustomerMapScreen(order: n.trackOrder!)),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _primary,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [BoxShadow(color: Color(0x590284C7), blurRadius: 14, offset: Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.near_me, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text('Track Live Map', style: _ts(size: 11, weight: FontWeight.w700, color: Colors.white, height: 1.27, letterSpacing: 0.22)),
                                  ],
                                ),
                              ),
                            ),
                          if (n.tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(999)),
                              child: Text(n.tag!, style: _ts(size: 10, weight: FontWeight.w800, color: _mintText, height: 1.2, letterSpacing: 0.6)),
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
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: _frost, shape: BoxShape.circle),
            child: const Icon(Icons.done_all, size: 20, color: _primary),
          ),
          const SizedBox(height: 4),
          Text("You're all caught up!", textAlign: TextAlign.center, style: _ts(size: 17, weight: FontWeight.w700, color: _onSurface, height: 1.41, letterSpacing: -0.17)),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'All alerts and order notifications are synchronized with Drink 8 Hub.',
              textAlign: TextAlign.center,
              style: _ts(size: 11, weight: FontWeight.w400, color: _onSurfaceVariant, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}