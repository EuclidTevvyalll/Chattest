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

import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/features/chat/domain/models/room_model.dart';
import 'package:rickandmorty/features/chat/domain/models/message_model.dart';

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

    final room = roomsAsync.value?.where((r) => r.id == roomId).firstOrNull;
    String title = 'Чат';
    String? avatarUrl;
    bool isOnline = false;

    if (room != null) {
      if (room.type == RoomType.room) {
        final other = room.participants.firstWhere(
          (p) => p.id != currentUserId,
          orElse: () => room.participants.first,
        );
        title = other.nickname ?? other.username;
        avatarUrl = other.avatarUrl;
        isOnline = other.isOnline ?? false;
      } else {
        title = room.name ?? 'Группа';
        avatarUrl = room.avatarUrl;
      }
    }

    final pendingMessages = useState<List<MessageModel>>([]);

    final allMessages = useMemoized(() {
      final messages = messagesAsync.value ?? [];
      final filteredPending = pendingMessages.value.where((pm) {
        return !messages.any((m) => 
          m.profileId == pm.profileId &&
          m.content == pm.content && 
          (m.createdAt.difference(pm.createdAt).inSeconds.abs() < 10));
      }).toList();
      
      final combined = [...messages, ...filteredPending];
      combined.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return combined;
    }, [messagesAsync.value, pendingMessages.value]);

    Future<void> handleSend() async {
      if (controller.text.trim().isNotEmpty) {
        final text = controller.text.trim();
        controller.clear();
        focusNode.requestFocus();

        if (currentUserId == null) return;

        final temporaryMessage = MessageModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          roomId: roomId,
          profileId: currentUserId,
          content: text,
          createdAt: DateTime.now(),
        );

        pendingMessages.value = [...pendingMessages.value, temporaryMessage];

        try {
          await ref.read(chatRepositoryProvider).sendMessage(roomId, text);
        } catch (e) {
          if (context.mounted) {
            pendingMessages.value = pendingMessages.value
                .where((m) => m.id != temporaryMessage.id)
                .toList();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось отправить сообщение: $e')),
            );
          }
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
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
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null 
                      ? Text(title[0].toUpperCase(), style: TextStyle(color: ThemeColors.blue, fontSize: 14)) 
                      : null,
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
                      return ChatBubble(
                        content: message.content,
                        isMine: message.profileId == currentUserId,
                        timestamp: message.createdAt.toLocal(),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Ошибка: $err')),
                ),
              ),
              
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
