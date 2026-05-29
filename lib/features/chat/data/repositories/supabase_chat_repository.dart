import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart' as dio;
import 'package:image/image.dart' as img;
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/chat/domain/repositories/chat_repository.dart';
import 'package:forgelink/core/services/transcription_service.dart';
import 'package:forgelink/core/services/censorship_service.dart';
import 'package:forgelink/core/config/supabase_config.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;
  // ignore: unused_field
  final dio.Dio _dio;

  SupabaseChatRepository(this._client, this._dio);

  @override
  Stream<List<RoomModel>> watchRooms() {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    return _client
        .from('room_participants')
        .stream(primaryKey: ['room_id', 'profile_id'])
        .eq('profile_id', myId)
        .asyncMap((participants) async {
          if (participants.isEmpty) return [];

          final roomIds = participants
              .map((p) => p['room_id']?.toString())
              .whereType<String>()
              .toSet()
              .toList();

          if (roomIds.isEmpty) return [];

          final List roomsData = await _client
              .from('rooms')
              .select('*, room_participants(role, profiles(*))')
              .filter('id', 'in', roomIds);

          final results = roomsData
              .map((roomMap) => _mapRoomData(roomMap))
              .toList();

          results.sort((a, b) {
            final timeA = a.lastMessageAt ?? a.createdAt;
            final timeB = b.lastMessageAt ?? b.createdAt;
            return timeB.compareTo(timeA);
          });

          return results;
        });
  }

  RoomModel _mapRoomData(dynamic roomMap) {
    final room = Map<String, dynamic>.from(roomMap);

    final lastMessageText = room['last_message']?.toString();
    final lastMessageTime = room['last_message_at'] != null
        ? DateTime.tryParse(room['last_message_at'].toString())
        : null;

    final participantsData = room['room_participants'] as List? ?? [];
    final participants = participantsData
        .map((p) {
          if (p['profiles'] == null) return null;
          var profile = ProfileModel.fromJson(p['profiles']);

          // Auto-expire check (Premium)
          if (profile.isPremium &&
              profile.premiumUntil != null &&
              profile.premiumUntil!.isBefore(DateTime.now())) {
            profile = profile.copyWith(isPremium: false, premiumUntil: null);
            // background update
            _client
                .from('profiles')
                .update({'is_premium': false, 'premium_until': null})
                .eq('id', profile.id)
                .then((_) {})
                .catchError((_) {});
          }

          // Auto-expire check (Ban)
          if (profile.isBanned == true &&
              profile.bannedUntil != null &&
              profile.bannedUntil!.isBefore(DateTime.now())) {
            profile = profile.copyWith(
              isBanned: false,
              bannedUntil: null,
              bannedReason: null,
            );
            // background update
            _client
                .from('profiles')
                .update({
                  'is_banned': false,
                  'banned_until': null,
                  'banned_reason': null,
                })
                .eq('id', profile.id)
                .then((_) {})
                .catchError((_) {});
          }

          return profile.copyWith(role: p['role']?.toString());
        })
        .whereType<ProfileModel>()
        .toList();

    return RoomModel(
      id: room['id']?.toString() ?? '',
      type: _parseRoomType(room['type']?.toString()),
      name: room['name']?.toString(),
      description: room['description']?.toString(),
      avatarUrl: room['avatar_url']?.toString(),
      createdAt:
          DateTime.tryParse(room['created_at']?.toString() ?? '') ??
          DateTime.now(),
      lastMessageAt: lastMessageTime,
      lastMessage: lastMessageText,
      lastMessageMediaUrl: room['last_message_media_url']?.toString(),
      lastMessageMediaType: room['last_message_media_type']?.toString(),
      lastMessageMediaName: room['last_message_media_name']?.toString(),
      createdBy: room['created_by']?.toString(),
      participants: participants,
    );
  }

  @override
  Future<List<RoomModel>> searchPublicChannels(String query) async {
    if (query.trim().isEmpty) return [];

    final List data = await _client
        .from('rooms')
        .select('*, room_participants(role, profiles(*))')
        .eq('type', 'channel')
        .ilike('name', '%$query%')
        .limit(20);

    return data.map((roomMap) => _mapRoomData(roomMap)).toList();
  }

  RoomType _parseRoomType(String? type) {
    if (type == 'group') return RoomType.group;
    if (type == 'channel') return RoomType.channel;
    return RoomType.room;
  }

  @override
  Stream<List<MessageModel>> watchMessages(
    String roomId, {
    RoomType type = RoomType.room,
  }) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((event) {
          return event
              .map((json) => MessageModel.fromJson(json))
              .where((m) => m.isDeleted != true)
              .toList()
              .reversed
              .toList();
        })
        .handleError((error) {
          debugPrint(
            'SupabaseChatRepository: ERROR in watchMessages for room $roomId: $error',
          );
        });
  }

  @override
  Future<void> sendMessage(
    String roomId,
    String content, {
    RoomType type = RoomType.room,
    String? replyToMessageId,
    String? forwardedFrom,
    Map<String, dynamic>? forwardedInfo,
    String? mediaUrl,
    String? mediaType,
    String? mediaName,
  }) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _client
            .from('messages')
            .insert({
              'room_id': roomId,
              'profile_id': myId,
              'content': content,
              'reply_to_message_id': replyToMessageId,
              'forwarded_from': forwardedFrom,
              'forwarded_info': forwardedInfo,
              'media_url': mediaUrl,
              'media_type': mediaType,
              'media_name': mediaName,
            })
            .timeout(const Duration(seconds: 15));

        return;
      } catch (e) {
        retryCount++;
        if (e is PostgrestException && e.code == '42501') {
          try {
            await _client.auth.refreshSession();
          } catch (_) {}
        }
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
      }
    }
  }

  @override
  Future<String> uploadMedia(
    String roomId,
    Uint8List bytes,
    String fileName,
    String? contentType,
  ) async {
    var uploadBytes = bytes;
    final mimeLower = contentType?.toLowerCase() ?? '';
    final fileLower = fileName.toLowerCase();

    // Determine target bucket based on file type
    String bucketName = 'chat-documents';
    if (mimeLower.startsWith('image/') ||
        fileLower.endsWith('.jpg') ||
        fileLower.endsWith('.jpeg') ||
        fileLower.endsWith('.png') ||
        fileLower.endsWith('.gif') ||
        fileLower.endsWith('.webp')) {
      bucketName = 'chat-images';
    } else if (mimeLower.startsWith('video/') ||
        fileLower.endsWith('.mp4') ||
        fileLower.endsWith('.mov')) {
      bucketName = 'chat-videos';
    } else if (mimeLower.startsWith('audio/') ||
        fileLower.endsWith('.mp3') ||
        fileLower.endsWith('.wav') ||
        fileLower.endsWith('.ogg') ||
        fileLower.endsWith('.m4a')) {
      bucketName = 'chat-audio';
    }

    // Compress if it's an image
    if (bucketName == 'chat-images') {
      debugPrint(
        'SupabaseChatRepository: Original image size: ${bytes.length} bytes',
      );
      try {
        final optimizedBytes = await compute(_optimizeImage, uploadBytes);
        if (optimizedBytes != null) {
          uploadBytes = optimizedBytes;
          debugPrint(
            'SupabaseChatRepository: Optimized image size: ${uploadBytes.length} bytes',
          );
        }
      } catch (e) {
        debugPrint('SupabaseChatRepository: Image optimization failed: $e');
      }
    }

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeFileName = fileName.replaceAll(
          RegExp(r'[^a-zA-Z0-9.\-_]'),
          '_',
        );
        final path = '$roomId/${timestamp}_$safeFileName';

        debugPrint(
          'SupabaseChatRepository: Uploading directly to storage bucket "$bucketName" at path: $path',
        );

        await _client.storage
            .from(bucketName)
            .uploadBinary(
              path,
              uploadBytes,
              fileOptions: FileOptions(
                contentType: contentType ?? 'application/octet-stream',
                upsert: true,
              ),
            );

        final publicUrl = _client.storage.from(bucketName).getPublicUrl(path);

        debugPrint(
          'SupabaseChatRepository: Storage upload successful! URL: $publicUrl',
        );
        return publicUrl;
      } catch (e) {
        retryCount++;
        debugPrint(
          'SupabaseChatRepository: Storage upload attempt $retryCount failed: $e',
        );

        if (e is StorageException &&
            (e.statusCode == '401' || e.statusCode == '403')) {
          try {
            await _client.auth.refreshSession();
          } catch (_) {}
        }

        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 2000 * retryCount));
      }
    }
    throw Exception('Upload failed after $maxRetries attempts');
  }

  @override
  Future<String?> createRoom(List<String> participantIds) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null || participantIds.isEmpty) return null;

    final allParticipants = {myId, ...participantIds}.toList();

    if (allParticipants.length == 2) {
      final otherId = participantIds.first;
      final List myRooms = await _client
          .from('room_participants')
          .select('room_id')
          .eq('profile_id', myId);

      final myRoomIds = myRooms.map((r) => r['room_id']).toList();

      if (myRoomIds.isNotEmpty) {
        final existing = await _client
            .from('room_participants')
            .select('room_id, rooms!inner(type)')
            .filter('room_id', 'in', myRoomIds)
            .eq('profile_id', otherId)
            .eq('rooms.type', 'direct')
            .limit(1)
            .maybeSingle();

        if (existing != null) {
          return existing['room_id']?.toString();
        }
      }
    }

    final roomData = await _client
        .from('rooms')
        .insert({
          'type': allParticipants.length > 2 ? 'group' : 'direct',
          'created_by': myId,
        })
        .select()
        .single();

    final roomId = roomData['id'].toString();

    final participantsInsert = allParticipants
        .map(
          (pid) => {
            'room_id': roomId,
            'profile_id': pid,
            'role': pid == myId ? 'owner' : 'member',
          },
        )
        .toList();

    await _client.from('room_participants').insert(participantsInsert);
    return roomId;
  }

  @override
  Future<String> createGroup(String name, List<String> participantIds) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Пользователь не авторизован');

    // Проверка уникальности названия
    final nameTaken = await isRoomNameTaken(name);
    if (nameTaken) {
      throw Exception('Название "$name" уже занято. Выберите другое название.');
    }

    final allParticipants = {myId, ...participantIds}.toList();

    final roomData = await _client
        .from('rooms')
        .insert({'type': 'group', 'name': name, 'created_by': myId})
        .select()
        .single();

    final roomId = roomData['id'].toString();

    final participantsInsert = allParticipants
        .map(
          (pid) => {
            'room_id': roomId,
            'profile_id': pid,
            'role': pid == myId ? 'owner' : 'member',
          },
        )
        .toList();

    await _client.from('room_participants').insert(participantsInsert);
    return roomId;
  }

  @override
  Future<String> createChannel(String name, String? description) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Пользователь не авторизован');

    // Проверка уникальности названия
    final nameTaken = await isRoomNameTaken(name);
    if (nameTaken) {
      throw Exception('Название "$name" уже занято. Выберите другое название.');
    }

    final roomData = await _client
        .from('rooms')
        .insert({
          'type': 'channel',
          'name': name,
          'description': description,
          'created_by': myId,
        })
        .select()
        .single();

    final roomId = roomData['id'].toString();

    await _client.from('room_participants').insert({
      'room_id': roomId,
      'profile_id': myId,
      'role': 'owner',
    });
    return roomId;
  }

  @override
  Future<void> joinRoom(String roomId) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    final existing = await _client
        .from('room_participants')
        .select()
        .eq('room_id', roomId)
        .eq('profile_id', myId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('room_participants').insert({
        'room_id': roomId,
        'profile_id': myId,
        'role': 'member',
      });
    }
  }

  @override
  Future<List<ProfileModel>> getProfiles() async {
    final data = await _client
        .from('profiles')
        .select('id, username, nickname, avatar_url, is_online, last_seen')
        .order('username');
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  @override
  Future<ProfileModel?> getProfileByUsername(String username) async {
    final data = await _client
        .from('profiles')
        .select('id, username, nickname, avatar_url, is_online, last_seen')
        .ilike('username', username)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  @override
  Future<List<ProfileModel>> getRoomParticipants(String roomId) async {
    final data = await _client
        .from('room_participants')
        .select(
          'role, profiles(id, username, nickname, avatar_url, is_online, last_seen, is_premium, premium_until, is_banned, banned_until, banned_reason)',
        )
        .eq('room_id', roomId);

    return (data as List)
        .map((p) {
          if (p['profiles'] == null) return null;
          var profile = ProfileModel.fromJson(p['profiles']);

          // Auto-expire check (Premium)
          if (profile.isPremium &&
              profile.premiumUntil != null &&
              profile.premiumUntil!.isBefore(DateTime.now())) {
            profile = profile.copyWith(isPremium: false, premiumUntil: null);
            // background update
            _client
                .from('profiles')
                .update({'is_premium': false, 'premium_until': null})
                .eq('id', profile.id)
                .then((_) {})
                .catchError((_) {});
          }

          // Auto-expire check (Ban)
          if (profile.isBanned == true &&
              profile.bannedUntil != null &&
              profile.bannedUntil!.isBefore(DateTime.now())) {
            profile = profile.copyWith(
              isBanned: false,
              bannedUntil: null,
              bannedReason: null,
            );
            // background update
            _client
                .from('profiles')
                .update({
                  'is_banned': false,
                  'banned_until': null,
                  'banned_reason': null,
                })
                .eq('id', profile.id)
                .then((_) {})
                .catchError((_) {});
          }

          return profile.copyWith(role: p['role']?.toString());
        })
        .whereType<ProfileModel>()
        .toList();
  }

  @override
  Future<void> toggleReaction(String messageId, String emoji) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    int retryCount = 0;
    const maxRetries = 5;

    while (retryCount < maxRetries) {
      try {
        final data = await _client
            .from('messages')
            .select('reactions')
            .eq('id', messageId)
            .single();

        final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
        final users = List<String>.from(reactions[emoji] ?? []);

        if (users.contains(myId)) {
          users.remove(myId);
        } else {
          users.add(myId);
        }

        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        await _client
            .from('messages')
            .update({'reactions': reactions})
            .eq('id', messageId);

        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<void> editMessage(String messageId, String newContent) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _client
            .from('messages')
            .update({
              'content': newContent,
              'is_edited': true,
              'edited_at': DateTime.now().toIso8601String(),
            })
            .eq('id', messageId);
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _client
            .from('messages')
            .update({
              'is_deleted': true,
              'deleted_at': DateTime.now().toIso8601String(),
              'deleted_by': _client.auth.currentUser?.id,
            })
            .eq('id', messageId);
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<void> deleteMessages(List<String> messageIds) async {
    if (messageIds.isEmpty) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _client
            .from('messages')
            .update({
              'is_deleted': true,
              'deleted_at': DateTime.now().toIso8601String(),
              'deleted_by': _client.auth.currentUser?.id,
            })
            .inFilter('id', messageIds);
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<void> reportTarget({
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  }) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    await _client.from('reports').insert({
      'reporter_id': myId,
      'target_id': targetId,
      'target_type': targetType,
      'reason': reason,
      'details': details,
    });

    // Invoke Edge Function directly to output ИИ moderation logs to the debug console
    try {
      debugPrint('SupabaseChatRepository: Invoking auto-moderate Edge Function...');
      final response = await _client.functions.invoke(
        'auto-moderate',
        body: {
          'record': {
            'id': 'client-direct-call',
            'reporter_id': myId,
            'target_id': targetId,
            'target_type': targetType,
            'reason': reason,
            'details': details,
          }
        },
      );
      debugPrint('SupabaseChatRepository: AI Moderation status code: ${response.status}');
      debugPrint('SupabaseChatRepository: AI Moderation response data: ${response.data}');
    } catch (e) {
      debugPrint('SupabaseChatRepository: Error calling auto-moderate function directly: $e');
    }
  }

  @override
  Future<void> updateParticipantRole(
    String roomId,
    String profileId,
    String role,
  ) async {
    try {
      await _client
          .from('room_participants')
          .update({'role': role})
          .eq('room_id', roomId)
          .eq('profile_id', profileId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;
    await _client
        .from('room_participants')
        .delete()
        .eq('room_id', roomId)
        .eq('profile_id', myId)
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _client
        .from('rooms')
        .delete()
        .eq('id', roomId)
        .timeout(const Duration(seconds: 10));
  }

  @override
  Stream<RoomModel?> watchRoom(String roomId) {
    return _client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .asyncMap((roomsList) async {
          if (roomsList.isEmpty) return null;
          try {
            final data = await _client
                .from('rooms')
                .select('*, room_participants(role, profiles(*))')
                .eq('id', roomId)
                .maybeSingle()
                .timeout(const Duration(seconds: 10));
            if (data == null) return null;
            return _mapRoomData(data);
          } catch (e) {
            debugPrint(
              'SupabaseChatRepository: Error in watchRoom asyncMap: $e',
            );
            return null;
          }
        });
  }

  @override
  Stream<List<ProfileModel>> watchRoomParticipants(String roomId) {
    return _client
        .from('room_participants')
        .stream(primaryKey: ['room_id', 'profile_id'])
        .eq('room_id', roomId)
        .asyncMap((participantsList) async {
          try {
            return await getRoomParticipants(
              roomId,
            ).timeout(const Duration(seconds: 10));
          } catch (e) {
            debugPrint(
              'SupabaseChatRepository: Error in watchRoomParticipants asyncMap: $e',
            );
            return [];
          }
        });
  }

  @override
  Future<String?> transcribeVoiceMessage(
    String messageId,
    String audioUrl,
  ) async {
    try {
      debugPrint(
        'SupabaseChatRepository: Checking existing transcription for $messageId',
      );

      // Сначала проверяем, есть ли уже перевод в базе данных
      final dbResult = await _client
          .from('messages')
          .select('transcription')
          .eq('id', messageId)
          .maybeSingle();

      if (dbResult != null && dbResult['transcription'] != null) {
        final existingText = dbResult['transcription'] as String;
        if (existingText.trim().isNotEmpty) {
          debugPrint(
            'SupabaseChatRepository: Found cached transcription in DB',
          );
          return existingText;
        }
      }

      debugPrint(
        'SupabaseChatRepository: Transcribing audio $audioUrl from API',
      );
      final service = TranscriptionService(SupabaseConfig.deepgramApiKey);
      final transcription = await service.transcribe(audioUrl);

      if (transcription == null) return null;

      final censoredTranscription = CensorshipService.censor(transcription);

      // Сохраняем результат в базу данных для кэширования
      await _client
          .from('messages')
          .update({'transcription': censoredTranscription})
          .eq('id', messageId);

      return censoredTranscription;
    } catch (e) {
      debugPrint('SupabaseChatRepository: Transcription error: $e');
      return null;
    }
  }

  static Uint8List? _optimizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    img.Image resized = image;
    if (image.width > 1200 || image.height > 1200) {
      if (image.width > image.height) {
        resized = img.copyResize(
          image,
          width: 1200,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = img.copyResize(
          image,
          height: 1200,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }

  @override
  Future<void> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isEmpty) return;

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _client
            .from('rooms')
            .update(updates)
            .eq('id', roomId)
            .timeout(const Duration(seconds: 10));
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<bool> isRoomNameTaken(String name, {String? excludeRoomId}) async {
    try {
      var query = _client
          .from('rooms')
          .select('id')
          .ilike('name', name)
          .inFilter('type', ['group', 'channel']);

      if (excludeRoomId != null) {
        query = query.neq('id', excludeRoomId);
      }

      final result = await query.maybeSingle();
      return result != null;
    } catch (e) {
      debugPrint('SupabaseChatRepository: Error checking room name: $e');
      return false;
    }
  }
}
