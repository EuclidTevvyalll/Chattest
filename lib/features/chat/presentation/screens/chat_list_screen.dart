import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';


import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends HookConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Messenger', style: ThemeTextStyles.h1(isDark: isDark)),
                    GlassBox(
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(12),
                      opacity: isDark ? 0.2 : 0.1,
                      child: IconButton(
                        onPressed: () => ref.read(authRepositoryProvider).logout(),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomsProvider);
                  },
                  child: roomsAsync.when(
                    data: (rooms) => ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        String displayName = 'Unknown';
                        String? avatarUrl = room.avatarUrl;
                        bool isOnline = false;

                        if (room.type == RoomType.room) {
                          final otherParticipant = room.participants.firstWhere(
                            (p) => p.id != currentUserId,
                            orElse: () => room.participants.first,
                          );
                          displayName = otherParticipant.nickname ?? otherParticipant.username;
                          avatarUrl = otherParticipant.avatarUrl;
                          isOnline = otherParticipant.isOnline ?? false;
                        } else {
                          displayName = room.name ?? 'Group';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () => context.pushNamed(
                              'chat_detail',
                              pathParameters: {'roomId': room.id},
                              queryParameters: {'type': room.type.name},
                            ),
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
                                            backgroundColor: ThemeColors.blue.withValues(alpha: 0.05),
                                            backgroundImage: avatarUrl != null
                                                ? NetworkImage(avatarUrl)
                                                : null,
                                            child: avatarUrl == null
                                                ? Text(
                                                    displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                                                    style: ThemeTextStyles.h2(color: ThemeColors.blue),
                                                  )
                                                : null,
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
                                                border: Border.all(color: isDark ? const Color(0xFF16213E) : Colors.white, width: 2),
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
                                                child: Text(
                                                  displayName,
                                                  style: ThemeTextStyles.h3(isDark: isDark),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (room.lastMessageAt != null)
                                                Text(
                                                  DateFormat.Hm().format(room.lastMessageAt!.toLocal()),
                                                  style: ThemeTextStyles.caption(
                                                    isDark: isDark,
                                                    color: ThemeColors.blue,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            room.lastMessage ?? 'No messages yet',
                                            style: ThemeTextStyles.bodyMedium(
                                              isDark: isDark,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: ThemeColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/create-chat'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
