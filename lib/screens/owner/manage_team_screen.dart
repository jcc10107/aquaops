import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';
const Color _background = Color(0xFFF6FAFC);
const Color _canvas = Color(0xFFF8FAFC);
const Color _onSurface = Color(0xFF131B2E);
const Color _onSurfaceVariant = Color(0xFF3F4850);
const Color _outline = Color(0xFF707881);
const Color _frost = Color(0xFFE0F2FE);
const Color _blue = Color(0xFF0284C7);
const Color _fieldBg = Color(0xFFF2F3FF);
const Color _container = Color(0xFFEAEDFF);
const Color _errorRed = Color(0xFFBA1A1A);
const Color _errorContainer = Color(0xFFFFDAD6);
const Color _coral = Color(0xFFF43F5E);
const double _maxWidth = 450;
const double _sidePadding = 16;

class ManageTeamScreen extends StatefulWidget {
  const ManageTeamScreen({super.key});

  @override
  State<ManageTeamScreen> createState() => _ManageTeamScreenState();
}

class _ManageTeamScreenState extends State<ManageTeamScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final Set<String> _removingIds = <String>{};

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    UserRole selectedRole = UserRole.staff;
    bool isSaving = false;
    String? errorText;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66283044),
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final password = passwordCtrl.text;
            final phone = phoneCtrl.text.trim();
            if (name.isEmpty || email.isEmpty || phone.isEmpty) {
              setSheetState(() => errorText = 'Please fill in all required fields.');
              return;
            }
            if (password.length < 8) {
              setSheetState(() => errorText = 'Password must be at least 8 characters.');
              return;
            }
            setSheetState(() {
              errorText = null;
              isSaving = true;
            });
            try {
              await _authService.createTeamAccount(
                name: name,
                email: email,
                password: password,
                phone: phone,
                role: selectedRole,
                assignedArea: selectedRole == UserRole.rider && areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : null,
              );
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              messenger.showSnackBar(SnackBar(content: Text('$name added as ${selectedRole.name}.'), backgroundColor: AppColors.primaryLight));
            } catch (e) {
              if (!sheetContext.mounted) return;
              setSheetState(() {
                isSaving = false;
                errorText = 'Failed to create account: $e';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(sheetContext).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: _frost, shape: BoxShape.circle),
                        child: const Icon(Icons.group_add, size: 20, color: _blue),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Add Team Member',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 28 / 22,
                            letterSpacing: -0.44,
                            color: _onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isSaving ? null : () => Navigator.pop(sheetContext),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: _container, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 18, color: _onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select Role',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 14 / 11,
                      letterSpacing: 0.22,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRoleOption(
                            label: 'Staff',
                            icon: Icons.point_of_sale,
                            selected: selectedRole == UserRole.staff,
                            selectedColor: _blue,
                            onTap: () => setSheetState(() => selectedRole = UserRole.staff),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildRoleOption(
                            label: 'Rider',
                            icon: Icons.two_wheeler,
                            selected: selectedRole == UserRole.rider,
                            selectedColor: _blue,
                            onTap: () => setSheetState(() => selectedRole = UserRole.rider),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 442),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SheetField(
                              label: 'FULL NAME',
                              icon: Icons.badge_outlined,
                              iconColor: _outline,
                              controller: nameCtrl,
                              hint: 'e.g. Maria Santos',
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'EMAIL ADDRESS',
                              icon: Icons.mail_outline,
                              iconColor: _outline,
                              controller: emailCtrl,
                              hint: 'name@aquaops.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'TEMPORARY PASSWORD',
                              icon: Icons.key_outlined,
                              iconColor: _outline,
                              controller: passwordCtrl,
                              hint: 'Min. 8 characters',
                              obscure: true,
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'PHONE NUMBER',
                              icon: Icons.call_outlined,
                              iconColor: _outline,
                              controller: phoneCtrl,
                              hint: '+63 900 000 0000',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'ASSIGNED AREA (DELIVERY ZONE)',
                              icon: Icons.explore_outlined,
                              iconColor: _blue,
                              controller: areaCtrl,
                              hint: 'e.g. Barangay San Antonio (Zone A)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(9999),
                        onTap: isSaving ? null : () => Navigator.pop(sheetContext),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 16 / 13,
                              letterSpacing: 0.13,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isSaving ? _blue.withValues(alpha: 0.7) : _blue,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9999),
                            onTap: isSaving ? null : submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: isSaving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 16 / 13,
                                  letterSpacing: 0.13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? selectedColor : _onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 16 / 13,
                letterSpacing: 0.13,
                color: selected ? selectedColor : _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(UserModel member) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x66283044),
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.95, end: 1),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _errorContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.warning_amber_rounded, size: 32, color: _errorRed),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Remove Team Member',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 28 / 22,
                            letterSpacing: -0.44,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Are you sure you want to remove '),
                                TextSpan(
                                  text: member.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: _onSurface),
                                ),
                                const TextSpan(
                                  text: ' from the station workforce? This action will revoke their login access and unassign their active shifts.',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.625,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late_outlined, size: 18, color: _coral),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'ACTIVE SHIFTS & LOGIN WILL BE REVOKED',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    height: 12 / 10,
                                    letterSpacing: 0.6,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: TextButton(
                                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _fieldBg,
                                    foregroundColor: _onSurface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: _font,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 16 / 13,
                                      letterSpacing: 0.13,
                                      color: _onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _errorRed,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(9999),
                                    onTap: isDeleting
                                        ? null
                                        : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      setDialogState(() => isDeleting = true);
                                      await Future.delayed(const Duration(milliseconds: 500));
                                      if (!mounted || !dialogContext.mounted) return;
                                      setState(() => _removingIds.add(member.id));
                                      Navigator.pop(dialogContext);
                                      try {
                                        await _firestoreService.deleteUserProfile(member.id);
                                      } catch (e) {
                                        if (mounted) setState(() => _removingIds.remove(member.id));
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    },
                                    child: Center(
                                      child: isDeleting
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                          : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'Remove',
                                            style: TextStyle(
                                              fontFamily: _font,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              height: 16 / 13,
                                              letterSpacing: 0.13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
              ),
            );
          },
        );
      },
    );
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
            constraints: const BoxConstraints(maxWidth: _maxWidth),
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
                        child: Icon(Icons.arrow_back, size: 24, color: _blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Back to Profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 24 / 17,
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

  Widget _buildTitleBlock() {
    return Column(
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
              Icon(Icons.badge, size: 13, color: _blue),
              SizedBox(width: 6),
              Text(
                'AQUA LOGISTICS WORKFORCE',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Team Directory',
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
          'Manage active station staff, delivery couriers and assigned zones',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 18 / 13,
            color: _onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(UserModel member) {
    final bool isRider = member.role == UserRole.rider;
    final String area = (member.assignedArea ?? '').trim();
    final String phone = member.phone.trim();
    final String contact = phone.isEmpty ? member.email : '$phone\n${member.email}';
    final String headline = isRider ? (area.isEmpty ? 'No delivery zone assigned yet' : area) : 'Station Operations Team';
    final String subtitle = isRider ? 'Delivery Courier' : 'Station Staff Member';
    final bool removing = _removingIds.contains(member.id);

    return AnimatedOpacity(
      opacity: removing ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: AnimatedScale(
        scale: removing ? 0.95 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _frost,
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
                                isRider ? Icons.two_wheeler : Icons.point_of_sale,
                                size: 20,
                                color: _blue,
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
                                          member.name,
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
                                          color: const Color(0xFF6CF8BB),
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          member.role.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: _font,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: Color(0xFF00714D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: _font,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            _HoverDeleteButton(
                              onTap: () => _confirmRemoveMember(member),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _canvas, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headline,
                              style: const TextStyle(
                                fontFamily: _font,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: _onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(isRider ? Icons.explore_outlined : Icons.storefront_outlined, size: 15, color: _blue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    contact,
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
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(9999)),
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

  Widget _buildAddButton() {
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
          onTap: _showAddMemberDialog,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Team Member',
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

  Widget _buildMemberList() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getTeamMembersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final members = snapshot.data!;
        if (members.isEmpty) {
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
              'No staff or rider accounts yet. Tap "Add Team Member" to create one.',
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
            for (int i = 0; i < members.length; i++) ...[
              _buildMemberCard(members[i]),
              if (i != members.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _background,
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
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(_sidePadding, 4, _sidePadding, 32 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleBlock(),
                        const SizedBox(height: 16),
                        _buildMemberList(),
                        const SizedBox(height: 20),
                        _buildAddButton(),
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

class _SheetField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;

  const _SheetField({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
  });

  @override
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 12 / 10,
            letterSpacing: 0.6,
            color: _onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _focused ? _frost : _fieldBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: widget.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscure,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _outline,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoverDeleteButton extends StatefulWidget {
  final VoidCallback onTap;

  const _HoverDeleteButton({required this.onTap});

  @override
  State<_HoverDeleteButton> createState() => _HoverDeleteButtonState();
}

class _HoverDeleteButtonState extends State<_HoverDeleteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered ? _errorContainer.withValues(alpha: 0.4) : Colors.transparent,
          ),
          child: Icon(
            Icons.delete_outline,
            size: 19,
            color: _hovered ? _errorRed : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}