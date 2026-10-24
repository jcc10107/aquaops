import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProofOfDeliveryDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final double chromeHeight;
  final IconData? badgeIcon;
  final Color? badgeIconColor;
  final String? badgeText;
  final Widget? detailsChild;

  const ProofOfDeliveryDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.chromeHeight = 220,
    this.badgeIcon,
    this.badgeIconColor,
    this.badgeText,
    this.detailsChild,
  });

  static const Color _primary = Color(0xFF0284C7);
  static const Color _slate50 = Color(0xFFF8FAFC);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate900 = Color(0xFF0F172A);

  TextStyle _ts({
    required double size,
    required FontWeight weight,
    required Color color,
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

  Widget _buildPlaceholder(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: _slate400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _ts(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    const double inset = 16;
    final double maxDialogWidth = math.min(mq.size.width - inset * 2, 450.0);
    final double availableHeight = math.max(
      0.0,
      mq.size.height - mq.padding.top - mq.padding.bottom - inset * 2 - chromeHeight,
    );

    final double widthFromHeight = availableHeight * 3 / 4;
    final double imageWidth = math.max(math.min(maxDialogWidth, widthFromHeight), 120.0);
    final double imageHeight = imageWidth * 4 / 3;
    final double dialogWidth = math.min(maxDialogWidth, math.max(imageWidth, 300.0));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(inset),
      child: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: _slate50,
                      border: Border(bottom: BorderSide(color: _slate100)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _ts(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _slate900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _ts(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: _slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _slate200),
                            ),
                            child: const Icon(Icons.close, size: 16, color: _slate500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image Container
                  Container(
                    width: double.infinity,
                    color: _slate900,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRect(
                              child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
                                  ? InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: SizedBox(
                                  width: imageWidth,
                                  height: imageHeight,
                                  child: Image.network(
                                    imageUrl!,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _primary,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholder(
                                          Icons.broken_image,
                                          'Unable to load photo.',
                                        ),
                                  ),
                                ),
                              )
                                  : _buildPlaceholder(
                                Icons.image_not_supported,
                                'No photo was submitted.',
                              ),
                            ),
                          ),
                          if (badgeText != null && badgeText!.isNotEmpty)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (badgeIcon != null) ...[
                                        Icon(
                                          badgeIcon,
                                          size: 12,
                                          color: badgeIconColor ?? const Color(0xFF34D399),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        badgeText!,
                                        style: _ts(
                                          size: 10,
                                          weight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Details & Close Footer
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        if (detailsChild != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _slate50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _slate100),
                            ),
                            child: detailsChild!,
                          ),
                        if (detailsChild != null) const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _slate100,
                            foregroundColor: _slate800,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Close Preview',
                            style: _ts(size: 12, weight: FontWeight.w700, color: _slate800),
                          ),
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
    );
  }
}