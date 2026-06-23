import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class ArchiveBottomNav extends StatelessWidget {
  const ArchiveBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ScreenshotSpacing.sm,
        0,
        ScreenshotSpacing.sm,
        bottomInset + ScreenshotSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xDD110E0A),
          border: Border.all(color: ScreenshotColors.outlineVariant),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ScreenshotSpacing.xs),
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                isActive: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                label: 'Search',
                icon: Icons.search_rounded,
                isActive: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                isActive: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 56,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isActive ? const Color(0x12EAE1DA) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isActive
                      ? ScreenshotColors.onSurface
                      : ScreenshotColors.outline,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: ScreenshotTypography.bodyMedium.copyWith(
                    color: isActive
                        ? ScreenshotColors.onSurface
                        : ScreenshotColors.outline,
                    fontFamily: ScreenshotTypography.uiFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
