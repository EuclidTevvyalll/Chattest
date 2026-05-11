import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/chat/domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;

  SupabaseChatRepository(this._client);

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

          final results = roomsData.map((roomMap) => _mapRoomData(roomMap)).toList();

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
          final profile = ProfileModel.fromJson(p['profiles']);
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
      createdAt: DateTime.tryParse(room['created_at']?.toString() ?? '') ??
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
        }).handleError((error) {
          debugPrint('SupabaseChatRepository: ERROR in watchMessages for room $roomId: $error');
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
        await _client.from('messages').insert({
          'room_id': roomId,
          'profile_id': myId,
          'content': content,
          'reply_to_message_id': replyToMessageId,
          'forwarded_from': forwardedFrom,
          'forwarded_info': forwardedInfo,
          'media_url': mediaUrl,
          'media_type': mediaType,
          'media_name': mediaName,
        }).timeout(const Duration(seconds: 15));
        
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
  Future<String> uploadMedia(String roomId, Uint8List bytes, String fileName,
      String? contentType) async {
    var uploadBytes = bytes;
    
    // Compress if it's an image
    if (contentType?.startsWith('image/') == true || 
        fileName.toLowerCase().endsWith('.jpg') || 
        fileName.toLowerCase().endsWith('.jpeg') || 
        fileName.toLowerCase().endsWith('.png')) {
      try {
        final image = img.decodeImage(uploadBytes);
        if (image != null) {
          img.Image resized = image;
          if (image.width > 1200 || image.height > 1200) {
            resized = img.copyResize(image, width: 1200, height: 1200, interpolation: img.Interpolation.linear);
          }
          final compressed = img.encodeJpg(resized, quality: 75);
          uploadBytes = Uint8List.fromList(compressed);
        }
      } catch (e) {
        debugPrint('SupabaseChatRepository: Image optimization failed: $e');
      }
    }

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final session = _client.auth.currentSession;
        if (session == null) {
          await _client.auth.refreshSession();
        }
        
        final path = '$roomId/$fileName';
        
        // Determine bucket name based on file type
        String bucket = 'chat-documents';
        if (contentType?.startsWith('image/') == true || 
            fileName.toLowerCase().endsWith('.jpg') || 
            fileName.toLowerCase().endsWith('.jpeg') || 
            fileName.toLowerCase().endsWith('.png')) {
          bucket = 'chat-images';
        } else if (contentType?.startsWith('video/') == true) {
          bucket = 'chat-videos';
        } else if (contentType?.startsWith('audio/') == true) {
          bucket = 'chat-audio';
        }

        debugPrint('SupabaseChatRepository: Uploading to bucket $bucket: $path');

        // Upload to the appropriate bucket
        await _client.storage.from(bucket).uploadBinary(
          path,
          uploadBytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'application/octet-stream',
            upsert: true,
          ),
        );

        // Get public URL
        final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
        debugPrint('SupabaseChatRepository: Direct upload successful! URL: $publicUrl');
        return publicUrl;
      } catch (e) {
        retryCount++;
        debugPrint('SupabaseChatRepository: Storage upload attempt $retryCount failed: $e');
        
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
        .select('id, username, nickname, avatar_url, is_online')
        .order('username');
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  @override
  Future<ProfileModel?> getProfileByUsername(String username) async {
    final data = await _client
        .from('profiles')
        .select('id, username, nickname, avatar_url, is_online')
        .ilike('username', username)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  @override
  Future<List<ProfileModel>> getRoomParticipants(String roomId) async {
    final data = await _client
        .from('room_participants')
        .select('role, profiles(id, username, nickname, avatar_url, is_online)')
        .eq('room_id', roomId);

    return (data as List)
        .map((p) {
          if (p['profiles'] == null) return null;
          final profile = ProfileModel.fromJson(p['profiles']);
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
}
