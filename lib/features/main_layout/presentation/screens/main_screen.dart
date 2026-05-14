import 'package:flutter/material.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MainLayout extends ConsumerWidget {
  final Widget bnb;
  final Widget child;
  const MainLayout({super.key, required this.bnb, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumDialogOpen = ref.watch(isPremiumDialogOpenProvider);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: isPremiumDialogOpen
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [bnb],
            ),
    );
  }
}
