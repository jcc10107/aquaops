import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../core/constants/zones.dart';
import '../../core/utils/app_toast.dart';
import '../../models/saved_address_model.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';

class _NewAddress {
  final String label;
  final String barangay;
  final String street;
  final String landmark;
  final String contact;
  final String phone;
  final bool isPrimary;

  const _NewAddress({
    required this.label,
    required this.barangay,
    required this.street,
    required this.landmark,
    required this.contact,
    required this.phone,
    required this.isPrimary,
  });
}

InputDecoration _fieldDecoration({String? hint, double vertical = 10, String? errorText}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: _font,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.slate400,
    ),
    filled: true,
    fillColor: AppColors.surfaceCanvas,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
    border: border(AppColors.slate200),
    enabledBorder: border(errorText != null ? AppColors.error : AppColors.slate200),
    focusedBorder: border(errorText != null ? AppColors.error : AppColors.primarySky),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error),
    errorText: errorText,
    errorStyle: const TextStyle(
      fontFamily: _font,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.error,
    ),
  );
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  String _tag = 'Home';
  String? _barangay;
  bool _isPrimary = false;
  String? _barangayError;
  String? _streetError;
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController(text: 'Juan Dela Cruz');
  final TextEditingController _phoneCtrl = TextEditingController(text: '0917 123 4567');
  final TextEditingController _barangayFreeTextCtrl = TextEditingController();

  @override
  void dispose() {
    _streetCtrl.dispose();
    _landmarkCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _barangayFreeTextCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final street = _streetCtrl.text.trim();
    setState(() {
      _barangayError = (_barangay == null || _barangay!.isEmpty) ? 'Please select a barangay.' : null;
      _streetError = street.isEmpty ? 'Street address is required.' : null;
    });
    if (_barangayError != null || _streetError != null) return;
    Navigator.pop(
      context,
      _NewAddress(
        label: _tag,
        barangay: _barangay!,
        street: street,
        landmark: _landmarkCtrl.text.trim(),
        contact: _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        isPrimary: _isPrimary,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textLight,
      ),
    );
  }

  Widget _tagPill(String tag, IconData icon) {
    final bool active = _tag == tag;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tag = tag),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceFrost : Colors.white,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: active ? AppColors.primarySky : AppColors.slate200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? AppColors.primarySky : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primarySky : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
                    child: const Icon(Icons.add_location_alt_outlined, size: 18, color: AppColors.primarySky),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Delivery Address',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close, size: 20, color: AppColors.slate400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Address Label'),
          const SizedBox(height: 6),
          Row(
            children: [
              _tagPill('Home', Icons.home_outlined),
              const SizedBox(width: 8),
              _tagPill('Work', Icons.apartment),
              const SizedBox(width: 8),
              _tagPill('Other', Icons.pin_drop_outlined),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Barangay '),
                    TextSpan(text: '*', style: TextStyle(color: AppColors.error)),
                  ],
                ),
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
              Text(
                'San Pablo City, Laguna',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<bool>(
            stream: _firestoreService.getServiceAreaRestrictedStream(),
            builder: (context, snapshot) {
              final restricted = snapshot.data ?? true;
              if (!restricted) {
                return TextField(
                  controller: _barangayFreeTextCtrl,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                  decoration: _fieldDecoration(hint: 'Enter city/barangay...', errorText: _barangayError),
                  onChanged: (v) => setState(() {
                    _barangay = v.trim().isEmpty ? null : v.trim();
                    _barangayError = null;
                  }),
                );
              }
              return SizedBox(
                width: double.infinity,
                child: DropdownMenu<String>(
                  initialSelection: _barangay,
                  menuHeight: 320,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  hintText: 'Search barangay...',
                  textStyle: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    hintStyle: const TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceCanvas,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky)),
                  ),
                  dropdownMenuEntries: sanPabloBarangays
                      .map((b) => DropdownMenuEntry<String>(value: b, label: b))
                      .toList(),
                  onSelected: (v) => setState(() {
                    _barangay = v;
                    _barangayError = null;
                  }),
                ),
              );
            },
          ),
          if (_barangayError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                _barangayError!,
                style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 16),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Street Address / House / Unit No. '),
                TextSpan(text: '*', style: TextStyle(color: AppColors.error)),
              ],
            ),
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _streetCtrl,
            onChanged: (_) {
              if (_streetError != null) setState(() => _streetError = null);
            },
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
            decoration: _fieldDecoration(
              hint: 'e.g. Block 8 Lot 14, Villa Antonio Subdivision',
              errorText: _streetError,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('Landmark & Dispatch Instructions'),
              const Text(
                'Help rider locate',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _landmarkCtrl,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
            decoration: _fieldDecoration(
              hint: "e.g. Yellow gate across Aling Nena's sari-sari store, press doorbell twice",
              vertical: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Contact Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _contactCtrl,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                      decoration: _fieldDecoration(vertical: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Phone Number'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                      decoration: _fieldDecoration(vertical: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.slate100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set as Primary Address',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        'Default route for quick refills & telemetry',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPrimary,
                  onChanged: (v) => setState(() => _isPrimary = v),
                  thumbColor: WidgetStateProperty.all(Colors.white),
                  trackColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected) ? AppColors.primarySky : AppColors.slate200,
                  ),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primarySky,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primarySky.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                splashColor: AppColors.primarySkyDark.withValues(alpha: 0.4),
                onTap: _submit,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 19, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Address',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceBackground,
                foregroundColor: AppColors.slate500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.slate100)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(child: _buildForm()),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedAddressesScreen extends StatefulWidget {
  final String uid;

  const SavedAddressesScreen({super.key, required this.uid});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _openAddAddressSheet(String uid) async {
    final result = await showModalBottomSheet<_NewAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x660F172A),
      constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
      builder: (sheetContext) => const _AddAddressSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await _firestoreService.addSavedAddress(
        uid: uid,
        label: result.label,
        addressText: '${result.street}, ${result.barangay}, San Pablo City',
        note: result.landmark.isEmpty ? null : result.landmark,
        contactName: result.contact.isEmpty ? null : result.contact,
        phone: result.phone.isEmpty ? null : result.phone,
        isPrimary: result.isPrimary,
      );
      if (mounted) {
        AppToast.showSuccess(context, 'Address added to San Pablo dispatch routes!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to save address: $e');
      }
    }
  }

  void _showEditAddressLabelDialog(String uid, SavedAddressModel address) {
    final labelCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: const Color(0x730F172A),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          elevation: 0,
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.slate100),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit Tag",
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.backgroundDark,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Current tag: '),
                        TextSpan(
                          text: address.label,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontWeight: FontWeight.w600,
                            color: AppColors.borderDark,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "New Tag Name:",
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.borderDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      border: Border.all(color: AppColors.slate200.withValues(alpha: 0.8)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextFormField(
                      controller: labelCtrl,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.backgroundDark,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter tag name',
                        hintStyle: TextStyle(
                          fontFamily: _font,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.buttonSecondary,
                            foregroundColor: AppColors.slate600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final label = labelCtrl.text.trim();
                            if (label.isEmpty) return;
                            Navigator.pop(dialogContext);
                            try {
                              await _firestoreService.updateSavedAddressLabel(
                                uid: uid,
                                addressId: address.id,
                                label: label,
                              );
                            } catch (e) {
                              if (mounted) {
                                AppToast.showError(context, 'Failed to update tag: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySky,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: AppColors.primarySky.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ).copyWith(
                            elevation: WidgetStateProperty.resolveWith((states) => 4),
                          ),
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAddress(String uid, SavedAddressModel address) async {
    try {
      await _firestoreService.deleteSavedAddress(
        uid: uid,
        addressId: address.id,
      );
      if (mounted) {
        AppToast.showInfo(context, 'Address removed');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to delete address: $e');
      }
    }
  }

  IconData _iconFor(SavedAddressModel address, bool isPrimary) {
    final label = address.label.toLowerCase();
    if (label.contains('home')) return Icons.home;
    if (label.contains('work') || label.contains('office') || label.contains('branch')) {
      return Icons.apartment;
    }
    return isPrimary ? Icons.home : Icons.pin_drop;
  }

  Widget _buildHeader({String title = 'Saved Addresses', Color backIconColor = AppColors.textLight}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back, size: 24, color: backIconColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.17,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(String uid, SavedAddressModel address, bool isPrimary) {
    final String note = address.note ?? '';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isPrimary ? 0.08 : 0.05),
            blurRadius: isPrimary ? 8 : 3,
            offset: Offset(0, isPrimary ? 4 : 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPrimary ? AppColors.surfaceFrost : AppColors.surfaceContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconFor(address, isPrimary),
                          size: 20,
                          color: isPrimary ? AppColors.primarySky : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    address.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: _font,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPrimary
                                        ? AppColors.secondaryContainer
                                        : AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    isPrimary ? 'PRIMARY' : 'SECONDARY',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isPrimary
                                          ? AppColors.onSecondaryContainer
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (isPrimary) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.cyanElectric,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    isPrimary
                                        ? 'Quick Refill Dispatch Route'
                                        : 'Delivery Drop-off Point',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 11,
                                      fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                                      color: isPrimary ? AppColors.cyanElectric : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _deleteAddress(uid, address),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.addressText,
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: AppColors.textLight,
                          ),
                        ),
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.explore_outlined, size: 15, color: AppColors.cyanElectric),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (isPrimary) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.tealAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'OPTIMAL FLOW CERTIFIED',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9999),
                      onTap: () => _showEditAddressLabelDialog(uid, address),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Edit Tag',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: AppColors.primarySky,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.primarySky),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: isPrimary ? AppColors.primarySky : AppColors.accentBlueSoft,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(9999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetSnapshot() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFrost.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.local_shipping_outlined, size: 22, color: AppColors.primarySky),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standard Fleet Geofence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Active real-time dispatch telemetry enabled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primarySky,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarySky.withValues(alpha: 0.38),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          splashColor: AppColors.primarySkyDark.withValues(alpha: 0.4),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _font,
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(String uid) {
    return _buildPrimaryActionButton(
      icon: Icons.add_location_alt_outlined,
      label: 'Add New Address',
      onTap: () => _openAddAddressSheet(uid),
    );
  }

  Widget _buildAddressList(String uid) {
    return StreamBuilder<List<SavedAddressModel>>(
      stream: _firestoreService.getSavedAddressesStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final addresses = snapshot.data!;
        if (addresses.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'No saved addresses yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        final hasExplicitPrimary = addresses.any((a) => a.isPrimary);
        return Column(
          children: [
            for (int i = 0; i < addresses.length; i++) ...[
              _buildAddressCard(uid, addresses[i], hasExplicitPrimary ? addresses[i].isPrimary : i == 0),
              if (i != addresses.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceFrost,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pin_drop, size: 13, color: AppColors.primarySky),
                              SizedBox(width: 6),
                              Text(
                                'AQUA LOGISTICS NETWORK',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.primarySky,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Saved Delivery Addresses',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 28 / 22,
                            letterSpacing: -0.44,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Manage frequent drop-off locations and telematic routes',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 18 / 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAddressList(uid),
                        const SizedBox(height: 12),
                        _buildFleetSnapshot(),
                        const SizedBox(height: 12),
                        _buildAddButton(uid),
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
}