import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

final currentProfileProvider = Provider<ProfileModel?>((ref) {
  return ref.watch(profileControllerProvider).asData?.value;
});

final userProfileProvider =
    FutureProvider.family<ProfileModel?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(userId);
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
  @override
  FutureOr<ProfileModel?> build() async {
    final user = ref.watch(authUserProvider);
    if (user == null) return null;
    return ref.read(profileRepositoryProvider).getProfile(user.id);
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
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileModel?>(
      ProfileController.new,
    );
