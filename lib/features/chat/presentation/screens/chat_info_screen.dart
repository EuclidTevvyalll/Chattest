import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:forgelink/widgets/custom_dialog.dart';
import 'package:forgelink/widgets/premium_badge.dart';
import 'dart:typed_data';

class ChatInfoScreen extends ConsumerWidget {
  final String roomId;

  const ChatInfoScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<RoomModel?>>(roomProvider(roomId), (previous, next) {
      if (next is AsyncData<RoomModel?> && next.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/');
          }
        });
      }
    });

    final roomAsync = ref.watch(roomProvider(roomId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(authUserProvider)?.id;

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
        title: Text('Информация', style: ThemeTextStyles.h3(isDark: isDark)),
      ),
      body: Container(
        width: double.infinity,
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

              final participantsAsync = ref.watch(
                roomParticipantsProvider(roomId),
              );

              return participantsAsync.when(
                data: (participants) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _buildBody(
                              context,
                              ref,
                              room,
                              participants,
                              isDark,
                              currentUserId,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Ошибка загрузки участников: $err')),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: ThemeColors.blue,
              ),
            ),
            error: (err, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
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
                      'Не удалось загрузить информацию',
                      style: ThemeTextStyles.h3(isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(roomsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Повторить',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    List<ProfileModel> participants,
    bool isDark,
    String? currentUserId,
  ) {
    if (room.type == RoomType.room) {
      if (participants.isEmpty) {
        return const Center(child: Text('Участник не найден'));
      }
      final other = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.first,
      );
      final avatarBase64 = ref
          .watch(userAvatarBase64Provider(other.id))
          .asData
          ?.value;
      return _buildUserProfile(context, ref, room, other, isDark, avatarBase64);
    } else if (room.type == RoomType.group) {
      return _buildGroupInfo(context, ref, room, participants, isDark);
    } else {
      return _buildChannelInfo(context, ref, room, participants, isDark);
    }
  }

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    ProfileModel profile,
    bool isDark,
    Uint8List? avatarBase64,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(
              profile.avatarUrl,
              profile.nickname ?? profile.username,
              isDark,
              avatarBase64,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile.nickname ?? 'Нет никнейма',
                  style: ThemeTextStyles.h1(isDark: isDark),
                ),
                PremiumBadge(isPremium: profile.isPremium, size: 24),
              ],
            ),
            Text(
              '@${profile.username}',
              style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue),
            ),
            const SizedBox(height: 40),
            _buildInfoSection(isDark, [
              _InfoTile(
                label: 'Никнейм',
                value: profile.nickname ?? '-',
                icon: Icons.badge_outlined,
                isDark: isDark,
              ),
              _InfoTile(
                label: 'Имя пользователя',
                value: '@${profile.username}',
                icon: Icons.alternate_email_rounded,
                isDark: isDark,
              ),
            ]),
          ],
        ),
        Column(
          children: [
            const SizedBox(height: 32),
            _buildActionButton(
              context,
              'Отправить сообщение',
              Icons.chat_bubble_outline_rounded,
              ThemeColors.blue,
              isDark,
              () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              'Удалить чат',
              Icons.delete_outline_rounded,
              Colors.redAccent,
              isDark,
              () => _handleLeaveOrDelete(context, ref, room, true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassBox(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        borderRadius: BorderRadius.circular(16),
        opacity: isDark ? 0.1 : 0.05,
        child: Row(
          children: [
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

  Widget _buildGroupInfo(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    List<ProfileModel> participants,
    bool isDark,
  ) {
    final currentUserId = ref.watch(authUserProvider)?.id;
    final myParticipant = participants
        .where((p) => p.id == currentUserId)
        .firstOrNull;
    final myRole = myParticipant?.role;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(room.avatarUrl, room.name ?? 'Группа', isDark, null),
            const SizedBox(height: 24),
            Text(
              room.name ?? 'Группа',
              style: ThemeTextStyles.h1(isDark: isDark),
            ),
            Text(
              '${room.participants.length} участников',
              style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue),
            ),
            const SizedBox(height: 40),
            _buildInfoSection(isDark, [
              _InfoTile(
                label: 'Описание',
                value: (room.description == null || room.description!.isEmpty)
                    ? 'Нет описания'
                    : room.description!,
                icon: Icons.info_outline,
                isDark: isDark,
              ),
            ]),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Участники',
                style: ThemeTextStyles.h3(isDark: isDark),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final p = participants[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.push('/profile/${p.id}'),
                    borderRadius: BorderRadius.circular(16),
                    child: GlassBox(
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(16),
                      opacity: isDark ? 0.1 : 0.05,
                      child: Row(
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final avatarAsync = ref.watch(
                                userAvatarBase64Provider(p.id),
                              );
                              final avatarBase64 = avatarAsync.asData?.value;
                              return CircleAvatar(
                                radius: 20,
                                backgroundColor: ThemeColors.blue.withValues(
                                  alpha: 0.1,
                                ),
                                backgroundImage: p.avatarUrl != null
                                    ? CachedNetworkImageProvider(p.avatarUrl!)
                                    : (avatarBase64 != null
                                          ? MemoryImage(avatarBase64)
                                          : null),
                                child:
                                    (avatarBase64 == null &&
                                        p.avatarUrl == null)
                                    ? Text(p.username[0].toUpperCase())
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.nickname ?? p.username,
                                    style: ThemeTextStyles.h3(isDark: isDark),
                                  ),
                                  PremiumBadge(isPremium: p.isPremium),
                                ],
                              ),
                              Text(
                                '@${p.username}',
                                style: ThemeTextStyles.caption(isDark: isDark),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (p.role == 'owner' || p.role == 'admin')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: ThemeColors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.role == 'owner' ? 'Владелец' : 'Админ',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: ThemeColors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Column(
          children: [
            const SizedBox(height: 32),
            if (myRole == 'owner' || myRole == 'admin')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionButton(
                  context,
                  'Редактировать',
                  Icons.edit_rounded,
                  ThemeColors.blue,
                  isDark,
                  () => context.pushNamed(
                    'edit_room',
                    pathParameters: {'roomId': room.id},
                  ),
                ),
              ),
            _buildActionButton(
              context,
              myRole == 'owner' ? 'Удалить группу' : 'Покинуть группу',
              myRole == 'owner'
                  ? Icons.delete_outline_rounded
                  : Icons.logout_rounded,
              Colors.redAccent,
              isDark,
              () => _handleLeaveOrDelete(context, ref, room, myRole == 'owner'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelInfo(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    List<ProfileModel> participants,
    bool isDark,
  ) {
    final authUser = ref.watch(authUserProvider);
    final currentUserId = authUser?.id;
    final myParticipant = participants
        .where((p) => p.id == currentUserId)
        .firstOrNull;
    final myRole = myParticipant?.role;
    final canSeeSubscribers = myRole == 'owner' || myRole == 'admin';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(room.avatarUrl, room.name ?? 'Канал', isDark, null),
            const SizedBox(height: 24),
            Text(
              room.name ?? 'Канал',
              style: ThemeTextStyles.h1(isDark: isDark),
            ),
            Text(
              '${participants.length} подписчиков',
              style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue),
            ),
            const SizedBox(height: 40),
            _buildInfoSection(isDark, [
              _InfoTile(
                label: 'Описание',
                value: (room.description == null || room.description!.isEmpty)
                    ? 'Нет описания'
                    : room.description!,
                icon: Icons.info_outline,
                isDark: isDark,
              ),
            ]),
            if (canSeeSubscribers) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Подписчики',
                  style: ThemeTextStyles.h3(isDark: isDark),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => context.push('/profile/${p.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: GlassBox(
                        padding: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(16),
                        opacity: isDark ? 0.1 : 0.05,
                        child: Row(
                          children: [
                            Consumer(
                              builder: (context, ref, _) {
                                final avatarAsync = ref.watch(
                                  userAvatarBase64Provider(p.id),
                                );
                                final avatarBase64 = avatarAsync.asData?.value;
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundColor: ThemeColors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage: p.avatarUrl != null
                                      ? CachedNetworkImageProvider(p.avatarUrl!)
                                      : (avatarBase64 != null
                                            ? MemoryImage(avatarBase64)
                                            : null),
                                  child:
                                      (avatarBase64 == null &&
                                          p.avatarUrl == null)
                                      ? Text(p.username[0].toUpperCase())
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.nickname ?? p.username,
                                      style: ThemeTextStyles.h3(isDark: isDark),
                                    ),
                                    PremiumBadge(isPremium: p.isPremium),
                                  ],
                                ),
                                Text(
                                  '@${p.username}',
                                  style: ThemeTextStyles.caption(
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (p.role == 'owner' || p.role == 'admin')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ThemeColors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.role == 'owner' ? 'Владелец' : 'Админ',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: ThemeColors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (myRole == 'owner' && p.id != currentUserId)
                              HookBuilder(
                                builder: (context) {
                                  final isLoading = useState(false);
                                  return isLoading.value
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            p.role == 'admin'
                                                ? Icons.admin_panel_settings
                                                : Icons
                                                      .admin_panel_settings_outlined,
                                            color: p.role == 'admin'
                                                ? ThemeColors.blue
                                                : (isDark
                                                      ? Colors.white24
                                                      : Colors.black26),
                                            size: 24,
                                          ),
                                          onPressed: () async {
                                            isLoading.value = true;
                                            try {
                                              final newRole = p.role == 'admin'
                                                  ? 'member'
                                                  : 'admin';
                                              await ref
                                                  .read(
                                                    chatControllerProvider
                                                        .notifier,
                                                  )
                                                  .updateParticipantRole(
                                                    room.id,
                                                    p.id,
                                                    newRole,
                                                  );
                                            } catch (e) {
                                              if (context.mounted) {
                                                showCustomDialog(
                                                  context: context,
                                                  title: 'Ошибка',
                                                  message:
                                                      'Ошибка обновления роли: $e',
                                                  isError: true,
                                                );
                                              }
                                            } finally {
                                              if (context.mounted) {
                                                isLoading.value = false;
                                              }
                                            }
                                          },
                                        );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        Column(
          children: [
            const SizedBox(height: 32),
            if (myRole == 'owner' || myRole == 'admin')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionButton(
                  context,
                  'Редактировать',
                  Icons.edit_rounded,
                  ThemeColors.blue,
                  isDark,
                  () => context.pushNamed(
                    'edit_room',
                    pathParameters: {'roomId': room.id},
                  ),
                ),
              ),
            _buildActionButton(
              context,
              myRole == 'owner' ? 'Удалить канал' : 'Покинуть канал',
              myRole == 'owner'
                  ? Icons.delete_outline_rounded
                  : Icons.logout_rounded,
              Colors.redAccent,
              isDark,
              () => _handleLeaveOrDelete(context, ref, room, myRole == 'owner'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(
    String? url,
    String placeholder,
    bool isDark, [
    Uint8List? base64,
  ]) {
    return Container(
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
          backgroundImage: url != null
              ? CachedNetworkImageProvider(url)
              : (base64 != null ? MemoryImage(base64) : null),
          child: (url == null && base64 == null)
              ? Text(
                  placeholder.isNotEmpty ? placeholder[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: ThemeColors.blue),
                )
              : null,
        ),
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

  Future<void> _handleLeaveOrDelete(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
    bool isDelete,
  ) async {
    final titleText = isDelete ? 'Удалить' : 'Покинуть';
    final targetText = room.type == RoomType.channel
        ? 'канал'
        : (room.type == RoomType.group ? 'группу' : 'чат');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        title: Text('$titleText $targetText?'),
        content: Text(
          isDelete
              ? 'Вы уверены, что хотите удалить этот $targetText? Это действие удалит все сообщения и саму комнату для всех участников.'
              : 'Вы уверены, что хотите покинуть этот $targetText? Вы больше не будете получать сообщения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(titleText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isDelete) {
          await ref.read(chatControllerProvider.notifier).deleteRoom(room.id);
        } else {
          await ref.read(chatControllerProvider.notifier).leaveRoom(room.id);
        }
        if (context.mounted) {
          showCustomDialog(
            context: context,
            title: 'Успех',
            message: isDelete ? 'Комната успешно удалена' : 'Вы покинули комнату',
          );
          context.go('/');
        }
      } catch (e) {
        if (context.mounted) {
          showCustomDialog(
            context: context,
            title: 'Ошибка',
            message: 'Не удалось выполнить действие: $e',
            isError: true,
          );
        }
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
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
                Text(value, style: ThemeTextStyles.bodyLarge(isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
