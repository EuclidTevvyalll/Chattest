import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:forgelink/features/auth/presentation/screens/banned_screen.dart';

class BannedGuard extends ConsumerWidget {
  final Widget child;

  const BannedGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile != null && profile.isBanned == true) {
          // Check if ban is expired
          if (profile.bannedUntil != null &&
              profile.bannedUntil!.isBefore(DateTime.now().toUtc())) {
            // Ban expired, show normal app.
            // The backend/DB should actually update is_banned, but just in case we let them in.
            return child;
          }
          return BannedScreen(profile: profile);
        }
        return child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          child, // If error loading profile, fallback to normal (or an error screen)
    );
  }
}
