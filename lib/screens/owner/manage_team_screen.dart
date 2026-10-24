import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';
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
    String? nameError;
    String? emailError;
    String? passwordError;
    String? phoneError;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66283044),
      constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final password = passwordCtrl.text;
            final phone = phoneCtrl.text.trim();
            setSheetState(() {
              nameError = name.isEmpty ? 'Full name is required.' : null;
              emailError = Validators.validateEmail(
                email,
                requiredMessage: 'Email is required.',
                invalidMessage: 'Enter a valid email address.',
              );
              passwordError = Validators.validatePassword(
                password,
                minLength: 8,
                requiredMessage: 'Password is required.',
                minLengthMessage: 'Password must be at least 8 characters.',
              );
              phoneError = Validators.validateMobile(
                phone,
                requiredMessage: 'Phone number is required.',
              );
            });
            if (nameError != null || emailError != null || passwordError != null || phoneError != null) {
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
                        decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
                        child: const Icon(Icons.group_add, size: 20, color: AppColors.primarySky),
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
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isSaving ? null : () => Navigator.pop(sheetContext),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRoleOption(
                            label: 'Staff',
                            icon: Icons.point_of_sale,
                            selected: selectedRole == UserRole.staff,
                            selectedColor: AppColors.primarySky,
                            onTap: () => setSheetState(() => selectedRole = UserRole.staff),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildRoleOption(
                            label: 'Rider',
                            icon: Icons.two_wheeler,
                            selected: selectedRole == UserRole.rider,
                            selectedColor: AppColors.primarySky,
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
                              iconColor: AppColors.outline,
                              controller: nameCtrl,
                              hint: 'e.g. Maria Santos',
                              keyboardType: TextInputType.name,
                              errorText: nameError,
                              onChanged: () {
                                if (nameError != null) setSheetState(() => nameError = null);
                              },
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'EMAIL ADDRESS',
                              icon: Icons.mail_outline,
                              iconColor: AppColors.outline,
                              controller: emailCtrl,
                              hint: 'name@aquaops.com',
                              keyboardType: TextInputType.emailAddress,
                              errorText: emailError,
                              onChanged: () {
                                if (emailError != null) setSheetState(() => emailError = null);
                              },
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'TEMPORARY PASSWORD',
                              icon: Icons.key_outlined,
                              iconColor: AppColors.outline,
                              controller: passwordCtrl,
                              hint: 'Min. 8 characters',
                              obscure: true,
                              errorText: passwordError,
                              onChanged: () {
                                if (passwordError != null) setSheetState(() => passwordError = null);
                              },
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'PHONE NUMBER',
                              icon: Icons.call_outlined,
                              iconColor: AppColors.outline,
                              controller: phoneCtrl,
                              hint: '09000000000',
                              keyboardType: TextInputType.phone,
                              errorText: phoneError,
                              onChanged: () {
                                if (phoneError != null) setSheetState(() => phoneError = null);
                              },
                            ),
                            const SizedBox(height: 8),
                            _SheetField(
                              label: 'ASSIGNED AREA (DELIVERY ZONE)',
                              icon: Icons.explore_outlined,
                              iconColor: AppColors.primarySky,
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isSaving ? AppColors.primarySky.withValues(alpha: 0.7) : AppColors.primarySky,
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
            Icon(icon, size: 18, color: selected ? selectedColor : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 16 / 13,
                letterSpacing: 0.13,
                color: selected ? selectedColor : AppColors.textSecondary,
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
                            color: AppColors.errorContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.warning_amber_rounded, size: 32, color: AppColors.error),
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
                            color: AppColors.textLight,
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
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textLight),
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late_outlined, size: 18, color: AppColors.coralAlert),
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
                                    color: AppColors.textSecondary,
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
                                    backgroundColor: AppColors.surfaceContainerLow,
                                    foregroundColor: AppColors.textLight,
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
                                      color: AppColors.textLight,
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
                                  color: AppColors.error,
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

  Widget _buildHeader({String title = 'Back to Profile', Color backIconColor = AppColors.primarySky}) {
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
                          height: 24 / 17,
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

  Widget _buildTitleBlock() {
    return Column(
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
              Icon(Icons.badge, size: 13, color: AppColors.primarySky),
              SizedBox(width: 6),
              Text(
                'AQUA LOGISTICS WORKFORCE',
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
          'Team Directory',
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
          'Manage active station staff, delivery couriers and assigned zones',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 18 / 13,
            color: AppColors.textSecondary,
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
                                color: AppColors.surfaceFrost,
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
                                color: AppColors.primarySky,
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
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryContainer,
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          member.role.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: _font,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: AppColors.onSecondaryContainer,
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
                                        decoration: const BoxDecoration(color: AppColors.primarySky, shape: BoxShape.circle),
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
                                            color: AppColors.primarySky,
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
                        decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(16)),
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
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(isRider ? Icons.explore_outlined : Icons.storefront_outlined, size: 15, color: AppColors.primarySky),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    contact,
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
                      color: AppColors.primarySky,
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

  Widget _buildAddButton() {
    return _buildPrimaryActionButton(
      icon: Icons.person_add_alt_1,
      label: 'Add Team Member',
      onTap: _showAddMemberDialog,
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
                color: AppColors.textSecondary,
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
      backgroundColor: AppColors.surfaceBackground,
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
  final String? errorText;
  final VoidCallback? onChanged;

  const _SheetField({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.errorText,
    this.onChanged,
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
    final bool hasError = widget.errorText != null;
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
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _focused ? AppColors.surfaceFrost : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: hasError ? Border.all(color: AppColors.error, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: hasError ? AppColors.error : widget.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscure,
                  onChanged: (_) => widget.onChanged?.call(),
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.outline,
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
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.error),
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
            color: _hovered ? AppColors.errorContainer.withValues(alpha: 0.4) : Colors.transparent,
          ),
          child: Icon(
            Icons.delete_outline,
            size: 19,
            color: _hovered ? AppColors.error : AppColors.slate400,
          ),
        ),
      ),
    );
  }
}