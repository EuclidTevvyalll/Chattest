import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/profile/domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<ProfileModel?> getProfile(String id) async {
    try {
      debugPrint('Supabase: Fetching profile for id: $id...');
      final data = await _client
          .from('profiles')
          .select('id, username, nickname, avatar_url, is_online, updated_at')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      debugPrint('Supabase: Profile fetched successfully.');
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('Supabase: Error fetching profile: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getAvatarBase64(String id, {bool priority = false}) async {
    // avatar_base64 column has been removed from the database.
    // The application now uses avatar_url for all profile images.
    return null;
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    // Adding an initial delay to let the network connection 'breathe'
    // after a potentially heavy storage upload.
    await Future.delayed(const Duration(milliseconds: 1500));

    int retryCount = 0;
    const maxRetries = 5;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
          'Supabase: Updating profile for id: ${profile.id} (Attempt ${retryCount + 1})...',
        );

        await _client
            .from('profiles')
            .update({
              'username': profile.username,
              'nickname': profile.nickname,
              'avatar_url': profile.avatarUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', profile.id);

        debugPrint('Supabase: Profile updated successfully.');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('Supabase: Profile update attempt $retryCount failed: $e');
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Increasing wait time between retries
        await Future.delayed(Duration(seconds: 1 * retryCount));
      }
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String userId) async {
    final fileName =
        'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = fileName;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
          'Supabase: Uploading avatar to storage (Attempt ${retryCount + 1}): $path...',
        );

        await _client.storage
            .from('avatars')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        final String publicUrl = _client.storage
            .from('avatars')
            .getPublicUrl(path);
        debugPrint('Supabase: Avatar uploaded successfully. URL: $publicUrl');
        return publicUrl;
      } catch (e) {
        retryCount++;
        debugPrint('Supabase: Upload attempt $retryCount failed: $e');
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Wait a bit before retrying
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
    throw Exception('Failed to upload avatar after $maxRetries attempts');
  }
}
