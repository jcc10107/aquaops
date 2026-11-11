import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';

class OwnerRefundProcessingScreen extends StatefulWidget {
  final String customerName;
  final String orderNumber;
  final String orderMeta;
  final String itemsSummary;
  final String claimReason;
  final IconData claimIcon;
  final String amount;
  final String gcashNumber;

  const OwnerRefundProcessingScreen({
    super.key,
    this.customerName = 'Elena Gomez',
    this.orderNumber = 'ORD-2026-104',
    this.orderMeta = 'May 24, 2026 • 10:42 AM • Claim #CLM-881',
    this.itemsSummary = '2x Slim Gallon, 1x Round Gallon',
    this.claimReason = 'Damaged Product',
    this.claimIcon = Icons.broken_image,
    this.amount = '₱105.00',
    this.gcashNumber = '0917 123 4567',
  });

  @override
  State<OwnerRefundProcessingScreen> createState() => _OwnerRefundProcessingScreenState();
}

class _OwnerRefundProcessingScreenState extends State<OwnerRefundProcessingScreen> {
  final TextEditingController _gcashRefController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isConfirmed = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _copied = false;
  String? _gcashRefError;
  String? _confirmError;

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

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

  @override
  void dispose() {
    _gcashRefController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _copyNumber() async {
    await Clipboard.setData(ClipboardData(text: Validators.sanitizePhone(widget.gcashNumber)));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  Future<void> _submitRefund() async {
    if (_isLoading || _isSuccess) return;
    final String ref = _gcashRefController.text.trim();
    setState(() {
      _gcashRefError = Validators.sanitizePhone(ref).length < 13 ? 'Enter a valid 13-digit GCash Ref Number.' : null;
      _confirmError = !_isConfirmed ? 'Please verify the checkbox confirming GCash payment was sent.' : null;
    });
    if (_gcashRefError != null || _confirmError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pop(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOrderCard(),
                        const SizedBox(height: 14),
                        _buildBeneficiaryCard(),
                        const SizedBox(height: 14),
                        _buildReferenceCard(),
                        const SizedBox(height: 14),
                        _buildRemarksCard(),
                        const SizedBox(height: 14),
                        _buildConfirmationCard(),
                        const SizedBox(height: 16),
                        _buildActions(),
                        const SizedBox(height: 16),
                        _buildAuditFootnote(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final double topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
        boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, size: 20, color: AppColors.borderDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owner Refund Processing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(size: 18, weight: FontWeight.w700, color: AppColors.backgroundDark, letterSpacing: -0.3),
                    ),
                    Text(
                      'DISPUTE RESOLUTION & GCASH REIMBURSEMENT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.primarySky, letterSpacing: 0.5),
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

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16), Color borderColor = AppColors.slate100}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 16,
          decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.backgroundDark, letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: AppColors.primarySky),
                    const SizedBox(width: 6),
                    Text('ORDER DETAILS', style: _ts(size: 11, weight: FontWeight.w800, color: AppColors.primarySky, letterSpacing: 0.5)),
                  ],
                ),
                Text(widget.amount, style: _ts(size: 20, weight: FontWeight.w700, color: AppColors.primarySky, letterSpacing: -0.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${widget.orderNumber}', style: _ts(size: 15, weight: FontWeight.w700, color: AppColors.backgroundDark)),
                    const SizedBox(height: 2),
                    Text(widget.orderMeta, style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.slate500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  border: Border.all(color: AppColors.amber200.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.amber500, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Pending Owner Action', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.amber700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.surfaceCanvas))),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ordered Items', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate400)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.itemsSummary,
                        textAlign: TextAlign.right,
                        style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.borderDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Claim Reason', style: _ts(size: 11, weight: FontWeight.w600, color: AppColors.slate400)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.rose50,
                          border: Border.all(color: AppColors.rose200.withValues(alpha: 0.7)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.claimIcon, size: 13, color: AppColors.rose600),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Claim Reason: ${widget.claimReason}',
                                overflow: TextOverflow.ellipsis,
                                style: _ts(size: 10.5, weight: FontWeight.w700, color: AppColors.rose600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _sectionTitle('Customer & GCash Beneficiary')),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.emerald200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 12, color: AppColors.emerald700),
                    const SizedBox(width: 4),
                    Text('Verified Buyer', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.emerald700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CUSTOMER / ACCOUNT NAME', style: _ts(size: 9.5, weight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(widget.customerName, style: _ts(size: 14, weight: FontWeight.w700, color: AppColors.backgroundDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GCASH REGISTERED NUMBER', style: _ts(size: 9.5, weight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(widget.gcashNumber, style: _ts(size: 15, weight: FontWeight.w700, color: AppColors.backgroundDark, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _copyNumber,
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _copied ? AppColors.emerald50 : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _copied ? AppColors.emerald300 : AppColors.sky200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_copied ? Icons.check : Icons.content_copy, size: 14, color: _copied ? AppColors.emerald700 : AppColors.primarySky),
                        const SizedBox(width: 6),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: _ts(size: 12, weight: FontWeight.w700, color: _copied ? AppColors.emerald700 : AppColors.primarySky),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceIce,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceFrost),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(color: AppColors.primarySky, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.info_outline, size: 15, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: _ts(size: 11, weight: FontWeight.w500, color: AppColors.borderDark, height: 1.35),
                      children: [
                        const TextSpan(text: 'Send exactly '),
                        TextSpan(text: widget.amount, style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.backgroundDark, height: 1.35)),
                        const TextSpan(text: ' to '),
                        TextSpan(text: widget.gcashNumber, style: _ts(size: 11, weight: FontWeight.w700, color: AppColors.primarySky, height: 1.35)),
                        const TextSpan(text: ' via your GCash app, then enter the 13-digit reference number below.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _sectionTitle('GCash Refund Reference')),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.rose50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.rose200),
                ),
                child: Text('REQUIRED • 13 DIGITS', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.rose600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: TextField(
              controller: _gcashRefController,
              enabled: !_isLoading && !_isSuccess,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_gcashRefError != null) setState(() => _gcashRefError = null);
              },
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final String digits = Validators.sanitizePhone(newValue.text);
                  final StringBuffer buffer = StringBuffer();
                  for (int i = 0; i < digits.length; i++) {
                    if (i > 0 && i % 4 == 0) buffer.write(' ');
                    buffer.write(digits[i]);
                  }
                  final String formatted = buffer.toString();
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.backgroundDark),
              decoration: InputDecoration(
                hintText: 'e.g. 1002 9384 7563',
                hintStyle: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate400),
                prefixIcon: const Icon(Icons.tag, size: 17, color: AppColors.slate400),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 44),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.only(right: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _gcashRefError != null ? AppColors.coralAlert : AppColors.slate200)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _gcashRefError != null ? AppColors.coralAlert : AppColors.primarySky, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _gcashRefError ?? 'From your GCash SMS confirmation or transaction receipt slip.',
              style: _ts(size: 10.5, weight: FontWeight.w400, color: _gcashRefError != null ? AppColors.coralAlert : AppColors.slate400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Owner Remarks'),
              Text('OPTIONAL', style: _ts(size: 10, weight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            enabled: !_isLoading && !_isSuccess,
            maxLines: 2,
            style: _ts(size: 12, weight: FontWeight.w500, color: AppColors.backgroundDark),
            decoration: InputDecoration(
              hintText: 'e.g. Dispatched via POS Terminal #2 waiver credited...',
              hintStyle: _ts(size: 12, weight: FontWeight.w500, color: AppColors.slate400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _isConfirmed = !_isConfirmed;
        if (_isConfirmed) _confirmError = null;
      }),
      child: _card(
        padding: const EdgeInsets.all(14),
        borderColor: _confirmError != null ? AppColors.coralAlert : AppColors.slate200.withValues(alpha: 0.8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 16,
                height: 16,
                child: Checkbox(
                  value: _isConfirmed,
                  onChanged: (v) => setState(() {
                    _isConfirmed = v ?? false;
                    if (_isConfirmed) _confirmError = null;
                  }),
                  activeColor: AppColors.primarySky,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm payment sent via GCash',
                    style: _ts(size: 12, weight: FontWeight.w700, color: AppColors.backgroundDark, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _confirmError ?? 'I verify that ${widget.amount} has been transferred to customer ${widget.customerName}.',
                    style: _ts(size: 11, weight: FontWeight.w400, color: _confirmError != null ? AppColors.coralAlert : AppColors.slate500, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final Color buttonColor = _isSuccess ? AppColors.emerald600 : AppColors.primarySky;

    Widget label;
    if (_isLoading) {
      label = Row(
        key: const ValueKey('loading'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Reconciling Ledger...', style: _ts(size: 12, weight: FontWeight.w700, color: Colors.white)),
        ],
      );
    } else if (_isSuccess) {
      label = Row(
        key: const ValueKey('success'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text('Refund Logged Successfully!', style: _ts(size: 12, weight: FontWeight.w700, color: Colors.white)),
        ],
      );
    } else {
      label = Row(
        key: const ValueKey('idle'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text('Confirm & Mark as Refunded', style: _ts(size: 12, weight: FontWeight.w700, color: Colors.white)),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ElevatedButton(
            onPressed: (_isLoading || _isSuccess) ? null : _submitRefund,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              disabledBackgroundColor: buttonColor,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              overlayColor: AppColors.primarySkyDark,
              elevation: 4,
              shadowColor: const Color(0x330EA5E9),
              minimumSize: const Size(double.infinity, 48),
              maximumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: label,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_isLoading || _isSuccess) ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Cancel & Close', style: _ts(size: 12, weight: FontWeight.w600, color: AppColors.slate500)),
        ),
      ],
    );
  }

  Widget _buildAuditFootnote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 15, color: AppColors.slate400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Encrypted AquaOps Telematics audit entry logged to Store #41',
            textAlign: TextAlign.center,
            style: _ts(size: 10, weight: FontWeight.w500, color: AppColors.slate400),
          ),
        ),
      ],
    );
  }
}