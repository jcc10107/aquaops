import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/saved_address_model.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';
const Color _background = Color(0xFFF6FAFC);
const Color _canvas = Color(0xFFF8FAFC);
const Color _onSurface = Color(0xFF131B2E);
const Color _onSurfaceVariant = Color(0xFF3F4850);
const Color _primary = Color(0xFF006194);
const Color _frost = Color(0xFFE0F2FE);
const Color _cyan = Color(0xFF06B6D4);
const Color _teal = Color(0xFF14B8A6);
const Color _secondary = Color(0xFF006C49);
const Color _blue = Color(0xFF0284C7);
const Color _blueDark = Color(0xFF0369A1);
const Color _slate100 = Color(0xFFF1F5F9);
const Color _slate200 = Color(0xFFE2E8F0);
const Color _slate300 = Color(0xFFCBD5E1);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate500 = Color(0xFF64748B);
const Color _errorRed = Color(0xFFBA1A1A);

const List<String> _barangays = [
  'Barangay I-A (Sambat)',
  'Barangay I-B',
  'Barangay II-A',
  'Barangay II-B',
  'Barangay II-C',
  'Barangay II-D',
  'Barangay II-E',
  'Barangay II-F',
  'Barangay III-A',
  'Barangay III-B',
  'Barangay III-C',
  'Barangay III-D',
  'Barangay III-E',
  'Barangay IV-A',
  'Barangay IV-B',
  'Barangay IV-C',
  'Barangay V-A',
  'Barangay V-B',
  'Barangay V-C',
  'Barangay V-D',
  'Barangay VI-A',
  'Barangay VI-B',
  'Barangay VI-C',
  'Barangay VI-D',
  'Barangay VI-E',
  'Barangay VII-A',
  'Barangay VII-B',
  'Barangay VII-C',
  'Barangay VII-D',
  'Barangay VII-E',
  'Barangay Bagong Bayan (Poblacion)',
  'Barangay Atisan',
  'Barangay Bautista',
  'Barangay Concepcion',
  'Barangay Del Remedio',
  'Barangay Dolores',
  'Barangay San Antonio 1',
  'Barangay San Antonio 2',
  'Barangay San Bartolome',
  'Barangay San Buenaventura',
  'Barangay San Crispin',
  'Barangay San Cristobal',
  'Barangay San Diego',
  'Barangay San Francisco',
  'Barangay San Gabriel',
  'Barangay San Gregorio',
  'Barangay San Ignacio',
  'Barangay San Isidro',
  'Barangay San Joaquin',
  'Barangay San Jose',
  'Barangay San Juan',
  'Barangay San Lorenzo',
  'Barangay San Lucas 1',
  'Barangay San Lucas 2',
  'Barangay San Marcos',
  'Barangay San Mateo',
  'Barangay San Miguel',
  'Barangay San Nicolas',
  'Barangay San Pedro',
  'Barangay San Rafael',
  'Barangay San Roque',
  'Barangay San Vicente',
  'Barangay Santa Ana',
  'Barangay Santa Catalina',
  'Barangay Santa Cruz',
  'Barangay Santa Elena',
  'Barangay Santa Felomina',
  'Barangay Santa Isabel',
  'Barangay Santa Maria',
  'Barangay Santa Maria Magdalena',
  'Barangay Santa Monica',
  'Barangay Santa Veronica',
  'Barangay Santiago 1',
  'Barangay Santiago 2',
  'Barangay Santisimo Rosario',
  'Barangay Santo Angel',
  'Barangay Santo Cristo',
  'Barangay Santo Niño',
  'Barangay Soledad',
];

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

InputDecoration _fieldDecoration({String? hint, double vertical = 10}) {
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
      color: _slate400,
    ),
    filled: true,
    fillColor: _canvas,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
    border: border(_slate200),
    enabledBorder: border(_slate200),
    focusedBorder: border(_blue),
  );
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  String _tag = 'Home';
  String? _barangay;
  bool _isPrimary = false;
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController(text: 'Juan Dela Cruz');
  final TextEditingController _phoneCtrl = TextEditingController(text: '0917 123 4567');

  @override
  void dispose() {
    _streetCtrl.dispose();
    _landmarkCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final street = _streetCtrl.text.trim();
    if (_barangay == null || _barangay!.isEmpty || street.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Text(
            'Please select a Barangay and enter street address.',
            style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
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
        color: _onSurface,
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
            color: active ? _frost : Colors.white,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: active ? _blue : _slate200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? _blue : _onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _blue : _onSurfaceVariant,
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
        border: Border(bottom: BorderSide(color: _slate100)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _slate300,
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
                    decoration: const BoxDecoration(color: _frost, shape: BoxShape.circle),
                    child: const Icon(Icons.add_location_alt_outlined, size: 18, color: _blue),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Delivery Address',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
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
                  child: Icon(Icons.close, size: 20, color: _slate400),
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
                    TextSpan(text: '*', style: TextStyle(color: _errorRed)),
                  ],
                ),
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              Text(
                'San Pablo City, Laguna',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            menuMaxHeight: 320,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.expand_more, size: 18, color: _slate400),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _onSurface,
            ),
            decoration: _fieldDecoration(hint: 'Select Barangay...'),
            items: _barangays
                .map((b) => DropdownMenuItem<String>(
              value: b,
              child: Text(b, overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: (v) => setState(() => _barangay = v),
          ),
          const SizedBox(height: 16),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Street Address / House / Unit No. '),
                TextSpan(text: '*', style: TextStyle(color: _errorRed)),
              ],
            ),
            style: TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _streetCtrl,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _onSurface,
            ),
            decoration: _fieldDecoration(hint: 'e.g. Block 8 Lot 14, Villa Antonio Subdivision'),
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
                  color: _slate400,
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
              color: _onSurface,
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
                        color: _onSurface,
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
                        color: _onSurface,
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
              border: Border(top: BorderSide(color: _slate100)),
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
                          color: _onSurface,
                        ),
                      ),
                      Text(
                        'Default route for quick refills & telemetry',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _slate400,
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
                        (states) => states.contains(WidgetState.selected) ? _blue : _slate200,
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
              color: _blue,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                splashColor: _blueDark.withValues(alpha: 0.4),
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
                backgroundColor: _background,
                foregroundColor: _slate500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _slate500,
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
            border: Border(top: BorderSide(color: _slate100)),
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

  bool _toastVisible = false;
  String _toastMessage = '';
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _toastMessage = message;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _toastVisible = false);
    });
  }

  Future<void> _openAddAddressSheet(String uid) async {
    final result = await showModalBottomSheet<_NewAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x660F172A),
      constraints: const BoxConstraints(maxWidth: 450),
      builder: (sheetContext) => const _AddAddressSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await _firestoreService.addSavedAddress(
        uid: uid,
        label: result.label,
        addressText: '${result.street}, ${result.barangay}, San Pablo City',
        note: result.landmark.isEmpty ? null : result.landmark,
      );
      _showToast('Address added to San Pablo dispatch routes!');
    } catch (e) {
      _showToast('Failed to save address: $e');
    }
  }

  void _showEditAddressLabelDialog(String uid, SavedAddressModel address) {
    final labelCtrl = TextEditingController(text: address.label);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Tag'),
        content: TextFormField(
          controller: labelCtrl,
          decoration: const InputDecoration(labelText: 'Tag'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.updateSavedAddressLabel(
                  uid: uid,
                  addressId: address.id,
                  label: label,
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update tag: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddress(String uid, SavedAddressModel address) async {
    try {
      await _firestoreService.deleteSavedAddress(
        uid: uid,
        addressId: address.id,
      );
      _showToast('Address removed');
    } catch (e) {
      _showToast('Failed to delete address: $e');
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _background.withValues(alpha: 0.85),
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
            constraints: const BoxConstraints(maxWidth: 450),
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back, size: 24, color: _onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Saved Addresses',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.17,
                          color: _onSurface,
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

  Widget _buildToast() {
    final top = MediaQuery.of(context).padding.top + 16;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _toastVisible ? Offset.zero : const Offset(0, -4),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _toastVisible ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _toastMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: Colors.white,
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
                          color: isPrimary ? _frost : const Color(0xFFEAEDFF),
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
                          color: isPrimary ? _primary : _onSurfaceVariant,
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
                                      color: _onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPrimary
                                        ? const Color(0xFF6CF8BB)
                                        : const Color(0xFFE2E7FF),
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
                                          ? const Color(0xFF00714D)
                                          : _onSurfaceVariant,
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
                                      color: _cyan,
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
                                      color: isPrimary ? _cyan : _onSurfaceVariant,
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
                            color: _onSurfaceVariant.withValues(alpha: 0.7),
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
                      color: _canvas,
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
                            color: _onSurface,
                          ),
                        ),
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.explore_outlined, size: 15, color: _cyan),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 11,
                                    color: _onSurfaceVariant,
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
                                  color: _teal,
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
                                    color: _secondary,
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
                                color: _blue,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: _blue),
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
                  color: isPrimary ? _primary : const Color(0xFFDAE2FD),
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
        color: _frost.withValues(alpha: 0.6),
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
            child: const Icon(Icons.local_shipping_outlined, size: 22, color: _primary),
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
                    color: _onSurface,
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
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String uid) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.38),
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
          splashColor: _blueDark.withValues(alpha: 0.4),
          onTap: () => _openAddAddressSheet(uid),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Add New Address',
                style: TextStyle(
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
                color: _onSurfaceVariant,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < addresses.length; i++) ...[
              _buildAddressCard(uid, addresses[i], i == 0),
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
      backgroundColor: _background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _frost,
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
                                  Icon(Icons.pin_drop, size: 13, color: _primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'AQUA LOGISTICS NETWORK',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: _primary,
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
                                color: _onSurface,
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
                                color: _onSurfaceVariant,
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
          _buildToast(),
        ],
      ),
    );
  }
}