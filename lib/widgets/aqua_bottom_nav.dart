import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../screens/refund/owner_request_screen.dart';

class _NavEntry {
  final Widget icon;
  final String label;

  const _NavEntry({required this.icon, required this.label});
}

class AquaBottomNav extends StatelessWidget implements PreferredSizeWidget {
  final bool isOwner;
  final bool isStaff;
  final bool isRider;
  final bool hasActiveOrder;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color brandLoginBlue = Color(0xFF0284C7);
  static const int _ownerRefundIndex = 4;

  const AquaBottomNav({
    super.key,
    required this.isOwner,
    this.isStaff = false,
    this.isRider = false,
    this.hasActiveOrder = false,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  List<_NavEntry> _buildEntries() {
    if (isOwner) {
      return const [
        _NavEntry(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        _NavEntry(icon: Icon(Icons.point_of_sale), label: 'POS'),
        _NavEntry(icon: Icon(Icons.local_shipping), label: 'Queue'),
        _NavEntry(icon: Icon(Icons.inventory_2), label: 'Stock'),
        _NavEntry(icon: Icon(Icons.assignment_return), label: 'Refund'),
      ];
    }
    if (isStaff) {
      return const [
        _NavEntry(icon: Icon(Icons.point_of_sale), label: 'POS'),
        _NavEntry(icon: Icon(Icons.inventory_2), label: 'Inventory'),
      ];
    }
    if (isRider) {
      return const [
        _NavEntry(icon: Icon(Icons.local_shipping), label: 'Queue'),
      ];
    }
    return [
      const _NavEntry(icon: Icon(Icons.local_mall), label: 'Store'),
      _NavEntry(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.receipt_long),
            if (hasActiveOrder)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.cyanElectric,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        label: 'Orders',
      ),
      const _NavEntry(icon: Icon(Icons.account_balance_wallet), label: 'Payments'),
    ];
  }

  void _handleTap(BuildContext context, int index) {
    if (isOwner && index == _ownerRefundIndex) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OwnerRequestScreen(),
        ),
      );
      return;
    }
    onTap(index);
  }

  Widget _buildItem(BuildContext context, int index, _NavEntry entry) {
    final bool selected = index == currentIndex;
    final Color color = selected ? brandLoginBlue : AppColors.textVariant;

    return Expanded(
      child: InkWell(
        onTap: () => _handleTap(context, index),
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(color: color, size: 24),
                child: entry.icon,
              ),
              const SizedBox(height: 4),
              Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_NavEntry> entries = _buildEntries();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: brandLoginBlue.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          for (int i = 0; i < entries.length; i++)
                            _buildItem(context, i, entries[i]),
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