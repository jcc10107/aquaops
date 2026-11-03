import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/validators.dart';
import '../../models/order_model.dart';
import '../../services/cloudinary_service.dart';

class CustomerRefundRequestScreen extends StatefulWidget {
  final OrderModel order;
  final Future<void> Function(
      String reason,
      String description,
      String gcashName,
      String gcashNumber,
      String? photoUrl,
      )? onSubmit;

  const CustomerRefundRequestScreen({
    super.key,
    required this.order,
    this.onSubmit,
  });

  @override
  State<CustomerRefundRequestScreen> createState() =>
      _CustomerRefundRequestScreenState();
}

class _GcashNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var digits = Validators.sanitizePhone(newValue.text);
    if (digits.length > 11) digits = digits.substring(0, 11);
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CustomerRefundRequestScreenState
    extends State<CustomerRefundRequestScreen> {
  static const double _headerHeight = 64;
  static const int _minChars = 20;

  static const List<String> _reasons = [
    'Damaged Product',
    'Wrong Item Received',
    'Missing Items',
    'Defective Product',
    'Order Not Received',
    'Poor Product Quality',
    'Other',
  ];

  final TextEditingController _customCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _numberCtrl = TextEditingController();
  final FocusNode _customFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _numberFocus = FocusNode();

  String _selectedReason = 'Damaged Product';
  Uint8List? _photoBytes;
  bool _pickingPhoto = false;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _customError;
  String? _descError;
  String? _nameError;
  String? _numberError;

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _customFocus.dispose();
    _descFocus.dispose();
    _nameFocus.dispose();
    _numberFocus.dispose();
    super.dispose();
  }

  TextStyle _t(
      double size,
      FontWeight weight,
      Color color, {
        double? height,
        double? letterSpacing,
      }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isSubmitted) return;
    final description = _descCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final digits = Validators.sanitizePhone(_numberCtrl.text);
    final custom = _customCtrl.text.trim();

    setState(() {
      _customError = (_selectedReason == 'Other' && custom.isEmpty)
          ? 'Please enter your custom refund reason.'
          : null;
      _descError = description.length < _minChars
          ? 'Please enter at least $_minChars characters.'
          : null;
      _nameError = name.isEmpty ? 'Please enter your GCash Account Name.' : null;
      _numberError = Validators.validateGCash(
        _numberCtrl.text,
        requiredMessage: 'Please enter an 11-digit GCash mobile number.',
        invalidMessage: 'Please enter an 11-digit GCash mobile number.',
      );
    });

    if (_customError != null || _descError != null || _nameError != null || _numberError != null) {
      AppToast.showError(
        context,
        'Some required details are missing or invalid.',
        title: 'Check the highlighted fields',
      );
      if (_customError != null) {
        _customFocus.requestFocus();
      } else if (_descError != null) {
        _descFocus.requestFocus();
      } else if (_nameError != null) {
        _nameFocus.requestFocus();
      } else {
        _numberFocus.requestFocus();
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final reason = _selectedReason == 'Other' ? custom : _selectedReason;
      if (widget.onSubmit != null) {
        String? photoUrl;
        if (_photoBytes != null) {
          photoUrl = await _cloudinary.uploadImage(
            _photoBytes!,
            filename: 'refund_evidence.jpg',
            folder: 'refund_evidence',
          );
        }
        await widget.onSubmit!(reason, description, name, digits, photoUrl);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      AppToast.showSuccess(
        context,
        'Claim filed for #${widget.order.orderNumber}. Store owner will review your reimbursement.',
        title: 'Refund Request Lodged',
      );
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, '$e', title: 'Submission Failed');
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      final shot = await _picker
          .pickImage(source: source)
          .timeout(const Duration(seconds: 20));
      if (shot == null) {
        if (!mounted) return;
        setState(() => _pickingPhoto = false);
        return;
      }
      final bytes = await shot.readAsBytes().timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _pickingPhoto = false;
      });
      AppToast.showSuccess(
        context,
        'Evidence photo attached to refund claim.',
        title: 'Photo Added',
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _pickingPhoto = false);
      AppToast.showError(
        context,
        'Taking too long — please try again or select a smaller photo.',
        title: 'Photo Timeout',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pickingPhoto = false);
      AppToast.showError(context, '$e', title: 'Photo Error');
    }
  }

  Widget _buildHeader(double topInset) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topInset),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: const Border(bottom: BorderSide(color: AppColors.slate200)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                height: _headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Material(
                      color: AppColors.sky50,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.arrow_back, size: 20, color: AppColors.primarySky),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request a Refund',
                            style: _t(17, FontWeight.bold, AppColors.textLight, height: 1.1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tell us what went wrong with your order',
                            style: _t(12, FontWeight.w500, AppColors.textSecondary),
                          ),
                        ],
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

  Widget _buildOrderCard() {
    final order = widget.order;
    final itemsSummary =
    order.items.map((i) => '${i.quantity}× ${i.name}').join(', ');
    final paymentLabel = order.isPaid
        ? (order.paymentMethod == PaymentMethod.gcash ? 'Paid via GCash' : 'Paid')
        : 'Cash on Delivery';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.sky50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primarySky),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order #${order.orderNumber}',
                    style: _t(14, FontWeight.bold, AppColors.textLight),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentLabel,
                  style: _t(10, FontWeight.bold, AppColors.slate600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ITEMS IN ORDER', style: _t(10, FontWeight.w800, AppColors.slate500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      itemsSummary.isEmpty ? 'Drinking water container' : itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(13, FontWeight.w500, AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL', style: _t(10, FontWeight.w800, AppColors.slate500, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(
                    '₱${order.totalAmount.toStringAsFixed(2)}',
                    style: _t(16, FontWeight.w800, AppColors.primarySky),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1. Reason for Refund',
                style: _t(14, FontWeight.bold, AppColors.textLight),
              ),
              Text(
                'REQUIRED',
                style: _t(10, FontWeight.w800, AppColors.primarySky, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-Column Selectable Options Grid
          LayoutBuilder(
            builder: (context, constraints) {
              const double gap = 8;
              final double itemWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _reasons.map((reason) {
                  final active = reason == _selectedReason;
                  return InkWell(
                    onTap: () => setState(() => _selectedReason = reason),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.sky50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? AppColors.primarySky : AppColors.slate200,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            active ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: active ? AppColors.primarySky : AppColors.slate400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _t(
                                12,
                                active ? FontWeight.bold : FontWeight.w600,
                                active ? AppColors.primarySky : AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 14),
            Text(
              'Specify Custom Reason',
              style: _t(11, FontWeight.bold, AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customCtrl,
              focusNode: _customFocus,
              onChanged: (_) {
                if (_customError != null) setState(() => _customError = null);
              },
              style: _t(13, FontWeight.w500, AppColors.textLight),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slate50,
                hintText: 'Please state your specific reason...',
                hintStyle: _t(13, FontWeight.w500, AppColors.slate400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _customError != null ? AppColors.coralAlert : AppColors.slate200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 2)),
              ),
            ),
            if (_customError != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(_customError!, style: _t(11, FontWeight.w500, AppColors.coralAlert)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final count = _descCtrl.text.trim().length;
    final met = count >= _minChars;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. Describe the Issue',
                style: _t(14, FontWeight.bold, AppColors.textLight),
              ),
              Text(
                '$count / $_minChars min',
                style: _t(
                  11,
                  FontWeight.bold,
                  met ? AppColors.emerald700 : AppColors.coralAlert,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            focusNode: _descFocus,
            onChanged: (_) {
              if (_descError != null) setState(() => _descError = null);
            },
            minLines: 3,
            maxLines: 5,
            style: _t(13, FontWeight.w500, AppColors.textLight, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.slate50,
              hintText: 'Explain what happened and which items are affected...',
              hintStyle: _t(13, FontWeight.w500, AppColors.slate400),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _descError != null ? AppColors.coralAlert : AppColors.slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 2)),
            ),
          ),
          if (_descError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(_descError!, style: _t(11, FontWeight.w500, AppColors.coralAlert)),
            ),
          const SizedBox(height: 14),

          // Photo Evidence Area
          Text(
            'Photo Evidence (Optional)',
            style: _t(12, FontWeight.bold, AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (_photoBytes != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_photoBytes!, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Photo attached', style: _t(12, FontWeight.bold, AppColors.textLight)),
                        Text('Ready to submit with claim', style: _t(11, FontWeight.w500, AppColors.emerald700)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.coralAlert),
                    onPressed: () {
                      setState(() => _photoBytes = null);
                      AppToast.showInfo(context, 'Evidence photo removed.');
                    },
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickingPhoto ? null : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primarySky,
                      side: const BorderSide(color: AppColors.slate200),
                      backgroundColor: AppColors.slate50,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickingPhoto ? null : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('From Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primarySky,
                      side: const BorderSide(color: AppColors.slate200),
                      backgroundColor: AppColors.slate50,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGcashCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3. GCash Reimbursement Details',
                style: _t(14, FontWeight.bold, AppColors.textLight),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sky50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'GCash Only',
                  style: _t(10, FontWeight.bold, AppColors.primarySky),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Account Holder Name',
            style: _t(12, FontWeight.bold, AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            textCapitalization: TextCapitalization.words,
            style: _t(14, FontWeight.bold, AppColors.textLight),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.slate50,
              hintText: 'e.g. Maria Santos',
              hintStyle: _t(14, FontWeight.w500, AppColors.slate400),
              prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.slate400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _nameError != null ? AppColors.coralAlert : AppColors.slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 2)),
            ),
          ),
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(_nameError!, style: _t(11, FontWeight.w500, AppColors.coralAlert)),
            ),
          const SizedBox(height: 14),
          Text(
            'GCash Mobile Number',
            style: _t(12, FontWeight.bold, AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _numberCtrl,
            focusNode: _numberFocus,
            onChanged: (_) {
              if (_numberError != null) setState(() => _numberError = null);
            },
            keyboardType: TextInputType.phone,
            inputFormatters: [_GcashNumberFormatter()],
            style: _t(14, FontWeight.bold, AppColors.textLight, letterSpacing: 1.0),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.slate50,
              hintText: '09XX XXX XXXX',
              hintStyle: _t(14, FontWeight.w500, AppColors.slate400, letterSpacing: 1.0),
              prefixIcon: const Icon(Icons.phone_iphone, size: 18, color: AppColors.slate400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _numberError != null ? AppColors.coralAlert : AppColors.slate200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySky, width: 2)),
            ),
          ),
          if (_numberError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(_numberError!, style: _t(11, FontWeight.w500, AppColors.coralAlert)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 13, color: AppColors.slate400),
              const SizedBox(width: 4),
              Text(
                'Your account info is used strictly for refund reimbursement.',
                style: _t(11, FontWeight.w500, AppColors.slate500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final done = _isSubmitted;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isSubmitting || _isSubmitted) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: done ? AppColors.emerald600 : AppColors.primarySky,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (done) ...[
                  const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  done ? 'Refund Request Lodged' : 'Submit Refund Request',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel and Keep Order',
            style: _t(13, FontWeight.w600, AppColors.slate500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    topInset + _headerHeight + 16,
                    16,
                    32 + media.padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderCard(),
                      const SizedBox(height: 16),
                      _buildReasonCard(),
                      const SizedBox(height: 16),
                      _buildDescriptionCard(),
                      const SizedBox(height: 16),
                      _buildGcashCard(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader(topInset)),
        ],
      ),
    );
  }
}