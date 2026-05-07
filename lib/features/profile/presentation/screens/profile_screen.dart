import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/profile/presentation/providers/profile_provider.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:rickandmorty/core/providers/theme_mode/theme_provider.dart';
import 'package:rickandmorty/features/profile/presentation/screens/avatar_crop_dialog.dart';

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
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('Профиль не найден'));
              }
              return _ProfileContent(profile: profile);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Ошибка: $err')),
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

    Future<void> pickAndUploadImage() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        
        if (!context.mounted) return;
        
        final croppedBytes = await showDialog<Uint8List>(
          context: context,
          builder: (context) => AvatarCropDialog(image: imageBytes),
        );

        if (croppedBytes != null) {
          await ref
              .read(profileControllerProvider.notifier)
              .uploadAvatar(croppedBytes);
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
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: isDark
                        ? Colors.grey[900]
                        : Colors.grey[200],
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: ThemeColors.blue,
                          )
                        : (ref.watch(profileControllerProvider).isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  )
                                : null),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: pickAndUploadImage,
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
                      child: const Icon(
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
