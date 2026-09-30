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

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    UserRole selectedRole = UserRole.staff;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Team Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(value: UserRole.staff, label: Text('Staff'), icon: Icon(Icons.point_of_sale, size: 16)),
                    ButtonSegment(value: UserRole.rider, label: Text('Rider'), icon: Icon(Icons.two_wheeler, size: 16)),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (selection) => setDialogState(() => selectedRole = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextFormField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextFormField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary Password (min 8 chars)')),
                const SizedBox(height: 12),
                TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Phone')),
                if (selectedRole == UserRole.rider) ...[
                  const SizedBox(height: 12),
                  TextFormField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Assigned Area (e.g. Zone A)')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final password = passwordCtrl.text;
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty || email.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      if (password.length < 8) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 8 characters.'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _authService.createTeamAccount(
                          name: name,
                          email: email,
                          password: password,
                          phone: phone,
                          role: selectedRole,
                          assignedArea: selectedRole == UserRole.rider && areaCtrl.text.trim().isNotEmpty ? areaCtrl.text.trim() : null,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(SnackBar(content: Text('$name added as ${selectedRole.name}.'), backgroundColor: AppColors.primaryLight));
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(SnackBar(content: Text('Failed to create account: $e'), backgroundColor: AppColors.error));
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Team'),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        foregroundColor: isDark ? Colors.white : AppColors.textLight,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
        backgroundColor: AppColors.primaryLight,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: StreamBuilder<List<UserModel>>(
            stream: _firestoreService.getTeamMembersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data!;
              if (members.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No staff or rider accounts yet. Tap "Add Member" to create one.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isRider = member.role == UserRole.rider;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isRider ? AppColors.cyanElectric.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.15),
                          child: Icon(isRider ? Icons.two_wheeler : Icons.point_of_sale, color: isRider ? AppColors.cyanElectric : AppColors.primaryLight, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textLight)),
                              Text(member.email, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                              if (isRider && (member.assignedArea ?? '').isNotEmpty)
                                Text('Area: ${member.assignedArea}', style: const TextStyle(fontSize: 11, color: AppColors.cyanElectric, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: isRider ? AppColors.cyanElectric.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
                          child: Text(member.role.name.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isRider ? AppColors.cyanElectric : AppColors.primaryLight)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: () => _confirmRemoveMember(member),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
