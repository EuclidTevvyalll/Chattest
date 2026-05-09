import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_repository_provider.dart';

class ChatControllerState {
  final Map<String, List<MessageModel>> pendingMessages;
  final Set<String> deletingIds;

  ChatControllerState({
    this.pendingMessages = const {},
    this.deletingIds = const {},
  });

  ChatControllerState copyWith({
    Map<String, List<MessageModel>>? pendingMessages,
    Set<String>? deletingIds,
  }) {
    return ChatControllerState(
      pendingMessages: pendingMessages ?? this.pendingMessages,
      deletingIds: deletingIds ?? this.deletingIds,
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatControllerState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatControllerState> {
  @override
  ChatControllerState build() {
    return ChatControllerState();
  }

  Future<void> sendMessage(
    String roomId,
    String content,
    String currentUserId, {
    String? replyToMessageId,
    String? forwardedFrom,
    Map<String, dynamic>? forwardedInfo,
    String? mediaUrl,
    String? mediaType,
    String? mediaName,
  }) async {
    final temporaryMessage = MessageModel(
      id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      profileId: currentUserId,
      content: content,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      forwardedFrom: forwardedFrom,
      forwardedInfo: forwardedInfo,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaName: mediaName,
    );

    // Add to pending messages for this room
    final currentPending = state.pendingMessages[roomId] ?? [];
    state = state.copyWith(
      pendingMessages: {
        ...state.pendingMessages,
        roomId: [...currentPending, temporaryMessage],
      },
    );

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId,
            content,
            replyToMessageId: replyToMessageId,
            forwardedFrom: forwardedFrom,
            forwardedInfo: forwardedInfo,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            mediaName: mediaName,
          );

      // Remove pending after a delay, but don't block the caller
      Future.delayed(const Duration(seconds: 1)).then((_) {
        _removePending(roomId, temporaryMessage.id);
      });
    } catch (e) {
      _removePending(roomId, temporaryMessage.id);
      rethrow;
    }
  }

  Future<void> sendMediaMessage(
    String roomId,
    String currentUserId,
    Uint8List bytes,
    String fileName,
    String mediaType, {
    String? content,
  }) async {
    final temporaryMessage = MessageModel(
      id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      profileId: currentUserId,
      content: content ?? '',
      createdAt: DateTime.now(),
      mediaName: fileName,
      mediaType: mediaType,
    );

    // Add to pending messages immediately
    final currentPending = state.pendingMessages[roomId] ?? [];
    state = state.copyWith(
      pendingMessages: {
        ...state.pendingMessages,
        roomId: [...currentPending, temporaryMessage],
      },
    );

    try {
      debugPrint('ChatController: Starting media upload for $fileName');
      // 1. Upload the file
      final mediaUrl = await ref
          .read(chatRepositoryProvider)
          .uploadMedia(roomId, bytes, fileName, mediaType);
      
      debugPrint('ChatController: Media uploaded successfully: $mediaUrl');

      // 2. Send the real message
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId,
            content ?? '',
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            mediaName: fileName,
          );
      
      debugPrint('ChatController: Real message sent successfully');

      // Remove pending after a short delay to allow stream to catch up
      Future.delayed(const Duration(seconds: 1)).then((_) {
        _removePending(roomId, temporaryMessage.id);
      });
    } catch (e) {
      debugPrint('ChatController: Error sending media message: $e');
      _removePending(roomId, temporaryMessage.id);
      rethrow;
    }
  }

  Future<void> editMessage(
    String roomId,
    String messageId,
    String newContent,
  ) async {
    if (state.deletingIds.contains(messageId)) return;

    try {
      await ref.read(chatRepositoryProvider).editMessage(messageId, newContent);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    // If it's a temporary message, just remove it from local state
    if (messageId.startsWith('temp_')) {
      _removePending(roomId, messageId);
      return;
    }

    if (state.deletingIds.contains(messageId)) return;

    state = state.copyWith(
      deletingIds: {...state.deletingIds, messageId},
    );

    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
    } catch (e) {
      state = state.copyWith(
        deletingIds:
            state.deletingIds.where((id) => id != messageId).toSet(),
      );
      rethrow;
    }
  }

  Future<void> forwardMessages(
    String targetRoomId,
    List<MessageModel> messages,
    String currentUserId,
    List<ProfileModel> profiles, {
    Map<String, String>? replyContents, // Add reply contents map
  }) async {
    // Sort messages chronologically to preserve order in the target room
    final sortedMessages = List<MessageModel>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final msg in sortedMessages) {
      // Find original sender name
      final sender = profiles.where((p) => p.id == msg.profileId).firstOrNull;
      final senderName = sender?.nickname ??
          sender?.username ??
          (msg.profileId == currentUserId ? 'Вы' : 'Пользователь');

      // Check if we have reply content for this message
      final replyContent = replyContents?[msg.id];
      final replySender = msg.forwardedInfo?['replied_sender'] ?? 
                         (msg.replyToMessageId != null ? 'Сообщение' : null);

      await sendMessage(
        targetRoomId,
        msg.content,
        currentUserId,
        forwardedFrom: msg.id,
        forwardedInfo: {
          'sender_name': senderName,
          'sender_id': msg.profileId,
          'fwd_replied_content': ?replyContent,
          'fwd_replied_sender': ?replySender,
        },
        mediaUrl: msg.mediaUrl,
        mediaType: msg.mediaType,
        mediaName: msg.mediaName,
      );
      // Increased delay to ensure database timestamps and triggers are sequential
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> deleteMessages(String roomId, List<String> messageIds) async {
    // Filter out temporary messages and remove them locally
    final tempIds = messageIds.where((id) => id.startsWith('temp_')).toList();
    for (final id in tempIds) {
      _removePending(roomId, id);
    }

    final realIds = messageIds.where((id) => !id.startsWith('temp_')).toList();
    if (realIds.isEmpty) return;

    // Filter out already deleting IDs
    final idsToProcess =
        realIds.where((id) => !state.deletingIds.contains(id)).toList();
    if (idsToProcess.isEmpty) return;

    state = state.copyWith(
      deletingIds: {...state.deletingIds, ...idsToProcess},
    );

    try {
      await ref.read(chatRepositoryProvider).deleteMessages(idsToProcess);
    } catch (e) {
      state = state.copyWith(
        deletingIds: state.deletingIds
            .where((id) => !idsToProcess.contains(id))
            .toSet(),
      );
      rethrow;
    }
  }

  void _removePending(String roomId, String messageId) {
    final currentPending = state.pendingMessages[roomId] ?? [];
    state = state.copyWith(
      pendingMessages: {
        ...state.pendingMessages,
        roomId: currentPending.where((m) => m.id != messageId).toList(),
      },
    );
  }
}
