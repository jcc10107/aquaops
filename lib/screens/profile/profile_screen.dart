import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/components/soft_input_field.dart';
import '../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  Map<String, String> _getUserData(String role) {
    switch (role) {
      case 'owner':
        return {
          'name': 'Juan Dela Cruz',
          'email': 'owner@drink8.com',
          'badge': 'STATION OWNER',
          'initials': 'JD'
        };
      case 'staff':
        return {
          'name': 'Arnel Bautista',
          'email': 'arnel.staff@drink8.com',
          'badge': 'STATION STAFF',
          'initials': 'AB'
        };
      case 'rider':
        return {
          'name': 'Jun Soriano',
          'email': 'jun.rider@drink8.com',
          'badge': 'DISPATCH RIDER',
          'initials': 'JS'
        };
      case 'customer':
      default:
        return {
          'name': 'Elena Gomez',
          'email': 'elena@aquaops.com',
          'badge': 'ACTIVE SUBSCRIBER',
          'initials': 'EG'
        };
    }
  }

  void _showEditProfileDialog(Map<String, String> userData, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 380,
          child: Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
            elevation: 24,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer, AppColors.cyanElectric]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: <Widget>[
                          Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.account_circle, color: Colors.white, size: 20)),
                          const SizedBox(width: 10),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Manage Profile', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)), Text('Update contact details', style: TextStyle(fontSize: 10, color: Colors.white70))]),
                        ],
                      ),
                      InkWell(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isDark ? AppColors.backgroundDark : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.cyanElectric, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle),
                              child: Center(child: Text(userData['initials']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [Text(userData['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)), const SizedBox(width: 4), const Icon(Icons.verified, size: 14, color: AppColors.secondary)]),
                                  Text(userData['email']!, style: const TextStyle(fontSize: 11, color: AppColors.textVariant)),
                                  const SizedBox(height: 4),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(100)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)), const SizedBox(width: 4), Text(userData['badge']!, style: const TextStyle(fontSize: 9, color: AppColors.secondary, fontWeight: FontWeight.w800, letterSpacing: 0.5))])),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SoftInputField(label: 'Full Name', icon: Icons.person, initialValue: userData['name']),
                      const SizedBox(height: 12),
                      const SoftInputField(label: 'Mobile Number', icon: Icons.phone, initialValue: '0917 123 4567'),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: BorderSide.none, backgroundColor: AppColors.surfaceContainer, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), child: const Text('Cancel', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 13)))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), gradient: const LinearGradient(colors: [AppColors.primary, AppColors.cyanElectric]), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]),
                              child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!'))); }, icon: const Icon(Icons.check, size: 15, color: Colors.white), label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddressesDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Center(
        child: SizedBox(
          width: 410,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(margin: const EdgeInsets.only(top: 10, bottom: 4), width: 36, height: 5, decoration: BoxDecoration(color: AppColors.outlineVariant.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(100)), child: const Row(children: [Icon(Icons.pin_drop, size: 12, color: AppColors.primary), SizedBox(width: 4), Text('AQUA LOGISTICS NETWORK', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.8))])),
                          InkWell(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: AppColors.textVariant))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Saved Delivery Addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)),
                      const Text('Manage frequent drop-off locations', style: TextStyle(fontSize: 11, color: AppColors.textVariant)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      _buildAddressCard('Home', 'Primary', 'Quick Refill Dispatch Route', 'Barangay San Isidro, San Pablo City', 'Near Blue Gate, Landmark: Water Station Alpha', Icons.home, AppColors.primary, isDark),
                      const SizedBox(height: 10),
                      _buildAddressCard('Branch Office', 'Secondary', 'Bulk Container Hub', 'Mabini Street, Suite 402, San Pablo City', 'Across City Plaza, Service Entrance B', Icons.apartment, AppColors.outline, isDark),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer]), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size(double.infinity, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                      onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening maps to add address...'))); },
                      icon: const Icon(Icons.add_location_alt, size: 18, color: Colors.white),
                      label: const Text('Add New Address', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(String title, String badge, String subtitle, String address, String note, IconData icon, Color accentColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceContainer : AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)))),
            Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 32, height: 32, decoration: BoxDecoration(color: accentColor == AppColors.primary ? AppColors.surfaceFrost : AppColors.outlineVariant, shape: BoxShape.circle), child: Icon(icon, size: 16, color: accentColor == AppColors.primary ? AppColors.primary : AppColors.textVariant)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                                  const SizedBox(width: 6),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: accentColor == AppColors.primary ? AppColors.secondaryContainer : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(100)), child: Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accentColor == AppColors.primary ? AppColors.secondary : AppColors.textVariant, letterSpacing: 0.5))),
                                ],
                              ),
                              Row(children: [if (accentColor == AppColors.primary) ...[Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.cyanElectric, shape: BoxShape.circle)), const SizedBox(width: 4)], Text(subtitle, style: TextStyle(fontSize: 10, color: accentColor == AppColors.primary ? AppColors.primary : AppColors.textVariant))])
                            ],
                          )
                        ],
                      ),
                      Icon(Icons.delete, size: 16, color: AppColors.outline.withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isDark ? AppColors.backgroundDark : AppColors.surfaceLowest, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(address, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMain, height: 1.2)),
                          const SizedBox(height: 2),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.explore, size: 12, color: accentColor == AppColors.primary ? AppColors.cyanElectric : AppColors.outline), const SizedBox(width: 4), Expanded(child: Text(note, style: const TextStyle(fontSize: 10, color: AppColors.textVariant)))])
                    ],
                  ),
                ),
                if (accentColor == AppColors.primary) ...[
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(Icons.verified, size: 14, color: AppColors.tealAccent), SizedBox(width: 4), Text('Optimal Flow Certified', style: TextStyle(fontSize: 10, color: AppColors.textVariant))]),
                  Row(children: [Text('Edit Tag', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)), Icon(Icons.chevron_right, size: 14, color: AppColors.primary)])
                ],
              )
            ]
          ],
        ),
      ),
    )
    ],
    ),
    ),
    );
  }

  void _showPasswordDialog(bool isDark) {
    showDialog(
        context: context,
        builder: (context) => Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: const _ChangePasswordDialog()
            )
        )
    );
  }

  void _showTermsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 380,
          child: Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
            elevation: 24,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(100)), child: const Row(children: [Icon(Icons.verified_user, size: 12, color: AppColors.primary), SizedBox(width: 4), Text('HYDRATION TRUST & ETHICS', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.8))])),
                          InkWell(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(shape: BoxShape.circle), child: const Icon(Icons.close, size: 18, color: AppColors.textVariant))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Terms & Privacy', style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      const Text('Drink 8 Purified Water Refilling Station • San Pablo City', style: TextStyle(fontSize: 10, color: AppColors.textVariant)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.gavel, size: 16, color: AppColors.primary), SizedBox(width: 6), Text('Part 1: Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain))]),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(8)),
                          child: const Column(
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EFFECTIVE DATE', style: TextStyle(fontSize: 9, color: AppColors.textVariant, fontWeight: FontWeight.bold)), Text('September 21, 2026', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold))]),
                              SizedBox(height: 4),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOCATION', style: TextStyle(fontSize: 9, color: AppColors.textVariant, fontWeight: FontWeight.bold)), Text('San Pablo City, Laguna', style: TextStyle(fontSize: 10, color: AppColors.textMain, fontWeight: FontWeight.w600))]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLegalParagraph('1. Acceptance of Terms', 'By downloading, accessing, or placing replenishment orders through the Drink 8 mobile interface, you unreservedly acknowledge and agree to be bound by these terms.', AppColors.primary),
                        _buildLegalParagraph('2. User Accounts & Registration', 'You agree to submit authentic, current, and verifiable registry details including your Full Legal Name, Active Mobile Number, and accurate Barangay Delivery Address.', AppColors.primary),
                        _buildLegalParagraph('3. Product & Gallon Policy', 'Drink 8 provides certified purified water. A clean, sanitarily sound empty container swap is mandatory per refill, or standard bottle deposit tariffs shall apply.', AppColors.primary),
                        const Divider(height: 24, color: AppColors.surfaceContainer),
                        const Row(children: [Icon(Icons.security, size: 16, color: AppColors.secondary), SizedBox(width: 6), Text('Part 2: Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain))]),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.verified, size: 14, color: AppColors.secondary), SizedBox(width: 6), Text('Compliance: RA No. 10173 (Data Privacy Act)', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold))])),
                        const SizedBox(height: 12),
                        _buildLegalParagraph('1. Information Collection', 'We strictly gather essential customer profile details: Name, Email, Contact Number, Address, and Digital Payment Verification Screenshots.', AppColors.secondary),
                        _buildLegalParagraph('2. Data Usage & Protection', 'Collected metrics are exclusively leveraged for scheduled route fulfillment. Drink 8 will never monetize or distribute your identity to third parties.', AppColors.secondary),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -3))]),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), gradient: const LinearGradient(colors: [AppColors.primary, AppColors.cyanElectric]), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size(double.infinity, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                      label: const Text('I Accept', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalParagraph(String title, String body, Color titleColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(fontSize: 10, color: AppColors.textVariant, height: 1.35)),
        ],
      ),
    );
  }

  void _showHelpCenterDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 410,
          child: Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
            elevation: 24,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(margin: const EdgeInsets.only(top: 10, bottom: 4), width: 36, height: 5, decoration: BoxDecoration(color: AppColors.outlineVariant.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Help Center & FAQs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)),
                        InkWell(onTap: () => Navigator.pop(context), child: Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: AppColors.textVariant))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search topics, refill guides, deposits...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.outline),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? AppColors.backgroundDark : AppColors.surfaceLowest,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: AppColors.surfaceContainer)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CATEGORIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 0.5)), Text('FAST ANSWERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1))]),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                            children: [
                              _buildHelpChip('Refills', 'Orders & Timing', Icons.water_drop, AppColors.primary),
                              _buildHelpChip('Bottle Swap', 'Deposit rules', Icons.sync_alt, AppColors.secondary),
                              _buildHelpChip('Delivery', 'Routes & zones', Icons.local_shipping, AppColors.primaryContainer),
                              _buildHelpChip('GCash / Pay', 'Reference code', Icons.account_balance_wallet, AppColors.cyanElectric),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text('COMMON INQUIRIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          _buildFaqAccordion('How does the empty gallon container swap work?', 'Leave your clean, undamaged Drink 8 empty container at your doorstep or hand it to our dispatch rider upon delivery to avoid new bottle deposit fees.'),
                          _buildFaqAccordion('What are your delivery hours in San Pablo City?', 'Our riders operate Monday to Saturday from 7:00 AM to 5:30 PM across covered barangays including San Isidro and San Antonio.'),
                          _buildFaqAccordion('How do I verify GCash payments?', 'Input your GCash 13-digit reference number upon ordering or upload your transaction screenshot directly in Checkout or to the rider.'),
                          _buildFaqAccordion('What if my delivery is delayed due to weather?', 'In case of heavy rains or localized flooding, order status updates will be broadcast directly via push alerts and SMS.'),
                          _buildFaqAccordion('Can I request an emergency refill?', 'Yes! Contact the station dispatch hotline or select \'Priority Queue\' during ordering if available.'),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isDark ? [AppColors.surfaceContainer, AppColors.surfaceDark] : [AppColors.surfaceFrost.withValues(alpha: 0.6), Colors.white],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.cyanElectric.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(100)), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Live Dispatch', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold))])),
                                        const SizedBox(height: 4),
                                        const Text('Still need help?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                                      ],
                                    ),
                                    Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceLowest, shape: BoxShape.circle), child: const Icon(Icons.headset_mic, color: AppColors.primary, size: 18)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceContainer)),
                                  child: Row(
                                    children: [
                                      Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.call, size: 14, color: AppColors.primary)),
                                      const SizedBox(width: 10),
                                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('DIRECT DISPATCH HOTLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.outline)), Text('(049) 562-8000', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))])),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.surfaceFrost, borderRadius: BorderRadius.circular(100)), child: const Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)))
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), gradient: const LinearGradient(colors: [AppColors.cyanElectric, AppColors.primary])),
                                  child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to Support...'))); }, icon: const Icon(Icons.chat, size: 16, color: Colors.white), label: const Text('Chat with Station Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                                ),
                                const SizedBox(height: 8),
                                const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule, size: 12, color: AppColors.textVariant), SizedBox(width: 4), Text('Mon - Sat: 7:00 AM - 5:30 PM', style: TextStyle(fontSize: 10, color: AppColors.textVariant))]))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpChip(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceContainer), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain), overflow: TextOverflow.ellipsis), Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textVariant), overflow: TextOverflow.ellipsis)])),
        ],
      ),
    );
  }

  Widget _buildFaqAccordion(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceContainer), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          trailing: Container(width: 24, height: 24, decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle), child: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary)),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [Text(answer, style: const TextStyle(fontSize: 11, color: AppColors.textVariant, height: 1.4))],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 360,
          child: Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
            elevation: 24,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.2), blurRadius: 8)]),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textVariant, height: 1.4)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, size: 14, color: AppColors.coralAlert),
                        SizedBox(width: 6),
                        Text('3 BOTTLE DEPOSITS WILL BE FORFEITED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textVariant, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(backgroundColor: AppColors.surfaceContainerLow, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            currentUserRoleNotifier.value = 'none';
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shadowColor: AppColors.error.withValues(alpha: 0.5), elevation: 4, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.delete, size: 14, color: Colors.white),
                          label: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNavTapped(int index) {
    final role = currentUserRoleNotifier.value;
    if (role == 'owner') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/owner_dashboard');
      if (index == 1) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 2) Navigator.pushReplacementNamed(context, '/dispatch');
      if (index == 3) Navigator.pushReplacementNamed(context, '/inventory');
      if (index == 4) return;
    } else if (role == 'staff') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/pos');
      if (index == 1) Navigator.pushReplacementNamed(context, '/inventory');
      if (index == 2) return;
    } else if (role == 'rider') {
      if (index == 0) Navigator.pushReplacementNamed(context, '/dispatch');
      if (index == 1) return;
    } else {
      if (index == 0 || index == 1 || index == 2) {
        Navigator.pushReplacementNamed(context, '/customer');
      }
      if (index == 3) return;
    }
  }

  Widget _buildFloatingBottomNav(bool isDark, String role) {
    List<BottomNavigationBarItem> items = [];
    int currentIndex = 0;

    if (role == 'owner') {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'POS'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Queue'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
      currentIndex = 4;
    } else if (role == 'staff') {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Station POS'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
      currentIndex = 2;
    } else if (role == 'rider') {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Routes'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
      currentIndex = 1;
    } else {
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Order'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Payments'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
      currentIndex = 3;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.95) : AppColors.surfaceLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BottomNavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: currentIndex,
                      onTap: _onNavTapped,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: AppColors.outline,
                      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontSize: 11),
                      items: items,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = currentUserRoleNotifier.value;
    final userData = _getUserData(role);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      extendBody: true,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCustomerHeader(isDark),
                const SizedBox(height: 24),
                _buildProfileHero(userData, isDark),
                const SizedBox(height: 24),

                _buildSectionHeader('ACCOUNT', role == 'customer' ? '2 Items' : '1 Item', AppColors.outline),
                _buildCardGroup([
                  _buildListTile('Manage Profile', 'Edit Name, Email & Phone', Icons.person, AppColors.primary, isDark, onTap: () => _showEditProfileDialog(userData, isDark)),
                  _buildDivider(isDark),
                  _buildListTile('Saved Delivery Addresses', 'Primary residence & hub instructions', Icons.location_on, AppColors.primary, isDark, onTap: () => _showAddressesDialog(isDark)),
                ], isDark),
                const SizedBox(height: 24),

                _buildSectionHeader('PREFERENCES', 'Customized', AppColors.secondary),
                _buildCardGroup([
                  _buildListTile('Notification Settings', 'Push alerts, delivery windows & reminders', Icons.notifications_active, AppColors.primary, isDark, trailing: _buildCustomSwitch()),
                ], isDark),
                const SizedBox(height: 24),

                _buildSectionHeader('SECURITY', 'Protected', AppColors.tealAccent),
                _buildCardGroup([
                  _buildListTile('Change Password', 'Update secure credentials & 2FA', Icons.lock, AppColors.primary, isDark, onTap: () => _showPasswordDialog(isDark)),
                ], isDark),
                const SizedBox(height: 24),

                _buildSectionHeader('SUPPORT & POLICIES', '24/7 Available', AppColors.outline),
                _buildCardGroup([
                  _buildListTile('Help Center & FAQs', 'Hydration guide & dispatch assistance', Icons.support_agent, AppColors.primary, isDark, onTap: () => _showHelpCenterDialog(isDark)),
                  _buildDivider(isDark),
                  _buildListTile('Terms & Privacy', 'Policies, bottle deposits & sanitization', Icons.shield, AppColors.primary, isDark, onTap: () => _showTermsDialog(isDark)),
                ], isDark),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorContainer.withValues(alpha: 0.6),
                            foregroundColor: AppColors.error,
                            minimumSize: const Size(double.infinity, 52),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)))
                        ),
                        onPressed: () {
                          currentUserRoleNotifier.value = 'none';
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
                        label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      if (role == 'customer') ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _showDeleteAccountDialog(isDark),
                          icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.error),
                          label: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ]
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                const Text('Version 1.0.0 (Build 42)', style: TextStyle(color: AppColors.outline, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text('SAN ANTONIO REGIONAL HUB • PURE HYDRATION', style: TextStyle(color: AppColors.outlineVariant, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(isDark, role),
    );
  }

  Widget _buildCustomerHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.85) : AppColors.surfaceLowest.withValues(alpha: 0.85), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 1))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.cyanElectric]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))]), child: const Icon(Icons.water_drop, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Text('AQUAOPS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -0.5)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)), child: const Text('DRINK 8', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)))]),
                  const Text('Customer Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)),
                ],
              )
            ],
          ),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle), child: const Icon(Icons.notifications, color: AppColors.outline, size: 24)),
                  Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppColors.coralAlert, shape: BoxShape.circle), child: const Text('4', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              ),
              const SizedBox(width: 8),
              Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 18))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileHero(Map<String, String> userData, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? AppColors.surfaceContainer : AppColors.surfaceLowest, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Container(
              width: 96, height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.primary, AppColors.cyanElectric, AppColors.secondary]), boxShadow: [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.4), blurRadius: 28, offset: const Offset(0, 10))]),
              child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer])), child: Center(child: Text(userData['initials']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)))),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(userData['name']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.5)), const SizedBox(width: 6), const Icon(Icons.check_circle, size: 20, color: AppColors.secondary)]),
            const SizedBox(height: 4),
            Text(userData['email']!, style: const TextStyle(fontSize: 13, color: AppColors.textVariant)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.8), border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(userData['badge']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 0.5)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2)),
          Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor)),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: isDark ? AppColors.surfaceContainer : AppColors.surfaceLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceContainer), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, IconData icon, Color iconColor, bool isDark, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.surfaceFrost, AppColors.surfaceIce]), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cyanElectric.withValues(alpha: 0.2))), child: Icon(icon, color: iconColor, size: 22)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textVariant), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle), child: const Icon(Icons.chevron_right, size: 20, color: AppColors.outlineVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) => Divider(height: 1, color: AppColors.surfaceContainer.withValues(alpha: 0.5));

  Widget _buildCustomSwitch() {
    return GestureDetector(
      onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
      child: Container(
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), gradient: LinearGradient(colors: _notificationsEnabled ? [AppColors.primary, AppColors.cyanElectric] : [AppColors.surfaceCanvas, AppColors.surfaceCanvas]), boxShadow: _notificationsEnabled ? [BoxShadow(color: AppColors.cyanElectric.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))] : []),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: _notificationsEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: _notificationsEnabled ? const Icon(Icons.check, size: 14, color: AppColors.primary) : null,
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isMatch = false;
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _newPassController.addListener(_checkStrength);
    _confirmPassController.addListener(_validate);
  }

  @override
  void dispose() {
    _currPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _checkStrength() {
    final val = _newPassController.text;
    int s = 0;
    if (val.length >= 2) s = 1;
    if (val.length >= 6) s = 2;
    if (val.length >= 8) s = 3;
    if (val.length >= 8 && RegExp(r'[A-Z]').hasMatch(val) && RegExp(r'[0-9]').hasMatch(val)) s = 4;
    setState(() { _strength = s; });
    _validate();
  }

  void _validate() {
    setState(() {
      _isMatch = _newPassController.text.isNotEmpty && _newPassController.text == _confirmPassController.text && _newPassController.text.length >= 6;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canSubmit = _isMatch;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 6, width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer, AppColors.cyanElectric]), borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.security, color: AppColors.primary, size: 26)),
                        const SizedBox(width: 12),
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain, letterSpacing: -0.5)), Text('Update login credentials', style: TextStyle(fontSize: 12, color: AppColors.textVariant))])
                      ],
                    ),
                    InkWell(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle), child: const Icon(Icons.close, size: 20, color: AppColors.outline))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCompactInput('Current Password', Icons.lock, _currPassController, isDark, showForgot: true),
                const SizedBox(height: 16),
                _buildCompactInput('New Password', Icons.lock_open, _newPassController, isDark),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _strength >= 1 ? AppColors.coralAlert : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(width: 4),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _strength >= 2 ? (_strength >= 4 ? AppColors.secondary : AppColors.cyanElectric) : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(width: 4),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _strength >= 3 ? (_strength >= 4 ? AppColors.secondary : AppColors.primary) : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(width: 4),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _strength >= 4 ? AppColors.secondary : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4)))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCompactInput('Confirm Password', Icons.lock_outline, _confirmPassController, isDark),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: _isMatch ? AppColors.secondaryContainer.withValues(alpha: 0.3) : (_confirmPassController.text.isNotEmpty ? AppColors.errorContainer.withValues(alpha: 0.4) : AppColors.surfaceIce), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(_isMatch ? Icons.check_circle : (_confirmPassController.text.isNotEmpty ? Icons.error : Icons.info), size: 18, color: _isMatch ? AppColors.secondary : (_confirmPassController.text.isNotEmpty ? AppColors.error : AppColors.cyanElectric)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_isMatch ? 'Passwords match perfectly' : (_confirmPassController.text.isNotEmpty ? 'Passwords do not match yet' : 'At least 8 characters with letters and numbers'), style: const TextStyle(fontSize: 11, color: AppColors.textVariant))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: BorderSide.none, backgroundColor: AppColors.surfaceContainerLow, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))), child: const Text('Cancel', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 13)))),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), gradient: LinearGradient(colors: canSubmit ? [AppColors.primary, AppColors.cyanElectric] : [Colors.grey, Colors.grey.shade400]), boxShadow: canSubmit ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : []),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                          onPressed: canSubmit ? () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated smoothly!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.secondary, behavior: SnackBarBehavior.floating)); } : null,
                          icon: const Icon(Icons.verified, size: 18, color: Colors.white),
                          label: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(color: AppColors.surfaceIce, borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Icon(Icons.verified_user, size: 16, color: AppColors.secondary), SizedBox(width: 6), Text('END-TO-END ENCRYPTED SESSION', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
                Text('v2.4', style: TextStyle(fontSize: 11, color: AppColors.outline))
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompactInput(String hint, IconData icon, TextEditingController controller, bool isDark, {bool showForgot = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(hint, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textVariant)),
            if (showForgot) const Text('Forgot?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary))
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textMain),
          decoration: InputDecoration(
            hintText: 'Enter $hint',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.outlineVariant),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            suffixIcon: const Icon(Icons.visibility, size: 18, color: AppColors.outline),
            filled: true,
            fillColor: isDark ? AppColors.backgroundDark : AppColors.surfaceCanvas,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}