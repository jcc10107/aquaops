import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/zones.dart';
import '../../core/utils/app_toast.dart';
import '../../models/saved_address_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../customer/location_picker_map_screen.dart';

const String _font = 'Plus Jakarta Sans';

class _NewAddress {
  final String label;
  final String barangay;
  final String street;
  final String landmark;
  final String contact;
  final String phone;
  final bool isPrimary;
  final double latitude;
  final double longitude;

  const _NewAddress({
    required this.label,
    required this.barangay,
    required this.street,
    required this.landmark,
    required this.contact,
    required this.phone,
    required this.isPrimary,
    required this.latitude,
    required this.longitude,
  });
}

InputDecoration _fieldDecoration({String? hint, double vertical = 10, String? errorText}) {
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
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorText != null ? AppColors.coralAlert : AppColors.slate200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorText != null ? AppColors.coralAlert : AppColors.primarySky)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.coralAlert)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.coralAlert, width: 1.5)),
    errorText: errorText,
    errorStyle: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.coralAlert),
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
  String? _barangayError;
  String? _streetError;
  String? _locationError;
  PreciseLocation? _pinnedLocation;
  // True once a pinned location fails to match any San Pablo barangay — the
  // customer picked "Outside San Pablo" on the map picker, or just pinned
  // somewhere outside the city. Forces the barangay field to free text
  // regardless of the owner's global service-area setting, since the pin's
  // actual coordinates already say this address isn't in San Pablo — letting
  // the dropdown stay up would force a fake San Pablo barangay onto a
  // real out-of-town address.
  bool _addressOutsideSanPablo = false;

  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
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

  Future<void> _pinLocationOnMap() async {
    // Opens immediately centered on the station — waiting on a
    // high-accuracy GPS fix here (up to 20s, and often slow on desktop
    // browsers with no real GPS chip) just to pick a starting point isn't
    // worth the delay, since the map's own GPS button and manual drag
    // already get the user to the right spot.
    final result = await Navigator.push<PreciseLocation>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerMapScreen(initialLat: stationLat, initialLng: stationLng)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _pinnedLocation = result;
      _locationError = null;
      // Reuse the reverse-geocoded address so the rider only has to touch
      // the landmark/recipient fields — not retype what the pin already
      // tells us.
      if (_streetCtrl.text.trim().isEmpty) {
        _streetCtrl.text = result.address;
      }
      final matchedBarangay = _matchBarangay(result.address);
      _addressOutsideSanPablo = matchedBarangay == null;
      if (matchedBarangay != null) {
        _barangay = matchedBarangay;
        _barangayError = null;
        _barangayFreeTextCtrl.text = matchedBarangay;
      } else {
        _barangay = null;
        _barangayFreeTextCtrl.text = '';
      }
    });
  }

  // Best-effort match of a reverse-geocoded address string against the
  // official barangay list, so the dropdown can pre-select itself. Not
  // guaranteed to find one (OSM's phrasing varies) — the field stays
  // editable either way.
  String? _matchBarangay(String address) {
    final lower = address.toLowerCase();
    final sortedByLength = [...sanPabloBarangays]..sort((a, b) => b.length.compareTo(a.length));
    for (final b in sortedByLength) {
      final bareName = b.replaceFirst(RegExp(r'^(Barangay|Brgy\.?)\s+', caseSensitive: false), '').toLowerCase().trim();
      if (bareName.isNotEmpty && lower.contains(bareName)) return b;
    }
    return null;
  }

  void _submit() {
    final street = _streetCtrl.text.trim();
    setState(() {
      _barangayError = (_barangay == null || _barangay!.isEmpty) ? 'Please select a barangay.' : null;
      _streetError = street.isEmpty ? 'Street address is required.' : null;
      _locationError = _pinnedLocation == null ? 'Pin the exact delivery location on the map.' : null;
    });
    if (_barangayError != null || _streetError != null || _locationError != null) return;
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
        latitude: _pinnedLocation!.latitude,
        longitude: _pinnedLocation!.longitude,
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE0F2FE) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.primarySky : AppColors.slate200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? AppColors.primarySky : AppColors.slate500),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? AppColors.primarySky : AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800, // Standard 800px width
          maxHeight: media.size.height * 0.88,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.slate100)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                      child: const Icon(Icons.add_location_alt_outlined, size: 20, color: AppColors.primarySky),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Add Delivery Address',
                        style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.slate500),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + media.viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Address Label', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
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

                      Text(
                        'Exact Pin Location *',
                        style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: _locationError != null ? AppColors.coralAlert : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      if (_pinnedLocation != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pinnedLocation!.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                ),
                              ),
                              TextButton(
                                onPressed: _pinLocationOnMap,
                                child: const Text('Change', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pinLocationOnMap,
                            icon: const Icon(Icons.pin_drop_outlined, size: 18),
                            label: const Text('Pin Exact Location on Map', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primarySky,
                              side: BorderSide(color: _locationError != null ? AppColors.coralAlert : AppColors.primarySky),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (_locationError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(_locationError!, style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.coralAlert)),
                        ),
                      const SizedBox(height: 16),

                      const Text('Barangay (San Pablo City) *', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Builder(
                        builder: (context) {
                          // Driven purely by the map pin itself now — not an
                          // owner-level setting — so the dropdown only ever
                          // stays up when the pinned location actually
                          // matched a San Pablo barangay.
                          final restricted = !_addressOutsideSanPablo;
                          if (!restricted) {
                            return TextField(
                              controller: _barangayFreeTextCtrl,
                              style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                              decoration: _fieldDecoration(hint: 'Enter barangay/city...', errorText: _barangayError),
                              onChanged: (v) => setState(() {
                                _barangay = v.trim().isEmpty ? null : v.trim();
                                _barangayError = null;
                              }),
                            );
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: DropdownMenu<String>(
                              // DropdownMenu only reads initialSelection on
                              // its first build — keying by the current
                              // value forces a fresh widget (and a fresh
                              // read of it) whenever pinning a location
                              // auto-fills _barangay, so the field visibly
                              // updates instead of silently staying blank.
                              key: ValueKey(_barangay),
                              initialSelection: _barangay,
                              menuHeight: 300,
                              enableFilter: true,
                              requestFocusOnTap: true,
                              hintText: 'Search or select barangay...',
                              textStyle: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                              inputDecorationTheme: InputDecorationTheme(
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
                          child: Text(_barangayError!, style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.coralAlert)),
                        ),
                      const SizedBox(height: 16),

                      const Text('Street Address / House / Unit No. *', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _streetCtrl,
                        onChanged: (_) {
                          if (_streetError != null) setState(() => _streetError = null);
                        },
                        style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                        decoration: _fieldDecoration(
                          hint: 'e.g. Block 8 Lot 14, Villa Antonio Subdivision',
                          errorText: _streetError,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Landmark & Delivery Instructions (Optional)', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _landmarkCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                        decoration: _fieldDecoration(
                          hint: 'e.g. Near yellow gate across sari-sari store',
                          vertical: 10,
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
                                const Text('Recipient Name', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _contactCtrl,
                                  style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                                  decoration: _fieldDecoration(hint: 'Contact person', vertical: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Contact Number', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                                  decoration: _fieldDecoration(hint: '09XX XXX XXXX', vertical: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.slate100))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Set as Primary Address', style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                  Text('Use as default location for water deliveries', style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPrimary,
                              activeThumbColor: AppColors.primarySky,
                              onChanged: (v) => setState(() => _isPrimary = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarySky,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Address', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: AppColors.slate500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
        latitude: result.latitude,
        longitude: result.longitude,
      );
      if (mounted) {
        AppToast.showSuccess(context, 'Delivery address saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to save address: $e');
      }
    }
  }

  void _showEditAddressLabelDialog(String uid, SavedAddressModel address) {
    final labelCtrl = TextEditingController(text: address.label);
    String? labelError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCanvas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Address Label', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold)),
              content: TextField(
                controller: labelCtrl,
                style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
                onChanged: (_) {
                  if (labelError != null) setDialogState(() => labelError = null);
                },
                decoration: InputDecoration(
                  hintText: 'e.g. Home, Work, Apartment',
                  errorText: labelError,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: labelError != null ? AppColors.coralAlert : AppColors.slate200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: labelError != null ? AppColors.coralAlert : AppColors.primarySky)),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final label = labelCtrl.text.trim();
                    if (label.isEmpty) {
                      setDialogState(() => labelError = 'Please enter a label for this address.');
                      return;
                    }
                    Navigator.pop(dialogContext);
                    try {
                      await _firestoreService.updateSavedAddressLabel(uid: uid, addressId: address.id, label: label);
                    } catch (e) {
                      if (mounted) AppToast.showError(context, 'Failed to update label: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySky, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String uid, SavedAddressModel address) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Address?', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${address.label}" from your delivery addresses?',
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.deleteSavedAddress(uid: uid, addressId: address.id);
                if (mounted) AppToast.showInfo(context, 'Address removed');
              } catch (e) {
                if (mounted) AppToast.showError(context, 'Failed to delete: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAlert, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _header(double topInset) {
    return Container(
      height: 64 + topInset,
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceCanvas,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Addresses',
                style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              SizedBox(height: 2),
              Text(
                'Delivery drop-off locations',
                style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String uid, SavedAddressModel address, bool isPrimary) {
    final String note = address.note ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? AppColors.primarySky : AppColors.slate200, width: isPrimary ? 1.5 : 1),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPrimary ? const Color(0xFFE0F2FE) : AppColors.surfaceCanvas,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  address.label.toLowerCase().contains('work') ? Icons.apartment : Icons.home_outlined,
                  size: 18,
                  color: isPrimary ? AppColors.primarySky : AppColors.slate500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(100)),
                        child: const Text('Primary', style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.slate400),
                onSelected: (val) {
                  if (val == 'edit') _showEditAddressLabelDialog(uid, address);
                  if (val == 'delete') _confirmDelete(uid, address);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Label', style: TextStyle(fontFamily: _font, fontSize: 13))),
                  PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.coralAlert))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.addressText,
            style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.slate400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryCoverageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF16A34A)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Service Coverage',
                  style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
                Text(
                  'San Pablo City, Laguna • Covered for fast refill dispatch',
                  style: TextStyle(fontFamily: _font, fontSize: 11, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas, // #F8FAFC
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
          child: Column(
            children: [
              _header(topInset),
              Expanded(
                child: StreamBuilder<List<SavedAddressModel>>(
                  stream: _firestoreService.getSavedAddressesStream(uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final addresses = snapshot.data!;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDeliveryCoverageCard(),
                          const SizedBox(height: 16),
                          if (addresses.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.slate200),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.location_off_outlined, size: 40, color: AppColors.slate400),
                                  SizedBox(height: 10),
                                  Text(
                                    'No Saved Addresses Yet',
                                    style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add your delivery locations for faster refilling checkout.',
                                    style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...addresses.map((a) => _buildAddressCard(uid, a, a.isPrimary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _openAddAddressSheet(uid),
                              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                              label: const Text('Add New Address', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySky,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}