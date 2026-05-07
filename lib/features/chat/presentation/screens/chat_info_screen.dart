import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';

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
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
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
              if (room == null) return const Center(child: Text('Комната не найдена'));

              if (room.type == RoomType.room) {
                final other = room.participants.firstWhere(
                  (p) => p.id != currentUserId,
                  orElse: () => room.participants.first,
                );
                return _buildUserProfile(context, other, isDark);
              } else if (room.type == RoomType.group) {
                return _buildGroupInfo(context, room, isDark);
              } else {
                return _buildChannelInfo(context, room, isDark);
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Ошибка: $err')),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, ProfileModel profile, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAvatar(profile.avatarUrl, profile.nickname ?? profile.username, isDark),
          const SizedBox(height: 24),
          Text(profile.nickname ?? 'Нет никнейма', style: ThemeTextStyles.h1(isDark: isDark)),
          Text('@${profile.username}', style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue)),
          const SizedBox(height: 40),
          _buildInfoSection(isDark, [
            _InfoTile(label: 'Никнейм', value: profile.nickname ?? '-', icon: Icons.badge_outlined, isDark: isDark),
            _InfoTile(label: 'Имя пользователя', value: '@${profile.username}', icon: Icons.alternate_email_rounded, isDark: isDark),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, RoomModel room, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAvatar(room.avatarUrl, room.name ?? 'Группа', isDark),
          const SizedBox(height: 24),
          Text(room.name ?? 'Группа', style: ThemeTextStyles.h1(isDark: isDark)),
          Text('${room.participants.length} участников', style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue)),
          const SizedBox(height: 40),
          _buildInfoSection(isDark, [
            _InfoTile(label: 'Описание', value: room.description ?? 'Нет описания', icon: Icons.info_outline, isDark: isDark),
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
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: ThemeColors.blue.withValues(alpha: 0.1),
                        backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                        child: p.avatarUrl == null ? Text(p.username[0].toUpperCase()) : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nickname ?? p.username, style: ThemeTextStyles.h3(isDark: isDark)),
                          Text('@${p.username}', style: ThemeTextStyles.caption(isDark: isDark)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAvatar(room.avatarUrl, room.name ?? 'Канал', isDark),
          const SizedBox(height: 24),
          Text(room.name ?? 'Канал', style: ThemeTextStyles.h1(isDark: isDark)),
          Text('${room.participants.length} подписчиков', style: ThemeTextStyles.bodyLarge(color: ThemeColors.blue)),
          const SizedBox(height: 40),
          _buildInfoSection(isDark, [
            _InfoTile(label: 'Описание', value: room.description ?? 'Нет описания', icon: Icons.info_outline, isDark: isDark),
          ]),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String placeholder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ThemeColors.primaryGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF1A1A2E) : Colors.white),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: ThemeColors.blue.withValues(alpha: 0.1),
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null ? Text(placeholder[0].toUpperCase(), style: const TextStyle(fontSize: 40)) : null,
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

  const _InfoTile({required this.label, required this.value, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: ThemeColors.blue, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ThemeTextStyles.caption(isDark: isDark)),
              Text(value, style: ThemeTextStyles.bodyLarge(isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }
}
