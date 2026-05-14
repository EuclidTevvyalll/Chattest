import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/core/providers/theme_mode/theme_provider.dart';
import 'package:forgelink/features/profile/presentation/screens/avatar_crop_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/widgets/custom_dialog.dart';
import 'package:forgelink/widgets/premium_badge.dart';

class ProfileScreen extends HookConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authUserProvider)?.id;
    final isMe = userId == null || userId == currentUserId;

    final profileAsync = isMe
        ? ref.watch(profileControllerProvider)
        : ref.watch(userProfileProvider(userId!));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = context.canPop();

    // Editing state lifted to handle AppBar actions
    final isEditing = useState(false);
    final profile = profileAsync.asData?.value;
    final nicknameController = useTextEditingController(
      text: profile?.nickname,
    );
    final usernameController = useTextEditingController(
      text: profile?.username,
    );

    // Sync controllers if profile changes (e.g. initial load)
    useEffect(() {
      if (profile != null) {
        nicknameController.text = profile.nickname ?? '';
        usernameController.text = profile.username;
      }
      return null;
    }, [profile]);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('Профиль', style: ThemeTextStyles.h2(isDark: isDark)),
        leading: canPop
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              )
            : null,
        actions: [
          if (isMe && profile != null)
            if (isEditing.value)
              TextButton(
                onPressed: () async {
                  await ref
                      .read(profileControllerProvider.notifier)
                      .updateProfile(
                        nickname: nicknameController.text,
                        username: usernameController.text,
                      );
                  isEditing.value = false;
                },
                child: Text(
                  'Сохранить',
                  style: ThemeTextStyles.h3(color: ThemeColors.blue),
                ),
              )
            else
              IconButton(
                onPressed: () => isEditing.value = true,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 18,
                  ),
                ),
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, const Color(0xFFF0F2F5)],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: profileAsync.maybeWhen(
            data: (profile) {
              if (profile == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_rounded,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Профиль не найден',
                        style: ThemeTextStyles.h3(isDark: isDark),
                      ),
                    ],
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _ProfileContent(
                        profile: profile,
                        isReadOnly: !isMe,
                        isEditing: isEditing.value,
                        nicknameController: nicknameController,
                        usernameController: usernameController,
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
            orElse: () => profileAsync.when(
              data: (profile) => LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _ProfileContent(
                        profile: profile!,
                        isReadOnly: !isMe,
                        isEditing: isEditing.value,
                        nicknameController: nicknameController,
                        usernameController: usernameController,
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: ThemeColors.blue),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GlassBox(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(32),
                    opacity: isDark ? 0.1 : 0.05,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки профиля',
                          style: ThemeTextStyles.h3(isDark: isDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          style: ThemeTextStyles.caption(isDark: isDark),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => isMe
                                ? ref.invalidate(profileControllerProvider)
                                : ref.invalidate(userProfileProvider(userId!)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeColors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Повторить'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends HookConsumerWidget {
  final ProfileModel profile;
  final bool isReadOnly;
  final bool isEditing;
  final TextEditingController nicknameController;
  final TextEditingController usernameController;

  const _ProfileContent({
    required this.profile,
    this.isReadOnly = false,
    required this.isEditing,
    required this.nicknameController,
    required this.usernameController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // States managed by parent now

    final isPicking = useState(false);
    final previewImage = ref.watch(avatarUploadPreviewProvider);

    Future<void> pickAndUploadImage() async {
      if (isPicking.value) return;

      // Delay to prevent UI glitches
      await Future.delayed(const Duration(milliseconds: 200));

      isPicking.value = true;

      try {
        Uint8List? imageBytes;

        if (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            withData: true,
          );

          if (result != null && result.files.single.bytes != null) {
            imageBytes = result.files.single.bytes;
          }
        } else {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            imageBytes = await image.readAsBytes();
          }
        }

        if (imageBytes != null && context.mounted) {
          final croppedBytes = await showDialog<Uint8List>(
            context: context,
            builder: (context) => AvatarCropDialog(image: imageBytes!),
          );

          if (croppedBytes != null && context.mounted) {
            // Optimistic update: show preview immediately
            ref.read(avatarUploadPreviewProvider.notifier).update(croppedBytes);

            try {
              // Wait for upload to complete
              await ref
                  .read(profileControllerProvider.notifier)
                  .uploadAvatar(croppedBytes);

              if (context.mounted) {
                showCustomDialog(
                  context: context,
                  title: 'Успех',
                  message: 'Аватарка успешно обновлена',
                );
              }
            } catch (e) {
              if (context.mounted) {
                showCustomDialog(
                  context: context,
                  title: 'Ошибка',
                  message: 'Ошибка загрузки: $e',
                  isError: true,
                );
              }
            } finally {
              if (context.mounted) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (context.mounted) {
                    ref.read(avatarUploadPreviewProvider.notifier).update(null);
                  }
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error picking image: $e');
        if (context.mounted) {
          showCustomDialog(
            context: context,
            title: 'Ошибка',
            message: 'Ошибка при выборе файла: $e',
            isError: true,
          );
        }
      } finally {
        if (context.mounted) {
          isPicking.value = false;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ThemeColors.primaryGradient,
                  ),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final avatarAsync = ref.watch(
                        currentAvatarBase64Provider,
                      );
                      final avatarBase64 = avatarAsync.asData?.value;
                      final isLoading = avatarAsync.isLoading;

                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: isDark
                            ? Colors.grey[900]
                            : Colors.grey[200],
                        backgroundImage: previewImage != null
                            ? MemoryImage(previewImage)
                            : (profile.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      profile.avatarUrl!,
                                    )
                                  : (avatarBase64 != null
                                        ? MemoryImage(avatarBase64)
                                        : null)),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isLoading)
                              const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ThemeColors.blue,
                                ),
                              ),
                            if (profile.avatarUrl == null &&
                                previewImage == null &&
                                avatarBase64 == null &&
                                !isLoading)
                              Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: ThemeColors.blue,
                              ),
                            if (previewImage != null)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (isReadOnly && profile.isOnline == true)
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF16213E)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (!isReadOnly && !isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: isPicking.value ? null : pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF16213E)
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: isPicking.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isReadOnly) ...[
            _buildInfoSection(isDark, [
              _InfoTile(
                label: 'Никнейм',
                value: profile.nickname ?? '-',
                icon: Icons.badge_outlined,
                isDark: isDark,
                isPremium: profile.isPremium,
              ),
              _InfoTile(
                label: 'Имя пользователя',
                value: '@${profile.username}',
                icon: Icons.alternate_email_rounded,
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection(isDark, [
              _InfoTile(
                label: 'Общие группы',
                value: '0',
                icon: Icons.group_outlined,
                isDark: isDark,
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ]),
          ] else ...[
            _ProfileField(
              label: 'Никнейм',
              controller: nicknameController,
              enabled: isEditing,
              icon: Icons.badge_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _ProfileField(
              label: 'Имя пользователя',
              controller: usernameController,
              enabled: isEditing,
              icon: Icons.alternate_email_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            if (!profile.isPremium)
              _buildPremiumBanner(context, ref, isDark)
            else
              _buildInfoSection(isDark, [
                _InfoTile(
                  label: 'ForgeLink Premium',
                  value: 'Статус: Активен',
                  icon: Icons.workspace_premium_rounded,
                  isDark: isDark,
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ),
              ]),
            const SizedBox(height: 32),
            _buildInfoSection(isDark, [
              _SettingsTile(
                title: 'Темная тема',
                subtitle: 'Переключить тему',
                icon: Icons.dark_mode_outlined,
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).switchTheme();
                  },
                  activeThumbColor: ThemeColors.blue,
                ),
                isDark: isDark,
              ),
              const Divider(height: 32, thickness: 0.5, indent: 40),
              _SettingsTile(
                title: 'Уведомления',
                subtitle: 'Включить push-уведомления',
                icon: Icons.notifications_none_rounded,
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: ThemeColors.blue,
                ),
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 32),
            _buildActionButton(
              context,
              'Выйти',
              Icons.logout_rounded,
              Colors.redAccent,
              isDark,
              () => ref.read(authRepositoryProvider).logout(),
            ),
          ],
          if (isReadOnly) ...[
            const SizedBox(height: 24),
            HookBuilder(
              builder: (context) {
                final isCreating = useState(false);
                return _buildActionButton(
                  context,
                  'Написать сообщение',
                  Icons.chat_bubble_outline_rounded,
                  ThemeColors.blue,
                  isDark,
                  isLoading: isCreating.value,
                  () async {
                    // Optimization: Check if we already have a direct room with this user locally
                    final rooms = ref.read(roomsProvider).asData?.value;
                    if (rooms != null) {
                      final existingRoom = rooms
                          .where(
                            (r) =>
                                r.type == RoomType.room &&
                                r.participants.any((p) => p.id == profile.id),
                          )
                          .firstOrNull;

                      if (existingRoom != null) {
                        if (context.mounted) {
                          context.pushNamed(
                            'chat_detail',
                            pathParameters: {'roomId': existingRoom.id},
                            queryParameters: {'type': RoomType.room.name},
                          );
                        }
                        return;
                      }
                    }

                    isCreating.value = true;
                    try {
                      final roomId = await ref
                          .read(chatControllerProvider.notifier)
                          .createRoom([profile.id]);

                      if (context.mounted && roomId != null) {
                        context.pushNamed(
                          'chat_detail',
                          pathParameters: {'roomId': roomId},
                          queryParameters: {'type': RoomType.room.name},
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showCustomDialog(
                          context: context,
                          title: 'Ошибка',
                          message: 'Ошибка: $e',
                          isError: true,
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        isCreating.value = false;
                      }
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Заблокировать пользователя',
              Icons.block_flipped,
              Colors.redAccent,
              isDark,
              () {},
            ),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, List<Widget> children) {
    return GlassBox(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      opacity: isDark ? 0.1 : 0.05,
      child: Column(children: children),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassBox(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        borderRadius: BorderRadius.circular(16),
        opacity: isDark ? 0.1 : 0.05,
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ThemeColors.blue,
                ),
              )
            else
              Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: ThemeTextStyles.bodyLarge(
                isDark: isDark,
              ).copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () {
        ref.read(isPremiumDialogOpenProvider.notifier).set(true);
        _showPremiumDialog(context, ref);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ForgeLink Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Получите корону и перевод голоса в текст!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: false,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (didPop, result) {
          ref.read(isPremiumDialogOpenProvider.notifier).set(false);
        },
        child: HookConsumer(
          builder: (context, ref, child) {
            final isProcessing = useState(false);
            final selectedPlanIndex = useState(0);

            final plans = [
              {
                'title': '1 месяц',
                'price': '299₽',
                'amount': 299.0,
                'months': 1,
                'duration': const Duration(days: 30),
                'save': null,
              },
              {
                'title': '3 месяца',
                'price': '799₽',
                'amount': 799.0,
                'months': 3,
                'duration': const Duration(days: 90),
                'save': '10%',
              },
              {
                'title': '6 месяцев',
                'price': '1499₽',
                'amount': 1499.0,
                'months': 6,
                'duration': const Duration(days: 180),
                'save': '15%',
              },
              {
                'title': '1 год',
                'price': '2499₽',
                'amount': 2499.0,
                'months': 12,
                'duration': const Duration(days: 365),
                'save': '30%',
              },
            ];

            return GlassBox(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              opacity: isDark ? 0.3 : 0.1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ForgeLink Premium',
                    style: ThemeTextStyles.h2(isDark: isDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выберите ваш тарифный план',
                    style: ThemeTextStyles.caption(isDark: isDark),
                  ),
                  const SizedBox(height: 24),

                  // Сетка планов
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(plans.length, (index) {
                      final plan = plans[index];
                      final isSelected = selectedPlanIndex.value == index;

                      return GestureDetector(
                        onTap: () => selectedPlanIndex.value = index,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                : isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFD700)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (plan['save'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Выгода ${plan['save']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                plan['title'] as String,
                                style: ThemeTextStyles.bodyLarge(
                                  isDark: isDark,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan['price'] as String,
                                style: ThemeTextStyles.h3(
                                  isDark: isDark,
                                ).copyWith(color: const Color(0xFFFFD700)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isProcessing.value
                          ? null
                          : () async {
                              isProcessing.value = true;
                              final selectedPlan =
                                  plans[selectedPlanIndex.value];

                              // Имитация оплаты
                              await Future.delayed(const Duration(seconds: 2));
                              try {
                                await ref
                                    .read(profileControllerProvider.notifier)
                                    .upgradeToPremium(
                                      selectedPlan['duration'] as Duration,
                                      selectedPlan['amount'] as double,
                                      selectedPlan['months'] as int,
                                    );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  showCustomDialog(
                                    context: context,
                                    title: 'Поздравляем! 👑',
                                    message:
                                        'Premium на ${selectedPlan['title']} успешно активирован!',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  isProcessing.value = false;
                                  showCustomDialog(
                                    context: context,
                                    title: 'Ошибка оплаты',
                                    message: e.toString(),
                                    isError: true,
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isProcessing.value
                          ? const CircularProgressIndicator(
                              color: Colors.black87,
                            )
                          : Text(
                              'Подключить за ${plans[selectedPlanIndex.value]['price']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Может позже',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final bool isDark;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            label,
            style: ThemeTextStyles.caption(
              isDark: isDark,
              color: ThemeColors.blue,
            ),
          ),
        ),
        GlassBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: BorderRadius.circular(20),
          opacity: isDark ? 0.08 : 0.04,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: ThemeTextStyles.bodyLarge(isDark: isDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Widget? trailing;
  final bool isPremium;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.trailing,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: ThemeColors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ThemeTextStyles.caption(isDark: isDark)),
                Row(
                  children: [
                    Text(
                      value,
                      style: ThemeTextStyles.bodyLarge(isDark: isDark),
                    ),
                    PremiumBadge(isPremium: isPremium),
                  ],
                ),
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final bool isDark;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ThemeColors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ThemeTextStyles.h3(isDark: isDark)),
              Text(subtitle, style: ThemeTextStyles.caption(isDark: isDark)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
