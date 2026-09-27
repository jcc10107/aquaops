import 'package:flutter/material.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  static const Color primary = Color(0xFF006194);
  static const Color primaryContainer = Color(0xFF007BB9);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color cyanElectric = Color(0xFF06B6D4);
  static const Color cyanHighlight = Color(0xFF22D3EE);
  static const Color coralAlert = Color(0xFFF43F5E);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceFrost = Color(0xFFE0F2FE);
  static const Color surfaceIce = Color(0xFFF0F9FF);
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF3F4850);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color primaryFixed = Color(0xFFCCE5FF);

  final String _hubName = 'San Antonio Central Hub';
  final String _statusLabel = 'STATION ONLINE • 4 STAGES ACTIVE';
  String _dateLabel = 'Today, Sep 26';
  final int _notificationCount = 4;

  final double _dailyGrossRevenue = 14850.00;
  final double _yesterdayGrossRevenue = 12540.00;
  final double _cashInTill = 8620.00;
  final double _gcashQr = 6230.00;
  final int _gallonsPumped = 342;
  final int _roundGallons = 210;
  final int _slimGallons = 132;
  final double _depositsHeld = 2100.00;
  final int _depositsHeldPieces = 14;

  final int _ridersEnRoute = 3;
  final double _onTimeRate = 94;

  final List<Map<String, dynamic>> _riders = const [
    {
      'initials': 'AB',
      'name': 'Arnel Bautista',
      'code': 'R-09',
      'route': 'North Caloocan / Phase 3',
      'doneCount': 18,
      'totalCount': 25,
      'codAmount': 1320.0,
      'status': 'Cash-out Due',
      'statusIsAlert': true,
      'doneBadgeIsAlert': false,
      'actionLabel': 'Ping Rider',
    },
    {
      'initials': 'JS',
      'name': 'Jun Soriano',
      'code': 'R-04',
      'route': 'Villa Luisa Subd • Stop #13',
      'doneCount': 12,
      'totalCount': 15,
      'codAmount': 840.0,
      'status': 'Moving (2km/h)',
      'statusIsAlert': false,
      'doneBadgeIsAlert': false,
      'actionLabel': 'View Map',
    },
  ];

  final List<Map<String, dynamic>> _supplies = const [
    {
      'name': 'Blue Caps',
      'quantity': 380,
      'badgeLabel': '15% LEFT',
      'badgeIsAlert': true,
      'footerLabel': 'Restock ASAP',
      'footerIsAlert': true,
      'icon': Icons.report,
    },
    {
      'name': 'Heat Seals',
      'quantity': 850,
      'badgeLabel': 'GOOD',
      'badgeIsAlert': false,
      'footerLabel': 'Safe for 4 days',
      'footerIsAlert': false,
      'icon': Icons.verified,
    },
    {
      'name': 'Clean Jars',
      'quantity': 48,
      'badgeLabel': 'READY',
      'badgeIsAlert': false,
      'footerLabel': 'Refill buffer ready',
      'footerIsAlert': false,
      'icon': Icons.local_drink,
    },
  ];

  final int _discrepancyCount = 0;
  final String _lastShiftLabel = 'Shift #1041 (Morning)';
  final double _lastShiftAmount = 3850.00;
  final String _lastShiftReconciler = 'Kuya Noel';
  final String _lastShiftTime = '12:15 PM';

  final int _navIndex = 0;

  void _onPingRider(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ping sent to $name.')),
    );
  }

  void _onViewRiderMap(String name) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.near_me, color: cyanElectric),
                        const SizedBox(width: 8),
                        Text(
                          'Live Map - $name',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: surfaceIce,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.map, size: 48, color: primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
  }

  void _onOpenDispatchConsole() {
    Navigator.pushReplacementNamed(context, '/dispatch');
  }

  void _onManageSupplies() {
    Navigator.pushReplacementNamed(context, '/inventory');
  }

  void _onNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 0) return;
    if (index == 1) Navigator.pushReplacementNamed(context, '/pos');
    if (index == 2) Navigator.pushReplacementNamed(context, '/dispatch');
    if (index == 3) Navigator.pushReplacementNamed(context, '/inventory');
    if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      extendBody: true,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withValues(alpha: 0.85),
        boxShadow: const [
          BoxShadow(color: Color(0x14007BB9), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, cyanElectric],
                      ),
                      boxShadow: [BoxShadow(color: Color(0x5906B6D4), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('AquaOps', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primary, letterSpacing: -0.2)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: surfaceFrost, borderRadius: BorderRadius.circular(100)),
                            child: const Text('HQ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: primary, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: tealAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('San Antonio Hub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: surfaceIce, shape: BoxShape.circle),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.notifications, color: primary, size: 22),
                          onPressed: () {},
                        ),
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: coralAlert,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: surfaceContainerLowest, width: 2),
                            ),
                            child: Text('$_notificationCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHubHeaderSection(),
          const SizedBox(height: 16),
          _buildRevenueCard(),
          const SizedBox(height: 16),
          _buildDispatchSection(),
          const SizedBox(height: 16),
          _buildSuppliesSection(),
          const SizedBox(height: 16),
          _buildReconciliationSection(),
        ],
      ),
    );
  }

  Widget _buildHubHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hubName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface, letterSpacing: -0.4),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xBF6CF8BB), shape: BoxShape.circle)),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: secondary, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: secondary, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          offset: const Offset(0, 40),
          color: surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) => setState(() => _dateLabel = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'Today, Sep 26', child: Text('Today')),
            PopupMenuItem(value: 'This Week (W39)', child: Text('This Week')),
            PopupMenuItem(value: 'Sep 2024 (MTD)', child: Text('This Month')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(100)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 15, color: primary),
                const SizedBox(width: 4),
                Text(_dateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                const Icon(Icons.arrow_drop_down, size: 16, color: onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    final growthPercent = (((_dailyGrossRevenue - _yesterdayGrossRevenue) / _yesterdayGrossRevenue) * 100);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryContainer, cyanElectric],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x59006194), blurRadius: 32, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments, size: 18, color: cyanHighlight),
                  SizedBox(width: 6),
                  Text('DAILY GROSS REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryFixed, letterSpacing: 1.2)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: secondaryContainer, borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 12, color: onSecondaryContainer),
                    const SizedBox(width: 2),
                    Text('+${growthPercent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSecondaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₱${_dailyGrossRevenue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6)),
              const SizedBox(width: 8),
              Text('vs ₱${_yesterdayGrossRevenue.toStringAsFixed(0)} y\'day', style: const TextStyle(fontSize: 11, color: primaryFixed)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CASH IN TILL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: primaryFixed, letterSpacing: 0.6)),
                          Icon(Icons.check_circle, size: 14, color: secondaryContainer),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('₱${_cashInTill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('Reconciled ready', style: TextStyle(fontSize: 10, color: primaryFixed), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GCASH / QR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: primaryFixed, letterSpacing: 0.6)),
                          Icon(Icons.verified, size: 14, color: cyanHighlight),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('₱${_gcashQr.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('InstaPay verified', style: TextStyle(fontSize: 10, color: primaryFixed), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.local_drink, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_gallonsPumped Gallons Pumped', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryFixed)),
                        Text('$_roundGallons Round • $_slimGallons Slim', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Deposits Held', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryFixed)),
                    Text('₱${_depositsHeld.toStringAsFixed(0)} ($_depositsHeldPieces pcs)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: secondaryContainer)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.two_wheeler, color: primary, size: 20),
                SizedBox(width: 6),
                Text('Active Dispatch Fleet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: surfaceFrost, borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: tealAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('$_ridersEnRoute En Route • ${_onTimeRate.toStringAsFixed(0)}% On-Time', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._riders.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildRiderCard(r),
        )),
        InkWell(
          onTap: _onOpenDispatchConsole,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: surfaceFrost, borderRadius: BorderRadius.circular(100)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Open Live Dispatch Console', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18, color: primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final bool statusIsAlert = rider['statusIsAlert'] as bool;
    final bool doneBadgeIsAlert = rider['doneBadgeIsAlert'] as bool;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F007BB9), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: surfaceFrost, shape: BoxShape.circle),
                    child: Center(
                      child: Text(rider['initials'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(rider['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(100)),
                            child: Text(rider['code'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(rider['route'] as String, style: const TextStyle(fontSize: 11, color: onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: doneBadgeIsAlert ? surfaceFrost : secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${rider['doneCount']}/${rider['totalCount']} Done',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: doneBadgeIsAlert ? primary : onSecondaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 15, color: secondary),
                    const SizedBox(width: 4),
                    Text('₱${(rider['codAmount'] as double).toStringAsFixed(0)} COD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '• ${rider['status']}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusIsAlert ? coralAlert : secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => statusIsAlert ? _onPingRider(rider['name'] as String) : _onViewRiderMap(rider['name'] as String),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(100)),
                  child: Text(rider['actionLabel'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2, color: primary, size: 20),
                SizedBox(width: 6),
                Text('Supplies & Bottling Stock', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
              ],
            ),
            InkWell(
              onTap: _onManageSupplies,
              child: const Text('Manage All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _supplies
              .asMap()
              .entries
              .map((entry) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry.key == _supplies.length - 1 ? 0 : 8),
              child: _buildSupplyCard(entry.value),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSupplyCard(Map<String, dynamic> supply) {
    final bool badgeIsAlert = supply['badgeIsAlert'] as bool;
    final bool footerIsAlert = supply['footerIsAlert'] as bool;
    final Color accent = badgeIsAlert ? coralAlert : (supply['name'] == 'Clean Jars' ? primary : secondary);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(supply['icon'] as IconData, size: 18, color: accent),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeIsAlert ? errorContainer : (supply['name'] == 'Clean Jars' ? surfaceFrost : secondaryContainer),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  supply['badgeLabel'] as String,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: badgeIsAlert ? onErrorContainer : (supply['name'] == 'Clean Jars' ? primary : onSecondaryContainer)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${supply['quantity']}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: badgeIsAlert ? coralAlert : onSurface)),
          Text(supply['name'] as String, style: const TextStyle(fontSize: 11, color: onSurfaceVariant), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(supply['footerLabel'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: footerIsAlert ? coralAlert : (supply['name'] == 'Clean Jars' ? primary : secondary))),
        ],
      ),
    );
  }

  Widget _buildReconciliationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in, color: primary, size: 20),
                SizedBox(width: 6),
                Text('Reconciliation Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: secondary),
                const SizedBox(width: 4),
                Text('$_discrepancyCount Discrepancies', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: surfaceContainerLowest, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0F007BB9), blurRadius: 16)]),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: secondaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.task_alt, size: 20, color: onSecondaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(_lastShiftLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: secondaryContainer, borderRadius: BorderRadius.circular(100)),
                          child: const Text('Settled', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: onSecondaryContainer)),
                        ),
                      ],
                    ),
                    Text('₱${_lastShiftAmount.toStringAsFixed(2)} reconciled by $_lastShiftReconciler', style: const TextStyle(fontSize: 11, color: onSurfaceVariant)),
                  ],
                ),
              ),
              Text(_lastShiftTime, style: const TextStyle(fontSize: 11, color: onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
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
                    color: surfaceContainerLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F006194), blurRadius: 24, offset: Offset(0, 8))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: _navIndex,
                      onTap: _onNavTapped,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: primary,
                      unselectedItemColor: onSurfaceVariant,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
                        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
                        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
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
}