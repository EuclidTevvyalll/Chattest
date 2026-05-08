import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';
import 'package:rickandmorty/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';
import 'package:rickandmorty/features/chat/domain/models/message_model.dart';
import 'package:rickandmorty/features/profile/presentation/providers/profile_provider.dart';
import 'dart:typed_data';

class ChatDetailScreen extends HookConsumerWidget {
  final String roomId;
  final RoomType type;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    this.type = RoomType.room,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(roomId));
    final roomsAsync = ref.watch(roomsProvider);

    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final authUser = ref.watch(authUserProvider);
    final currentUserId = authUser?.id ?? Supabase.instance.client.auth.currentUser?.id;

    final participantsAsync = ref.watch(roomParticipantsProvider(roomId));
    
    final room = roomsAsync.value?.where((r) => r.id == roomId).firstOrNull;
    String title = 'Загрузка...';
    String? avatarUrl;
    Uint8List? avatarBase64;
    bool isOnline = false;
 
    if (room != null) {
      if (room.type == RoomType.room) {
        participantsAsync.whenData((participants) {
          if (participants.isNotEmpty) {
            final other = participants.firstWhere(
              (p) => p.id != currentUserId,
              orElse: () => participants.first,
            );
            title = other.nickname ?? other.username;
            avatarUrl = other.avatarUrl;
            isOnline = other.isOnline ?? false;
            
            avatarBase64 = ref.watch(userAvatarBase64Provider(other.id)).asData?.value;
          }
        });
        
        // If still loading or empty, use placeholders but keep "room" logic
        if (title == 'Загрузка...' && room.name != null) title = room.name!;
      } else {
        title = room.name ?? 'Группа';
        avatarUrl = room.avatarUrl;
      }
    }

    final pendingMessagesMap = ref.watch(chatControllerProvider);
    final roomPendingMessages = pendingMessagesMap[roomId] ?? [];
    final replyMessage = useState<MessageModel?>(null);

    final allMessages = useMemoized(() {
      final messages = messagesAsync.value ?? [];
      final filteredPending = roomPendingMessages.where((pm) {
        // More robust check: if there is ANY message from us with same content 
        // within a reasonable time window (60s), consider it 'delivered'
        return !messages.any((m) => 
          m.profileId == pm.profileId &&
          m.content == pm.content && 
          (m.createdAt.difference(pm.createdAt).inSeconds.abs() < 60));
      }).toList();
      
      final combined = [...messages, ...filteredPending];
      combined.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return combined;
    }, [messagesAsync.value, roomPendingMessages]);

    Future<void> handleSend() async {
      if (controller.text.trim().isNotEmpty && currentUserId != null) {
        final text = controller.text.trim();
        final replyId = replyMessage.value?.id;
        
        controller.clear();
        replyMessage.value = null;
        focusNode.requestFocus();

        // Send via controller (background)
        ref.read(chatControllerProvider.notifier).sendMessage(
          roomId, 
          text, 
          currentUserId,
          replyToMessageId: replyId,
        ).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: $e')),
            );
          }
        });
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark 
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.7) 
            : Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(
              isDark ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
              BlendMode.srcOver,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () => context.pushNamed(
            'chat_info',
            pathParameters: {'roomId': roomId},
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ThemeColors.blue.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null 
                      ? CachedNetworkImageProvider(avatarUrl!)
                      : (avatarBase64 != null ? MemoryImage(avatarBase64!) : null),
                    child: participantsAsync.isLoading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: ThemeColors.blue),
                        )
                      : (avatarUrl == null && avatarBase64 == null
                          ? Text(title.isNotEmpty ? title[0].toUpperCase() : '?', style: TextStyle(color: ThemeColors.blue, fontSize: 14)) 
                          : null),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF16213E) : Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ThemeTextStyles.h3(isDark: isDark)),
                  if (isOnline)
                    Text('в сети', style: ThemeTextStyles.caption(color: Colors.green, isDark: isDark)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
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
              Expanded(
                child: messagesAsync.when(
                  data: (_) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    reverse: true,
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      final message = allMessages[allMessages.length - 1 - index];
                      
                      // Find replied message info
                      String? repliedContent;
                      String? repliedSenderName;
                      if (message.replyToMessageId != null) {
                        final repliedMsg = allMessages.where((m) => m.id == message.replyToMessageId).firstOrNull;
                        if (repliedMsg != null) {
                          repliedContent = repliedMsg.content;
                          // Find sender name
                          final participants = participantsAsync.value ?? [];
                          final sender = participants.where((p) => p.id == repliedMsg.profileId).firstOrNull;
                          repliedSenderName = sender?.nickname ?? sender?.username ?? (repliedMsg.profileId == currentUserId ? 'Вы' : 'Пользователь');
                        }
                      }

                      return ChatBubble(
                        content: message.content,
                        isMine: message.profileId == currentUserId,
                        timestamp: message.createdAt.toLocal(),
                        reactions: message.reactions,
                        currentUserId: currentUserId,
                        repliedMessageContent: repliedContent,
                        repliedMessageSenderName: repliedSenderName,
                        onReactionToggled: (emoji) {
                          ref.read(chatRepositoryProvider).toggleReaction(message.id, emoji);
                        },
                        onReply: () {
                          replyMessage.value = message;
                          focusNode.requestFocus();
                        },
                      );
                    },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: ThemeColors.blue,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text('Ошибка загрузки сообщений', style: ThemeTextStyles.h3(isDark: isDark)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(messagesProvider(roomId)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeColors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Повторить', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Reply Preview
              if (replyMessage.value != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GlassBox(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderRadius: BorderRadius.circular(16),
                    opacity: isDark ? 0.2 : 0.1,
                    child: Row(
                      children: [
                        const Icon(Icons.reply_rounded, color: ThemeColors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                replyMessage.value!.profileId == currentUserId ? 'Вы' : 'Ответ на сообщение',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.blue,
                                ),
                              ),
                              Text(
                                replyMessage.value!.content,
                                style: ThemeTextStyles.bodySmall(isDark: isDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                          onPressed: () => replyMessage.value = null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Input Area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassBox(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  borderRadius: BorderRadius.circular(30),
                  opacity: isDark ? 0.15 : 0.08,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? Colors.white54 : Colors.black45),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onSubmitted: (_) => handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Напишите сообщение...',
                            hintStyle: ThemeTextStyles.bodyMedium(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          style: ThemeTextStyles.bodyMedium(isDark: isDark),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          gradient: ThemeColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ThemeColors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: handleSend,
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
