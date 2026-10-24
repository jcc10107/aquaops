import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/layout_constants.dart';
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
      _customError = (_selectedReason == 'Other' && custom.isEmpty) ? 'Please enter your custom refund reason.' : null;
      _descError = description.length < _minChars ? 'Please enter at least $_minChars characters.' : null;
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
          photoUrl = await _cloudinary.uploadImage(_photoBytes!, filename: 'refund_evidence.jpg', folder: 'refund_evidence');
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
        'Order ${widget.order.orderNumber} is being audited. Reimbursement via GCash will follow.',
        title: 'Refund Claim Lodged!',
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildHeader(double topInset) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topInset),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: SizedBox(
                height: _headerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.surfaceIce,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Refund Form',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(17, FontWeight.w700, AppColors.textLight,
                                  height: 1.3, letterSpacing: -0.17),
                            ),
                            Text(
                              'DISPUTE RESOLUTION & GCASH REIMBURSEMENT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(10, FontWeight.w800, AppColors.primarySky,
                                  height: 1.2, letterSpacing: 0.6),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.surfaceFrost.withValues(alpha: 0.6),
                    AppColors.surfaceFrost.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceIce,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long, size: 16, color: AppColors.primarySky),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ORDER DETAILS',
                          style: _t(11, FontWeight.w700, AppColors.primarySky,
                              height: 14 / 11, letterSpacing: 0.9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ${order.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(17, FontWeight.w700, AppColors.textLight,
                          height: 24 / 17, letterSpacing: -0.17),
                    ),
                    Text(
                      itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(13, FontWeight.w500, AppColors.textSecondary, height: 18 / 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${order.totalAmount.toStringAsFixed(2)}',
                    style: _t(17, FontWeight.w700, AppColors.primarySky,
                        height: 24 / 17, letterSpacing: -0.17),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: AppColors.onSecondaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          paymentLabel,
                          style: _t(10, FontWeight.w800, AppColors.onSecondaryContainer,
                              height: 1.2, letterSpacing: 0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Widget trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primarySky,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(17, FontWeight.w700, AppColors.textLight,
                      height: 24 / 17, letterSpacing: -0.17),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  Widget _inputShell({
    required FocusNode focusNode,
    required Widget child,
    double radius = 16,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
    double? height,
    String? errorText,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final hasError = errorText != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: focused ? Colors.white : AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: hasError ? AppColors.coralAlert : (focused ? AppColors.cyanElectric : Colors.transparent),
                  width: 2,
                ),
              ),
              child: child,
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  errorText,
                  style: _t(11, FontWeight.w500, AppColors.coralAlert, height: 14 / 11),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: _t(11, FontWeight.w700, AppColors.textSecondary,
            height: 14 / 11, letterSpacing: 0.22),
      ),
    );
  }

  Widget _buildReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Select Refund Reason',
            Text(
              'REQUIRED',
              style: _t(10, FontWeight.w800, AppColors.primarySky, height: 1.2, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _reasons.map((reason) {
              final active = reason == _selectedReason;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = reason),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primarySky : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: active
                        ? [
                      BoxShadow(
                        color: AppColors.primarySky.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : const [],
                  ),
                  child: Text(
                    reason,
                    style: _t(
                      11,
                      FontWeight.w700,
                      active ? Colors.white : AppColors.textSecondary,
                      height: 14 / 11,
                      letterSpacing: 0.22,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 12),
            _fieldLabel('Specify Custom Reason'),
            _inputShell(
              focusNode: _customFocus,
              height: 52,
              errorText: _customError,
              child: TextField(
                controller: _customCtrl,
                focusNode: _customFocus,
                onChanged: (_) {
                  if (_customError != null) setState(() => _customError = null);
                },
                style: _t(13, FontWeight.w500, AppColors.textLight, height: 18 / 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Please state your specific reason...',
                  hintStyle: _t(13, FontWeight.w500, AppColors.outline, height: 18 / 13),
                ),
              ),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Detailed Issue Description',
            Text(
              '$count / $_minChars min',
              style: _t(10, FontWeight.w800, met ? AppColors.secondary : AppColors.coralAlert,
                  height: 1.2, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          _inputShell(
            focusNode: _descFocus,
            padding: const EdgeInsets.all(14),
            errorText: _descError,
            child: TextField(
              controller: _descCtrl,
              focusNode: _descFocus,
              onChanged: (_) {
                if (_descError != null) setState(() => _descError = null);
              },
              minLines: 4,
              maxLines: 4,
              style: _t(13, FontWeight.w500, AppColors.textLight, height: 18 / 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText:
                'Describe the issue encountered with your order in detail (e.g., hairline crack near neck causing continuous leak during delivery)...',
                hintStyle: _t(13, FontWeight.w500, AppColors.outline, height: 18 / 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceIce,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primarySky),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Clear descriptions help AquaOps technicians process dispatch replacements and approvals faster.',
                    style: _t(11, FontWeight.w400, AppColors.primarySky, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        'Evidence file attached to refund claim.',
        title: 'Photo Added',
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _pickingPhoto = false);
      AppToast.showError(
        context,
        'Taking too long — please try a smaller photo or try again.',
        title: 'Photo Error',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pickingPhoto = false);
      AppToast.showError(context, '$e', title: 'Photo Error');
    }
  }

  Widget _photoButton(IconData icon, String label, ImageSource source) {
    return Expanded(
      child: Material(
        color: AppColors.surfaceIce,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: _pickingPhoto ? null : () => _pickPhoto(source),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _pickingPhoto
                  ? [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primarySky),
                ),
                const SizedBox(width: 8),
                Text('Loading...', style: _t(13, FontWeight.w700, AppColors.primarySky, height: 16 / 13, letterSpacing: 0.13)),
              ]
                  : [
                Icon(icon, size: 20, color: AppColors.primarySky),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: _t(13, FontWeight.w700, AppColors.primarySky,
                      height: 16 / 13, letterSpacing: 0.13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Photo Evidence',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  'RECOMMENDED',
                  style: _t(10, FontWeight.w800, AppColors.secondary,
                      height: 1.2, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _photoButton(Icons.photo_camera, 'Take Photo', ImageSource.camera),
              const SizedBox(width: 8),
              _photoButton(Icons.add_photo_alternate, 'Attach Photo', ImageSource.gallery),
            ],
          ),
          const SizedBox(height: 12),
          if (_photoBytes != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_photoBytes!, width: 36, height: 36, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evidence photo attached',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(13, FontWeight.w700, AppColors.textLight, height: 18 / 13),
                        ),
                        Text(
                          'Ready to submit with your claim',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(11, FontWeight.w400, AppColors.secondary, height: 16 / 11),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() => _photoBytes = null);
                      AppToast.showInfo(
                        context,
                        'You can take or attach a replacement photo anytime.',
                        title: 'Photo Removed',
                      );
                    },
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.delete_outline, size: 20, color: AppColors.coralAlert),
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No photo attached yet. Evidence speeds up verification.',
                  textAlign: TextAlign.center,
                  style: _t(11, FontWeight.w400, AppColors.outline, height: 16 / 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGcashCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'GCash Refund Details',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceFrost,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 13, color: AppColors.primarySky),
                  const SizedBox(width: 4),
                  Text(
                    'SECURE',
                    style: _t(10, FontWeight.w800, AppColors.primarySky,
                        height: 1.2, letterSpacing: 0.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('GCash Account Name'),
          _inputShell(
            focusNode: _nameFocus,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            errorText: _nameError,
            child: Row(
              children: [
                const Icon(Icons.badge, size: 18, color: AppColors.primarySky),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    textCapitalization: TextCapitalization.words,
                    style: _t(15, FontWeight.w500, AppColors.textLight, height: 22 / 15),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'e.g. Maria Santos',
                      hintStyle: _t(15, FontWeight.w500, AppColors.outline, height: 22 / 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('GCash Account Number'),
          _inputShell(
            focusNode: _numberFocus,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            errorText: _numberError,
            child: Row(
              children: [
                const Icon(Icons.phone_iphone, size: 18, color: AppColors.primarySky),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _numberCtrl,
                    focusNode: _numberFocus,
                    onChanged: (_) {
                      if (_numberError != null) setState(() => _numberError = null);
                    },
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_GcashNumberFormatter()],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      height: 22 / 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '09XX XXX XXXX',
                      hintStyle: _t(15, FontWeight.w500, AppColors.outline, height: 22 / 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.shield, size: 18, color: AppColors.primarySky),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Data Privacy Guard: ',
                          style: _t(11, FontWeight.w700, AppColors.textLight, height: 1.5),
                        ),
                        const TextSpan(
                          text:
                          'Only shared with station owner for manual reimbursement processing. Never stored on external servers.',
                        ),
                      ],
                    ),
                    style: _t(11, FontWeight.w400, AppColors.textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final done = _isSubmitted;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: done ? AppColors.secondary : AppColors.primarySky,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: (done ? AppColors.secondary : AppColors.primarySky).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: (_isSubmitting || _isSubmitted) ? null : _submit,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSubmitting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else if (done)
                  const Icon(Icons.check_circle, size: 20, color: Colors.white),
                if (_isSubmitting || done) const SizedBox(width: 8),
                Text(
                  _isSubmitting
                      ? 'Transmitting Request...'
                      : (done ? 'Submitted Successfully' : 'Submit Refund Request'),
                  style: _t(17, FontWeight.w700, Colors.white,
                      height: 24 / 17, letterSpacing: -0.17),
                ),
                if (!_isSubmitting && !done) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    topInset + _headerHeight + 16,
                    16,
                    96 + media.padding.bottom,
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
                      _buildPhotoCard(),
                      const SizedBox(height: 16),
                      _buildGcashCard(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            'Cancel & Keep Order',
                            style: _t(13, FontWeight.w700, AppColors.textSecondary,
                                height: 16 / 13, letterSpacing: 0.13),
                          ),
                        ),
                      ),
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