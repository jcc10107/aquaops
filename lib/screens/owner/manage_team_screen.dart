import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';

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
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
              messenger.showSnackBar(SnackBar(content: Text('$name added as ${selectedRole.name}.'), backgroundColor: AppColors.primarySky));
            } catch (e) {
              if (!sheetContext.mounted) return;
              setSheetState(() {
                isSaving = false;
                errorText = 'Failed to create account: $e';
              });
            }
          }

          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                            child: const Icon(Icons.person_add_alt_1, size: 20, color: AppColors.primarySky),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Add Team Member',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: AppColors.slate500),
                            onPressed: isSaving ? null : () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Select Role',
                        style: TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.surfaceCanvas, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRoleOption(
                                label: 'Staff Member',
                                icon: Icons.point_of_sale,
                                selected: selectedRole == UserRole.staff,
                                onTap: () => setSheetState(() => selectedRole = UserRole.staff),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildRoleOption(
                                label: 'Dispatch Rider',
                                icon: Icons.two_wheeler,
                                selected: selectedRole == UserRole.rider,
                                onTap: () => setSheetState(() => selectedRole = UserRole.rider),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SheetField(
                        label: 'FULL NAME',
                        icon: Icons.badge_outlined,
                        controller: nameCtrl,
                        hint: 'e.g. Maria Santos',
                        keyboardType: TextInputType.name,
                        errorText: nameError,
                        onChanged: () {
                          if (nameError != null) setSheetState(() => nameError = null);
                        },
                      ),
                      const SizedBox(height: 10),
                      _SheetField(
                        label: 'EMAIL ADDRESS',
                        icon: Icons.mail_outline,
                        controller: emailCtrl,
                        hint: 'name@aquaops.com',
                        keyboardType: TextInputType.emailAddress,
                        errorText: emailError,
                        onChanged: () {
                          if (emailError != null) setSheetState(() => emailError = null);
                        },
                      ),
                      const SizedBox(height: 10),
                      _SheetField(
                        label: 'TEMPORARY PASSWORD',
                        icon: Icons.key_outlined,
                        controller: passwordCtrl,
                        hint: 'Min. 8 characters',
                        obscure: true,
                        errorText: passwordError,
                        onChanged: () {
                          if (passwordError != null) setSheetState(() => passwordError = null);
                        },
                      ),
                      const SizedBox(height: 10),
                      _SheetField(
                        label: 'PHONE NUMBER',
                        icon: Icons.call_outlined,
                        controller: phoneCtrl,
                        hint: '09000000000',
                        keyboardType: TextInputType.phone,
                        errorText: phoneError,
                        onChanged: () {
                          if (phoneError != null) setSheetState(() => phoneError = null);
                        },
                      ),
                      if (selectedRole == UserRole.rider) ...[
                        const SizedBox(height: 10),
                        _SheetField(
                          label: 'ASSIGNED AREA (DELIVERY ZONE)',
                          icon: Icons.explore_outlined,
                          controller: areaCtrl,
                          hint: 'e.g. Barangay San Antonio (Zone A)',
                        ),
                      ],
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.coralAlert),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(sheetContext),
                            child: const Text('Cancel', style: TextStyle(fontFamily: _font, color: AppColors.slate600)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySky,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Create Account', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildRoleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppColors.slate200) : null,
          boxShadow: selected ? const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.primarySky : AppColors.slate500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primarySky : AppColors.slate600,
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
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCanvas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Remove Team Member', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold)),
              content: Text(
                'Are you sure you want to remove ${member.name} from the station workforce? Their login access will be revoked.',
                style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(onPressed: isDeleting ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setDialogState(() => isDeleting = true);
                    setState(() => _removingIds.add(member.id));
                    Navigator.pop(dialogContext);
                    try {
                      await _firestoreService.deleteUserProfile(member.id);
                      messenger.showSnackBar(SnackBar(content: Text('Removed ${member.name}.')));
                    } catch (e) {
                      if (mounted) setState(() => _removingIds.remove(member.id));
                      messenger.showSnackBar(SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.coralAlert));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAlert, foregroundColor: Colors.white),
                  child: const Text('Confirm Remove'),
                ),
              ],
            );
          },
        );
      },
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
                'Team Directory',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Staff and rider account management',
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

  Widget _buildMemberCard(UserModel member) {
    final bool isRider = member.role == UserRole.rider;
    final String area = (member.assignedArea ?? '').trim();
    final String phone = member.phone.trim();
    final String headline = isRider ? (area.isEmpty ? 'No delivery zone assigned' : area) : 'Station Operations Team';
    final bool removing = _removingIds.contains(member.id);

    return AnimatedOpacity(
      opacity: removing ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: Color(0xFFF0F9FF), shape: BoxShape.circle),
              child: Icon(isRider ? Icons.two_wheeler : Icons.point_of_sale, size: 20, color: AppColors.primarySky),
            ),
            const SizedBox(width: 12),
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRider ? const Color(0xFFE0F2FE) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          member.role.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isRider ? const Color(0xFF0369A1) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    headline,
                    style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone.isEmpty ? member.email : '$phone • ${member.email}',
                    style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.slate400),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.coralAlert),
              onPressed: () => _confirmRemoveMember(member),
            ),
          ],
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
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final members = snapshot.data!;
        if (members.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Center(
              child: Text(
                'No staff or rider accounts found in system.',
                style: TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Column(
          children: members.map((m) => _buildMemberCard(m)).toList(),
        );
      },
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
                      _buildMemberList(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _showAddMemberDialog,
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Add Team Member', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final String? errorText;
  final VoidCallback? onChanged;

  const _SheetField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          onChanged: (_) => onChanged?.call(),
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.slate400),
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.slate400),
            filled: true,
            fillColor: AppColors.surfaceCanvas,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primarySky)),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}