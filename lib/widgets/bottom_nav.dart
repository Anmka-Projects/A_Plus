import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design/app_colors.dart';
import '../core/navigation/route_names.dart';
import '../core/localization/localization_helper.dart';

/// Bottom Navigation Bar - Liquid Glass Effect
class BottomNav extends StatelessWidget {
  final String activeTab;

  const BottomNav({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: AppColors.berkeleyBlue.withOpacity(0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 4),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: context.l10n.home,
                        id: 'home',
                        activeTab: activeTab,
                        onTap: () => context.go(RouteNames.home),
                      ),
                      _NavItem(
                        icon: Icons.explore_rounded,
                        label: context.l10n.allCourses,
                        id: 'allCourses',
                        activeTab: activeTab,
                        onTap: () => context.go(RouteNames.allCourses),
                      ),
                      _NavItem(
                        icon: Icons.menu_book_rounded,
                        label: context.l10n.myCourses,
                        id: 'enrolled',
                        activeTab: activeTab,
                        onTap: () => context.go(RouteNames.enrolled),
                      ),
                      _NavItem(
                        icon: Icons.person_rounded,
                        label: context.l10n.profile,
                        id: 'dashboard',
                        activeTab: activeTab,
                        onTap: () => context.go(RouteNames.dashboard),
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
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String id;
  final String activeTab;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.id,
    required this.activeTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == id;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 6,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandBlue.withOpacity(0.16),
                    AppColors.brandPurple.withOpacity(0.12),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                size: isActive ? 26 : 24,
                color: isActive
                    ? AppColors.brandPurple
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.brandPurple
                    : AppColors.mutedForeground,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
