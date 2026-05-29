import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_repository_provider.dart';
import 'package:forgelink/core/services/censorship_service.dart';
import 'package:forgelink/core/services/duplicate_detector.dart';

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
    NotifierProvider<ChatController, ChatControllerState>(ChatController.new);

class ChatController extends Notifier<ChatControllerState> {
  String? _lastSentContent;
  DateTime? _lastSentTime;

  @override
  ChatControllerState build() {
    return ChatControllerState();
  }

  Future<String?> sendMessage(
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
    if (content.trim().isNotEmpty && forwardedFrom == null) {
      final now = DateTime.now();
      if (_lastSentContent != null && _lastSentTime != null) {
        final timeDiff = now.difference(_lastSentTime!);
        if (timeDiff.inSeconds < 5) {
          final isDup = DuplicateDetector.isDuplicate(content, _lastSentContent!);
          if (isDup) {
            return 'Пожалуйста, не отправляйте похожие сообщения слишком часто.';
          }
        }
      }
      _lastSentContent = content;
      _lastSentTime = now;
    }

    final censoredContent = CensorshipService.censor(content);
    final temporaryMessage = MessageModel(
      id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      profileId: currentUserId,
      content: censoredContent,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      forwardedFrom: forwardedFrom,
      forwardedInfo: forwardedInfo,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaName: mediaName,
    );
    final currentPending = state.pendingMessages[roomId] ?? [];
    state = state.copyWith(
      pendingMessages: {
        ...state.pendingMessages,
        roomId: [...currentPending, temporaryMessage],
      },
    );
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            roomId,
            censoredContent,
            replyToMessageId: replyToMessageId,
            forwardedFrom: forwardedFrom,
            forwardedInfo: forwardedInfo,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            mediaName: mediaName,
          );
      Future.delayed(const Duration(seconds: 1)).then((_) {
        _removePending(roomId, temporaryMessage.id);
      });
      return null;
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
    final censoredContent = content != null ? CensorshipService.censor(content) : null;
    final temporaryMessage = MessageModel(
      id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      profileId: currentUserId,
      content: censoredContent ?? '',
      createdAt: DateTime.now(),
      mediaName: fileName,
      mediaType: mediaType,
    );
    final currentPending = state.pendingMessages[roomId] ?? [];
    state = state.copyWith(
      pendingMessages: {
        ...state.pendingMessages,
        roomId: [...currentPending, temporaryMessage],
      },
    );
    _enqueueUpload(() async {
      try {
        debugPrint('ChatController: Starting media upload for $fileName');
        final mediaUrl = await ref
            .read(chatRepositoryProvider)
            .uploadMedia(roomId, bytes, fileName, mediaType);
        debugPrint('ChatController: Media uploaded successfully: $mediaUrl');
        await ref
            .read(chatRepositoryProvider)
            .sendMessage(
              roomId,
              censoredContent ?? '',
              mediaUrl: mediaUrl,
              mediaType: mediaType,
              mediaName: fileName,
            );
        debugPrint('ChatController: Real message sent successfully');
        Future.delayed(const Duration(seconds: 1)).then((_) {
          _removePending(roomId, temporaryMessage.id);
        });
      } catch (e) {
        debugPrint('ChatController: Error sending media message: $e');
        _removePending(roomId, temporaryMessage.id);
        rethrow;
      }
    });
  }

  final List<Future<void> Function()> _uploadQueue = [];
  bool _isProcessingQueue = false;
  void _enqueueUpload(Future<void> Function() uploadTask) {
    _uploadQueue.add(uploadTask);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    while (_uploadQueue.isNotEmpty) {
      final task = _uploadQueue.removeAt(0);
      try {
        await task();
      } catch (e) {
        debugPrint('ChatController: Queue task failed: $e');
      }
    }
    _isProcessingQueue = false;
  }

  Future<void> editMessage(
    String roomId,
    String messageId,
    String newContent,
  ) async {
    if (state.deletingIds.contains(messageId)) return;
    try {
      final censoredContent = CensorshipService.censor(newContent);
      await ref.read(chatRepositoryProvider).editMessage(messageId, censoredContent);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    if (messageId.startsWith('temp_')) {
      _removePending(roomId, messageId);
      return;
    }
    if (state.deletingIds.contains(messageId)) return;
    state = state.copyWith(deletingIds: {...state.deletingIds, messageId});
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
    } catch (e) {
      state = state.copyWith(
        deletingIds: state.deletingIds.where((id) => id != messageId).toSet(),
      );
      rethrow;
    }
  }

  Future<void> forwardMessages(
    String targetRoomId,
    List<MessageModel> messages,
    String currentUserId,
    List<ProfileModel> profiles, {
    Map<String, String>? replyContents,
  }) async {
    final sortedMessages = List<MessageModel>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final msg in sortedMessages) {
      final sender = profiles.where((p) => p.id == msg.profileId).firstOrNull;
      final senderName =
          sender?.nickname ??
          sender?.username ??
          (msg.profileId == currentUserId ? 'Вы' : 'Пользователь');
      final replyContent = replyContents?[msg.id];
      final replySender =
          msg.forwardedInfo?['replied_sender'] ??
          (msg.replyToMessageId != null ? 'Сообщение' : null);
      await sendMessage(
        targetRoomId,
        msg.content,
        currentUserId,
        forwardedFrom: msg.id,
        forwardedInfo: {
          'sender_name': senderName,
          'sender_id': msg.profileId,
          'fwd_replied_content': replyContent,
          'fwd_replied_sender': replySender,
        },
        mediaUrl: msg.mediaUrl,
        mediaType: msg.mediaType,
        mediaName: msg.mediaName,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> deleteMessages(String roomId, List<String> messageIds) async {
    final tempIds = messageIds.where((id) => id.startsWith('temp_')).toList();
    for (final id in tempIds) {
      _removePending(roomId, id);
    }
    final realIds = messageIds.where((id) => !id.startsWith('temp_')).toList();
    if (realIds.isEmpty) return;
    final idsToProcess = realIds
        .where((id) => !state.deletingIds.contains(id))
        .toList();
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

  Future<String?> createRoom(List<String> participantIds) async {
    try {
      final roomId = await ref
          .read(chatRepositoryProvider)
          .createRoom(participantIds);
      ref.invalidate(roomsProvider);
      if (roomId != null) ref.invalidate(roomParticipantsProvider(roomId));
      return roomId;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> createGroup(String name, List<String> participantIds) async {
    try {
      final roomId = await ref
          .read(chatRepositoryProvider)
          .createGroup(name, participantIds);
      ref.invalidate(roomsProvider);
      if (roomId != null) ref.invalidate(roomParticipantsProvider(roomId));
      return roomId;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> createChannel(String name, String description) async {
    try {
      final roomId = await ref
          .read(chatRepositoryProvider)
          .createChannel(name, description);
      ref.invalidate(roomsProvider);
      if (roomId != null) ref.invalidate(roomParticipantsProvider(roomId));
      return roomId;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      await ref.read(chatRepositoryProvider).joinRoom(roomId);
      ref.invalidate(roomsProvider);
      ref.invalidate(roomParticipantsProvider(roomId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateParticipantRole(
    String roomId,
    String profileId,
    String role,
  ) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateParticipantRole(roomId, profileId, role);
      ref.invalidate(roomParticipantsProvider(roomId));
      ref.invalidate(roomsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      await ref.read(chatRepositoryProvider).leaveRoom(roomId);
      ref.invalidate(roomsProvider);
      ref.invalidate(roomParticipantsProvider(roomId));
      ref.invalidate(roomProvider(roomId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await ref.read(chatRepositoryProvider).deleteRoom(roomId);
      ref.invalidate(roomsProvider);
      ref.invalidate(roomParticipantsProvider(roomId));
      ref.invalidate(roomProvider(roomId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      await ref
          .read(chatRepositoryProvider)
          .updateRoom(
            roomId: roomId,
            name: name,
            description: description,
            avatarUrl: avatarUrl,
          );
      ref.invalidate(roomProvider(roomId));
      ref.invalidate(roomsProvider);
    } catch (e) {
      rethrow;
    }
  }
}
