import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // We listen to room_participants to know which rooms the user is in.
    // To make it update on new messages, we'll also 'touch' the room_participants
    // or rely on the rooms table updates if we add a trigger.
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

          // Fetch rooms directly. They are updated by the database trigger on every new message.
          final List roomsData = await _client
              .from('rooms')
              .select('*, room_participants(role, profiles(*))')
              .filter('id', 'in', roomIds);

          final results = roomsData.map((roomMap) => _mapRoomData(roomMap)).toList();

          // Sorting: latest activity first
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
    debugPrint('SupabaseChatRepository: Watching messages for room $roomId');
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((event) {
          debugPrint(
            'SupabaseChatRepository: Stream event received with ${event.length} total messages',
          );
          for (var m in event) {
            if (m['is_deleted'] == true) {
              debugPrint('SupabaseChatRepository: Found deleted message in stream: ${m['id']}');
            }
          }
          return event
              .map((json) => MessageModel.fromJson(json))
              .where((m) => m.isDeleted != true) // Always hide deleted messages
              .toList()
              .reversed
              .toList();
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
        });
        return;
      } catch (e) {
        retryCount++;
        debugPrint('SupabaseChatRepository: Send attempt $retryCount failed: $e');
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<String> uploadMedia(String roomId, Uint8List bytes, String fileName,
      String? contentType) async {
    try {
      final sizeMb = bytes.length / (1024 * 1024);
      debugPrint('SupabaseChatRepository: Uploading $fileName (${sizeMb.toStringAsFixed(2)} MB) via Edge Function...');
      
      final base64File = base64Encode(bytes);
      debugPrint('SupabaseChatRepository: Base64 encoding complete, size: ${base64File.length} chars');
      
      final response = await _client.functions.invoke(
        'upload-media',
        body: {
          'roomId': roomId,
          'fileName': fileName,
          'fileBase64': base64File,
          'contentType': contentType ?? 'application/octet-stream',
        },
      );

      debugPrint('SupabaseChatRepository: Edge Function response status: ${response.status}');

      if (response.status == 200 || response.status == 201) {
        final data = response.data;
        if (data is Map && data.containsKey('url')) {
          debugPrint('SupabaseChatRepository: Upload successful! URL: ${data['url']}');
          return data['url'];
        }
        throw Exception('Invalid response from Edge Function: ${response.data}');
      } else {
        debugPrint('SupabaseChatRepository: Edge Function failed with status ${response.status}: ${response.data}');
        throw Exception('Edge Function Error (Status ${response.status}): ${response.data}');
      }
    } catch (e) {
      debugPrint('SupabaseChatRepository: Upload failed with error: $e');
      rethrow;
    }
  }

  @override
  Future<String?> createRoom(List<String> participantIds) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null || participantIds.isEmpty) return null;

    final allParticipants = {myId, ...participantIds}.toList();

    // Check if a direct room already exists
    if (allParticipants.length == 2) {
      final otherId = participantIds.first;

      // Manual check for existing direct room
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

    // Create room
    final roomData = await _client
        .from('rooms')
        .insert({
          'type': allParticipants.length > 2 ? 'group' : 'direct',
          'created_by': myId,
        })
        .select()
        .single();

    final roomId = roomData['id'].toString();

    // Add participants
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

    // Check if already a participant to avoid unique constraint error
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
        // 1. Fetch current reactions
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

        // 2. Update reactions
        await _client
            .from('messages')
            .update({'reactions': reactions})
            .eq('id', messageId);

        debugPrint('Supabase: Reaction toggled successfully.');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('Supabase: Toggle reaction attempt $retryCount failed: $e');
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Small delay before next attempt
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
        debugPrint('SupabaseChatRepository: Edit attempt $retryCount failed: $e');
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    debugPrint('SupabaseChatRepository: Deleting message $messageId');

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Use soft delete by setting is_deleted = true
        await _client
            .from('messages')
            .update({
              'is_deleted': true,
              'deleted_at': DateTime.now().toIso8601String(),
              'deleted_by': _client.auth.currentUser?.id,
            })
            .eq('id', messageId);
        debugPrint('SupabaseChatRepository: Soft delete successful');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('SupabaseChatRepository: Delete attempt $retryCount failed: $e');
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  @override
  Future<void> deleteMessages(List<String> messageIds) async {
    debugPrint('SupabaseChatRepository: Deleting ${messageIds.length} messages');
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
        debugPrint('SupabaseChatRepository: Bulk soft delete successful');
        return;
      } catch (e) {
        retryCount++;
        debugPrint('SupabaseChatRepository: Bulk delete attempt $retryCount failed: $e');
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
      debugPrint('Error updating participant role: $e');
      rethrow;
    }
  }
}
