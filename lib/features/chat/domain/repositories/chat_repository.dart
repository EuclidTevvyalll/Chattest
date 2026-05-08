import 'package:rickandmorty/features/chat/domain/models/message_model.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';

abstract class ChatRepository {
  Stream<List<RoomModel>> watchRooms();
  Stream<List<MessageModel>> watchMessages(String roomId, {RoomType type = RoomType.room});
  Future<List<ProfileModel>> getProfiles();
  Future<ProfileModel?> getProfileByUsername(String username);

  Future<void> sendMessage(String roomId, String content, {RoomType type = RoomType.room, String? replyToMessageId});
  Future<String?> createRoom(List<String> participantIds);
  Future<String?> createGroup(String name, List<String> participantIds);
  Future<String?> createChannel(String name, String? description);
  Future<List<ProfileModel>> getRoomParticipants(String roomId);
  Future<void> toggleReaction(String messageId, String emoji);
}
