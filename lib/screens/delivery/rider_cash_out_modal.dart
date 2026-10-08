import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../models/rider_cash_out_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class RiderCashOutModal extends StatefulWidget {
  const RiderCashOutModal({super.key});

  @override
  State<RiderCashOutModal> createState() => _RiderCashOutModalState();
}

class _RiderCashOutModalState extends State<RiderCashOutModal> {
  static const double _maxWidth = 450;
  static const double _gap = 16;
  static const double _headerHeight = 64;

  static const Color _emerald = Color(0xFF059669);
  static const Color _emeraldLight = Color(0xFF10B981);
  static const Color _heroLabel = Color(0xFFA7F3D0);
  static const Color _emerald100 = Color(0xFFD1FAE5);
  static const Color _emerald700 = Color(0xFF047857);
  static const Color _cyanHighlight = Color(0xFF22D3EE);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color _surfaceCanvas = Color(0xFFF8FAFC);
  static const Color _background = Color(0xFFF6FAFC);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _fieldBorder = Color(0xFFE2E8F0);
  static const Color _handle = Color(0xFFBFC7D2);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _amber = Color(0xFFB45309);
  static const Color _greenDark = Color(0xFF047857);
  static const Color _greenLight = Color(0xFFECFDF5);
  static const Color _greenBorder = Color(0xFFA7F3D0);

  static final TextStyle _labelMd = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.22,
    color: _onSurfaceVariant,
  );

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _cashHandedOverCtrl = TextEditingController();
  final TextEditingController _verifiedByCtrl = TextEditingController();
  final FocusNode _cashFocus = FocusNode();

  String? _selectedRiderId;
  bool _certified = true;
  bool _isSubmitting = false;
  bool _isDone = false;
  double? _lastDiscrepancy;

  @override
  void initState() {
    super.initState();
    _cashHandedOverCtrl.addListener(() => setState(() {}));
    _prefillVerifierName();
  }

  @override
  void dispose() {
    _cashHandedOverCtrl.dispose();
    _verifiedByCtrl.dispose();
    _cashFocus.dispose();
    super.dispose();
  }

  Future<void> _prefillVerifierName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await _firestoreService.getUser(uid);
    if (mounted && profile != null) {
      _verifiedByCtrl.text = profile.name;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.plusJakartaSans()), backgroundColor: AppColors.error),
    );
  }

  Future<void> _closeCashOut(UserModel rider, DateTime since) async {
    if (!_certified) return;
    final handedOver = double.tryParse(_cashHandedOverCtrl.text);
    if (handedOver == null) {
      _showError('Enter the counted cash amount.');
      return;
    }
    if (_verifiedByCtrl.text.trim().isEmpty) {
      _showError('Enter the verifying staff name.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final discrepancy = await _firestoreService.closeRiderCashOut(
        riderId: rider.id,
        riderName: rider.name,
        since: since,
        cashHandedOver: handedOver,
        verifiedByName: _verifiedByCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isDone = true;
        _lastDiscrepancy = discrepancy;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Failed to close cash-out: $e');
    }
  }

  TextStyle _mono(double size, {FontWeight weight = FontWeight.w700, Color color = _onSurface, double letterSpacing = 0}) {
    return GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: _surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _fieldBorder.withValues(alpha: 0.8)),
    );
  }

  Widget _buildHeader(double topInset) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: topInset),
              color: _background.withValues(alpha: 0.85),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: SizedBox(
                    height: _headerHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(100),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.arrow_back, size: 24, color: _onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rider Cash-Out',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 17, height: 1.25, fontWeight: FontWeight.w700, color: _onSurface),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 6,
                                      height: 6,
                                      child: DecoratedBox(decoration: BoxDecoration(color: _emeraldLight, shape: BoxShape.circle)),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Shift Reconciliation Protocol',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _emerald),
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
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.04), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_emerald, _emeraldLight],
        ),
        boxShadow: [BoxShadow(color: _emeraldLight.withValues(alpha: 0.3), blurRadius: 25, spreadRadius: -5, offset: const Offset(0, 10))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -56, bottom: -56, child: _buildGlow(176, _cyanHighlight.withValues(alpha: 0.28))),
          Positioned(left: -48, top: -48, child: _buildGlow(128, Colors.white.withValues(alpha: 0.2))),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.currency_exchange, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASH RECONCILIATION',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: _heroLabel),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rider Cash-Out',
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, letterSpacing: -0.44, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCourierSheet(List<UserModel> riders, UserModel rider) {
    String pendingId = rider.id;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(sheetContext).padding.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 50,
                        spreadRadius: -12,
                        offset: Offset(0, 25),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(color: _handle, borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose Active Courier',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 18, height: 1.25, fontWeight: FontWeight.w700, color: _onSurface),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select rider to reconcile shift cash-out',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: _surfaceContainerLow,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(sheetContext),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Icons.close, size: 18, color: _onSurfaceVariant),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: riders.map((r) {
                              final isSelected = r.id == pendingId;
                              final zone = (r.assignedArea != null && r.assignedArea!.isNotEmpty)
                                  ? r.assignedArea!
                                  : 'No specific area assigned';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => setSheetState(() => pendingId = r.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? _greenLight.withValues(alpha: 0.4) : _surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? _emeraldLight : _fieldBorder.withValues(alpha: 0.8),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected ? _emerald100 : _slate100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.sports_motorsports,
                                              size: 20,
                                              color: isSelected ? _emerald700 : _slate600,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: _onSurface),
                                                ),
                                                Text(
                                                  zone,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected) const Icon(Icons.check_circle, size: 22, color: _emerald),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_emerald, _emeraldLight]),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(100),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              if (pendingId != rider.id) {
                                setState(() {
                                  _selectedRiderId = pendingId;
                                  _isDone = false;
                                  _cashHandedOverCtrl.clear();
                                });
                              }
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Confirm Courier Selection',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Widget _buildRiderDropdown(List<UserModel> riders, UserModel rider) {
    return Container(
      width: double.infinity,
      decoration: _fieldDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCourierSheet(riders, rider),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rider.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: _onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more, size: 20, color: _onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourierCard(List<UserModel> riders, UserModel rider) {
    final hasArea = rider.assignedArea != null && rider.assignedArea!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE DELIVERY COURIER',
            style: GoogleFonts.plusJakartaSans(fontSize: 10, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: _onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          _buildRiderDropdown(riders, rider),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _emeraldLight.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(100)),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: _emerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Assigned Zone: ', style: _labelMd),
                        TextSpan(
                          text: hasArea ? rider.assignedArea : 'No specific area assigned',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _onSurface),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String value, String label, {Color color = _emerald}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _emeraldLight.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w700, letterSpacing: -0.17, color: _onSurface),
          ),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 16 / 11, color: _onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCashCollectedCard(double cashCollected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CASH COLLECTED (COD)', style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.55, color: _onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            '₱${cashCollected.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _mono(30, weight: FontWeight.w800, color: _emerald, letterSpacing: -0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceBanner(double variance) {
    final balanced = variance.abs() < 0.01;
    final color = balanced ? _secondary : _amber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(balanced ? Icons.check_circle : Icons.swap_horiz, size: 20, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    balanced ? 'Exact match: Balanced' : (variance > 0 ? 'Over' : 'Short'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.22, color: color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('₱${variance.abs().toStringAsFixed(2)} Variance', style: _mono(11, color: color)),
        ],
      ),
    );
  }

  Widget _buildTurnoverCard(double cashCollected, double? variance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _emeraldLight.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.point_of_sale, size: 18, color: _emerald),
              ),
              const SizedBox(width: 8),
              Text('Physical Turnover', style: GoogleFonts.plusJakartaSans(fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w700, letterSpacing: -0.17, color: _onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Physical Cash Handed to Station (₱)', style: _labelMd),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _cashFocus,
            builder: (context, _) {
              final focused = _cashFocus.hasFocus;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: focused ? Colors.white : _surfaceCanvas,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: focused ? _emerald : Colors.transparent, width: 2),
                ),
                child: Row(
                  children: [
                    Text('₱', style: _mono(17, color: _emerald)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _cashHandedOverCtrl,
                        focusNode: _cashFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: _mono(17),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: cashCollected.toStringAsFixed(2),
                          hintStyle: _mono(17, color: _faint),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (variance != null) ...[
            const SizedBox(height: 16),
            _buildVarianceBanner(variance),
          ],
          const SizedBox(height: 16),
          Text('Verifying Station Staff Name', style: _labelMd),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _surfaceCanvas, borderRadius: BorderRadius.circular(100)),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: _emeraldLight.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.badge, size: 18, color: _emerald),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _verifiedByCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w700, color: _onSurface),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      ),
                      Text('Station Staff', style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 16 / 11, color: _onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _emeraldLight.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
                  child: Text('Authorized', style: GoogleFonts.plusJakartaSans(fontSize: 10, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: _emerald)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifyCard(double amount, int emptiesReturned) {
    return Material(
      color: _emeraldLight.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _certified = !_certified),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(_certified ? Icons.check_box : Icons.check_box_outline_blank, size: 24, color: _emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'I certify that physical cash of '),
                      TextSpan(text: '₱${amount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: _emerald)),
                      const TextSpan(text: ' and '),
                      TextSpan(text: '$emptiesReturned empty containers', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: _emerald)),
                      const TextSpan(text: ' have been physically handed over and reconciled without discrepancies.'),
                    ],
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500, color: _onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(UserModel rider, DateTime since) {
    return Opacity(
      opacity: _certified ? 1.0 : 0.5,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_emerald, _emeraldLight]),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: _emeraldLight.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: (_certified && !_isSubmitting) ? () => _closeCashOut(rider, since) : null,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isSubmitting ? 'Reconciling & Closing...' : 'Verify & Close Cash-Out',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneCard() {
    final isBalanced = (_lastDiscrepancy ?? 0).abs() < 0.01;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isBalanced ? _greenLight : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBalanced ? _greenBorder : const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Icon(
            isBalanced ? Icons.check_circle : Icons.warning_amber,
            size: 40,
            color: isBalanced ? _greenDark : const Color(0xFFB91C1C),
          ),
          const SizedBox(height: 12),
          Text(
            isBalanced
                ? 'Cash-out recorded — balanced!'
                : 'Cash-out recorded with a discrepancy of ₱${_lastDiscrepancy!.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _emerald,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text('Done', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSection(UserModel rider, DateTime since, List<OrderModel> allOrders) {
    if (_isDone) return _buildDoneCard();

    final orders = allOrders
        .where((o) => o.assignedRiderId == rider.id && o.status == OrderStatus.delivered && o.revenueDate.isAfter(since))
        .toList();

    final stopsCompleted = orders.length;
    final gallonsDelivered = orders.fold<int>(0, (s, o) => s + o.gallonsDelivered);
    final emptiesReturned = orders.fold<int>(0, (s, o) => s + o.emptyGallonsReturned);
    final cashCollected = orders.where((o) => o.paymentMethod == PaymentMethod.cash).fold<double>(0, (s, o) => s + o.totalAmount);
    final gcashCollected = orders.where((o) => o.paymentMethod == PaymentMethod.gcash).fold<double>(0, (s, o) => s + o.totalAmount);
    final handedOver = double.tryParse(_cashHandedOverCtrl.text);
    final variance = handedOver == null ? null : handedOver - cashCollected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'DELIVERIES SINCE LAST CASH-OUT',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w700, letterSpacing: 0.65, color: _onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile(Icons.local_shipping, '$stopsCompleted stops', 'Completed Routes')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricTile(Icons.water_drop, '$gallonsDelivered units', 'Gallons Delivered')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricTile(Icons.autorenew, '$emptiesReturned units', 'Empties Retrieved')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricTile(Icons.qr_code_2, '₱${gcashCollected.toStringAsFixed(2)}', 'GCash Drop-Offs')),
          ],
        ),
        const SizedBox(height: _gap),
        _buildCashCollectedCard(cashCollected),
        const SizedBox(height: _gap),
        _buildTurnoverCard(cashCollected, variance),
        const SizedBox(height: _gap),
        _buildCertifyCard(handedOver ?? cashCollected, emptiesReturned),
        const SizedBox(height: 8),
        _buildSubmitButton(rider, since),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            padding: EdgeInsets.zero,
            foregroundColor: _onSurfaceVariant,
            overlayColor: _fieldBorder.withValues(alpha: 0.4),
            shape: const StadiumBorder(),
          ),
          child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w700, letterSpacing: 0.13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, topInset + _headerHeight + 16, 16, 64 + media.padding.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),
                        const SizedBox(height: _gap),
                        StreamBuilder<List<UserModel>>(
                          stream: _firestoreService.getRidersStream(),
                          builder: (context, ridersSnapshot) {
                            final riders = ridersSnapshot.data ?? const <UserModel>[];
                            if (riders.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text('No rider accounts found.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _onSurfaceVariant)),
                              );
                            }
                            _selectedRiderId ??= riders.first.id;
                            final rider = riders.firstWhere((r) => r.id == _selectedRiderId, orElse: () => riders.first);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCourierCard(riders, rider),
                                const SizedBox(height: _gap),
                                StreamBuilder<RiderCashOutModel?>(
                                  stream: _firestoreService.getLatestRiderCashOutStream(rider.id),
                                  builder: (context, lastCashOutSnapshot) {
                                    final since = lastCashOutSnapshot.data?.closedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

                                    return StreamBuilder<List<OrderModel>>(
                                      stream: _firestoreService.getAllOrdersStream(),
                                      builder: (context, ordersSnapshot) {
                                        return _buildRiderSection(rider, since, ordersSnapshot.data ?? const <OrderModel>[]);
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader(topInset)),
          ],
        ),
      ),
    );
  }
}