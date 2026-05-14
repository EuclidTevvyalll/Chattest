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
          .select(
            'id, username, nickname, avatar_url, is_online, last_seen, updated_at, is_banned, banned_until, banned_reason, is_premium, premium_until',
          )
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;

      var profile = ProfileModel.fromJson(data);

      // Auto-expire check (Premium)
      if (profile.isPremium &&
          profile.premiumUntil != null &&
          profile.premiumUntil!.isBefore(DateTime.now())) {
        debugPrint(
          'Supabase: Premium expired for ${profile.id}. Auto-downgrading...',
        );
        profile = profile.copyWith(isPremium: false, premiumUntil: null);
        // Optimistic background update
        _client
            .from('profiles')
            .update({'is_premium': false, 'premium_until': null})
            .eq('id', profile.id)
            .then((_) {
              debugPrint('Supabase: DB updated for expired premium.');
            })
            .catchError((e) {
              debugPrint('Supabase: Failed to auto-downgrade in DB: $e');
            });
      }

      // Auto-expire check (Ban)
      if (profile.isBanned == true &&
          profile.bannedUntil != null &&
          profile.bannedUntil!.isBefore(DateTime.now())) {
        debugPrint('Supabase: Ban expired for ${profile.id}. Unbanning...');
        profile = profile.copyWith(
          isBanned: false,
          bannedUntil: null,
          bannedReason: null,
        );
        // Optimistic background update
        _client
            .from('profiles')
            .update({
              'is_banned': false,
              'banned_until': null,
              'banned_reason': null,
            })
            .eq('id', profile.id)
            .then((_) {
              debugPrint('Supabase: DB updated for expired ban.');
            })
            .catchError((e) {
              debugPrint('Supabase: Failed to unban in DB: $e');
            });
      }

      debugPrint('Supabase: Profile fetched successfully.');
      return profile;
    } catch (e) {
      debugPrint('Supabase: Error fetching profile: $e');
      rethrow;
    }
  }

  @override
  Stream<ProfileModel?> watchProfile(String id) {
    debugPrint('Realtime: Start watching profile for $id');
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) {
          if (data.isEmpty) {
            debugPrint('Realtime: No data for profile $id');
            return null;
          }
          final record = data.first;
          debugPrint(
            'Realtime: Received update for profile $id. is_banned: ${record['is_banned']}',
          );
          try {
            var profile = ProfileModel.fromJson(record);

            // Auto-expire check (Premium)
            if (profile.isPremium &&
                profile.premiumUntil != null &&
                profile.premiumUntil!.isBefore(DateTime.now())) {
              debugPrint(
                'Realtime: Premium expired for ${profile.id}. Auto-downgrading...',
              );
              profile = profile.copyWith(isPremium: false, premiumUntil: null);
              // Optimistic background update
              _client
                  .from('profiles')
                  .update({'is_premium': false, 'premium_until': null})
                  .eq('id', profile.id)
                  .then((_) {
                    debugPrint('Realtime: DB updated for expired premium.');
                  })
                  .catchError((e) {
                    debugPrint('Realtime: Failed to auto-downgrade in DB: $e');
                  });
            }

            // Auto-expire check (Ban)
            if (profile.isBanned == true &&
                profile.bannedUntil != null &&
                profile.bannedUntil!.isBefore(DateTime.now())) {
              debugPrint(
                'Realtime: Ban expired for ${profile.id}. Unbanning...',
              );
              profile = profile.copyWith(
                isBanned: false,
                bannedUntil: null,
                bannedReason: null,
              );
              // Optimistic background update
              _client
                  .from('profiles')
                  .update({
                    'is_banned': false,
                    'banned_until': null,
                    'banned_reason': null,
                  })
                  .eq('id', profile.id)
                  .then((_) {
                    debugPrint('Realtime: DB updated for expired ban.');
                  })
                  .catchError((e) {
                    debugPrint('Realtime: Failed to unban in DB: $e');
                  });
            }

            return profile;
          } catch (e) {
            debugPrint('Realtime: Error parsing profile data: $e');
            return null;
          }
        })
        .handleError((error) {
          debugPrint('Realtime: Stream error for profile $id: $error');
        });
  }

  @override
  Future<String?> getAvatarBase64(String id, {bool priority = false}) async {
    return null;
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final updateData = {
          'username': profile.username,
          'nickname': profile.nickname,
          'avatar_url': profile.avatarUrl,
          'is_premium': profile.isPremium,
          'premium_until': profile.premiumUntil?.toIso8601String(),
          'is_banned': profile.isBanned,
          'banned_until': profile.bannedUntil?.toIso8601String(),
          'banned_reason': profile.bannedReason,
          'updated_at': DateTime.now().toIso8601String(),
        };

        debugPrint(
          'Supabase: Sending update for profile ${profile.id}: $updateData',
        );

        await _client.from('profiles').update(updateData).eq('id', profile.id);

        debugPrint('Supabase: Profile updated successfully in database.');
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
        debugPrint(
          'Supabase: Compressing avatar (Original: ${uploadBytes.length} bytes)',
        );
        // Resize to 512x512 max for avatar
        img.Image resized = image;
        if (image.width > 512 || image.height > 512) {
          resized = img.copyResize(
            image,
            width: 512,
            height: 512,
            interpolation: img.Interpolation.linear,
          );
        }
        final compressed = img.encodeJpg(resized, quality: 70);
        uploadBytes = Uint8List.fromList(compressed);
        debugPrint(
          'Supabase: Avatar compression complete (New: ${uploadBytes.length} bytes)',
        );
      }
    } catch (e) {
      debugPrint('Supabase: Avatar optimization failed: $e');
    }

    final fileName =
        'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    debugPrint('Supabase: Preparing avatar upload for $fileName...');

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
          'Supabase: Avatar upload attempt ${retryCount + 1} directly to storage...',
        );

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

        final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

        debugPrint('Supabase: Avatar upload successful! URL: $publicUrl');
        return publicUrl;
      } catch (e) {
        retryCount++;
        debugPrint('Supabase: Avatar upload attempt $retryCount failed: $e');

        if (e is StorageException &&
            (e.statusCode == '401' || e.statusCode == '403')) {
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

  @override
  Future<void> logSubscription(String userId, double amount, int months) async {
    try {
      debugPrint(
        'Supabase: Logging subscription for $userId: $amount ($months months)',
      );
      await _client.from('subscriptions').insert({
        'user_id': userId,
        'amount': amount,
        'duration_months': months,
        // created_at обычно заполняется автоматически в БД
      });
      debugPrint('Supabase: Subscription logged successfully.');
    } catch (e) {
      debugPrint('Supabase: Error logging subscription: $e');
      rethrow; // Выбрасываем ошибку, чтобы увидеть её в UI/логах
    }
  }
}
