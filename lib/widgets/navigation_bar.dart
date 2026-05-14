import 'package:flutter/material.dart';

import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = navBarItems(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.blue.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GlassBox(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          opacity: isDark ? 0.35 : 0.75,
          blur: 20,
          borderRadius: BorderRadius.circular(28),
          color: isDark ? Colors.black : Colors.white,
          border: Border.all(
            color: ThemeColors.blue.withValues(alpha: isDark ? 0.15 : 0.1),
            width: 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 18 : 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThemeColors.blue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: isSelected ? 22 : 20,
                        color: isSelected
                            ? ThemeColors.blue
                            : (isDark ? Colors.white54 : Colors.black38),
                      ),
                      if (isSelected && item.label != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label!,
                          style: ThemeTextStyles.bodyMedium(isDark: isDark),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String? label;

  NavBarItem({required this.icon, required this.activeIcon, this.label});
}

List<NavBarItem> navBarItems(BuildContext context) => [
  NavBarItem(
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'Чаты',
  ),
  NavBarItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Настройки',
  ),
];
