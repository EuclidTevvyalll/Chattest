import 'dart:typed_data';
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';

abstract class ChatRepository {
  Stream<List<RoomModel>> watchRooms();
  Stream<List<MessageModel>> watchMessages(
    String roomId, {
    RoomType type = RoomType.room,
  });
  Future<List<ProfileModel>> getProfiles();
  Future<ProfileModel?> getProfileByUsername(String username);
  Future<List<RoomModel>> searchPublicChannels(String query);

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
  });

  Future<String> uploadMedia(
    String roomId,
    Uint8List bytes,
    String fileName,
    String? contentType,
  );
  Future<String?> createRoom(List<String> participantIds);
  Future<String?> createGroup(String name, List<String> participantIds);
  Future<String?> createChannel(String name, String? description);
  Future<void> joinRoom(String roomId);
  Future<List<ProfileModel>> getRoomParticipants(String roomId);
  Future<void> toggleReaction(String messageId, String emoji);
  Future<void> editMessage(String messageId, String newContent);
  Future<void> deleteMessage(String messageId);
  Future<void> deleteMessages(List<String> messageIds);
  Future<void> reportTarget({
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  });
  Future<void> updateParticipantRole(
    String roomId,
    String profileId,
    String role,
  );
  Future<String?> transcribeVoiceMessage(String messageId, String audioUrl);
}
