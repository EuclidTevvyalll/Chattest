import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/profile/domain/repositories/profile_repository.dart';

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
    try {
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('Supabase: Uploading avatar via Edge Function (Base64 JSON): $fileName...');
      
      final base64File = base64Encode(bytes);
      
      final response = await _client.functions.invoke(
        'upload-media',
        body: {
          'roomId': 'avatars', // Use 'avatars' as a pseudo-room for bucket selection in function
          'fileName': fileName,
          'fileBase64': base64File,
          'contentType': 'image/jpeg',
        },
      );

      if (response.status == 200 || response.status == 201) {
        final data = response.data;
        if (data is Map && data.containsKey('url')) {
          return data['url'];
        }
        throw Exception('Invalid response from Edge Function: ${response.data}');
      } else {
        throw Exception('Edge Function Error (Status ${response.status}): ${response.data}');
      }
    } catch (e) {
      debugPrint('Supabase: Avatar upload failed: $e');
      rethrow;
    }
  }
}
