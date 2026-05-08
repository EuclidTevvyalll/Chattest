import 'package:flutter/material.dart';
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
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool? isEdited;
  final bool? isDeleted;
  final String? currentUserId;
  final String? repliedMessageContent;
  final String? repliedMessageSenderName;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isMine,
    required this.timestamp,
    this.reactions = const {},
    this.onReactionToggled,
    this.onReply,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.isEdited,
    this.isDeleted,
    this.currentUserId,
    this.repliedMessageContent,
    this.repliedMessageSenderName,
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
                        final newOffset =
                            scrollController.offset +
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
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  (reactions[emoji]?.contains(currentUserId) ??
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () => _showReactionPicker(context),
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
                        if (repliedMessageContent != null) ...[
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
                                  repliedMessageSenderName ??
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
                                  repliedMessageContent!,
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
