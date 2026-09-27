import 'package:flutter/material.dart';

class _AquaColors {
  static const Color primary = Color(0xFF006194);
  static const Color cyanElectric = Color(0xFF06B6D4);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color coralAlert = Color(0xFFF43F5E);
  static const Color amber600 = Color(0xFFD97706);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceCanvas = Color(0xFFF8FAFC);
  static const Color surfaceIce = Color(0xFFF0F9FF);
  static const Color surfaceFrost = Color(0xFFE0F2FE);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color textMain = Color(0xFF131B2E);
  static const Color textVariant = Color(0xFF3F4850);
  static const Color outline = Color(0xFF707881);
}

class EmergencyTransferModal extends StatefulWidget {
  final String sourceRider;
  final String sourceZone;
  final int pendingStops;
  final String codAmount;

  const EmergencyTransferModal({
    super.key,
    this.sourceRider = 'Arnel Bautista',
    this.sourceZone = 'Barangay San Antonio • Sector 4',
    this.pendingStops = 2,
    this.codAmount = '₱190.00',
  });

  @override
  State<EmergencyTransferModal> createState() =>
      _EmergencyTransferModalState();
}

class _EmergencyTransferModalState extends State<EmergencyTransferModal> {
  String _reason = 'Bike Breakdown';
  String _scope = 'all';
  bool _notify = true;
  bool _isTransferring = false;
  bool _isDone = false;

  final List<Map<String, dynamic>> _reasons = const [
    {'label': 'Bike Breakdown', 'icon': Icons.build_circle},
    {'label': 'Heavy Rain / Flood', 'icon': Icons.thunderstorm},
    {'label': 'Rider Medical', 'icon': Icons.medical_services},
    {'label': 'Overcapacity', 'icon': Icons.inventory_2},
  ];

  void _confirmTransfer() {
    setState(() => _isTransferring = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isTransferring = false;
        _isDone = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 390,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _AquaColors.surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _AquaColors.primary.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _AquaColors.coralAlert,
                            _AquaColors.cyanElectric,
                            _AquaColors.secondaryContainer,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _AquaColors.coralAlert
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: _AquaColors.coralAlert,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Route Transfer',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: _AquaColors.textMain,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Reassign an active delivery queue in real time without resetting progress (e.g. bike breakdown, heavy rainfall, flat tire).',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _AquaColors.textVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'TRIGGER REASON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _AquaColors.textVariant,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _reasons.map((r) {
                            final bool active = _reason == r['label'];
                            return InkWell(
                              onTap: () =>
                                  setState(() => _reason = r['label'] as String),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? _AquaColors.coralAlert
                                      : _AquaColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: active
                                      ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      r['icon'] as IconData,
                                      size: 14,
                                      color: active
                                          ? _AquaColors.surfaceLowest
                                          : _AquaColors.textMain,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      r['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: active
                                            ? _AquaColors.surfaceLowest
                                            : _AquaColors.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Source Rider (Current Queue)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _AquaColors.textMain,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _AquaColors.coralAlert
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Stalled',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _AquaColors.coralAlert,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _AquaColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: _AquaColors.surfaceFrost,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.two_wheeler,
                                      size: 20,
                                      color: _AquaColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.sourceRider,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _AquaColors.textMain,
                                          ),
                                        ),
                                        Text(
                                          widget.sourceZone,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _AquaColors.textVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: _AquaColors.outline,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _AquaColors.surfaceLowest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_shipping,
                                          size: 16,
                                          color: _AquaColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.pendingStops} Pending Stops',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _AquaColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          '5 Gallons • ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _AquaColors.textVariant,
                                          ),
                                        ),
                                        Text(
                                          '${widget.codAmount} COD',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _AquaColors.textMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 24,
                                  width: 2,
                                  color: _AquaColors.cyanElectric
                                      .withValues(alpha: 0.4),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _AquaColors.cyanElectric
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                        Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.south,
                                    size: 18,
                                    color: _AquaColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Target Rider (New Assignee)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _AquaColors.textMain,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _AquaColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Optimal Match',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _AquaColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _AquaColors.surfaceIce,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _AquaColors.secondaryContainer
                                          .withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_bike,
                                      size: 20,
                                      color: _AquaColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Jun Soriano',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _AquaColors.textMain,
                                          ),
                                        ),
                                        Text(
                                          'Barangay San Isidro • Available',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _AquaColors.textVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.expand_circle_down,
                                    size: 20,
                                    color: _AquaColors.outline,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _AquaColors.surfaceLowest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.near_me,
                                          size: 15,
                                          color: _AquaColors.secondary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '1.2 km away (4 mins)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _AquaColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.water_drop,
                                          size: 14,
                                          color: _AquaColors.textVariant,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Load: ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _AquaColors.textVariant,
                                          ),
                                        ),
                                        Text(
                                          '4 / 20 jugs',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _AquaColors.textMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'QUEUE TRANSFER SCOPE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _AquaColors.textVariant,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _scope = 'all'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _scope == 'all'
                                        ? _AquaColors.surfaceFrost
                                        : _AquaColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          _scope == 'all'
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: _scope == 'all'
                                              ? _AquaColors.primary
                                              : _AquaColors.outline,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'All Stops (${widget.pendingStops})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _AquaColors.textMain,
                                              ),
                                            ),
                                            const Text(
                                              'Full queue handoff',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _AquaColors.textVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _scope = 'split'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _scope == 'split'
                                        ? _AquaColors.surfaceFrost
                                        : _AquaColors.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          _scope == 'split'
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: _scope == 'split'
                                              ? _AquaColors.primary
                                              : _AquaColors.outline,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Split Queue',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _AquaColors.textMain,
                                              ),
                                            ),
                                            Text(
                                              'Transfer only stop #2',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _AquaColors.textVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => setState(() => _notify = !_notify),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _AquaColors.surfaceCanvas,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _notify
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: _AquaColors.secondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Instant Dispatch Alert',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _AquaColors.textMain,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.bolt,
                                            size: 14,
                                            color: _AquaColors.secondary,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'In-app alert & push ping only (no SMS/WhatsApp)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _AquaColors.textVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: TextButton(
                                onPressed: _isTransferring
                                    ? null
                                    : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: _AquaColors.surfaceContainer,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: _AquaColors.textMain,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 15,
                              child: ElevatedButton(
                                onPressed: _isTransferring || _isDone
                                    ? null
                                    : _confirmTransfer,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  elevation: 0,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: _isDone
                                        ? null
                                        : const LinearGradient(
                                      colors: [
                                        _AquaColors.coralAlert,
                                        _AquaColors.amber600,
                                      ],
                                    ),
                                    color: _isDone
                                        ? _AquaColors.secondary
                                        : null,
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: _isDone
                                        ? []
                                        : [
                                      BoxShadow(
                                        color: _AquaColors.coralAlert
                                            .withValues(alpha: 0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    alignment: Alignment.center,
                                    child: _isTransferring
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isDone
                                              ? Icons.check
                                              : Icons.swap_horiz,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isDone
                                              ? 'Queue Transferred!'
                                              : 'Transfer Queue Now',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 15,
                              color: _AquaColors.tealAccent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Live tracking handoff verified by AquaOps Dispatch Telematics',
                              style: TextStyle(
                                fontSize: 11,
                                color: _AquaColors.textVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}