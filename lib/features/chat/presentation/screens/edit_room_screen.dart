import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_repository_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/profile/presentation/screens/avatar_crop_dialog.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/widgets/custom_dialog.dart';

class EditRoomScreen extends HookConsumerWidget {
  final String roomId;

  const EditRoomScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));
    final participantsAsync = ref.watch(roomParticipantsProvider(roomId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(authUserProvider)?.id;

    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);
    final newAvatarBytes = useState<Uint8List?>(null);
    final isInitialized = useState(false);
    final nameError = useState<String?>(null);

    // Инициализация полей из текущих данных комнаты
    final room = roomAsync.value;
    useEffect(() {
      if (room != null && !isInitialized.value) {
        nameController.text = room.name ?? '';
        descriptionController.text = room.description ?? '';
        isInitialized.value = true;
      }
      return null;
    }, [room]);

    // Проверка прав: только owner или admin
    final myParticipant = participantsAsync.value
        ?.where((p) => p.id == currentUserId)
        .firstOrNull;
    final myRole = myParticipant?.role;
    final canEdit = myRole == 'owner' || myRole == 'admin';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Редактирование',
          style: ThemeTextStyles.h3(isDark: isDark),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, const Color(0xFFF0F2F5)],
          ),
        ),
        child: SafeArea(
          child: roomAsync.when(
            data: (room) {
              if (room == null) {
                return const Center(child: Text('Комната не найдена'));
              }

              if (!canEdit && participantsAsync.hasValue) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 64,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет доступа',
                          style: ThemeTextStyles.h2(isDark: isDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Только владелец или администратор может\nредактировать профиль',
                          style: ThemeTextStyles.bodyMedium(isDark: isDark),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isChannel = room.type == RoomType.channel;
              final typeLabel = isChannel ? 'канала' : 'группы';

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // Аватар
                          _buildAvatarEditor(
                            context,
                            isDark,
                            room,
                            newAvatarBytes,
                          ),

                          const SizedBox(height: 32),

                          // Название
                          _buildFieldLabel(
                            'Название $typeLabel',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          GlassBox(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: BorderRadius.circular(16),
                            opacity: isDark ? 0.1 : 0.05,
                            child: TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Введите название...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                ),
                                errorText: nameError.value,
                              ),
                              style: ThemeTextStyles.bodyLarge(isDark: isDark),
                              onChanged: (_) {
                                if (nameError.value != null) {
                                  nameError.value = null;
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Описание
                          _buildFieldLabel('Описание', isDark),
                          const SizedBox(height: 8),
                          GlassBox(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: BorderRadius.circular(16),
                            opacity: isDark ? 0.1 : 0.05,
                            child: TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                hintText: 'Введите описание (необязательно)...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                ),
                              ),
                              style: ThemeTextStyles.bodyMedium(isDark: isDark),
                              maxLines: 4,
                              minLines: 1,
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Кнопка сохранения
                  _buildSaveButton(
                    context,
                    ref,
                    isDark,
                    room,
                    nameController,
                    descriptionController,
                    newAvatarBytes,
                    isLoading,
                    nameError,
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: ThemeColors.blue,
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки',
                      style: ThemeTextStyles.h3(isDark: isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarEditor(
    BuildContext context,
    bool isDark,
    RoomModel room,
    ValueNotifier<Uint8List?> newAvatarBytes,
  ) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          if (!context.mounted) return;

          final cropped = await showDialog<Uint8List>(
            context: context,
            builder: (_) => AvatarCropDialog(image: bytes),
          );

          if (cropped != null) {
            newAvatarBytes.value = cropped;
          }
        }
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ThemeColors.primaryGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: ThemeColors.blue.withValues(alpha: 0.1),
                backgroundImage: newAvatarBytes.value != null
                    ? MemoryImage(newAvatarBytes.value!)
                    : (room.avatarUrl != null
                        ? CachedNetworkImageProvider(room.avatarUrl!)
                        : null),
                child:
                    (newAvatarBytes.value == null && room.avatarUrl == null)
                        ? Text(
                            (room.name ?? '?').isNotEmpty
                                ? (room.name ?? '?')[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              color: ThemeColors.blue,
                            ),
                          )
                        : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeColors.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: ThemeTextStyles.bodyMedium(isDark: isDark).copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    RoomModel room,
    TextEditingController nameController,
    TextEditingController descriptionController,
    ValueNotifier<Uint8List?> newAvatarBytes,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> nameError,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
      ),
      child: HookBuilder(
        builder: (context) {
          useListenable(nameController);
          final hasChanges = nameController.text.trim() != (room.name ?? '') ||
              descriptionController.text.trim() !=
                  (room.description ?? '') ||
              newAvatarBytes.value != null;
          final canSave = !isLoading.value &&
              nameController.text.trim().isNotEmpty &&
              hasChanges;

          return GestureDetector(
            onTap: canSave
                ? () => _handleSave(
                      context,
                      ref,
                      room,
                      nameController,
                      descriptionController,
                      newAvatarBytes,
                      isLoading,
                      nameError,
                    )
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: canSave ? 1.0 : 0.5,
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
                          'Сохранить',
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
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    TextEditingController nameController,
    TextEditingController descriptionController,
    ValueNotifier<Uint8List?> newAvatarBytes,
    ValueNotifier<bool> isLoading,
    ValueNotifier<String?> nameError,
  ) async {
    final newName = nameController.text.trim();
    final newDescription = descriptionController.text.trim();
    isLoading.value = true;

    try {
      // Проверка уникальности названия, если оно изменилось
      if (newName != (room.name ?? '')) {
        final repo = ref.read(chatRepositoryProvider);
        final isTaken = await repo.isRoomNameTaken(
          newName,
          excludeRoomId: room.id,
        );
        if (isTaken) {
          nameError.value = 'Название "$newName" уже занято';
          isLoading.value = false;
          return;
        }
      }

      // Загрузка аватара если выбран новый
      String? avatarUrl;
      if (newAvatarBytes.value != null) {
        final repo = ref.read(chatRepositoryProvider);
        avatarUrl = await repo.uploadMedia(
          room.id,
          newAvatarBytes.value!,
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'image/jpeg',
        );
      }

      // Обновление профиля комнаты
      await ref.read(chatControllerProvider.notifier).updateRoom(
        roomId: room.id,
        name: newName != (room.name ?? '') ? newName : null,
        description: newDescription != (room.description ?? '')
            ? newDescription
            : null,
        avatarUrl: avatarUrl,
      );

      if (context.mounted) {
        showCustomDialog(
          context: context,
          title: 'Успех',
          message: 'Профиль успешно обновлён',
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        isLoading.value = false;
        showCustomDialog(
          context: context,
          title: 'Ошибка',
          message: 'Не удалось сохранить: $e',
          isError: true,
        );
      }
    }
  }
}
