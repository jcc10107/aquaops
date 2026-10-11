import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../services/firestore_service.dart';

enum NotificationCategory { delivery, orders, system }

String normalizeNotificationRole(String raw) {
  if (raw == 'owner' || raw == 'staff' || raw == 'rider') return raw;
  return 'customer';
}

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _fmtClock(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $ampm';
}

String notificationTimeText(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m minute${m == 1 ? '' : 's'} ago';
  }
  final startOfToday = DateTime(now.year, now.month, now.day);
  if (!t.isBefore(startOfToday)) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
  if (!t.isBefore(startOfYesterday)) return 'Yesterday • ${_fmtClock(t)}';
  return '${_fmtDate(t)} • ${_fmtClock(t)}';
}

class AppNotification {
  final String id;
  final NotificationCategory category;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final DateTime sortTime;
  final String? timeLabel;
  final String? tag;
  final OrderModel? trackOrder;

  const AppNotification({
    required this.id,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.sortTime,
    this.timeLabel,
    this.tag,
    this.trackOrder,
  });
}

class NotificationReadStore extends ChangeNotifier {
  NotificationReadStore._();
  static final NotificationReadStore instance = NotificationReadStore._();

  String? _uid;
  bool _loading = false;
  final Set<String> _read = <String>{};

  String _key(String uid) => 'read_notifications_$uid';

  bool isLoadedFor(String uid) => _uid == uid;

  bool isRead(String id) => _read.contains(id);

  Future<void> ensureLoaded(String uid) async {
    if (_uid == uid || _loading) return;
    _loading = true;
    final Set<String> loaded = <String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      loaded.addAll(prefs.getStringList(_key(uid)) ?? const <String>[]);
    } catch (_) {}
    _read
      ..clear()
      ..addAll(loaded);
    _uid = uid;
    _loading = false;
    notifyListeners();
  }

  void _trim() {
    if (_read.length <= 500) return;
    final list = _read.toList();
    _read
      ..clear()
      ..addAll(list.sublist(list.length - 500));
  }

  Future<void> _persist(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(uid), _read.toList());
    } catch (_) {}
  }

  void markRead(String uid, String id) {
    if (_uid != uid || _read.contains(id)) return;
    _read.add(id);
    _trim();
    notifyListeners();
    _persist(uid);
  }

  void markAllRead(String uid, Iterable<String> ids) {
    if (_uid != uid) return;
    _read.addAll(ids);
    _trim();
    notifyListeners();
    _persist(uid);
  }
}

class NotificationFeed extends StatefulWidget {
  final String role;
  final String? uid;
  final Widget Function(BuildContext context, List<AppNotification> items, bool isLoading, bool hasError) builder;

  const NotificationFeed({
    super.key,
    required this.role,
    required this.uid,
    required this.builder,
  });

  @override
  State<NotificationFeed> createState() => _NotificationFeedState();
}

class _NotificationFeedState extends State<NotificationFeed> {
  static const Color _blue = Color(0xFF0284C7);
  static const Color _frost = Color(0xFFE0F2FE);
  static const Color _mint = Color(0xFF6CF8BB);
  static const Color _mintText = Color(0xFF00714D);
  static const Color _coral = Color(0xFFF43F5E);
  static const Color _coralBg = Color(0xFFFFDAD6);
  static const Color _amber = Color(0xFFD97706);
  static const Color _amberBg = Color(0xFFFEF3C7);

  final FirestoreService _fs = FirestoreService();
  Stream<List<InventoryModel>>? _inventory;
  Stream<List<MaintenanceAlertModel>>? _maintenance;
  Stream<List<OrderModel>>? _orders;
  Stream<List<RefundModel>>? _refunds;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant NotificationFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role || oldWidget.uid != widget.uid) {
      _initStreams();
    }
  }

  void _initStreams() {
    _inventory = null;
    _maintenance = null;
    _orders = null;
    _refunds = null;
    final uid = widget.uid;
    switch (widget.role) {
      case 'owner':
        _inventory = _fs.getInventoryStream();
        _maintenance = _fs.getMaintenanceAlertsStream();
        _orders = _fs.getAllOrdersStream();
        _refunds = _fs.getRefundRequestsStream();
        break;
      case 'staff':
        _inventory = _fs.getInventoryStream();
        _maintenance = _fs.getMaintenanceAlertsStream();
        _orders = _fs.getAllOrdersStream();
        break;
      case 'rider':
        _orders = _fs.getAllOrdersStream();
        break;
      default:
        if (uid != null) {
          _orders = _fs.getOrdersForCustomerStream(uid);
          _refunds = _fs.getRefundRequestsForCustomerStream(uid);
        }
        break;
    }
  }

  Widget _source<T>(Stream<T>? stream, Widget Function(AsyncSnapshot<T>? snapshot) build) {
    if (stream == null) return build(null);
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) => build(snapshot),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _source<List<InventoryModel>>(_inventory, (inv) {
      return _source<List<MaintenanceAlertModel>>(_maintenance, (maint) {
        return _source<List<OrderModel>>(_orders, (orders) {
          return _source<List<RefundModel>>(_refunds, (refunds) {
            final snaps = <AsyncSnapshot<dynamic>>[
              if (inv != null) inv,
              if (maint != null) maint,
              if (orders != null) orders,
              if (refunds != null) refunds,
            ];
            final bool loading = snaps.any((s) => !s.hasData && !s.hasError);
            final bool error = snaps.any((s) => s.hasError);
            final items = _compute(
              inv?.data ?? const <InventoryModel>[],
              maint?.data ?? const <MaintenanceAlertModel>[],
              orders?.data ?? const <OrderModel>[],
              refunds?.data ?? const <RefundModel>[],
            );
            return widget.builder(context, items, loading, error);
          });
        });
      });
    });
  }

  List<AppNotification> _compute(
      List<InventoryModel> inv,
      List<MaintenanceAlertModel> maint,
      List<OrderModel> orders,
      List<RefundModel> refunds,
      ) {
    final now = DateTime.now();
    final items = <AppNotification>[];
    switch (widget.role) {
      case 'owner':
        items.addAll(_stockItems(inv, maint, now));
        items.addAll(_ownerOrderItems(orders, now));
        items.addAll(_posItems(orders, now));
        items.addAll(_ownerRefundItems(refunds));
        break;
      case 'staff':
        items.addAll(_stockItems(inv, maint, now));
        items.addAll(_posItems(orders, now));
        break;
      case 'rider':
        items.addAll(_riderItems(orders, now));
        break;
      default:
        items.addAll(_customerOrderItems(orders, now));
        items.addAll(_customerRefundItems(refunds, now));
        break;
    }
    items.sort((a, b) {
      final c = b.sortTime.compareTo(a.sortTime);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return items;
  }

  String _summary(OrderModel o) {
    if (o.items.isEmpty) return 'Your order';
    return o.items.map((i) => '${i.quantity}× ${i.name}').join(', ');
  }

  String _money(double v) => '₱${v.toStringAsFixed(2)}';

  String _payment(OrderModel o) => o.paymentMethod == PaymentMethod.gcash ? 'GCash' : 'Cash';

  List<AppNotification> _stockItems(List<InventoryModel> inv, List<MaintenanceAlertModel> maint, DateTime now) {
    final items = <AppNotification>[];
    for (final i in inv.where((i) => i.isLowStock)) {
      items.add(AppNotification(
        id: 'low_stock:${i.id}',
        category: NotificationCategory.system,
        icon: Icons.inventory_2,
        iconColor: _coral,
        iconBg: _coralBg,
        title: 'Low Stock Alert',
        message: '${i.name} is below minimum threshold (${i.currentStock} ${i.unit} left).',
        sortTime: now,
        timeLabel: 'Needs restock',
      ));
    }
    for (final a in maint.where((a) => a.isOverdue)) {
      items.add(AppNotification(
        id: 'maint:${a.id}',
        category: NotificationCategory.system,
        icon: Icons.build_circle,
        iconColor: _amber,
        iconBg: _amberBg,
        title: 'Maintenance Overdue',
        message: '${a.equipmentName} — ${a.taskType} is overdue.',
        sortTime: a.dueDate,
        timeLabel: 'Due ${_fmtDate(a.dueDate)}',
      ));
    }
    return items;
  }

  List<AppNotification> _posItems(List<OrderModel> orders, DateTime now) {
    final pos = orders
        .where((o) => o.orderNumber.startsWith('POS-') && now.difference(o.createdAt).inHours < 24)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pos.take(15).map((o) {
      return AppNotification(
        id: 'pos:${o.id}',
        category: NotificationCategory.orders,
        icon: Icons.point_of_sale,
        iconColor: _mintText,
        iconBg: _mint,
        title: 'POS Sale ${o.orderNumber}',
        message: '${o.items.map((i) => '${i.quantity}× ${i.name}').join(', ')} • ${_money(o.totalAmount)} paid via ${_payment(o)}.',
        sortTime: o.createdAt,
        tag: _payment(o),
      );
    }).toList();
  }

  List<AppNotification> _ownerOrderItems(List<OrderModel> orders, DateTime now) {
    final items = <AppNotification>[];
    for (final o in orders) {
      if (o.orderNumber.startsWith('POS-')) continue;
      final active = o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;
      if (active && o.assignedRiderId == null) {
        items.add(AppNotification(
          id: 'unassigned:${o.id}',
          category: NotificationCategory.delivery,
          icon: Icons.local_shipping,
          iconColor: _blue,
          iconBg: _frost,
          title: 'Unassigned Delivery',
          message: 'Order ${o.orderNumber} for ${o.customerName} needs a rider.',
          sortTime: now,
          timeLabel: 'Needs a rider',
        ));
      }
      if (o.status == OrderStatus.outForDelivery && o.lastTransferReason != null && o.lastTransferReason!.trim().isNotEmpty) {
        items.add(AppNotification(
          id: 'transfer:${o.id}:${o.assignedRiderId}',
          category: NotificationCategory.delivery,
          icon: Icons.swap_horiz,
          iconColor: _amber,
          iconBg: _amberBg,
          title: 'Delivery Transferred',
          message: 'Order ${o.orderNumber} is now with ${o.assignedRiderName ?? 'another rider'}. Reason: ${o.lastTransferReason}.',
          sortTime: o.createdAt,
          timeLabel: 'In progress',
        ));
      }
      if (o.status == OrderStatus.cancelled && now.difference(o.createdAt).inDays <= 3) {
        items.add(AppNotification(
          id: 'owner_cancel:${o.id}',
          category: NotificationCategory.orders,
          icon: Icons.cancel,
          iconColor: _coral,
          iconBg: _coralBg,
          title: 'Order Cancelled',
          message: 'Order ${o.orderNumber} from ${o.customerName} (${_money(o.totalAmount)}) was cancelled.',
          sortTime: o.createdAt,
          timeLabel: 'Cancelled',
        ));
      }
    }
    return items;
  }

  List<AppNotification> _ownerRefundItems(List<RefundModel> refunds) {
    return refunds.where((r) => r.status == RefundStatus.pending).map((r) {
      return AppNotification(
        id: 'refund_request:${r.id}',
        category: NotificationCategory.orders,
        icon: Icons.assignment_return,
        iconColor: _amber,
        iconBg: _amberBg,
        title: 'Refund Request Awaiting Review',
        message: '${r.customerName} requested ${_money(r.amount)} for order ${r.orderNumber}${r.reason.isEmpty ? '' : ' — ${r.reason}'}.',
        sortTime: r.requestedAt,
        tag: 'Needs Action',
      );
    }).toList();
  }

  List<AppNotification> _riderItems(List<OrderModel> orders, DateTime now) {
    final uid = widget.uid;
    final items = <AppNotification>[];
    for (final o in orders.where((o) => uid != null && o.assignedRiderId == uid)) {
      if (o.status == OrderStatus.outForDelivery) {
        final transferred = o.lastTransferReason != null && o.lastTransferReason!.trim().isNotEmpty;
        final summary = o.items.map((i) => '${i.quantity}× ${i.name}').join(', ');
        final address = (o.deliveryAddress ?? '').trim();
        items.add(AppNotification(
          id: 'rider_assign:${o.id}:${o.assignedRiderId}',
          category: NotificationCategory.delivery,
          icon: transferred ? Icons.swap_horiz : Icons.two_wheeler,
          iconColor: transferred ? _amber : _blue,
          iconBg: transferred ? _amberBg : _frost,
          title: transferred ? 'Delivery Transferred to You' : 'New Delivery Assigned',
          message: '${o.orderNumber} for ${o.customerName}${address.isEmpty ? '' : ' • $address'} • $summary • ${_money(o.totalAmount)} (${_payment(o)})${transferred ? '. Reason: ${o.lastTransferReason}' : ''}.',
          sortTime: o.createdAt,
          timeLabel: 'Active now',
          tag: _payment(o),
        ));
      } else if (o.status == OrderStatus.cancelled && now.difference(o.createdAt).inDays <= 3) {
        items.add(AppNotification(
          id: 'rider_cancel:${o.id}',
          category: NotificationCategory.delivery,
          icon: Icons.cancel,
          iconColor: _coral,
          iconBg: _coralBg,
          title: 'Delivery Cancelled',
          message: 'Order ${o.orderNumber} for ${o.customerName} was cancelled. No drop-off is needed.',
          sortTime: o.createdAt,
          timeLabel: 'Cancelled',
        ));
      }
    }
    return items;
  }

  List<AppNotification> _customerOrderItems(List<OrderModel> orders, DateTime now) {
    final items = <AppNotification>[];
    for (final o in orders) {
      switch (o.status) {
        case OrderStatus.pending:
          items.add(AppNotification(
            id: 'cust_order:${o.id}:pending',
            category: NotificationCategory.orders,
            icon: Icons.receipt_long,
            iconColor: _mintText,
            iconBg: _mint,
            title: 'Order ${o.orderNumber} Placed',
            message: '${_summary(o)} • ${_money(o.totalAmount)}. We are assigning a rider to your order.',
            sortTime: o.createdAt,
          ));
          break;
        case OrderStatus.refilling:
          items.add(AppNotification(
            id: 'cust_order:${o.id}:refilling',
            category: NotificationCategory.orders,
            icon: Icons.water_drop,
            iconColor: _blue,
            iconBg: _frost,
            title: 'Order ${o.orderNumber} Is Being Prepared',
            message: '${_summary(o)} is being refilled and packed.',
            sortTime: o.createdAt,
            timeLabel: 'In progress',
          ));
          break;
        case OrderStatus.outForDelivery:
          final rider = (o.assignedRiderName ?? '').trim();
          final address = (o.deliveryAddress ?? '').trim();
          items.add(AppNotification(
            id: 'cust_order:${o.id}:outForDelivery',
            category: NotificationCategory.delivery,
            icon: Icons.local_shipping,
            iconColor: _blue,
            iconBg: _frost,
            title: 'Order ${o.orderNumber} Out for Delivery',
            message: '${rider.isEmpty ? 'Your rider' : 'Rider $rider'} is on the way${address.isEmpty ? '' : ' to $address'}.',
            sortTime: o.createdAt,
            timeLabel: 'On the way',
            trackOrder: o,
          ));
          break;
        case OrderStatus.delivered:
          final at = o.deliveredAt ?? o.createdAt;
          if (now.difference(at).inDays > 7) break;
          final recipient = (o.recipientName ?? '').trim();
          items.add(AppNotification(
            id: 'cust_order:${o.id}:delivered',
            category: NotificationCategory.delivery,
            icon: Icons.check_circle,
            iconColor: _mintText,
            iconBg: _mint,
            title: 'Order ${o.orderNumber} Delivered',
            message: '${_summary(o)} was delivered${recipient.isEmpty ? '' : ' and received by $recipient'}. Total ${_money(o.totalAmount)}.',
            sortTime: at,
            tag: 'Delivered',
          ));
          break;
        case OrderStatus.cancelled:
          if (now.difference(o.createdAt).inDays > 7) break;
          items.add(AppNotification(
            id: 'cust_order:${o.id}:cancelled',
            category: NotificationCategory.orders,
            icon: Icons.cancel,
            iconColor: _coral,
            iconBg: _coralBg,
            title: 'Order ${o.orderNumber} Cancelled',
            message: 'This order was cancelled.',
            sortTime: o.createdAt,
            timeLabel: 'Cancelled',
          ));
          break;
      }
    }
    return items;
  }

  List<AppNotification> _customerRefundItems(List<RefundModel> refunds, DateTime now) {
    final items = <AppNotification>[];
    for (final r in refunds) {
      final at = r.status == RefundStatus.pending ? r.requestedAt : (r.processedAt ?? r.requestedAt);
      if (now.difference(at).inDays > 14) continue;
      final isRedelivery = r.resolutionType == 'redelivery';
      String title;
      String message;
      String tag;
      IconData icon;
      Color iconColor;
      Color iconBg;
      switch (r.status) {
        case RefundStatus.pending:
          title = 'Refund Request Submitted';
          message = 'Your request for order ${r.orderNumber} (${_money(r.amount)}) is under review.';
          tag = 'Under Review';
          icon = Icons.currency_exchange;
          iconColor = _amber;
          iconBg = _amberBg;
          break;
        case RefundStatus.approved:
          if (isRedelivery) {
            final when = r.redeliveryScheduledAt;
            title = 'Redelivery Approved';
            message = when == null
                ? 'A free redelivery for order ${r.orderNumber} was approved.'
                : 'A free redelivery for order ${r.orderNumber} is scheduled for ${_fmtDate(when)} • ${_fmtClock(when)}.';
            tag = 'Redelivery Queued';
            icon = Icons.local_shipping;
          } else {
            title = 'Refund Approved';
            message = 'Your ${_money(r.amount)} refund for order ${r.orderNumber} was approved and will be sent to your GCash.';
            tag = 'Approved';
            icon = Icons.verified;
          }
          iconColor = _mintText;
          iconBg = _mint;
          break;
        case RefundStatus.processed:
          final ref = (r.gcashRefNumber ?? '').trim();
          title = 'Refund Completed';
          message = '${_money(r.amount)} was sent to your GCash for order ${r.orderNumber}${ref.isEmpty ? '' : ' (Ref #$ref)'}.';
          tag = 'Completed';
          icon = Icons.check_circle;
          iconColor = _mintText;
          iconBg = _mint;
          break;
        case RefundStatus.rejected:
          final reason = (r.rejectionReason ?? '').trim();
          title = 'Refund Declined';
          message = 'Your request for order ${r.orderNumber} was declined${reason.isEmpty ? '.' : ': $reason'}';
          tag = 'Declined';
          icon = Icons.cancel;
          iconColor = _coral;
          iconBg = _coralBg;
          break;
      }
      items.add(AppNotification(
        id: 'cust_refund:${r.id}:${r.status.name}',
        category: NotificationCategory.orders,
        icon: icon,
        iconColor: iconColor,
        iconBg: iconBg,
        title: title,
        message: message,
        sortTime: at,
        tag: tag,
      ));
    }
    return items;
  }
}