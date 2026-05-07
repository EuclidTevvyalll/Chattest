import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/profile/domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<ProfileModel?> getProfile(String id) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();
    
    return ProfileModel.fromJson(response);
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    await _client.from('profiles').update({
      'username': profile.username,
      'nickname': profile.nickname,
      'avatar_url': profile.avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String userId) async {
    File? tempFile;
    try {
      final fileName = 'avatar_$userId.png';
      
      // Use path_provider to get temporary directory for the file
      // This helps avoid semaphore timeout errors on Windows
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      
      await _client.storage.from('avatars').upload(
            fileName,
            tempFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      final url = _client.storage.from('avatars').getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    } finally {
      // Always clean up the temporary file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('Error deleting temporary file: $e');
        }
      }
    }
  }
}

