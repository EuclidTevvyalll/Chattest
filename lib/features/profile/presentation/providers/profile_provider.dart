import 'dart:async';
import 'dart:typed_data';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/profile/data/repositories/supabase_profile_repository.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;
  
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});

class ProfileController extends AsyncNotifier<ProfileModel?> {
  @override
  FutureOr<ProfileModel?> build() {
    return ref.watch(currentProfileProvider.future);
  }

  Future<void> updateProfile({
    String? username,
    String? nickname,
    String? avatarUrl,
  }) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(
      username: username ?? currentProfile.username,
      nickname: nickname ?? currentProfile.nickname,
      avatarUrl: avatarUrl ?? currentProfile.avatarUrl,
    );

    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      state = AsyncValue.data(updatedProfile);
      ref.invalidate(currentProfileProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(Uint8List bytes) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncValue.loading();
    try {
      final url = await ref.read(profileRepositoryProvider).uploadAvatar(bytes, currentProfile.id);
      await updateProfile(avatarUrl: url);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileModel?>(
  ProfileController.new,
);
