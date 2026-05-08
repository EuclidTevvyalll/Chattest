import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/profile/presentation/providers/profile_provider.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:rickandmorty/core/providers/theme_mode/theme_provider.dart';
import 'package:rickandmorty/features/profile/presentation/screens/avatar_crop_dialog.dart';
import 'package:rickandmorty/main.dart'; // To access rootScaffoldMessengerKey
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
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
              return _ProfileContent(profile: profile);
            },
            loading: () {
              if (profileAsync.hasValue) {
                return _ProfileContent(profile: profileAsync.value!);
              }
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ThemeColors.blue,
                ),
              );
            },
            orElse: () => profileAsync.when(
              data: (profile) => _ProfileContent(profile: profile!),
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
                            onPressed: () =>
                                ref.invalidate(profileControllerProvider),
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

  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = useState(false);
    final nicknameController = useTextEditingController(text: profile.nickname);
    final usernameController = useTextEditingController(text: profile.username);

    final isPicking = useState(false);
    final previewImage = ref.watch(avatarUploadPreviewProvider);

    Future<void> pickAndUploadImage() async {
      if (isPicking.value || !isEditing.value) return;
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
                rootScaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Аватарка успешно обновлена'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    width: 300,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                rootScaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text('Ошибка загрузки: $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    width: 300,
                  ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при выборе файла: $e')),
          );
        }
      } finally {
        if (context.mounted) {
          isPicking.value = false;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Профиль', style: ThemeTextStyles.h1(isDark: isDark)),
              if (isEditing.value)
                TextButton(
                  onPressed: () {
                    ref
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
                  icon: Icon(
                    Icons.edit_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (isEditing.value)
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
          const SizedBox(height: 40),
          _ProfileField(
            label: 'Никнейм',
            controller: nicknameController,
            enabled: isEditing.value,
            icon: Icons.badge_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Имя пользователя',
            controller: usernameController,
            enabled: isEditing.value,
            icon: Icons.alternate_email_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 40),
          GlassBox(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(24),
            opacity: isDark ? 0.1 : 0.05,
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => ref.read(authRepositoryProvider).logout(),
            child: GlassBox(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              borderRadius: BorderRadius.circular(24),
              opacity: isDark ? 0.1 : 0.05,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Выйти',
                    style: ThemeTextStyles.h3(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),
        ],
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
