import 'dart:async';
import 'dart:convert';
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
      debugPrint('Supabase: Fetching light profile for id: $id...');
      // We explicitly select everything EXCEPT the heavy avatar_base64
      final data = await _client
          .from('profiles')
          .select('id, username, nickname, avatar_url, is_online, updated_at')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      debugPrint('Supabase: Light profile fetched successfully.');
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('Supabase: Error fetching profile: $e');
      rethrow;
    }
  }

  // Sequential loading queue
  final List<_AvatarRequest> _avatarQueue = [];
  bool _isProcessingQueue = false;

  @override
  Future<String?> getAvatarBase64(String id, {bool priority = false}) async {
    final completer = Completer<String?>();
    final request = _AvatarRequest(id, completer, priority);

    if (priority) {
      // Put high priority requests (own avatar) at the front
      _avatarQueue.insert(0, request);
    } else {
      _avatarQueue.add(request);
    }

    _processAvatarQueue();
    return completer.future;
  }

  Future<void> _processAvatarQueue() async {
    if (_isProcessingQueue || _avatarQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_avatarQueue.isNotEmpty) {
      final request = _avatarQueue.removeAt(0);
      try {
        final result = await _fetchAvatarInternal(request.id);
        if (!request.completer.isCompleted) {
          request.completer.complete(result);
        }
      } catch (e) {
        if (!request.completer.isCompleted) {
          request.completer.complete(null);
        }
      }
      // Small delay between requests to be extra safe on Windows network stack
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _isProcessingQueue = false;
  }

  Future<String?> _fetchAvatarInternal(String id) async {
    try {
      debugPrint('Supabase: Fetching heavy avatar for id: $id...');
      final data = await _client
          .from('profiles')
          .select('avatar_base64')
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return data['avatar_base64'] as String?;
    } catch (e) {
      debugPrint('Supabase: Error fetching avatar: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      debugPrint('Supabase: Updating profile for id: ${profile.id}...');

      await _client
          .from('profiles')
          .update({
            'username': profile.username,
            'nickname': profile.nickname,
            'avatar_url': profile.avatarUrl,
            'avatar_base64': profile.avatarBase64,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profile.id);

      debugPrint('Supabase: Profile updated successfully.');
    } catch (e) {
      debugPrint('Supabase: Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String userId) async {
    final base64String = base64Encode(bytes);
    debugPrint(
      'Supabase: Avatar prepared as Base64 (${base64String.length} chars)',
    );
    return 'base64:$base64String';
  }
}

class _AvatarRequest {
  final String id;
  final Completer<String?> completer;
  final bool priority;

  _AvatarRequest(this.id, this.completer, this.priority);
}
