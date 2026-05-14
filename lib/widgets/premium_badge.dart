import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final double size;
  final Color? color;

  const PremiumBadge({
    super.key,
    required this.isPremium,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.workspace_premium_rounded,
        color: color ?? const Color(0xFFFFD700),
        size: size,
      ),
    );
  }
}
