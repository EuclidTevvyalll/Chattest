import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/liquidglass_container.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

class ChatInfoScreen extends ConsumerWidget {
  final String roomId;

  const ChatInfoScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
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
          child: roomsAsync.when(
            data: (rooms) {
              final room = rooms.where((r) => r.id == roomId).firstOrNull;
              if (room == null) {
                return const Center(child: Text('Комната не найдена'));
              }

              final participantsAsync = ref.watch(
                roomParticipantsProvider(roomId),
              );

              return participantsAsync.when(
                data: (participants) {
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
                    return _buildUserProfile(
                      context,
                      other,
                      isDark,
                      avatarBase64,
                    );
                  } else if (room.type == RoomType.group) {
                    // Update the room model with fetched participants for the builder
                    final roomWithParticipants = room.copyWith(
                      participants: participants,
                    );
                    return _buildGroupInfo(
                      context,
                      roomWithParticipants,
                      isDark,
                    );
                  } else {
                    final roomWithParticipants = room.copyWith(
                      participants: participants,
                    );
                    return _buildChannelInfo(
                      context,
                      roomWithParticipants,
                      isDark,
                    );
                  }
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

  Widget _buildUserProfile(
    BuildContext context,
    ProfileModel profile,
    bool isDark,
    Uint8List? avatarBase64,
  ) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          SizedBox(height: topPadding + 20),
          _buildAvatar(
            profile.avatarUrl,
            profile.nickname ?? profile.username,
            isDark,
            avatarBase64,
          ),
          const SizedBox(height: 24),
          Text(
            profile.nickname ?? 'Нет никнейма',
            style: ThemeTextStyles.h1(isDark: isDark),
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
          const SizedBox(height: 16),
          _buildInfoSection(isDark, [
            _InfoTile(
              label: 'Уведомления',
              value: 'Включены',
              icon: Icons.notifications_none_rounded,
              isDark: isDark,
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: ThemeColors.blue,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection(isDark, [
            _InfoTile(
              label: 'Медиа, ссылки и файлы',
              value: 'Пусто',
              icon: Icons.perm_media_outlined,
              isDark: isDark,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
            _InfoTile(
              label: 'Общие группы',
              value: '0',
              icon: Icons.group_outlined,
              isDark: isDark,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ]),
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
            'Заблокировать пользователя',
            Icons.block_flipped,
            Colors.redAccent,
            isDark,
            () {},
          ),
          _buildActionButton(
            context,
            'Удалить чат',
            Icons.delete_outline_rounded,
            Colors.redAccent,
            isDark,
            () {},
          ),
        ],
      ),
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

  Widget _buildGroupInfo(BuildContext context, RoomModel room, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          SizedBox(height: topPadding + 20),
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
              value: room.description ?? 'Нет описания',
              icon: Icons.info_outline,
              isDark: isDark,
            ),
          ]),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Участники', style: ThemeTextStyles.h3(isDark: isDark)),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: room.participants.length,
            itemBuilder: (context, index) {
              final p = room.participants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                            child: (avatarBase64 == null && p.avatarUrl == null)
                                ? Text(p.username[0].toUpperCase())
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nickname ?? p.username,
                            style: ThemeTextStyles.h3(isDark: isDark),
                          ),
                          Text(
                            '@${p.username}',
                            style: ThemeTextStyles.caption(isDark: isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelInfo(BuildContext context, RoomModel room, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          SizedBox(height: topPadding + 20),
          _buildAvatar(room.avatarUrl, room.name ?? 'Канал', isDark, null),
          const SizedBox(height: 24),
          Text(room.name ?? 'Канал', style: ThemeTextStyles.h1(isDark: isDark)),
          Text(
            '${room.participants.length} подписчиков',
            style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue),
          ),
          const SizedBox(height: 40),
          _buildInfoSection(isDark, [
            _InfoTile(
              label: 'Описание',
              value: room.description ?? 'Нет описания',
              icon: Icons.info_outline,
              isDark: isDark,
            ),
          ]),
        ],
      ),
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
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Widget? trailing;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = trailing;
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
          ?t,
        ],
      ),
    );
  }
}
