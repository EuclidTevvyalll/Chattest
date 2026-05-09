import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isMine;
  final String timestamp;
  final Map<String, List<String>> reactions;
  final Function(String emoji)? onReactionToggled;
  final Function()? onReply;
  final Function()? onForward;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress; // Added
  final VoidCallback? onTap; // Added
  final Map<String, dynamic>? forwardedInfo;
  final bool? isEdited;
  final bool? isDeleted;
  final bool isSelected; // Added
  final bool isSelectionMode; // Added
  final String? currentUserId;
  final String? repliedMessageContent;
  final String? repliedMessageSenderName;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaName;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isMine,
    required this.timestamp,
    this.reactions = const {},
    this.onReactionToggled,
    this.onReply,
    this.onForward,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.onTap,
    this.forwardedInfo,
    this.isEdited,
    this.isDeleted,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.currentUserId,
    this.repliedMessageContent,
    this.repliedMessageSenderName,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
  });

  void _showReactionPicker(BuildContext context) {
    final emojis = [
      '👍',
      '❤️',
      '😂',
      '🔥',
      '😮',
      '😢',
      '👏',
      '🎉',
      '🤔',
      '💯',
      '🚀',
      '👀',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => Align(
        alignment: const Alignment(0, 0.4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: BorderRadius.circular(28),
            opacity: isDark ? 0.2 : 0.4,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final newOffset = scrollController.offset +
                              pointerSignal.scrollDelta.dy;
                          if (newOffset < 0) {
                            scrollController.jumpTo(0);
                          } else if (newOffset >
                              scrollController.position.maxScrollExtent) {
                            scrollController.jumpTo(
                              scrollController.position.maxScrollExtent,
                            );
                          } else {
                            scrollController.jumpTo(newOffset);
                          }
                        }
                      },
                      child: ListView.builder(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: emojis.length,
                        itemBuilder: (context, index) {
                          final emoji = emojis[index];
                          return GestureDetector(
                            onTap: () {
                              onReactionToggled?.call(emoji);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: (reactions[emoji]
                                            ?.contains(currentUserId) ??
                                        false)
                                    ? ThemeColors.blue.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white10),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onReply?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            color: ThemeColors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ответить',
                            style: ThemeTextStyles.bodyLarge(
                              isDark: isDark,
                              color: ThemeColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onForward?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.forward_rounded,
                            color: ThemeColors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Переслать',
                            style: ThemeTextStyles.bodyLarge(
                              isDark: isDark,
                              color: ThemeColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onLongPress?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: ThemeColors.blue,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Выбрать',
                            style: ThemeTextStyles.bodyLarge(
                              isDark: isDark,
                              color: ThemeColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onReport?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.report_problem_rounded,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Пожаловаться',
                            style: ThemeTextStyles.bodyLarge(
                              isDark: isDark,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMine && !(isDeleted ?? false)) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onEdit?.call();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: ThemeColors.blue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Изменить',
                              style: ThemeTextStyles.bodyLarge(
                                isDark: isDark,
                                color: ThemeColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_rounded,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Удалить',
                              style: ThemeTextStyles.bodyLarge(
                                isDark: isDark,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayRepliedContent = repliedMessageContent ??
        forwardedInfo?['fwd_replied_content'] ??
        forwardedInfo?['replied_content'];
    final displayRepliedSender = repliedMessageSenderName ??
        forwardedInfo?['fwd_replied_sender'] ??
        forwardedInfo?['replied_sender'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: isSelectionMode
                    ? onLongPress
                    : () => _showReactionPicker(context),
                onTap: isSelectionMode ? onTap : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      isSelectionMode ? const EdgeInsets.all(4) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThemeColors.blue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? ThemeColors.blue
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? ThemeColors.blue
                                    : (isDark ? Colors.white24 : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMine ? 20 : 4),
                              bottomRight: Radius.circular(isMine ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isMine ? ThemeColors.blue : Colors.black)
                                    .withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GlassBox(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isMine
                              ? ThemeColors.blue
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white),
                          opacity: isMine
                              ? (isDark ? 0.3 : 0.6)
                              : (isDark ? 0.1 : 0.7),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMine ? 20 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (forwardedInfo != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.forward_rounded,
                                        size: 12,
                                        color: isMine
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Переслано от ${forwardedInfo!['sender_name'] ?? 'Пользователь'}',
                                        style: ThemeTextStyles.caption(
                                          color: isMine
                                              ? Colors.white70
                                              : Colors.grey,
                                        ).copyWith(fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (displayRepliedContent != null) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: isMine
                                            ? Colors.white70
                                            : ThemeColors.blue,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayRepliedSender ??
                                            'Удаленный пользователь',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isMine
                                              ? Colors.white
                                              : ThemeColors.blue,
                                        ),
                                      ),
                                      Text(
                                        displayRepliedContent,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMine
                                              ? Colors.white70
                                              : (isDark
                                                  ? Colors.white60
                                                  : Colors.black54),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (mediaUrl != null || mediaName != null) ...[
                                if (mediaType?.startsWith('image') ?? (mediaUrl == null && mediaName != null))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: mediaUrl == null 
                                        ? Container(
                                            height: 200,
                                            width: double.infinity,
                                            color: isMine ? Colors.white12 : Colors.black12,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: ThemeColors.blue,
                                              ),
                                            ),
                                          )
                                        : mediaUrl!.startsWith('data:image')
                                          ? Image.memory(
                                              base64Decode(
                                                  mediaUrl!.split(',').last),
                                              fit: BoxFit.cover,
                                              height: 200,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const SizedBox(
                                                height: 200,
                                                child: Center(
                                                  child: Icon(
                                                      Icons.broken_image,
                                                      color:
                                                          Colors.redAccent),
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: mediaUrl!,
                                        placeholder: (context, url) =>
                                            Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: isMine
                                                ? Colors.white12
                                                : (isDark
                                                    ? Colors.white10
                                                    : Colors.black.withValues(
                                                        alpha: 0.1)),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: ThemeColors.blue,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Icon(Icons.broken_image,
                                                color: Colors.redAccent),
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  // For other file types (Videos, Files)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        // Open media URL in browser or viewer
                                        if (mediaUrl != null) {
                                          // TODO: Implement media viewer or launcher
                                          debugPrint('Opening media: $mediaUrl');
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMine
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : Colors.black.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isMine 
                                              ? Colors.white24 
                                              : Colors.black12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (mediaUrl == null && mediaName != null)
                                              const SizedBox(
                                                width: 32,
                                                height: 32,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white70,
                                                ),
                                              )
                                            else
                                              Icon(
                                                (mediaType?.startsWith('video/') ?? false)
                                                    ? Icons.play_circle_fill_rounded
                                                    : Icons.insert_drive_file_rounded,
                                                size: 32,
                                                color: isMine ? Colors.white : ThemeColors.blue,
                                              ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    mediaName ?? 'Файл',
                                                    style: ThemeTextStyles.bodyMedium(
                                                      color: isMine ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                                    ).copyWith(fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (mediaType != null)
                                                    Text(
                                                      mediaType!.split('/').last.toUpperCase(),
                                                      style: ThemeTextStyles.caption(
                                                        isDark: isDark,
                                                        color: isMine ? Colors.white70 : (isDark ? Colors.white54 : Colors.black54),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                              if (isDeleted ?? false)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 14,
                                      color: isMine ? Colors.white60 : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Сообщение удалено',
                                      style: ThemeTextStyles.bodyMedium(
                                        color: isMine
                                            ? Colors.white60
                                            : Colors.grey,
                                      ).copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  content,
                                  style: ThemeTextStyles.bodyMedium(
                                    color: isMine
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : Colors.black87),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timestamp,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMine
                                          ? Colors.white70
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                    ),
                                  ),
                                  if (isEdited ?? false) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      'изменено',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        color: isMine
                                            ? Colors.white70
                                            : (isDark
                                                ? Colors.white38
                                                : Colors.black38),
                                      ),
                                    ),
                                  ],
                                ],
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
              if (reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: reactions.entries.map((entry) {
                      final emoji = entry.key;
                      final count = entry.value.length;
                      final isSelected = entry.value.contains(currentUserId);

                      return GestureDetector(
                        onTap: () => onReactionToggled?.call(emoji),
                        child: GlassBox(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? ThemeColors.blue
                              : (isDark ? Colors.white : Colors.black87),
                          opacity: isSelected ? 0.2 : 0.05,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                count.toString(),
                                style: ThemeTextStyles.caption(
                                  isDark: isDark,
                                  color: isSelected
                                      ? ThemeColors.blue
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
