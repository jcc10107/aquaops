import 'package:flutter/material.dart';
import '../../models/branch_model.dart';
import '../../services/firestore_service.dart';

const String _font = 'Plus Jakarta Sans';
const Color _background = Color(0xFFF6FAFC);
const Color _onSurface = Color(0xFF131B2E);
const Color _onSurfaceVariant = Color(0xFF3F4850);
const Color _blue = Color(0xFF0284C7);
const Color _fieldBg = Color(0xFFF2F3FF);
const Color _coral = Color(0xFFF43F5E);
const double _maxWidth = 450;

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
                constraints: const BoxConstraints(maxWidth: _maxWidth),
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
                          style: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _onSurface),
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
                              backgroundColor: _blue,
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
        Text(label, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: _font, fontSize: 13, color: _onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fieldBg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _coral)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _coral, width: 1.5)),
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
            child: const Text('Remove', style: TextStyle(color: _coral)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(color: _onSurface),
        title: const Text('Manage Branches', style: TextStyle(fontFamily: _font, color: _onSurface, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBranchSheet(),
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Branch', style: TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: StreamBuilder<List<BranchModel>>(
              stream: _firestoreService.getBranchesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.only(top: 48), child: CircularProgressIndicator()));
                }
                final branches = snapshot.data!;
                if (branches.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, size: 48, color: _onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text(
                          'No branches added yet. This station is currently treated as the only location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: _font, fontSize: 13, color: _onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Adding a branch here is groundwork for future expansion — it does not yet split inventory, staff, or orders by location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: _font, fontSize: 11, color: _onSurfaceVariant),
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                            child: const Icon(Icons.store, color: _blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name, style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, color: _onSurface)),
                                Text(b.address, style: const TextStyle(fontFamily: _font, fontSize: 12, color: _onSurfaceVariant)),
                                if (b.phone != null && b.phone!.isNotEmpty)
                                  Text(b.phone!, style: const TextStyle(fontFamily: _font, fontSize: 11, color: _onSurfaceVariant)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: _onSurfaceVariant),
                            onPressed: () => _openBranchSheet(existing: b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: _coral),
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
