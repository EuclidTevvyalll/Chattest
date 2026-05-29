import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_repository_provider.dart';
import 'package:forgelink/features/chat/domain/models/message_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';

class ChatSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final chatSearchQueryProvider = NotifierProvider<ChatSearchQuery, String>(
  ChatSearchQuery.new,
);

final roomsProvider = StreamProvider.autoDispose<List<RoomModel>>((ref) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    timer = Timer(const Duration(seconds: 30), () {
      link.close();
    });
  });
  ref.onDispose(() => timer?.cancel());

  final repo = ref.watch(chatRepositoryProvider);
  final user = ref.watch(authUserProvider);

  if (user == null) return Stream.value([]);

  return repo.watchRooms();
});

final globalChannelSearchProvider =
    FutureProvider.family<List<RoomModel>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final repo = ref.watch(chatRepositoryProvider);
      return repo.searchPublicChannels(query);
    });

final filteredRoomsProvider = Provider<AsyncValue<List<RoomModel>>>((ref) {
  final roomsAsync = ref.watch(roomsProvider);
  final query = ref.watch(chatSearchQueryProvider).trim().toLowerCase();
  final currentUserId = ref.watch(authUserProvider)?.id;

  if (query.isEmpty) return roomsAsync;

  final globalChannelsAsync = ref.watch(globalChannelSearchProvider(query));

  return roomsAsync.when(
    data: (localRooms) {
      final filteredLocal = localRooms.where((room) {
        final name = (room.name ?? '').trim().toLowerCase();
        final nameMatches = name.contains(query);

        final lastMsg = (room.lastMessage ?? '').trim().toLowerCase();
        final messageMatches = lastMsg.contains(query);

        final participantMatches =
            room.type == RoomType.room &&
            room.participants.any((p) {
              if (p.id == currentUserId) return false;

              final username = p.username.trim().toLowerCase();
              final nickname = (p.nickname ?? '').trim().toLowerCase();

              String normalize(String s) => s
                  .replaceAll('a', 'а')
                  .replaceAll('e', 'е')
                  .replaceAll('o', 'о')
                  .replaceAll('p', 'р')
                  .replaceAll('c', 'с')
                  .replaceAll('x', 'х');

              final normQuery = normalize(query);
              final normUser = normalize(username);
              final normNick = normalize(nickname);

              final matches =
                  username.contains(query) ||
                  nickname.contains(query) ||
                  normUser.contains(normQuery) ||
                  normNick.contains(normQuery);

              if (kDebugMode && query.isNotEmpty) {
                if (matches) {
                  debugPrint(
                    'SEARCH MATCH: "$query" matches User("$username", "$nickname")',
                  );
                } else if (query.length >= 3) {
                  debugPrint(
                    'SEARCH NO MATCH: "$query" vs User("$username", "$nickname")',
                  );
                }
              }

              return matches;
            });

        return nameMatches || messageMatches || participantMatches;
      }).toList();

      return globalChannelsAsync.when(
        data: (globalChannels) {
          final all = [...filteredLocal];
          for (final ch in globalChannels) {
            if (!all.any((r) => r.id == ch.id)) {
              all.add(ch);
            }
          }
          return AsyncValue.data(all);
        },
        loading: () => AsyncValue.data(filteredLocal),
        error: (err, stack) => AsyncValue.data(filteredLocal),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final contactsProvider = Provider<AsyncValue<List<ProfileModel>>>((ref) {
  final roomsAsync = ref.watch(roomsProvider);
  final currentUserId = ref.watch(authUserProvider)?.id;

  return roomsAsync.whenData((rooms) {
    final contacts = <String, ProfileModel>{};
    for (final room in rooms) {
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

final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, roomId) {
      final link = ref.keepAlive();
      Timer? timer;
      ref.onCancel(() {
        timer = Timer(const Duration(seconds: 30), () {
          link.close();
        });
      });
      ref.onDispose(() => timer?.cancel());

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

    final messageIds = messages.map((m) => m.id).toSet();
    final uniquePending = pending.where((pm) {
      if (messageIds.contains(pm.id)) return false;

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
    StreamProvider.autoDispose.family<List<ProfileModel>, String>((ref, roomId) {
      final link = ref.keepAlive();
      Timer? timer;
      ref.onCancel(() {
        timer = Timer(const Duration(seconds: 30), () {
          link.close();
        });
      });
      ref.onDispose(() => timer?.cancel());

      return ref.watch(chatRepositoryProvider).watchRoomParticipants(roomId);
    });

final roomProvider =
    StreamProvider.autoDispose.family<RoomModel?, String>((ref, roomId) {
      final link = ref.keepAlive();
      Timer? timer;
      ref.onCancel(() {
        timer = Timer(const Duration(seconds: 30), () {
          link.close();
        });
      });
      ref.onDispose(() => timer?.cancel());

      return ref.watch(chatRepositoryProvider).watchRoom(roomId);
    });
