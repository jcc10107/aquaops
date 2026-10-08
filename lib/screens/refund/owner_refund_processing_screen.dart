import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static const Color _bgCanvas = Color(0xFFF6FAFC);
  static const Color _primary = Color(0xFF0284C7);
  static const Color _primaryDark = Color(0xFF0369A1);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate900 = Color(0xFF0F172A);

  static const Color _amber50 = Color(0xFFFFFBEB);
  static const Color _amber200 = Color(0xFFFDE68A);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _amber700 = Color(0xFFB45309);

  static const Color _emerald50 = Color(0xFFECFDF5);
  static const Color _emerald200 = Color(0xFFA7F3D0);
  static const Color _emerald300 = Color(0xFF6EE7B7);
  static const Color _emerald600 = Color(0xFF059669);
  static const Color _emerald700 = Color(0xFF047857);

  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose600 = Color(0xFFE11D48);

  static const Color _sky50 = Color(0xFFF0F9FF);
  static const Color _sky100 = Color(0xFFE0F2FE);
  static const Color _sky200 = Color(0xFFBAE6FD);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

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

  @override
  void dispose() {
    _gcashRefController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.gcashNumber.replaceAll(' ', '')));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  Future<void> _submitRefund() async {
    if (_isLoading || _isSuccess) return;
    if (!_isConfirmed) {
      _showMessage('Please verify the checkbox confirming GCash payment was sent.');
      return;
    }
    final String ref = _gcashRefController.text.trim();
    if (ref.replaceAll(' ', '').length < 13) {
      _showMessage('Please provide a valid 13-digit GCash Ref Number.');
      return;
    }

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
      backgroundColor: _bgCanvas,
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
                  constraints: const BoxConstraints(maxWidth: 448),
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
        border: Border(bottom: BorderSide(color: _slate100)),
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
                  decoration: const BoxDecoration(color: _slate100, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, size: 20, color: _slate700),
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
                      style: _ts(size: 18, weight: FontWeight.w700, color: _slate900, letterSpacing: -0.3),
                    ),
                    Text(
                      'DISPUTE RESOLUTION & GCASH REIMBURSEMENT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(size: 11, weight: FontWeight.w700, color: _primary, letterSpacing: 0.5),
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

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16), Color borderColor = _slate100}) {
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
          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: _ts(size: 12, weight: FontWeight.w700, color: _slate900, letterSpacing: 0.3),
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
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _slate100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: _primary),
                    const SizedBox(width: 6),
                    Text('ORDER DETAILS', style: _ts(size: 11, weight: FontWeight.w800, color: _primary, letterSpacing: 0.5)),
                  ],
                ),
                Text(widget.amount, style: _ts(size: 20, weight: FontWeight.w700, color: _primary, letterSpacing: -0.5)),
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
                    Text('Order #${widget.orderNumber}', style: _ts(size: 15, weight: FontWeight.w700, color: _slate900)),
                    const SizedBox(height: 2),
                    Text(widget.orderMeta, style: _ts(size: 11, weight: FontWeight.w500, color: _slate500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _amber50,
                  border: Border.all(color: _amber200.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: _amber500, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Pending Owner Action', style: _ts(size: 10, weight: FontWeight.w700, color: _amber700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _slate50))),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ordered Items', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.itemsSummary,
                        textAlign: TextAlign.right,
                        style: _ts(size: 12, weight: FontWeight.w700, color: _slate700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Claim Reason', style: _ts(size: 11, weight: FontWeight.w600, color: _slate400)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: _rose50,
                          border: Border.all(color: _rose200.withValues(alpha: 0.7)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.claimIcon, size: 13, color: _rose600),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Claim Reason: ${widget.claimReason}',
                                overflow: TextOverflow.ellipsis,
                                style: _ts(size: 10.5, weight: FontWeight.w700, color: _rose600),
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
                  color: _emerald50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _emerald200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 12, color: _emerald700),
                    const SizedBox(width: 4),
                    Text('Verified Buyer', style: _ts(size: 10, weight: FontWeight.w700, color: _emerald700)),
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
              color: _slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _slate200.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CUSTOMER / ACCOUNT NAME', style: _ts(size: 9.5, weight: FontWeight.w700, color: _slate400, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(widget.customerName, style: _ts(size: 14, weight: FontWeight.w700, color: _slate900)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _slate200.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GCASH REGISTERED NUMBER', style: _ts(size: 9.5, weight: FontWeight.w700, color: _slate400, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(widget.gcashNumber, style: _ts(size: 15, weight: FontWeight.w700, color: _slate900, letterSpacing: 0.5)),
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
                      color: _copied ? _emerald50 : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _copied ? _emerald300 : _sky200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_copied ? Icons.check : Icons.content_copy, size: 14, color: _copied ? _emerald700 : _primary),
                        const SizedBox(width: 6),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: _ts(size: 12, weight: FontWeight.w700, color: _copied ? _emerald700 : _primary),
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
              color: _sky50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.info_outline, size: 15, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: _ts(size: 11, weight: FontWeight.w500, color: _slate700, height: 1.35),
                      children: [
                        const TextSpan(text: 'Send exactly '),
                        TextSpan(text: widget.amount, style: _ts(size: 11, weight: FontWeight.w700, color: _slate900, height: 1.35)),
                        const TextSpan(text: ' to '),
                        TextSpan(text: widget.gcashNumber, style: _ts(size: 11, weight: FontWeight.w700, color: _primary, height: 1.35)),
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
                  color: _rose50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _rose200),
                ),
                child: Text('REQUIRED • 13 DIGITS', style: _ts(size: 10, weight: FontWeight.w700, color: _rose600)),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
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
              style: _ts(size: 12, weight: FontWeight.w500, color: _slate900),
              decoration: InputDecoration(
                hintText: 'e.g. 1002 9384 7563',
                hintStyle: _ts(size: 12, weight: FontWeight.w500, color: _slate400),
                prefixIcon: const Icon(Icons.tag, size: 17, color: _slate400),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 44),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.only(right: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'From your GCash SMS confirmation or transaction receipt slip.',
              style: _ts(size: 10.5, weight: FontWeight.w400, color: _slate400),
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
              Text('OPTIONAL', style: _ts(size: 10, weight: FontWeight.w700, color: _slate400, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            enabled: !_isLoading && !_isSuccess,
            maxLines: 2,
            style: _ts(size: 12, weight: FontWeight.w500, color: _slate900),
            decoration: InputDecoration(
              hintText: 'e.g. Dispatched via POS Terminal #2 waiver credited...',
              hintStyle: _ts(size: 12, weight: FontWeight.w500, color: _slate400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isConfirmed = !_isConfirmed),
      child: _card(
        padding: const EdgeInsets.all(14),
        borderColor: _slate200.withValues(alpha: 0.8),
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
                  onChanged: (v) => setState(() => _isConfirmed = v ?? false),
                  activeColor: _primary,
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
                    style: _ts(size: 12, weight: FontWeight.w700, color: _slate900, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'I verify that ${widget.amount} has been transferred to customer ${widget.customerName}.',
                    style: _ts(size: 11, weight: FontWeight.w400, color: _slate500, height: 1.3),
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
    final Color buttonColor = _isSuccess ? _emerald600 : _primary;

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
              overlayColor: _primaryDark,
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
          child: Text('Cancel & Close', style: _ts(size: 12, weight: FontWeight.w600, color: _slate500)),
        ),
      ],
    );
  }

  Widget _buildAuditFootnote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 15, color: _slate400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Encrypted AquaOps Telematics audit entry logged to Store #41',
            textAlign: TextAlign.center,
            style: _ts(size: 10, weight: FontWeight.w500, color: _slate400),
          ),
        ),
      ],
    );
  }
}