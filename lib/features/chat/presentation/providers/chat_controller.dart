import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/chat/domain/models/message_model.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';

final chatControllerProvider =
    NotifierProvider<ChatController, Map<String, List<MessageModel>>>(
      ChatController.new,
    );

class ChatController extends Notifier<Map<String, List<MessageModel>>> {
  @override
  Map<String, List<MessageModel>> build() {
    return {};
  }

  // To prevent double-clicks and excessive requests
  final Set<String> _processingIds = {};

  Future<void> sendMessage(
    String roomId,
    String content,
    String currentUserId, {
    String? replyToMessageId,
  }) async {
    final temporaryMessage = MessageModel(
      id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      profileId: currentUserId,
      content: content,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
    );

    // Add to pending messages for this room
    state = {
      ...state,
      roomId: [...(state[roomId] ?? []), temporaryMessage],
    };

    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(roomId, content, replyToMessageId: replyToMessageId);

      // Wait a bit before removing pending to ensure the stream has time to catch up
      await Future.delayed(const Duration(seconds: 1));
      _removePending(roomId, temporaryMessage.id);
    } catch (e) {
      _removePending(roomId, temporaryMessage.id);
      rethrow;
    }
  }

  Future<void> editMessage(
    String roomId,
    String messageId,
    String newContent,
  ) async {
    if (_processingIds.contains(messageId)) return;
    _processingIds.add(messageId);

    try {
      await ref.read(chatRepositoryProvider).editMessage(messageId, newContent);
    } finally {
      _processingIds.remove(messageId);
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    debugPrint('ChatController: Deleting message $messageId from room $roomId');

    // If it's a temporary message, just remove it from local state
    if (messageId.startsWith('temp_')) {
      debugPrint('ChatController: Removing temporary message locally');
      _removePending(roomId, messageId);
      return;
    }

    if (_processingIds.contains(messageId)) return;
    _processingIds.add(messageId);

    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
      debugPrint('ChatController: Deletion request sent to repository');
    } finally {
      _processingIds.remove(messageId);
    }
  }

  void _removePending(String roomId, String messageId) {
    final currentPending = state[roomId] ?? [];
    state = {
      ...state,
      roomId: currentPending.where((m) => m.id != messageId).toList(),
    };
  }
}
