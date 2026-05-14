import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/widgets/premium_badge.dart';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';

class ForwardDialog extends HookConsumerWidget {
  final String content;
  final Function(String roomId) onForward;

  const ForwardDialog({
    super.key,
    required this.content,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(authUserProvider)?.id;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: GlassBox(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(28),
        opacity: isDark ? 0.2 : 0.4,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.forward_rounded, color: ThemeColors.blue),
                const SizedBox(width: 12),
                Text(
                  'Переслать в...',
                  style: ThemeTextStyles.h2(isDark: isDark),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: ThemeTextStyles.bodySmall(
                isDark: isDark,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 32, color: Colors.white10),
            Flexible(
              child: roomsAsync.when(
                data: (rooms) => rooms.isEmpty
                    ? Center(
                        child: Text(
                          'У вас пока нет чатов',
                          style: ThemeTextStyles.bodyMedium(isDark: isDark),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          return _RoomForwardItem(
                            room: rooms[index],
                            currentUserId: currentUserId,
                            isDark: isDark,
                            onTap: () {
                              onForward(rooms[index].id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: ThemeColors.blue),
                ),
                error: (err, _) => Center(child: Text('Ошибка: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomForwardItem extends ConsumerWidget {
  final RoomModel room;
  final String? currentUserId;
  final bool isDark;
  final VoidCallback onTap;

  const _RoomForwardItem({
    required this.room,
    this.currentUserId,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(roomParticipantsProvider(room.id));

    return participantsAsync.when(
      data: (participants) {
        String displayName = 'Неизвестно';
        String? avatarUrl = room.avatarUrl;
        Uint8List? avatarBase64;

        if (room.type == RoomType.room && participants.isNotEmpty) {
          final otherParticipant = participants.firstWhere(
            (p) => p.id != currentUserId,
            orElse: () => participants.first,
          );
          displayName = otherParticipant.nickname ?? otherParticipant.username;
          avatarUrl = otherParticipant.avatarUrl;
          avatarBase64 = ref
              .watch(userAvatarBase64Provider(otherParticipant.id))
              .asData
              ?.value;
          final isPremium = otherParticipant.isPremium;
          return _buildItem(displayName, avatarUrl, avatarBase64, isPremium);
        } else {
          displayName = room.name ?? 'Группа';
          return _buildItem(displayName, avatarUrl, avatarBase64, false);
        }
      },
      loading: () => const SizedBox(height: 56),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildItem(
    String displayName,
    String? avatarUrl,
    Uint8List? avatarBase64,
    bool isPremium,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: ThemeColors.blue.withValues(alpha: 0.1),
        backgroundImage: avatarUrl != null
            ? CachedNetworkImageProvider(avatarUrl)
            : (avatarBase64 != null ? MemoryImage(avatarBase64) : null),
        child: avatarUrl == null && avatarBase64 == null
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: ThemeColors.blue),
              )
            : null,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              displayName,
              style: ThemeTextStyles.h3(isDark: isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PremiumBadge(isPremium: isPremium),
        ],
      ),
      trailing: const Icon(
        Icons.send_rounded,
        color: ThemeColors.blue,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
