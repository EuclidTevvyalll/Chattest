import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
                      onPressed: () {
                        final selectedPlan = plans[selectedPlanIndex.value];
                        _showCardPaymentDialog(context, ref, selectedPlan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
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

  // --- CARD PAYMENT FLOW ---

  bool _validateCardNumber(String cardNumber) {
    String clean = cardNumber.replaceAll(' ', '');
    return clean.length == 16;
  }

  bool _validateExpiry(String expiry) {
    if (expiry.length != 5) return false;
    final parts = expiry.split('/');
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    final fullYear = 2000 + year;
    final expiryDate = DateTime(fullYear, month + 1, 0);
    return expiryDate.isAfter(DateTime.now());
  }

  bool _validateCVV(String cvv) {
    return cvv.length == 3 && int.tryParse(cvv) != null;
  }

  bool _validateCardholder(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return false;
    final parts = clean.split(' ');
    if (parts.length < 2) return false;
    final regex = RegExp(r'^[a-zA-Z]+$');
    return parts.every((part) => regex.hasMatch(part));
  }

  Widget _buildVisualCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String holder,
    required bool isDark,
  }) {
    String brand = 'КАРТА';
    if (cardNumber.startsWith('4')) {
      brand = 'VISA';
    } else if (cardNumber.startsWith('5')) {
      brand = 'MASTERCARD';
    } else if (cardNumber.startsWith('2')) {
      brand = 'МИР';
    }

    String displayNum = cardNumber;
    if (displayNum.isEmpty) {
      displayNum = '•••• •••• •••• ••••';
    } else {
      String cleanNum = displayNum.replaceAll(' ', '');
      int len = cleanNum.length;
      if (len < 16) {
        String filled = cleanNum + '•' * (16 - len);
        StringBuffer sb = StringBuffer();
        for (int i = 0; i < 16; i++) {
          sb.write(filled[i]);
          if ((i + 1) % 4 == 0 && i != 15) sb.write(' ');
        }
        displayNum = sb.toString();
      }
    }

    final displayHolder = holder.trim().isEmpty ? 'ИМЯ ВЛАДЕЛЬЦА' : holder.toUpperCase();
    final displayExpiry = expiry.trim().isEmpty ? 'ММ/ГГ' : expiry;

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF311042),
            Color(0xFF4C0519),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 45,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE875), Color(0xFFC59B27)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: CardChipPainter(),
                ),
              ),
              Text(
                brand,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ВЛАДЕЛЕЦ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayHolder,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ГОДЕН ДО',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayExpiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'КОД CVV',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cvv.isEmpty ? '•••' : cvv,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? errorText,
    required bool isDark,
    required TextInputType keyboardType,
    List<TextInputFormatter>? formatters,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: errorText != null 
                  ? Colors.redAccent 
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
        GlassBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: BorderRadius.circular(16),
          opacity: isDark ? 0.08 : 0.04,
          border: errorText != null
              ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5)
              : null,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            inputFormatters: formatters,
            style: ThemeTextStyles.bodyLarge(isDark: isDark),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.black38,
                fontSize: 15,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _showCardPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> selectedPlan,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: false,
      builder: (context) => PopScope(
        child: HookConsumer(
          builder: (context, ref, child) {
            final cardNumberController = useTextEditingController();
            final expiryController = useTextEditingController();
            final cvvController = useTextEditingController();
            final cardholderController = useTextEditingController();

            final cardNumberError = useState<String?>(null);
            final expiryError = useState<String?>(null);
            final cvvError = useState<String?>(null);
            final cardholderError = useState<String?>(null);

            final isProcessing = useState(false);

            final cardNumberState = useState('');
            final expiryState = useState('');
            final cvvState = useState('');
            final cardholderState = useState('');

            useEffect(() {
              void updateCardNumber() => cardNumberState.value = cardNumberController.text;
              void updateExpiry() => expiryState.value = expiryController.text;
              void updateCvv() => cvvState.value = cvvController.text;
              void updateCardholder() => cardholderState.value = cardholderController.text;

              cardNumberController.addListener(updateCardNumber);
              expiryController.addListener(updateExpiry);
              cvvController.addListener(updateCvv);
              cardholderController.addListener(updateCardholder);

              return () {
                cardNumberController.removeListener(updateCardNumber);
                expiryController.removeListener(updateExpiry);
                cvvController.removeListener(updateCvv);
                cardholderController.removeListener(updateCardholder);
              };
            }, []);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassBox(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                opacity: isDark ? 0.35 : 0.15,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Оплата подписки',
                            style: ThemeTextStyles.h2(isDark: isDark),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildVisualCard(
                        cardNumber: cardNumberState.value,
                        expiry: expiryState.value,
                        cvv: cvvState.value,
                        holder: cardholderState.value,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildPaymentInputField(
                        label: 'Номер карты',
                        controller: cardNumberController,
                        hint: '4111 1111 1111 1112',
                        errorText: cardNumberError.value,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CardNumberFormatter(),
                        ],
                        onChanged: (_) => cardNumberError.value = null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildPaymentInputField(
                              label: 'Срок действия',
                              controller: expiryController,
                              hint: 'ММ/ГГ',
                              errorText: expiryError.value,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CardExpiryFormatter(),
                              ],
                              onChanged: (_) => expiryError.value = null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPaymentInputField(
                              label: 'CVV код',
                              controller: cvvController,
                              hint: '123',
                              errorText: cvvError.value,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              onChanged: (_) => cvvError.value = null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentInputField(
                        label: 'Владелец карты',
                        controller: cardholderController,
                        hint: 'IVAN IVANOV',
                        errorText: cardholderError.value,
                        isDark: isDark,
                        keyboardType: TextInputType.name,
                        formatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                          UpperCaseTextFormatter(),
                        ],
                        onChanged: (_) => cardholderError.value = null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isProcessing.value
                              ? null
                              : () async {
                                  final numVal = cardNumberController.text;
                                  final expVal = expiryController.text;
                                  final cvvVal = cvvController.text;
                                  final holderVal = cardholderController.text;

                                  bool isValid = true;
                                  
                                  if (!_validateCardNumber(numVal)) {
                                    cardNumberError.value = 'Неверный номер карты';
                                    isValid = false;
                                  } else {
                                    cardNumberError.value = null;
                                  }

                                  if (!_validateExpiry(expVal)) {
                                    expiryError.value = 'Неверный срок действия';
                                    isValid = false;
                                  } else {
                                    expiryError.value = null;
                                  }

                                  if (!_validateCVV(cvvVal)) {
                                    cvvError.value = 'Должно быть 3 цифры';
                                    isValid = false;
                                  } else {
                                    cvvError.value = null;
                                  }

                                  if (!_validateCardholder(holderVal)) {
                                    cardholderError.value = 'Введите Имя и Фамилию (LATIN)';
                                    isValid = false;
                                  } else {
                                    cardholderError.value = null;
                                  }

                                  if (!isValid) return;

                                  isProcessing.value = true;
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
                                  'Оплатить ${selectedPlan['price']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
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

class CardChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // If deleting, allow it
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    var text = newValue.text.replaceAll('/', '');
    
    // Only allow digits
    if (RegExp(r'[^0-9]').hasMatch(text)) {
      return oldValue;
    }

    if (text.isEmpty) {
      return newValue;
    }

    // Step 1: Format Month
    if (text.isNotEmpty) {
      final firstDigit = text[0];
      if (firstDigit != '0' && firstDigit != '1') {
        // If user typed 2-9, auto-prepend 0 to make it 02-09
        text = '0$text';
      }
    }

    if (text.length >= 2) {
      final monthVal = int.tryParse(text.substring(0, 2)) ?? 0;
      if (monthVal < 1) {
        text = '01${text.substring(2)}';
      } else if (monthVal > 12) {
        text = '12${text.substring(2)}';
      }
    }

    // Step 2: Format Year
    final now = DateTime.now();
    final currentYearShort = now.year % 100; // e.g. 26
    final currentMonth = now.month;          // e.g. 5

    if (text.length >= 3) {
      final firstYearDigit = int.tryParse(text[2]) ?? 0;
      final currentYearTens = currentYearShort ~/ 10; // e.g. 2 for 26
      if (firstYearDigit < currentYearTens) {
        return oldValue;
      }
    }

    if (text.length >= 4) {
      final yearVal = int.tryParse(text.substring(2, 4)) ?? 0;
      if (yearVal < currentYearShort) {
        return oldValue;
      }
      
      // If same year, month must be current or future month
      final monthVal = int.tryParse(text.substring(0, 2)) ?? 0;
      if (yearVal == currentYearShort && monthVal < currentMonth) {
        return oldValue;
      }
    }

    // Keep length at max 4 digits
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    // Format with slash MM/YY
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length >= 2) {
        buffer.write('/');
      }
    }

    final newString = buffer.toString();
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
