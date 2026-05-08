import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';

import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';

final profilesProvider = FutureProvider<List<ProfileModel>>((ref) {
  return ref.watch(chatRepositoryProvider).getProfiles();
});

class CreateChatScreen extends HookConsumerWidget {
  const CreateChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final selectedProfiles = useState<Set<String>>({});
    final chatType = useState<RoomType>(RoomType.room);
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState(false);

    Widget buildTypeButton(
      String label,
      RoomType type,
      ValueNotifier<RoomType> chatType,
      bool isDark,
    ) {
      final isSelected = chatType.value == type;
      return GestureDetector(
        onTap: () => chatType.value = type,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Новый чат',
                      style: ThemeTextStyles.h2(isDark: isDark),
                    ),
                  ],
                ),
              ),
              // Type Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassBox(
                  padding: const EdgeInsets.all(4),
                  borderRadius: BorderRadius.circular(16),
                  opacity: isDark ? 0.1 : 0.05,
                  child: Row(
                    children: [
                      Expanded(
                        child: buildTypeButton(
                          'Личный',
                          RoomType.room,
                          chatType,
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: buildTypeButton(
                          'Группа',
                          RoomType.group,
                          chatType,
                          isDark,
                        ),
                      ),
                      Expanded(
                        child: buildTypeButton(
                          'Канал',
                          RoomType.channel,
                          chatType,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Name/Username Input
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlassBox(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(16),
                  opacity: isDark ? 0.1 : 0.05,
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: chatType.value == RoomType.room
                          ? 'Имя пользователя'
                          : (chatType.value == RoomType.group
                                ? 'Название группы'
                                : 'Название канала'),

                      border: InputBorder.none,
                      prefixIcon: chatType.value == RoomType.room
                          ? const Icon(Icons.alternate_email, size: 20)
                          : null,
                    ),
                    style: ThemeTextStyles.bodyLarge(isDark: isDark),
                  ),
                ),
              ),

              if (chatType.value == RoomType.channel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassBox(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(16),
                    opacity: isDark ? 0.1 : 0.05,
                    child: TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Описание (необязательно)',
                        border: InputBorder.none,
                      ),
                      style: ThemeTextStyles.bodyMedium(isDark: isDark),
                    ),
                  ),
                ),
              if (chatType.value == RoomType.group)
                Expanded(
                  child: contactsAsync.when(
                    data: (profiles) {
                      final currentUserId = ref.watch(authUserProvider)?.id;

                      final otherProfiles = profiles
                          .where((p) => p.id != currentUserId)
                          .toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: otherProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = otherProfiles[index];
                          final isSelected = selectedProfiles.value.contains(
                            profile.id,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                if (chatType.value == RoomType.room) {
                                  selectedProfiles.value = {profile.id};
                                } else {
                                  if (isSelected) {
                                    selectedProfiles.value = {
                                      ...selectedProfiles.value,
                                    }..remove(profile.id);
                                  } else {
                                    selectedProfiles.value = {
                                      ...selectedProfiles.value,
                                      profile.id,
                                    };
                                  }
                                }
                              },
                              child: GlassBox(
                                padding: const EdgeInsets.all(12),
                                borderRadius: BorderRadius.circular(16),
                                opacity: isSelected
                                    ? 0.15
                                    : (isDark ? 0.08 : 0.03),
                                color: isSelected
                                    ? ThemeColors.blue
                                    : Colors.white,
                                border: isSelected
                                    ? Border.all(
                                        color: ThemeColors.blue.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      )
                                    : Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        width: 1,
                                      ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: ThemeColors.blue
                                          .withValues(alpha: 0.2),

                                      child: Text(
                                        (profile.nickname ??
                                                profile.username)[0]
                                            .toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      profile.nickname ?? profile.username,
                                      style: ThemeTextStyles.h3(isDark: isDark),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: ThemeColors.blue,
                      ),
                    ),
                    error: (err, st) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ошибка загрузки пользователей',
                            style: ThemeTextStyles.caption(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: HookBuilder(
                  builder: (context) {
                    useListenable(nameController);
                    final canCreate =
                        !isLoading.value &&
                        ((chatType.value == RoomType.room &&
                                (selectedProfiles.value.isNotEmpty ||
                                    nameController.text.isNotEmpty)) ||
                            (chatType.value == RoomType.group &&
                                nameController.text.isNotEmpty &&
                                selectedProfiles.value.isNotEmpty) ||
                            (chatType.value == RoomType.channel &&
                                nameController.text.isNotEmpty));

                    return GestureDetector(
                      onTap: canCreate
                          ? () async {
                              final repo = ref.read(chatRepositoryProvider);
                              isLoading.value = true;
                              try {
                                bool success = false;
                                String? newRoomId;
                                if (chatType.value == RoomType.room) {
                                  List<String> ids = selectedProfiles.value
                                      .toList();

                                  // Handle username search
                                  if (ids.isEmpty &&
                                      nameController.text.isNotEmpty) {
                                    final username = nameController.text.trim();
                                    final profile = await repo
                                        .getProfileByUsername(username);

                                    if (!context.mounted) return;

                                    if (profile != null) {
                                      if (profile.id ==
                                          ref.read(authUserProvider)?.id) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Вы не можете создать чат с самим собой',
                                            ),
                                          ),
                                        );
                                        isLoading.value = false;
                                        return;
                                      }
                                      ids = [profile.id];
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Пользователь $username не найден',
                                          ),
                                        ),
                                      );
                                      isLoading.value = false;
                                      return;
                                    }
                                  }

                                  if (ids.isNotEmpty) {
                                    newRoomId = await repo.createRoom(ids);
                                    success = true;
                                  }
                                } else if (chatType.value == RoomType.group) {
                                  newRoomId = await repo.createGroup(
                                    nameController.text,
                                    selectedProfiles.value.toList(),
                                  );
                                  success = true;
                                } else if (chatType.value == RoomType.channel) {
                                  newRoomId = await repo.createChannel(
                                    nameController.text,
                                    descriptionController.text,
                                  );
                                  success = true;
                                }

                                if (!context.mounted) return;

                                // Invalidate roomsProvider to force an immediate refresh
                                ref.invalidate(roomsProvider);

                                isLoading.value = false;

                                if (success && newRoomId != null) {
                                  context.pushReplacementNamed(
                                    'chat_detail',
                                    pathParameters: {'roomId': newRoomId},
                                    queryParameters: {
                                      'type': chatType.value.name,
                                    },
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  isLoading.value = false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка: $e')),
                                  );
                                }
                              }
                            }
                          : null,

                      child: Opacity(
                        opacity: canCreate ? 1.0 : 0.5,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: ThemeColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Создать',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
