import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rickandmorty/features/chat/data/repositories/supabase_chat_repository.dart';
import 'package:rickandmorty/features/chat/domain/models/message_model.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';
import 'package:rickandmorty/features/chat/domain/repositories/chat_repository.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository(Supabase.instance.client);
});

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

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  roomId,
) {
  final user = ref.watch(authUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).watchMessages(roomId);
});

final roomParticipantsProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, roomId) {
      return ref.watch(chatRepositoryProvider).getRoomParticipants(roomId);
    });
