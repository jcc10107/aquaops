// lib/widgets/custom_header.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../core/constants/app_colors.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  String _getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'U';

    List<String> nameParts = fullName.trim().split(RegExp(r'\s+'));
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
    } else {
      return nameParts[0].substring(0, nameParts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = currentUserRoleNotifier.value;

    String mockDatabaseName = "Admin User";
    if (role == 'owner') mockDatabaseName = "Juan Dela Cruz";
    if (role == 'staff') mockDatabaseName = "Arnel Bautista";
    if (role == 'customer') mockDatabaseName = "Elena Gomez";

    final userInitials = _getInitials(mockDatabaseName);
    final myNotifications = globalNotifications
        .where((n) => n['role'] == role || role == 'owner')
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.85)
                    : AppColors.surfaceLowest.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.borderLight.withValues(alpha: 0.4),
                  ),
                ),
                boxShadow: isDark
                    ? []
                    : [
                  const BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF0088CC), AppColors.cyanHighlight],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyanElectric.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0077B6), Color(0xFF004E7C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.water_drop,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: isDark ? Colors.white : AppColors.textMain,
                                    ),
                                    children: const [
                                      TextSpan(text: 'Aqua'),
                                      TextSpan(
                                        text: 'Ops',
                                        style: TextStyle(color: Color(0xFF0077B6)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFEFF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA5F3FC).withValues(alpha: 0.6)),
                                  ),
                                  child: const Text(
                                    'HQ',
                                    style: TextStyle(
                                      color: Color(0xFF00689C),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentTeal,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentTeal.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'San Antonio Hub',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : AppColors.textVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : AppColors.outlineVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.borderDark : AppColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : AppColors.borderLight.withValues(alpha: 0.5),
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                offset: const Offset(0, 50),
                                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLowest,
                                elevation: 12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                icon: Icon(
                                  Icons.notifications_none,
                                  color: isDark ? Colors.grey[300] : AppColors.textVariant,
                                  size: 22,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    enabled: false,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                                        const Text('Clear', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  ...myNotifications.map((n) => PopupMenuItem(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(n['title'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                                            Text(n['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(n['desc'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  )),
                                  if (myNotifications.isEmpty)
                                    PopupMenuItem(child: Text('No new alerts.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black))),
                                ],
                              ),
                            ),
                            if (myNotifications.isNotEmpty)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.coralAlert, Color(0xFFDC2626)],
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.coralAlert.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${myNotifications.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF004B73), Color(0xFF00689C), Color(0xFF0EA5E9)],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF003857), Color(0xFF005A87)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withValues(alpha: 0.2),
                                              Colors.transparent,
                                              Colors.white.withValues(alpha: 0.25),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        userInitials,
                                        style: const TextStyle(
                                          color: Color(0xFFECFEFF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  @override
  Size get preferredSize => const Size.fromHeight(76);
}