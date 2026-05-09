import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_repository_provider.dart';
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';

final roomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final user = ref.watch(authUserProvider);

  if (user == null) return Stream.value([]);

  return repo.watchRooms();
});

final contactsProvider = Provider<AsyncValue<List<ProfileModel>>>((ref) {
  final roomsAsync = ref.watch(roomsProvider);
  final currentUserId = ref.watch(authUserProvider)?.id;

  return roomsAsync.whenData((rooms) {
    final contacts = <String, ProfileModel>{};
    for (final room in rooms) {
      // Only extract participants from 1-on-1 rooms (type: room)
      if (room.type == RoomType.room) {
        for (final participant in room.participants) {
          if (participant.id != currentUserId) {
            contacts[participant.id] = participant;
          }
        }
      }
    }
    return contacts.values.toList();
  });
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  roomId,
) {
  final user = ref.watch(authUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(chatRepositoryProvider).watchMessages(roomId);
});

final messagesProvider = Provider.family<AsyncValue<List<MessageModel>>, String>((
  ref,
  roomId,
) {
  final messagesAsync = ref.watch(messagesStreamProvider(roomId));
  final pending = ref.watch(
    chatControllerProvider.select((s) => s.pendingMessages[roomId] ?? []),
  );

  return messagesAsync.whenData((messages) {
    if (pending.isEmpty) return messages;

    // Combine real messages with pending ones, avoiding duplicates
    final messageIds = messages.map((m) => m.id).toSet();
    final uniquePending = pending.where((pm) {
      // 1. Check by ID (direct match)
      if (messageIds.contains(pm.id)) return false;

      // 2. Check by content/sender/time to avoid duplicates while real message is arriving
      final hasMatchingReal = messages.any((m) {
        final isSameSender = m.profileId == pm.profileId;
        final isSameContent = m.content == pm.content;
        final isSameMedia =
            m.mediaName == pm.mediaName && m.mediaType == pm.mediaType;
        final isWithinTime =
            m.createdAt.difference(pm.createdAt).inSeconds.abs() < 60;

        return isSameSender && isSameContent && isSameMedia && isWithinTime;
      });

      return !hasMatchingReal;
    }).toList();

    if (uniquePending.isNotEmpty) {
      debugPrint(
        'messagesProvider: Combining ${messages.length} real and ${uniquePending.length} unique pending messages for room $roomId',
      );
    }

    final combined = [...messages, ...uniquePending];
    combined.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return combined;
  });
});


final roomParticipantsProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, roomId) {
      return ref.watch(chatRepositoryProvider).getRoomParticipants(roomId);
    });
