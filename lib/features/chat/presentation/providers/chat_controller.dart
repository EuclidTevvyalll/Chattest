import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/chat/domain/models/message_model.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';

final chatControllerProvider = NotifierProvider<ChatController, Map<String, List<MessageModel>>>(ChatController.new);

class ChatController extends Notifier<Map<String, List<MessageModel>>> {
  @override
  Map<String, List<MessageModel>> build() {
    return {};
  }

  Future<void> sendMessage(String roomId, String content, String currentUserId, {String? replyToMessageId}) async {
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
      await ref.read(chatRepositoryProvider).sendMessage(
        roomId,
        content,
        replyToMessageId: replyToMessageId,
      );
      
      // Proactively refresh the rooms list
      ref.invalidate(roomsProvider);
      
      // Wait longer before removing pending to ensure the stream has time to catch up
      // The screen logic will handle deduplication if the real message arrives earlier
      await Future.delayed(const Duration(seconds: 5));
      _removePending(roomId, temporaryMessage.id);
    } catch (e) {
      _removePending(roomId, temporaryMessage.id);
      rethrow;
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
