import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rickandmorty/features/chat/domain/models/message_model.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/chat/domain/repositories/chat_repository.dart';

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
              .toList();

          if (roomIds.isEmpty) return [];

          final List roomsData = await _client
              .from('rooms')
              .select('*, room_participants(profiles(*)), messages(content, created_at)')
              .inFilter('id', roomIds)
              .order('created_at', referencedTable: 'messages', ascending: false)
              .limit(1, referencedTable: 'messages');

          return roomsData.map((roomMap) {
            final room = Map<String, dynamic>.from(roomMap);
            final participantsRaw = room['room_participants'] as List?;
            
            final participantsList = (participantsRaw ?? [])
                .map((p) => p['profiles'] != null ? ProfileModel.fromJson(p['profiles']) : null)
                .whereType<ProfileModel>()
                .toList();

            // Get the last message from the nested messages list
            final messages = room['messages'] as List?;
            final lastMessageText = (messages != null && messages.isNotEmpty) 
                ? messages.first['content']?.toString() 
                : null;

            return RoomModel(
              id: room['id']?.toString() ?? '',
              type: _parseRoomType(room['type']?.toString()),
              name: room['name']?.toString(),
              description: room['description']?.toString(),
              avatarUrl: room['avatar_url']?.toString(),
              createdAt: DateTime.tryParse(room['created_at']?.toString() ?? '') ?? DateTime.now(),
              lastMessageAt: DateTime.tryParse(room['last_message_at']?.toString() ?? ''),
              lastMessage: lastMessageText,
              createdBy: room['created_by']?.toString(),
              participants: participantsList,
            );
          }).toList();
        });
  }

  RoomType _parseRoomType(String? type) {
    if (type == 'group') return RoomType.group;
    if (type == 'channel') return RoomType.channel;
    return RoomType.room;
  }

  @override
  Stream<List<MessageModel>> watchMessages(String roomId, {RoomType type = RoomType.room}) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false) // Order by latest first for the stream
        .limit(50)
        .map((event) => event
            .map((json) => MessageModel.fromJson(json))
            .toList()
            .reversed // Reverse locally to show in chronological order if needed, or keep for reverse ListView
            .toList());
  }

  @override
  Future<void> sendMessage(
    String roomId,
    String content, {
    RoomType type = RoomType.room,
  }) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    await _client.from('messages').insert({
      'room_id': roomId,
      'profile_id': myId,
      'content': content,
    });

    // Update last_message_at in background to avoid blocking and potential timeouts
    _client.from('rooms').update({
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId).then((_) {}).catchError((_) {});
  }

  @override
  Future<String?> createRoom(List<String> participantIds) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null || participantIds.isEmpty) return null;

    final allParticipants = {myId, ...participantIds}.toList();

    // Check if a direct room already exists
    if (allParticipants.length == 2) {
      final otherId = participantIds.first;
      
      // Fetch all direct rooms where I am a participant, including all other participants of those rooms
      final List myDirectRooms = await _client
          .from('room_participants')
          .select('room_id, rooms!inner(type), all_participants:room_participants(profile_id)')
          .eq('profile_id', myId)
          .eq('rooms.type', 'direct');

      for (final room in myDirectRooms) {
        final participants = room['all_participants'] as List? ?? [];
        // If any participant in this room matches the otherId, the room already exists
        final hasOtherUser = participants.any((p) => p['profile_id'] == otherId);
        if (hasOtherUser) return room['room_id']?.toString();
      }
    }

    // Create room
    final roomData = await _client.from('rooms').insert({
      'type': allParticipants.length > 2 ? 'group' : 'direct',
      'created_by': myId,
    }).select().single();

    final roomId = roomData['id'].toString();

    // Add participants
    final participantsInsert = allParticipants.map((pid) => {
      'room_id': roomId,
      'profile_id': pid,
      'role': pid == myId ? 'owner' : 'member',
    }).toList();

    await _client.from('room_participants').insert(participantsInsert);
    return roomId;
  }

  @override
  Future<String> createGroup(String name, List<String> participantIds) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Пользователь не авторизован');

    final allParticipants = {myId, ...participantIds}.toList();

    final roomData = await _client.from('rooms').insert({
      'type': 'group',
      'name': name,
      'created_by': myId,
    }).select().single();

    final roomId = roomData['id'].toString();

    final participantsInsert = allParticipants.map((pid) => {
      'room_id': roomId,
      'profile_id': pid,
      'role': pid == myId ? 'owner' : 'member',
    }).toList();

    await _client.from('room_participants').insert(participantsInsert);
    return roomId;
  }

  @override
  Future<String> createChannel(String name, String? description) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) throw Exception('Пользователь не авторизован');

    final roomData = await _client.from('rooms').insert({
      'type': 'channel',
      'name': name,
      'description': description,
      'created_by': myId,
    }).select().single();

    final roomId = roomData['id'].toString();

    await _client.from('room_participants').insert({
      'room_id': roomId,
      'profile_id': myId,
      'role': 'owner',
    });
    return roomId;
  }

  @override
  Future<List<ProfileModel>> getProfiles() async {
    final data = await _client.from('profiles').select().order('username');
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  @override
  Future<ProfileModel?> getProfileByUsername(String username) async {
    final data = await _client
        .from('profiles')
        .select()
        .ilike('username', username)
        .maybeSingle();
    
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }
}
