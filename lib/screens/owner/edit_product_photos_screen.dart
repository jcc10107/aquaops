import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/editor_text_field.dart';
import '../../widgets/product_illustration.dart';

const String _font = 'Plus Jakarta Sans';

class EditProductPhotosScreen extends StatefulWidget {
  const EditProductPhotosScreen({super.key});

  @override
  State<EditProductPhotosScreen> createState() => _EditProductPhotosScreenState();
}

class _EditProductPhotosScreenState extends State<EditProductPhotosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  // Which product id is currently mid-upload — only that one card shows a
  // spinner, the rest of the list stays interactive.
  String? _uploadingId;

  @override
  void initState() {
    super.initState();
    // No-op once the products collection has anything in it — see
    // FirestoreService.seedDefaultProductsIfEmpty for why this exists.
    _firestoreService.seedDefaultProductsIfEmpty();
  }

  Future<void> _pickAndUpload(String productId) async {
    if (_uploadingId != null) return;
    setState(() => _uploadingId = productId);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final shot = await _picker
          .pickImage(source: ImageSource.gallery, imageQuality: 85)
          .timeout(const Duration(seconds: 20));

      if (shot == null) {
        if (!mounted) return;
        setState(() => _uploadingId = null);
        return;
      }

      final bytes = await shot.readAsBytes().timeout(const Duration(seconds: 20));
      final url = await _cloudinary
          .uploadImage(bytes, filename: '$productId.jpg', folder: 'product_photos')
          .timeout(const Duration(seconds: 30));

      await _firestoreService.setProductImage(productId, url);

      if (!mounted) return;
      setState(() => _uploadingId = null);
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingId = null);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppColors.coralAlert),
      );
    }
  }

  Future<void> _showProductDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
      text: existing == null ? '' : (existing['price'] as double).toStringAsFixed(2),
    );
    final typeCtrl = TextEditingController(text: existing?['type'] as String? ?? '');
    String? nameError;
    String? priceError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                          child: Icon(
                            existing == null ? Icons.add_box_outlined : Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primarySky,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          existing == null ? 'Add Product' : 'Edit Product',
                          style: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    EditorTextField(
                      label: 'Product Name',
                      controller: nameCtrl,
                      hintText: 'e.g. Slim Refill',
                      errorText: nameError,
                      onChanged: () {
                        if (nameError != null) setDialogState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: 14),
                    EditorTextField(
                      label: 'Price (₱)',
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hintText: 'e.g. 35.00',
                      errorText: priceError,
                      onChanged: () {
                        if (priceError != null) setDialogState(() => priceError = null);
                      },
                    ),
                    const SizedBox(height: 14),
                    EditorTextField(
                      label: 'Description',
                      controller: typeCtrl,
                      hintText: 'e.g. Refill exchange • Cap sanitized',
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.slate200),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                final price = double.tryParse(priceCtrl.text.trim());
                                final bool validPrice = price != null && price > 0;
                                setDialogState(() {
                                  nameError = name.isEmpty ? 'Name is required.' : null;
                                  priceError = validPrice ? null : 'Enter a price greater than ₱0.';
                                });
                                if (name.isEmpty || !validPrice) return;

                                try {
                                  if (existing == null) {
                                    await _firestoreService.addProduct(name: name, price: price, type: typeCtrl.text.trim());
                                  } else {
                                    await _firestoreService.updateProduct(
                                      existing['id'] as String,
                                      name: name,
                                      price: price,
                                      type: typeCtrl.text.trim(),
                                    );
                                  }
                                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                                      SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.coralAlert),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySky,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              ),
                              child: const Text('Save', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
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

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Product added.' : 'Product updated.')),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Product?', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
        content: Text(
          'This removes "${product['name']}" from the customer store. This cannot be undone.',
          style: const TextStyle(fontFamily: _font),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralAlert, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteProduct(product['id'] as String);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product removed.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.coralAlert),
          );
        }
      }
    }
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
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Products',
                  style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                SizedBox(height: 2),
                Text(
                  'Photos, prices & catalog shown to customers',
                  style: TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.primarySky,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showProductDialog(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product, String? imageUrl) {
    final String id = product['id'] as String;
    final bool isUploading = _uploadingId == id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppColors.surfaceIce,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ProductIllustration(productId: id),
                      )
                    : ProductIllustration(productId: id),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['type'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: _font, fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${(product['price'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primarySky),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _showProductDialog(existing: product),
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.slate500),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => _confirmDelete(product),
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.coralAlert),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : () => _pickAndUpload(id),
              icon: isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                    )
                  : const Icon(Icons.upload_file_outlined, size: 16, color: AppColors.primarySky),
              label: Text(
                imageUrl != null ? 'Replace Photo' : 'Upload Photo',
                style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primarySky),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.primarySky),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
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
      backgroundColor: AppColors.surfaceCanvas,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _header(topInset),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getProductsStream(),
                  builder: (context, productsSnapshot) {
                    final products = productsSnapshot.data ?? const <Map<String, dynamic>>[];
                    return StreamBuilder<Map<String, String>>(
                      stream: _firestoreService.getProductImagesStream(),
                      builder: (context, imagesSnapshot) {
                        final images = imagesSnapshot.data ?? const <String, String>{};
                        if (products.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No products yet. Tap + above to add your first one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: _font, color: AppColors.textSecondary),
                              ),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                          child: Column(
                            children: [
                              for (final product in products) ...[
                                _productCard(product, images[product['id']]),
                                const SizedBox(height: 12),
                              ],
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
    );
  }
}
