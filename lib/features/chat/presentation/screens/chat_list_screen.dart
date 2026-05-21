import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_provider.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';
import 'package:forgelink/features/profile/presentation/providers/profile_provider.dart';
import 'package:forgelink/features/chat/presentation/providers/chat_controller.dart';
import 'dart:typed_data';

import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/widgets/premium_badge.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends HookConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(filteredRoomsProvider);
    final searchQuery = ref.watch(chatSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = useTextEditingController();
    final currentUserId = ref.watch(authUserProvider)?.id;

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Мессенджер',
                      style: ThemeTextStyles.h2(isDark: isDark),
                    ),
                    Row(
                      children: [
                        GlassBox(
                          padding: const EdgeInsets.all(2),
                          borderRadius: BorderRadius.circular(6),
                          opacity: isDark ? 0.2 : 0.1,
                          child: IconButton(
                            onPressed: () =>
                                _showCreateChatSheet(context, isDark),
                            icon: Icon(
                              Icons.add_rounded,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassBox(
                          padding: const EdgeInsets.all(2),
                          borderRadius: BorderRadius.circular(6),
                          opacity: isDark ? 0.2 : 0.1,
                          child: IconButton(
                            onPressed: () =>
                                ref.read(authRepositoryProvider).logout(),
                            icon: Icon(
                              Icons.logout_rounded,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassBox(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(16),
                  opacity: isDark ? 0.1 : 0.05,
                  child: TextField(
                    controller: searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) => ref
                        .read(chatSearchQueryProvider.notifier)
                        .update(value),
                    decoration: InputDecoration(
                      hintText: 'Поиск чатов...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                ref
                                    .read(chatSearchQueryProvider.notifier)
                                    .update('');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              color: isDark ? Colors.white38 : Colors.black38,
                            )
                          : null,
                    ),
                    style: ThemeTextStyles.bodyMedium(isDark: isDark),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomsProvider);
                  },
                  child: roomsAsync.when(
                    data: (rooms) {
                      final cleanQuery = searchQuery.trim();
                      if (cleanQuery.isNotEmpty) {
                        final localResults = rooms.where((r) {
                          return r.participants.any((p) => p.id == currentUserId);
                        }).toList();

                        final newChannels = rooms.where((r) {
                          final isParticipant = r.participants.any((p) => p.id == currentUserId);
                          return !isParticipant && r.type == RoomType.channel;
                        }).toList();

                        if (localResults.isEmpty && newChannels.isEmpty) {
                          return _EmptySearchPlaceholder(isDark: isDark);
                        }

                        final listItems = <dynamic>[];
                        if (newChannels.isNotEmpty) {
                          if (localResults.isNotEmpty) {
                            listItems.add('Мои чаты');
                            listItems.addAll(localResults);
                          }
                          listItems.add('Глобальный поиск');
                          listItems.addAll(newChannels);
                        } else {
                          listItems.addAll(localResults);
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];
                            if (item is String) {
                              return _SectionHeader(
                                title: item,
                                icon: item == 'Мои чаты'
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.explore_outlined,
                                isDark: isDark,
                              );
                            }
                            return _RoomItem(
                              room: item as RoomModel,
                              currentUserId: currentUserId,
                              isDark: isDark,
                            );
                          },
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          return _RoomItem(
                            room: rooms[index],
                            currentUserId: currentUserId,
                            isDark: isDark,
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
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 64,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Не удалось загрузить чаты',
                              style: ThemeTextStyles.h3(isDark: isDark),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              err.toString(),
                              textAlign: TextAlign.center,
                              style: ThemeTextStyles.bodySmall(isDark: isDark),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateChatSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _CreateChatBottomSheet(isDark: isDark),
    );
  }
}

class _RoomItem extends ConsumerWidget {
  final RoomModel room;
  final String? currentUserId;
  final bool isDark;

  const _RoomItem({
    required this.room,
    this.currentUserId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String displayName = 'Неизвестно';
    String? avatarUrl = room.avatarUrl;
    bool isOnline = false;

    if (room.type == RoomType.room && room.participants.isNotEmpty) {
      final otherParticipant = room.participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => room.participants.first,
      );
      displayName = otherParticipant.nickname ?? otherParticipant.username;
      avatarUrl = otherParticipant.avatarUrl;
      isOnline = otherParticipant.isOnline ?? false;

      final otherAvatarBase64Async = ref.watch(
        userAvatarBase64Provider(otherParticipant.id),
      );
      final isPremium = otherParticipant.isPremium;
      return _buildItem(
        context,
        ref,
        displayName,
        avatarUrl,
        isOnline,
        isPremium,
        false,
        otherAvatarBase64Async.asData?.value,
      );
    } else {
      displayName = room.name ?? 'Группа';
    }

    return _buildItem(
      context,
      ref,
      displayName,
      avatarUrl,
      isOnline,
      false,
      false,
      null,
    );
  }

  Widget _buildItem(
    BuildContext context,
    WidgetRef ref,
    String displayName,
    String? avatarUrl,
    bool isOnline,
    bool isPremium,
    bool isLoading,
    Uint8List? avatarBase64,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          final isParticipant = room.participants.any(
            (p) => p.id == currentUserId,
          );
          if (!isParticipant && room.type == RoomType.channel) {
            await ref.read(chatControllerProvider.notifier).joinRoom(room.id);
          }
          if (context.mounted) {
            context.pushNamed(
              'chat_detail',
              pathParameters: {'roomId': room.id},
              queryParameters: {'type': room.type.name},
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.blue.withValues(alpha: isDark ? 0.05 : 0.03),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: GlassBox(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(24),
            opacity: isDark ? 0.08 : 0.05,
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThemeColors.blue.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: ThemeColors.blue.withValues(
                          alpha: 0.05,
                        ),
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : (avatarBase64 != null
                                  ? MemoryImage(avatarBase64)
                                  : null),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ThemeColors.blue,
                                ),
                              )
                            : (avatarUrl == null && avatarBase64 == null
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : '?',
                                      style: ThemeTextStyles.h2(
                                        color: ThemeColors.blue,
                                      ),
                                    )
                                  : null),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
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
                          ),
                          if (room.lastMessageAt != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                DateFormat.Hm().format(
                                  room.lastMessageAt!.toLocal(),
                                ),
                                style: ThemeTextStyles.caption(
                                  isDark: isDark,
                                  color: ThemeColors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildLastMessage(room, isDark),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastMessage(RoomModel room, bool isDark) {
    final isSticker = room.lastMessageMediaType == 'sticker';

    if (room.lastMessageMediaUrl != null || isSticker) {
      final isImage =
          room.lastMessageMediaType?.startsWith('image/') == true ||
          room.lastMessageMediaName?.toLowerCase().endsWith('.jpg') == true ||
          room.lastMessageMediaName?.toLowerCase().endsWith('.jpeg') == true ||
          room.lastMessageMediaName?.toLowerCase().endsWith('.png') == true;
      final isVideo = room.lastMessageMediaType?.startsWith('video/') == true;

      return Row(
        children: [
          if (isImage)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: room.lastMessageMediaUrl!,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.withValues(alpha: 0.1)),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported_rounded, size: 14),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                isSticker
                    ? Icons.sticky_note_2_rounded
                    : (isVideo
                          ? Icons.videocam_rounded
                          : Icons.insert_drive_file_rounded),
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          Expanded(
            child: Text(
              isSticker
                  ? '👾 Стикер'
                  : (room.lastMessage != null && room.lastMessage!.isNotEmpty
                        ? room.lastMessage!
                        : (isImage
                              ? 'Фото'
                              : (isVideo
                                    ? 'Видео'
                                    : (room.lastMessageMediaName ?? 'Файл')))),
              style: ThemeTextStyles.bodyMedium(
                isDark: isDark,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      room.lastMessage ?? 'Сообщений пока нет',
      style: ThemeTextStyles.bodyMedium(
        isDark: isDark,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CreateChatBottomSheet extends StatelessWidget {
  final bool isDark;

  const _CreateChatBottomSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Создать новое', style: ThemeTextStyles.h2(isDark: isDark)),
          const SizedBox(height: 32),
          _buildOption(
            context,
            icon: Icons.person_add_rounded,
            title: 'Новый чат',
            subtitle: 'Приватная беседа тет-а-тет',
            color: const Color(0xFF6366F1),
            onTap: () {
              Navigator.pop(context);
              context.push('/create-chat?type=room');
            },
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            icon: Icons.group_add_rounded,
            title: 'Новая группа',
            subtitle: 'Общайтесь с друзьями и коллегами',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.pop(context);
              context.push('/create-chat?type=group');
            },
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            icon: Icons.campaign_rounded,
            title: 'Новый канал',
            subtitle: 'Транслируйте контент на аудиторию',
            color: const Color(0xFFEC4899),
            onTap: () {
              Navigator.pop(context);
              context.push('/create-chat?type=channel');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ThemeTextStyles.h3(isDark: isDark)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ThemeTextStyles.caption(
                      isDark: isDark,
                    ).copyWith(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: ThemeTextStyles.caption(
              isDark: isDark,
            ).copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchPlaceholder extends StatelessWidget {
  final bool isDark;

  const _EmptySearchPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeColors.blue.withValues(alpha: isDark ? 0.1 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ничего не найдено',
                style: ThemeTextStyles.h3(isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'По вашему запросу результатов нет.\nПопробуйте ввести другое название.',
                style: ThemeTextStyles.bodyMedium(
                  isDark: isDark,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Delete the old Speed Dial class as it's no longer used
