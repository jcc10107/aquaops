import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
import '../../models/branch_model.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';

class ManageBranchesScreen extends StatefulWidget {
  const ManageBranchesScreen({super.key});

  @override
  State<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends State<ManageBranchesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _openBranchSheet({BranchModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    String? nameError;
    String? addressError;
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final name = nameCtrl.text.trim();
              final address = addressCtrl.text.trim();
              setSheetState(() {
                nameError = name.isEmpty ? 'Branch name is required.' : null;
                addressError = address.isEmpty ? 'Address is required.' : null;
              });
              if (nameError != null || addressError != null) return;
              setSheetState(() => saving = true);
              try {
                if (existing == null) {
                  await _firestoreService.addBranch(
                    name: name,
                    address: address,
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  );
                } else {
                  await _firestoreService.updateBranch(
                    branchId: existing.id,
                    name: name,
                    address: address,
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  );
                }
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              } catch (e) {
                setSheetState(() => saving = false);
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text('Failed to save branch: $e')),
                  );
                }
              }
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          existing == null ? 'Add Branch' : 'Edit Branch',
                          style: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 16),
                        _field('Branch Name', nameCtrl, error: nameError),
                        const SizedBox(height: 12),
                        _field('Address', addressCtrl, error: addressError, maxLines: 2),
                        const SizedBox(height: 12),
                        _field('Phone (optional)', phoneCtrl),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving ? null : save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySky,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(existing == null ? 'Add Branch' : 'Save Changes',
                                style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
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

  Widget _field(String label, TextEditingController controller, {String? error, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.coralAlert)),
            focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.coralAlert, width: 1.5)),
            errorText: error,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BranchModel branch) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Branch?'),
        content: Text('This will remove "${branch.name}" from the branch list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _firestoreService.deleteBranch(branch.id);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.coralAlert)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textLight),
        title: const Text('Manage Branches', style: TextStyle(fontFamily: _font, color: AppColors.textLight, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBranchSheet(),
        backgroundColor: AppColors.primarySky,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Branch', style: TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: StreamBuilder<List<BranchModel>>(
              stream: _firestoreService.getBranchesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.only(top: 48), child: CircularProgressIndicator()));
                }
                final branches = snapshot.data!;
                if (branches.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      children: [
                        Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'No branches added yet. This station is currently treated as the only location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Adding a branch here is groundwork for future expansion — it does not yet split inventory, staff, or orders by location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = branches[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: AppColors.surfaceFrost, shape: BoxShape.circle),
                            child: const Icon(Icons.store, color: AppColors.primarySky, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                                Text(b.address, style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
                                if (b.phone != null && b.phone!.isNotEmpty)
                                  Text(b.phone!, style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                            onPressed: () => _openBranchSheet(existing: b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.coralAlert),
                            onPressed: () => _confirmDelete(b),
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
      ),
    );
  }
}