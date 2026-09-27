import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RiderCashOutModal extends StatefulWidget {
  const RiderCashOutModal({super.key});

  @override
  State<RiderCashOutModal> createState() => _RiderCashOutModalState();
}

class _RiderCashOutModalState extends State<RiderCashOutModal> {
  bool _certified = true;
  bool _isSubmitting = false;
  bool _isDone = false;

  final List<Map<String, dynamic>> _denominations = const [
    {'label': '₱1,000', 'count': 1, 'total': 1000.0},
    {'label': '₱200', 'count': 1, 'total': 200.0},
    {'label': '₱100', 'count': 1, 'total': 100.0},
    {'label': '₱20', 'count': 1, 'total': 20.0},
  ];

  void _closeShift() {
    if (!_certified) return;
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isDone = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textMain = isDark ? Colors.white : AppColors.textLight;

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
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 16)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.vividGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.currency_exchange, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SHIFT HANDOVER', style: TextStyle(fontSize: 10, color: AppColors.surfaceFrost, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Rider Daily Cash-Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(radius: 22, backgroundColor: AppColors.surfaceFrost, child: Icon(Icons.person, color: AppColors.primaryLight)),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Arnel Bautista', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMain)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, size: 16, color: AppColors.primaryLight),
                                        ],
                                      ),
                                      const Row(
                                        children: [
                                          Icon(Icons.location_on, size: 13, color: AppColors.cyanElectric),
                                          SizedBox(width: 4),
                                          Text('Zone: Barangay San Antonio', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(100)),
                                child: const Text('Shift #1042', style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SHIFT SUMMARY METRICS', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppColors.secondaryLight),
                                SizedBox(width: 4),
                                Text('Live Synced', style: TextStyle(fontSize: 10, color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.local_shipping, size: 18, color: AppColors.primaryLight),
                                        SizedBox(width: 6),
                                        Expanded(child: Text('Completed Routes', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(children: [
                                        TextSpan(text: '25 ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
                                        const TextSpan(text: 'stops', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.water_drop, size: 18, color: AppColors.cyanElectric),
                                        SizedBox(width: 6),
                                        Expanded(child: Text('Gallons Delivered', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(children: [
                                        TextSpan(text: '45 ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
                                        const TextSpan(text: 'units', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.autorenew, size: 18, color: AppColors.accentTeal),
                                        SizedBox(width: 6),
                                        Expanded(child: Text('Empties Retrieved', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text.rich(
                                          TextSpan(children: [
                                            TextSpan(text: '44 ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textMain)),
                                            const TextSpan(text: 'units', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ]),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.coralAlert.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('-1 pen.', style: TextStyle(fontSize: 10, color: AppColors.coralAlert)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.qr_code_2, size: 18, color: AppColors.tertiary),
                                        SizedBox(width: 6),
                                        Expanded(child: Text('GCash Drop-Offs', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text('₱450.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.tertiary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(16)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('APP CASH BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1)),
                                  DecoratedBox(
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(100))),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      child: Row(
                                        children: <Widget>[
                                          Icon(Icons.circle, size: 6, color: AppColors.secondaryLight),
                                          SizedBox(width: 4),
                                          Text('Ready for Deposit', style: TextStyle(fontSize: 10, color: AppColors.secondaryLight)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text('₱1,320.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.secondary, fontFamily: 'monospace')),
                              Text(
                                'Net physical currency collected directly from residential and store drops.',
                                style: TextStyle(fontSize: 11, color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.attach_money, size: 18, color: AppColors.primaryLight),
                                      SizedBox(width: 6),
                                      Text('Physical Cash Denominations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(100)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 13, color: AppColors.secondaryLight),
                                        SizedBox(width: 4),
                                        Text('Balanced', style: TextStyle(fontSize: 10, color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._denominations.map((d) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(6)),
                                              child: Text(d['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('× ${d['count']} bill', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        Text(
                                          '₱${(d['total'] as double).toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textMain),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 4),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Counted Bills', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                  Text('₱1,320.00', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondaryLight)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.point_of_sale, size: 20, color: AppColors.primaryLight),
                                  SizedBox(width: 8),
                                  Text('Physical Turnover Audit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Physical Cash Handed to Station (₱)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: '1320',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.textLight),
                                decoration: InputDecoration(
                                  prefixText: '₱ ',
                                  prefixStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, size: 16, color: AppColors.secondaryLight),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Exact match: Balanced variance (₱0.00)', style: TextStyle(fontSize: 11, color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
                                  Text('Re-count', style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('Verifying Station Staff Name', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: 'Maria Santos (Staff)',
                                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.badge, color: AppColors.primaryLight, size: 20),
                                  suffixIcon: const Icon(Icons.shield, color: AppColors.secondaryLight, size: 20),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Station Attendant #4 - San Antonio Branch', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => setState(() => _certified = !_certified),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_certified ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.primaryLight, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 12, color: textMain, height: 1.4),
                                      children: const [
                                        TextSpan(text: 'I certify that physical cash of '),
                                        TextSpan(text: '₱1,320.00', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                        TextSpan(text: ' and '),
                                        TextSpan(text: '44 empty containers', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                        TextSpan(text: ' have been physically handed over.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info, size: 18, color: AppColors.primaryLight),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Closing this shift automatically locks rider dispatch records, updates central drawer ledger, and archives active GPS telemetry.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          icon: const Icon(Icons.print, size: 18, color: AppColors.primaryLight),
                          label: const Text('Print Shift Summary (Thermal BT)', style: TextStyle(fontSize: 13, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _certified ? 1.0 : 0.5,
                          child: ElevatedButton.icon(
                            onPressed: (_certified && !_isSubmitting && !_isDone) ? _closeShift : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryLight,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(_isDone ? Icons.check_circle : Icons.verified_user, size: 22, color: Colors.white),
                            label: Text(
                              _isDone ? 'Shift Remittance Complete!' : (_isSubmitting ? 'Reconciling & Closing Shift...' : 'Verify & Close Shift'),
                              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            foregroundColor: AppColors.textSecondary,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          child: const Text('Cancel Shift Reconciliation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}