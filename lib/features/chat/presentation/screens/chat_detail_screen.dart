import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rickandmorty/features/chat/presentation/providers/chat_provider.dart';
import 'package:rickandmorty/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:rickandmorty/features/chat/presentation/widgets/forward_dialog.dart';
import 'package:rickandmorty/features/chat/presentation/widgets/report_dialog.dart';
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
    final currentUserId =
        authUser?.id ?? Supabase.instance.client.auth.currentUser?.id;

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

            avatarBase64 = ref
                .watch(userAvatarBase64Provider(other.id))
                .asData
                ?.value;
          }
        });

        // If still loading or empty, use placeholders but keep "room" logic
        if (title == 'Загрузка...' && room.name != null) title = room.name!;
      } else {
        title = room.name ?? 'Группа';
        avatarUrl = room.avatarUrl;
      }
    }

    final chatState = ref.watch(chatControllerProvider);
    final roomPendingMessages = chatState.pendingMessages[roomId] ?? [];
    final replyMessage = useState<MessageModel?>(null);
    final editingMessage = useState<MessageModel?>(null);
    final selectedMessages = useState<List<MessageModel>>([]);
    final isUploading = useState(false);
    final isSelectionMode = selectedMessages.value.isNotEmpty;

    void toggleSelection(MessageModel message) {
      if (message.id.startsWith('temp_')) return;
      if (selectedMessages.value.any((m) => m.id == message.id)) {
        selectedMessages.value = selectedMessages.value
            .where((m) => m.id != message.id)
            .toList();
      } else {
        selectedMessages.value = [...selectedMessages.value, message];
      }
    }

    // Sync editing message content to text field
    useEffect(() {
      if (editingMessage.value != null) {
        controller.text = editingMessage.value!.content;
        focusNode.requestFocus();
      }
      return null;
    }, [editingMessage.value]);

    final allMessages = useMemoized(() {
      final messages = messagesAsync.value ?? [];
      
      // Filter out messages that are being deleted optimistically
      final activeMessages = messages.where((m) => !chatState.deletingIds.contains(m.id)).toList();

      final filteredPending = roomPendingMessages.where((pm) {
        // Check if there's a real message that matches this pending one
        return !activeMessages.any((m) {
          final isSameContent = m.content == pm.content && m.profileId == pm.profileId;
          final isSameForward = m.forwardedFrom == pm.forwardedFrom;
          final isWithinTime = m.createdAt.difference(pm.createdAt).inSeconds.abs() < 60;

          if (pm.forwardedFrom != null) {
            // For forwarded messages, be more specific with forwardedFrom ID
            return isSameForward && isWithinTime;
          }
          return isSameContent && isWithinTime;
        });
      }).toList();

      final combined = [...activeMessages, ...filteredPending];
      combined.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return combined;
    }, [messagesAsync.value, chatState]);

    Future<void> handleSend() async {
      if (controller.text.trim().isNotEmpty && currentUserId != null) {
        final text = controller.text.trim();

        if (editingMessage.value != null) {
          final messageId = editingMessage.value!.id;
          editingMessage.value = null;
          controller.clear();
          focusNode.requestFocus();
          try {
            await ref
                .read(chatControllerProvider.notifier)
                .editMessage(roomId, messageId, text);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка при редактировании: $e')),
              );
            }
          }
        } else {
          final replyId = replyMessage.value?.id;
          controller.clear();
          replyMessage.value = null;
          focusNode.requestFocus();

          // Send via controller (background)
          ref
              .read(chatControllerProvider.notifier)
              .sendMessage(
                roomId,
                text,
                currentUserId,
                replyToMessageId: replyId,
              )
              .catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              });
        }
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
              isDark
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.1),
              BlendMode.srcOver,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
          ),
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
                        : (avatarBase64 != null
                              ? MemoryImage(avatarBase64!)
                              : null),
                    child: participantsAsync.isLoading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: ThemeColors.blue,
                            ),
                          )
                        : (avatarUrl == null && avatarBase64 == null
                              ? Text(
                                  title.isNotEmpty
                                      ? title[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: ThemeColors.blue,
                                    fontSize: 14,
                                  ),
                                )
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
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF16213E)
                                : Colors.white,
                            width: 1.5,
                          ),
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
                    Text(
                      'в сети',
                      style: ThemeTextStyles.caption(
                        color: Colors.green,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    reverse: true,
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      final message =
                          allMessages[allMessages.length - 1 - index];

                      // Find replied message info
                      String? repliedContent;
                      String? repliedSenderName;
                      if (message.replyToMessageId != null) {
                        final repliedMsg = allMessages
                            .where((m) => m.id == message.replyToMessageId)
                            .firstOrNull;
                        if (repliedMsg != null) {
                          repliedContent = repliedMsg.content;
                          // Find sender name
                          final participants = participantsAsync.value ?? [];
                          final sender = participants
                              .where((p) => p.id == repliedMsg.profileId)
                              .firstOrNull;
                          repliedSenderName = sender?.nickname ??
                              sender?.username ??
                              (repliedMsg.profileId == currentUserId
                                  ? 'Вы'
                                  : 'Пользователь');
                        } else {
                          // If parent message is not found, it means it was deleted
                          repliedContent = 'Сообщение удалено';
                          repliedSenderName = 'Удаленное сообщение';
                        }
                      }

                      final isMine = message.profileId == currentUserId;
                      return ChatBubble(
                        content: message.content,
                        isMine: isMine,
                        timestamp: DateFormat('HH:mm')
                            .format(message.createdAt.toLocal()),
                        isEdited: message.isEdited,
                        isDeleted: message.isDeleted,
                        reactions: message.reactions,
                        currentUserId: currentUserId,
                        repliedMessageContent: repliedContent,
                        repliedMessageSenderName: repliedSenderName,
                        forwardedInfo: message.forwardedInfo,
                        mediaUrl: message.mediaUrl,
                        mediaType: message.mediaType,
                        isSelected: selectedMessages.value
                            .any((m) => m.id == message.id),
                        isSelectionMode: isSelectionMode,
                        onTap: () => toggleSelection(message),
                        onLongPress: () => toggleSelection(message),
                        onReactionToggled: (emoji) {
                          ref
                              .read(chatRepositoryProvider)
                              .toggleReaction(message.id, emoji);
                        },
                        onReply: () {
                          replyMessage.value = message;
                          focusNode.requestFocus();
                        },
                        onEdit: isMine
                            ? () {
                                editingMessage.value = message;
                              }
                            : null,
                        onDelete: (isMine || room?.type == RoomType.room)
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Удалить сообщение?'),
                                    content: const Text(
                                      'Это действие нельзя отменить.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Отмена'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Удалить',
                                          style: TextStyle(
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await ref
                                        .read(chatControllerProvider.notifier)
                                        .deleteMessage(roomId, message.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Ошибка при удалении: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            : null,
                        onForward: () {
                          // Find sender name for forwarding info
                          final participants = participantsAsync.value ?? [];
                          final sender = participants
                              .where((p) => p.id == message.profileId)
                              .firstOrNull;
                          final senderName = sender?.nickname ??
                              sender?.username ??
                              (message.profileId == currentUserId
                                  ? 'Вы'
                                  : 'Пользователь');

                          showDialog(
                            context: context,
                            builder: (context) => ForwardDialog(
                              content: message.content,
                              onForward: (targetRoomId) {
                                ref
                                    .read(chatControllerProvider.notifier)
                                    .sendMessage(
                                      targetRoomId,
                                      message.content,
                                      currentUserId!,
                                      forwardedFrom: message.id,
                                      forwardedInfo: {
                                        'sender_name': senderName,
                                        'sender_id': message.profileId,
                                      },
                                    )
                                    .then((_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Сообщение переслано'),
                                      ),
                                    );
                                  }
                                }).catchError((e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка пересылки: $e'),
                                      ),
                                    );
                                  }
                                });
                              },
                            ),
                          );
                        },
                        onReport: () {
                          showDialog(
                            context: context,
                            builder: (context) => ReportDialog(
                              targetId: message.id,
                              targetType: 'message',
                              onReport: (reason, details) async {
                                try {
                                  await ref
                                      .read(chatRepositoryProvider)
                                      .reportTarget(
                                        targetId: message.id,
                                        targetType: 'message',
                                        reason: reason,
                                        details: details,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Жалоба отправлена модераторам',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Ошибка при отправке жалобы: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
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
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки сообщений',
                          style: ThemeTextStyles.h3(isDark: isDark),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(messagesProvider(roomId)),
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

              // Reply Preview
              if (replyMessage.value != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    opacity: isDark ? 0.2 : 0.1,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          color: ThemeColors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                replyMessage.value!.profileId == currentUserId
                                    ? 'Вы'
                                    : 'Ответ на сообщение',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.blue,
                                ),
                              ),
                              Text(
                                (replyMessage.value!.isDeleted ?? false)
                                    ? 'Сообщение удалено'
                                    : replyMessage.value!.content,
                                style: ThemeTextStyles.bodySmall(
                                  isDark: isDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          onPressed: () => replyMessage.value = null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Edit Preview
              if (editingMessage.value != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GlassBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    opacity: isDark ? 0.2 : 0.1,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: ThemeColors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Редактирование',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.blue,
                                ),
                              ),
                              Text(
                                editingMessage.value!.content,
                                style: ThemeTextStyles.bodySmall(
                                  isDark: isDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          onPressed: () {
                            editingMessage.value = null;
                            controller.clear();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Selection Action Bar or Input Area
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isSelectionMode
                      ? GlassBox(
                          key: const ValueKey('selection_bar'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          borderRadius: BorderRadius.circular(30),
                          opacity: isDark ? 0.2 : 0.3,
                          color: ThemeColors.blue.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              Text(
                                '${selectedMessages.value.length}',
                                style: ThemeTextStyles.h3(
                                    isDark: isDark, color: ThemeColors.blue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Выбрано',
                                  style: ThemeTextStyles.bodyMedium(
                                      isDark: isDark),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_rounded,
                                    color: ThemeColors.blue),
                                tooltip: 'Переслать',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ForwardDialog(
                                      content:
                                          '${selectedMessages.value.length} сообщения',
                                      onForward: (targetRoomId) async {
                                        final msgs =
                                            List<MessageModel>.from(
                                                selectedMessages.value);
                                        selectedMessages.value = [];

                                        final profiles =
                                            participantsAsync.value ?? [];

                                        final replyContents = <String, String>{};
                                        for (final msg in msgs) {
                                          if (msg.replyToMessageId != null) {
                                            final replied = messagesAsync.value
                                                ?.where((m) =>
                                                    m.id == msg.replyToMessageId)
                                                .firstOrNull;
                                            if (replied != null) {
                                              replyContents[msg.id] =
                                                  replied.content;
                                            }
                                          }
                                        }

                                        ref
                                            .read(chatControllerProvider
                                                .notifier)
                                            .forwardMessages(
                                              targetRoomId,
                                              msgs,
                                              currentUserId!,
                                              profiles,
                                              replyContents: replyContents,
                                            );

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Сообщения пересланы'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                              if (room?.type == RoomType.room ||
                                  selectedMessages.value.every(
                                      (m) => m.profileId == currentUserId))
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded,
                                      color: Colors.redAccent),
                                  tooltip: 'Удалить',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: isDark
                                            ? const Color(0xFF1A1A1A)
                                            : Colors.white,
                                        title: const Text('Удалить сообщения?'),
                                        content: Text(
                                            'Вы уверены, что хотите удалить ${selectedMessages.value.length} сообщения?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      final ids = selectedMessages.value
                                          .map((m) => m.id)
                                          .toList();
                                      selectedMessages.value = [];
                                      await ref
                                          .read(chatControllerProvider.notifier)
                                          .deleteMessages(roomId, ids);
                                    }
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Закрыть',
                                onPressed: () => selectedMessages.value = [],
                              ),
                            ],
                          ),
                        )
                      : GlassBox(
                          key: const ValueKey('input_bar'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          opacity: isDark ? 0.15 : 0.08,
                          child: Row(
                            children: [
                                IconButton(
                                  icon: isUploading.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: ThemeColors.blue,
                                          ),
                                        )
                                      : Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                  onPressed: isUploading.value
                                      ? null
                                      : () async {
                                          try {
                                            final picker = ImagePicker();
                                            final image =
                                                await picker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 70,
                                            );

                                            if (image != null &&
                                                context.mounted) {
                                              isUploading.value = true;

                                              // Added artificial delay to prevent Windows network contention (SocketException 10054)
                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: 500));

                                              if (!context.mounted) return;

                                              await ref
                                                  .read(
                                                      chatControllerProvider.notifier)
                                                  .sendMediaMessage(
                                                    roomId,
                                                    currentUserId!,
                                                    image.path,
                                                    image.name,
                                                    'image/${image.name.split('.').last}',
                                                  );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Ошибка загрузки: $e'),
                                                ),
                                              );
                                            }
                                          } finally {
                                            isUploading.value = false;
                                          }
                                        },
                                ),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onSubmitted: (_) => handleSend(),
                                  decoration: InputDecoration(
                                    hintText: 'Напишите сообщение...',
                                    hintStyle: ThemeTextStyles.bodyMedium(
                                      color:
                                          isDark ? Colors.white38 : Colors.black38,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  style:
                                      ThemeTextStyles.bodyMedium(isDark: isDark),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  gradient: ThemeColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ThemeColors.blue
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: handleSend,
                                  icon: Icon(
                                    editingMessage.value != null
                                        ? Icons.done_rounded
                                        : Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
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
}
