import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/profile/data/repositories/supabase_profile_repository.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarPreviewNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;
  void update(Uint8List? value) => state = value;
}

final avatarUploadPreviewProvider =
    NotifierProvider<AvatarPreviewNotifier, Uint8List?>(
      AvatarPreviewNotifier.new,
    );

class PremiumDialogNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final isPremiumDialogOpenProvider =
    NotifierProvider<PremiumDialogNotifier, bool>(PremiumDialogNotifier.new);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

final currentProfileProvider = Provider<ProfileModel?>((ref) {
  return ref.watch(profileControllerProvider).asData?.value;
});

final userProfileProvider = FutureProvider.family<ProfileModel?, String>((
  ref,
  userId,
) async {
  final keepAlive = ref.keepAlive();

  // Timer to clean up cache if not used for 5 minutes
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 5), () {
      keepAlive.close();
    });
  });
  ref.onResume(() => timer?.cancel());

  final repo = ref.watch(profileRepositoryProvider);
  final profile = await repo
      .getProfile(userId)
      .timeout(const Duration(seconds: 5));

  if (profile != null) {
    bool needsUpdate = false;
    var updatedProfile = profile;
    final now = DateTime.now();

    // Check premium
    if (updatedProfile.isPremium && updatedProfile.premiumUntil != null) {
      if (updatedProfile.premiumUntil!.isBefore(now)) {
        updatedProfile = updatedProfile.copyWith(
          isPremium: false,
          premiumUntil: null,
        );
        needsUpdate = true;
      }
    }

    // Check ban
    if (updatedProfile.isBanned == true && updatedProfile.bannedUntil != null) {
      if (updatedProfile.bannedUntil!.isBefore(now)) {
        updatedProfile = updatedProfile.copyWith(
          isBanned: false,
          bannedUntil: null,
          bannedReason: null,
        );
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      // Background update to not block UI
      unawaited(
        repo.updateProfile(updatedProfile).catchError((e) {
          debugPrint('Error updating expired profile for $userId: $e');
        }),
      );
      return updatedProfile;
    }
  }

  return profile;
});

final currentAvatarBase64Provider = FutureProvider<Uint8List?>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;

  final base64 = await ref
      .watch(profileRepositoryProvider)
      .getAvatarBase64(user.id, priority: true);
  if (base64 == null) return null;
  return base64Decode(base64);
});

final userAvatarBase64Provider = FutureProvider.family<Uint8List?, String>((
  ref,
  userId,
) async {
  final base64 = await ref
      .watch(profileRepositoryProvider)
      .getAvatarBase64(userId);
  if (base64 == null) return null;
  return base64Decode(base64);
});

class ProfileController extends AsyncNotifier<ProfileModel?> {
  StreamSubscription<ProfileModel?>? _subscription;

  @override
  FutureOr<ProfileModel?> build() async {
    ref.keepAlive();
    final user = ref.watch(authUserProvider);
    if (user == null) return null;

    // Подписываемся на изменения в реальном времени
    _subscription?.cancel();
    _subscription = ref
        .read(profileRepositoryProvider)
        .watchProfile(user.id)
        .listen(
          (profile) {
            if (profile != null) {
              debugPrint(
                'ProfileController: UI state updated from realtime (isBanned: ${profile.isBanned})',
              );
              state = AsyncValue.data(profile);
            }
          },
          onError: (err) =>
              debugPrint('ProfileController: Realtime stream error: $err'),
        );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Первоначальная загрузка
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(user.id);

    // Проверка на истечение премиума при загрузке
    if (profile != null && profile.isPremium && profile.premiumUntil != null) {
      if (profile.premiumUntil!.isBefore(DateTime.now())) {
        debugPrint('ProfileController: Premium expired. Downgrading...');
        final expiredProfile = profile.copyWith(
          isPremium: false,
          premiumUntil: null,
        );
        await ref.read(profileRepositoryProvider).updateProfile(expiredProfile);
        return expiredProfile;
      }
    }

    // Проверка на истечение бана при загрузке
    if (profile != null &&
        profile.isBanned == true &&
        profile.bannedUntil != null) {
      if (profile.bannedUntil!.isBefore(DateTime.now())) {
        debugPrint('ProfileController: Ban expired. Unbanning...');
        final unbannedProfile = profile.copyWith(
          isBanned: false,
          bannedUntil: null,
          bannedReason: null,
        );
        await ref
            .read(profileRepositoryProvider)
            .updateProfile(unbannedProfile);
        return unbannedProfile;
      }
    }

    return profile;
  }

  Future<void> updateProfile({
    String? username,
    String? nickname,
    String? avatarUrl,
    String? avatarBase64,
  }) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(
      username: username ?? currentProfile.username,
      nickname: nickname ?? currentProfile.nickname,
      avatarUrl: avatarUrl ?? currentProfile.avatarUrl,
      avatarBase64: avatarBase64 ?? currentProfile.avatarBase64,
    );

    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      state = AsyncValue.data(updatedProfile);
      // Only invalidate the avatar providers to force a re-fetch of the new image
      // if it was updated, but don't invalidate the whole profile provider
      // which triggers a cascade of UI rebuilds.
      if (avatarUrl != null || avatarBase64 != null) {
        ref.invalidate(currentAvatarBase64Provider);
        ref.invalidate(userAvatarBase64Provider(currentProfile.id));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(Uint8List bytes) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      final res = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(bytes, currentProfile.id);
      if (res.startsWith('base64:')) {
        await updateProfile(avatarBase64: res.replaceFirst('base64:', ''));
      } else {
        await updateProfile(avatarUrl: res);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> upgradeToPremium(
    Duration duration,
    double amount,
    int months,
  ) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final now = DateTime.now();
    final newExpiration =
        (currentProfile.premiumUntil != null &&
            currentProfile.premiumUntil!.isAfter(now))
        ? currentProfile.premiumUntil!.add(duration)
        : now.add(duration);

    final updatedProfile = currentProfile.copyWith(
      isPremium: true,
      premiumUntil: newExpiration,
    );

    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      // Log the transaction
      await ref
          .read(profileRepositoryProvider)
          .logSubscription(currentProfile.id, amount, months);
      state = AsyncValue.data(updatedProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileModel?>(
      ProfileController.new,
    );
