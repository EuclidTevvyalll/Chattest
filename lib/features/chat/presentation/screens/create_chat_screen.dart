import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';

import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_repository_provider.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/widgets/premium_badge.dart';
import 'package:forgelink/widgets/custom_dialog.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';

final profilesProvider = FutureProvider<List<ProfileModel>>((ref) {
  return ref.watch(chatRepositoryProvider).getProfiles();
});

class CreateChatScreen extends HookConsumerWidget {
  final RoomType initialType;

  const CreateChatScreen({super.key, this.initialType = RoomType.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final selectedProfiles = useState<Set<String>>({});
    final chatType = useState<RoomType>(initialType);
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState(false);

    useEffect(() {
      selectedProfiles.value = {};
      return null;
    }, [chatType.value]);

    Widget buildTypeButton(
      String label,
      RoomType type,
      ValueNotifier<RoomType> chatType,
      bool isDark,
    ) {
      final isSelected = chatType.value == type;
      return GestureDetector(
        onTap: () {
          if (chatType.value != type) {
            chatType.value = type;
            nameController.clear();
            descriptionController.clear();
            selectedProfiles.value = {};
          }
        },
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
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
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
                  Text('Новый чат', style: ThemeTextStyles.h2(isDark: isDark)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                ? 'Имя пользователя...'
                                : 'Название...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              chatType.value == RoomType.room
                                  ? Icons.person_search_rounded
                                  : Icons.edit_note_rounded,
                              size: 20,
                            ),
                          ),
                          style: ThemeTextStyles.bodyLarge(isDark: isDark),
                        ),
                      ),
                    ),

                    // Description
                    if (chatType.value != RoomType.room)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

                    // Contact List (for groups)
                    if (chatType.value == RoomType.group) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Выберите участников',
                          style: ThemeTextStyles.h3(
                            isDark: isDark,
                          ).copyWith(fontSize: 16),
                        ),
                      ),
                      contactsAsync.when(
                        data: (profiles) {
                          final currentUserId = ref.watch(authUserProvider)?.id;
                          final filteredProfiles = profiles
                              .where((p) => p.id != currentUserId)
                              .toList();

                          if (filteredProfiles.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Пользователи не найдены',
                                  style: ThemeTextStyles.bodyMedium(
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredProfiles.length,
                            itemBuilder: (context, index) {
                              final profile = filteredProfiles[index];
                              final isSelected = selectedProfiles.value
                                  .contains(profile.id);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
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
                                    border: Border.all(
                                      color: isSelected
                                          ? ThemeColors.blue.withValues(
                                              alpha: 0.5,
                                            )
                                          : Colors.white.withValues(
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    profile.nickname ??
                                                        profile.username,
                                                    style: ThemeTextStyles.h3(
                                                      isDark: isDark,
                                                    ),
                                                  ),
                                                  PremiumBadge(
                                                    isPremium:
                                                        profile.isPremium,
                                                  ),
                                                ],
                                              ),
                                              if (profile.nickname != null)
                                                Text(
                                                  '@${profile.username}',
                                                  style:
                                                      ThemeTextStyles.caption(
                                                        isDark: isDark,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
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
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: ThemeColors.blue,
                            ),
                          ),
                        ),
                        error: (err, st) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Ошибка загрузки',
                              style: ThemeTextStyles.caption(isDark: isDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Sticky Bottom Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                ],
              ),
              child: HookBuilder(
                builder: (context) {
                  useListenable(nameController);
                  final canCreate =
                      !isLoading.value &&
                      ((chatType.value == RoomType.room &&
                              nameController.text.isNotEmpty) ||
                          (chatType.value == RoomType.group &&
                              nameController.text.isNotEmpty &&
                              selectedProfiles.value.isNotEmpty) ||
                          (chatType.value == RoomType.channel &&
                              nameController.text.isNotEmpty));

                  return GestureDetector(
                    onTap: canCreate
                        ? () async {
                            final chatController = ref.read(
                              chatControllerProvider.notifier,
                            );
                            isLoading.value = true;
                            try {
                              bool success = false;
                              String? newRoomId;
                              if (chatType.value == RoomType.room) {
                                List<String> ids = selectedProfiles.value
                                    .toList();
                                if (ids.isEmpty) {
                                  final username = nameController.text.trim();
                                  final repo = ref.read(chatRepositoryProvider);
                                  final profile = await repo
                                      .getProfileByUsername(username);
                                  if (profile != null) {
                                    ids = [profile.id];
                                  } else {
                                    if (context.mounted) {
                                      showCustomDialog(
                                        context: context,
                                        title: 'Пользователь не найден',
                                        message:
                                            'Пользователь $username не найден',
                                        isError: true,
                                      );
                                      isLoading.value = false;
                                      return;
                                    }
                                  }
                                }
                                if (ids.isNotEmpty) {
                                  newRoomId = await chatController.createRoom(
                                    ids,
                                  );
                                  success = true;
                                }
                              } else if (chatType.value == RoomType.group) {
                                newRoomId = await chatController.createGroup(
                                  nameController.text,
                                  selectedProfiles.value.toList(),
                                );
                                success = true;
                              } else if (chatType.value == RoomType.channel) {
                                newRoomId = await chatController.createChannel(
                                  nameController.text,
                                  descriptionController.text,
                                );
                                success = true;
                              }

                              if (!context.mounted) return;
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
                                showCustomDialog(
                                  context: context,
                                  title: 'Ошибка',
                                  message: 'Ошибка: $e',
                                  isError: true,
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
    );
  }
}
