import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ManageTeamScreen extends StatefulWidget {
  const ManageTeamScreen({super.key});

  @override
  State<ManageTeamScreen> createState() => _ManageTeamScreenState();
}

class _ManageTeamScreenState extends State<ManageTeamScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  static const String _font = 'Plus Jakarta Sans';
  static const Color _background = Color(0xFFF6FAFC);
  static const Color _canvas = Color(0xFFF8FAFC);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _outline = Color(0xFF707881);
  static const Color _primary = Color(0xFF006194);
  static const Color _frost = Color(0xFFE0F2FE);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _blue = Color(0xFF0284C7);
  static const Color _fieldBg = Color(0xFFF2F3FF);
  static const Color _container = Color(0xFFEAEDFF);
  static const double _maxWidth = 450;
  static const double _sidePadding = 20;

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
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                          decoration: const BoxDecoration(color: _frost, shape: BoxShape.circle),
                          child: const Icon(Icons.group_add, size: 20, color: _primary),
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
                              selectedColor: _primary,
                              onTap: () => setSheetState(() => selectedRole = UserRole.staff),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildRoleOption(
                              label: 'Rider',
                              icon: Icons.two_wheeler,
                              selected: selectedRole == UserRole.rider,
                              selectedColor: _cyan,
                              onTap: () => setSheetState(() => selectedRole = UserRole.rider),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSheetField(
                      label: 'FULL NAME',
                      icon: Icons.badge_outlined,
                      iconColor: _outline,
                      controller: nameCtrl,
                      hint: 'e.g. Maria Santos',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 8),
                    _buildSheetField(
                      label: 'EMAIL ADDRESS',
                      icon: Icons.mail_outline,
                      iconColor: _outline,
                      controller: emailCtrl,
                      hint: 'name@aquaops.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    _buildSheetField(
                      label: 'TEMPORARY PASSWORD',
                      icon: Icons.key_outlined,
                      iconColor: _outline,
                      controller: passwordCtrl,
                      hint: 'Min. 8 characters',
                      obscure: true,
                    ),
                    const SizedBox(height: 8),
                    _buildSheetField(
                      label: 'PHONE NUMBER',
                      icon: Icons.call_outlined,
                      iconColor: _outline,
                      controller: phoneCtrl,
                      hint: '+63 900 000 0000',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    Visibility(
                      visible: selectedRole == UserRole.rider,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: _buildSheetField(
                        label: 'ASSIGNED AREA (DELIVERY ZONE)',
                        icon: Icons.explore_outlined,
                        iconColor: _cyan,
                        controller: areaCtrl,
                        hint: 'e.g. Barangay San Antonio (Zone A)',
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

  Widget _buildSheetField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
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

  void _confirmRemoveMember(UserModel member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Team Member'),
        content: Text('Remove ${member.name} (${member.role.name}) from the team? This only removes their AquaOps profile — do this along with disabling their login if needed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.deleteUserProfile(member.id);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Remove'),
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
              Icon(Icons.badge, size: 13, color: _primary),
              SizedBox(width: 6),
              Text(
                'AQUA LOGISTICS WORKFORCE',
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
    final String contact = phone.isEmpty ? member.email : '$phone • ${member.email}';
    final String headline = isRider ? (area.isEmpty ? 'No delivery zone assigned yet' : area) : 'Station Operations Team';
    final String subtitle = isRider ? 'Delivery Courier' : 'Station Staff Member';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
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
                          color: _container,
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
                          color: _onSurfaceVariant,
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
                                  decoration: const BoxDecoration(color: _cyan, shape: BoxShape.circle),
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
                                      color: _cyan,
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
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
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
                            Icon(isRider ? Icons.explore_outlined : Icons.storefront_outlined, size: 15, color: _cyan),
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
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(9999)),
                ),
              ),
            ),
          ],
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
      body: SafeArea(
        bottom: false,
        child: Column(
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
                      padding: EdgeInsets.fromLTRB(_sidePadding, 8, _sidePadding, 24 + bottomInset),
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
      ),
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
            color: _hovered ? const Color(0xFFFFDAD6).withValues(alpha: 0.4) : Colors.transparent,
          ),
          child: Icon(
            Icons.delete_outline,
            size: 19,
            color: _hovered
                ? const Color(0xFFBA1A1A)
                : const Color(0xFF3F4850).withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}