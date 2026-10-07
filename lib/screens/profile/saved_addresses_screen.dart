import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/saved_address_model.dart';
import '../../services/firestore_service.dart';

class SavedAddressesScreen extends StatefulWidget {
  final String uid;

  const SavedAddressesScreen({super.key, required this.uid});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  static const String _font = 'Plus Jakarta Sans';
  static const Color _background = Color(0xFFF6FAFC);
  static const Color _canvas = Color(0xFFF8FAFC);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _primary = Color(0xFF006194);
  static const Color _frost = Color(0xFFE0F2FE);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _blue = Color(0xFF0284C7);

  void _showAddAddressDialog(String uid) {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Tag (e.g. Home, Office)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Full Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Landmark / Notes (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              final addressText = addressCtrl.text.trim();
              if (label.isEmpty || addressText.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.addSavedAddress(
                  uid: uid,
                  label: label,
                  addressText: addressText,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to save address: $e'),
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

  void _confirmDeleteAddress(String uid, SavedAddressModel address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address'),
        content: Text('Remove "${address.label}" from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.deleteSavedAddress(
                  uid: uid,
                  addressId: address.id,
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete address: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF475569), size: 22),
                  SizedBox(width: 6),
                  Text(
                    'Back to Profile',
                    style: TextStyle(
                      fontFamily: _font,
                      color: Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                          isPrimary ? Icons.home : Icons.apartment,
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
                        onTap: () => _confirmDeleteAddress(uid, address),
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
          onTap: () => _showAddAddressDialog(uid),
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottomInset),
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
                          const SizedBox(height: 16),
                          _buildFleetSnapshot(),
                          const SizedBox(height: 20),
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
      ),
    );
  }
}