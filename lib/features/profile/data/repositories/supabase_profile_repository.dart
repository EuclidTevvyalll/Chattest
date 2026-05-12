import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
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
    return null;
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
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
        await Future.delayed(Duration(seconds: 1 * retryCount));
      }
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String userId) async {
    var uploadBytes = bytes;
    
    // Aggressively compress avatar
    try {
      final image = img.decodeImage(uploadBytes);
      if (image != null) {
        debugPrint('Supabase: Compressing avatar (Original: ${uploadBytes.length} bytes)');
        // Resize to 512x512 max for avatar
        img.Image resized = image;
        if (image.width > 512 || image.height > 512) {
          resized = img.copyResize(image, width: 512, height: 512, interpolation: img.Interpolation.linear);
        }
        final compressed = img.encodeJpg(resized, quality: 70);
        uploadBytes = Uint8List.fromList(compressed);
        debugPrint('Supabase: Avatar compression complete (New: ${uploadBytes.length} bytes)');
      }
    } catch (e) {
      debugPrint('Supabase: Avatar optimization failed: $e');
    }

    final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    debugPrint('Supabase: Preparing avatar upload for $fileName...');
    
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        debugPrint('Supabase: Avatar upload attempt ${retryCount + 1} directly to storage...');
        
        final path = '$userId/$fileName';
        await _client.storage
            .from('avatars')
            .uploadBinary(
              path,
              uploadBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        final publicUrl = _client.storage
            .from('avatars')
            .getPublicUrl(path);

        debugPrint('Supabase: Avatar upload successful! URL: $publicUrl');
        return publicUrl;
      } catch (e) {
        retryCount++;
        debugPrint('Supabase: Avatar upload attempt $retryCount failed: $e');
        
        if (e is StorageException && (e.statusCode == '401' || e.statusCode == '403')) {
          try {
            await _client.auth.refreshSession();
          } catch (_) {}
        }

        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
    throw Exception('Avatar upload failed after $maxRetries attempts');
  }
}


