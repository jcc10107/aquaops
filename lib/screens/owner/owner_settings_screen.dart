import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/firestore_service.dart';
import 'edit_product_photos_screen.dart';
import 'gcash_account_editor_screen.dart';
import 'manage_branches_screen.dart';
import 'manage_team_screen.dart';
import 'terms_privacy_editor_screen.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  static const String _font = 'Plus Jakarta Sans';

  void _showEditDeliveryFeeDialog(BuildContext context, double currentBaseFee, double currentRatePerKm) {
    final baseCtrl = TextEditingController(text: currentBaseFee.toStringAsFixed(2));
    final rateCtrl = TextEditingController(text: currentRatePerKm.toStringAsFixed(2));
    String? baseError;
    String? rateError;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceCanvas,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Edit Delivery Fee',
              style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Base Fee', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: baseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    if (baseError != null) setDialogState(() => baseError = null);
                  },
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    hintText: 'e.g. 15.00',
                    errorText: baseError,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Rate per Kilometer', style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    if (rateError != null) setDialogState(() => rateError = null);
                  },
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    hintText: 'e.g. 5.00',
                    errorText: rateError,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Charged on top of base fee, calculated by road distance from the station to customer address.',
                  style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final base = double.tryParse(baseCtrl.text.trim());
                  final rate = double.tryParse(rateCtrl.text.trim());
                  setDialogState(() {
                    baseError = (base == null || base < 0) ? 'Enter a valid, non-negative amount.' : null;
                    rateError = (rate == null || rate < 0) ? 'Enter a valid, non-negative amount.' : null;
                  });
                  if (baseError != null || rateError != null) return;
                  await _firestoreService.setDeliveryFeeConfig(baseFee: base!, ratePerKm: rate!);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySky, foregroundColor: Colors.white),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(topInset),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Banner
                      _buildHeroCard(),
                      const SizedBox(height: 20),

                      // 1. People & Access
                      _buildSectionHeader('People & Access', 'Accounts & Team Roles'),
                      const SizedBox(height: 8),
                      _buildCardGroup([
                        _buildListTile(
                          'Manage Staff & Riders',
                          'Team accounts, role assignments, and routes',
                          Icons.groups_outlined,
                          AppColors.primarySky,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageTeamScreen()),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // 2. Station Configuration
                      _buildSectionHeader('Station Configuration', 'Coverage & Operations'),
                      const SizedBox(height: 8),
                      _buildCardGroup([
                        _buildListTile(
                          'Manage Branches',
                          'Water refilling station locations & contact info',
                          Icons.store_outlined,
                          AppColors.primarySky,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageBranchesScreen()),
                          ),
                        ),
                        _buildDivider(),
                        StreamBuilder<({double baseFee, double ratePerKm})>(
                          stream: _firestoreService.getDeliveryFeeConfigStream(),
                          builder: (context, snapshot) {
                            final config = snapshot.data ?? (baseFee: 0.0, ratePerKm: 0.0);
                            final subtitle = (config.baseFee == 0 && config.ratePerKm == 0)
                                ? 'Free Delivery (₱0.00)'
                                : '₱${config.baseFee.toStringAsFixed(2)} base + ₱${config.ratePerKm.toStringAsFixed(2)}/km';

                            return _buildListTile(
                              'Delivery Fee Configuration',
                              subtitle,
                              Icons.local_shipping_outlined,
                              AppColors.primarySky,
                              onTap: () => _showEditDeliveryFeeDialog(context, config.baseFee, config.ratePerKm),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildListTile(
                          'Manage Products',
                          'Add, reprice, or remove items in the store catalog',
                          Icons.photo_camera_outlined,
                          AppColors.primarySky,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProductPhotosScreen()),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // 3. Payments
                      _buildSectionHeader('Payments', 'Customer Collections'),
                      const SizedBox(height: 8),
                      _buildCardGroup([
                        _buildListTile(
                          'GCash Account',
                          'Payment number & QR code shown at checkout',
                          Icons.qr_code_2_outlined,
                          AppColors.primarySky,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GcashAccountEditorScreen()),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // 4. Policies & Legal
                      _buildSectionHeader('Policies & Legal', 'Compliance & Content'),
                      const SizedBox(height: 8),
                      _buildCardGroup([
                        _buildListTile(
                          'Edit Terms & Privacy',
                          'Update published station policies & terms of service',
                          Icons.edit_document,
                          AppColors.primarySky,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsPrivacyEditorScreen()),
                          ),
                        ),
                      ]),
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

  Widget _buildHeader(double topInset) {
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
              onTap: () => Navigator.pop(context),
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
                'Owner Settings',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Station administration and configuration',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
            child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primarySky, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATION ADMINISTRATION',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primarySky,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Business Configuration',
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage your station policies, delivery coverage, pricing, and staff roles.',
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(
      String title,
      String subtitle,
      IconData icon,
      Color iconColor, {
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: trailing != null ? 12 : 8),
            trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: AppColors.slate100);
}