import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
                    SnackBar(content: Text('Failed to save branch: $e'), backgroundColor: AppColors.coralAlert),
                  );
                }
              }
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Standard 800px width
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              existing == null ? 'Add Branch' : 'Edit Branch',
                              style: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: AppColors.slate500),
                              onPressed: saving ? null : () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _field('Branch Name', nameCtrl, error: nameError),
                        const SizedBox(height: 12),
                        _field('Address', addressCtrl, error: addressError, maxLines: 2),
                        const SizedBox(height: 12),
                        _field('Phone Number (Optional)', phoneCtrl),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: saving ? null : save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarySky,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: saving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(existing == null ? 'Add Branch' : 'Save Changes',
                                style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceCanvas,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primarySky)),
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
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Branch?', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${branch.name}" from station locations?', style: const TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _firestoreService.deleteBranch(branch.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAlert, foregroundColor: Colors.white),
            child: const Text('Confirm Remove'),
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
                'Manage Branches',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Refilling station branch locations',
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
              _header(topInset),
              Expanded(
                child: StreamBuilder<List<BranchModel>>(
                  stream: _firestoreService.getBranchesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final branches = snapshot.data!;
                    if (branches.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                              child: const Icon(Icons.store_outlined, size: 28, color: AppColors.primarySky),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Branches Added Yet',
                              style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This station is currently operating as a single main location. Add branches to prepare for multi-location operations.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 80 + bottomInset),
                      itemCount: branches.length,
                      itemBuilder: (context, i) {
                        final b = branches[i];
                        return Container(
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
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                child: const Icon(Icons.store, color: AppColors.primarySky, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                    const SizedBox(height: 2),
                                    Text(b.address, style: const TextStyle(fontFamily: _font, fontSize: 12, color: AppColors.textSecondary)),
                                    if (b.phone != null && b.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(b.phone!, style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.slate400)),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slate500),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBranchSheet(),
        backgroundColor: AppColors.primarySky,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Branch', style: TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}