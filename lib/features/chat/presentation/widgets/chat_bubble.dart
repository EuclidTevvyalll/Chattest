import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forgelink/core/config/supabase_config.dart';
import 'package:flutter/gestures.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/liquidglass_container.dart';
import 'package:forgelink/features/chat/presentation/widgets/video_player_bubble.dart';

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
  final String? senderName;
  final String? senderAvatarUrl;
  final String? senderAvatarBase64;
  final String? channelName;
  final bool showSenderInfo;

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
    this.senderName,
    this.senderAvatarUrl,
    this.senderAvatarBase64,
    this.channelName,
    this.showSenderInfo = false,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    (reactions[emoji]?.contains(
                                          currentUserId,
                                        ) ??
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
    final displayRepliedContent =
        repliedMessageContent ??
        forwardedInfo?['fwd_replied_content'] ??
        forwardedInfo?['replied_content'];
    final displayRepliedSender =
        repliedMessageSenderName ??
        forwardedInfo?['fwd_replied_sender'] ??
        forwardedInfo?['replied_sender'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final bubbleMaxWidth = screenWidth * (isSelectionMode ? 0.55 : 0.65);
            final mediaMaxWidth = screenWidth * (isSelectionMode ? 0.5 : 0.6);
            
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: bubbleMaxWidth,
              ),
              child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (showSenderInfo && !isMine) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (channelName == null &&
                          (senderAvatarUrl != null ||
                              senderAvatarBase64 != null))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundImage: senderAvatarUrl != null
                                ? CachedNetworkImageProvider(senderAvatarUrl!)
                                : (senderAvatarBase64 != null
                                          ? MemoryImage(
                                              base64Decode(senderAvatarBase64!),
                                            )
                                          : null)
                                      as ImageProvider?,
                            child:
                                (senderAvatarUrl == null &&
                                    senderAvatarBase64 == null)
                                ? Text(
                                    (senderName ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  )
                                : null,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          senderName ?? channelName ?? 'Пользователь',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              GestureDetector(
                onLongPress: isSelectionMode
                    ? onLongPress
                    : () => _showReactionPicker(context),
                onTap: isSelectionMode ? onTap : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: isSelectionMode
                      ? const EdgeInsets.all(4)
                      : EdgeInsets.zero,
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
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: mediaMaxWidth,
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
                                color:
                                    (isMine ? ThemeColors.blue : Colors.black)
                                        .withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GlassBox(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
                                          style:
                                              ThemeTextStyles.caption(
                                                color: isMine
                                                    ? Colors.white70
                                                    : Colors.grey,
                                              ).copyWith(
                                                fontStyle: FontStyle.italic,
                                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  if (mediaType?.startsWith('image') ??
                                      (mediaUrl == null && mediaName != null))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: RepaintBoundary(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: InkWell(
                                            onTap: () => _showMediaDetail(
                                                context, isDark),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: mediaUrl == null
                                            ? Container(
                                                constraints:
                                                    BoxConstraints(
                                                      minHeight: 100,
                                                      maxWidth: mediaMaxWidth,
                                                      maxHeight: 200,
                                                    ),

                                                color: isMine
                                                    ? Colors.white12
                                                    : Colors.black12,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: ThemeColors.blue,
                                                      ),
                                                ),
                                              )
                                            : mediaUrl!.startsWith('data:image')
                                                ? ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: mediaMaxWidth,
                                                      maxHeight: 500,
                                                    ),
                                                    child: Image.memory(
                                                      base64Decode(
                                                        mediaUrl!.split(',').last,
                                                      ),
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (context, error,
                                                                  stackTrace) =>
                                                              const SizedBox(
                                                        height: 200,
                                                        child: Center(
                                                          child: Icon(
                                                              Icons.broken_image,
                                                              color: Colors
                                                                  .redAccent),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                            : ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: mediaMaxWidth,
                                                  maxHeight: 500,
                                                ),
                                                child: CachedNetworkImage(
                                                  imageUrl: mediaUrl!,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    constraints: BoxConstraints(
                                                      minHeight: 100,
                                                      maxWidth: mediaMaxWidth,
                                                      maxHeight: 200,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isMine
                                                          ? Colors.white12
                                                          : (isDark
                                                              ? Colors.white10
                                                              : Colors.black.withValues(alpha: 0.1)),
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
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const SizedBox(
                                                    height: 300,
                                                    child: Center(
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.redAccent),
                                                    ),
                                                  ),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    )
                                  else
                                    // For other file types (Videos, Files)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: (mediaType?.startsWith('video/') == true)
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: VideoPlayerBubble(
                                                videoUrl: mediaUrl!,
                                                maxWidth: screenWidth * (isSelectionMode ? 0.5 : 0.6),
                                              ),
                                            )
                                          : InkWell(
                                              onTap: () => _showFileDetail(context, isDark),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isMine
                                                      ? Colors.white.withValues(alpha: 0.15)
                                                      : Colors.black.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isMine ? Colors.white24 : Colors.black12,
                                                  ),
                                                ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (mediaUrl == null &&
                                                  mediaName != null)
                                                const SizedBox(
                                                  width: 32,
                                                  height: 32,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white70,
                                                      ),
                                                )
                                              else
                                                Icon(
                                                  (mediaType?.startsWith(
                                                            'video/',
                                                          ) ??
                                                          false)
                                                      ? Icons
                                                            .play_circle_fill_rounded
                                                      : Icons
                                                            .insert_drive_file_rounded,
                                                  size: 32,
                                                  color: isMine
                                                      ? Colors.white
                                                      : ThemeColors.blue,
                                                ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      mediaName ?? 'Файл',
                                                      style:
                                                          ThemeTextStyles.bodyMedium(
                                                            color: isMine
                                                                ? Colors.white
                                                                : (isDark
                                                                      ? Colors
                                                                            .white
                                                                      : Colors
                                                                            .black87),
                                                          ).copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (mediaType != null)
                                                      Text(
                                                        mediaType!
                                                            .split('/')
                                                            .last
                                                            .toUpperCase(),
                                                        style: ThemeTextStyles.caption(
                                                          isDark: isDark,
                                                          color: isMine
                                                              ? Colors.white70
                                                              : (isDark
                                                                    ? Colors
                                                                          .white54
                                                                    : Colors
                                                                          .black54),
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
                                        color: isMine
                                            ? Colors.white60
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Сообщение удалено',
                                        style: ThemeTextStyles.bodyMedium(
                                          color: isMine
                                              ? Colors.white60
                                              : Colors.grey,
                                        ).copyWith(fontStyle: FontStyle.italic),
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
          );
        },
      ),
    ),
  );
}

  void _showMediaDetail(BuildContext context, bool isDark) {
    if (mediaUrl == null) return;

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: const [],
        ),
        body: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: mediaUrl!.startsWith('data:image')
                ? Image.memory(
                    base64Decode(mediaUrl!.split(',').last),
                    fit: BoxFit.contain,
                  )
                : CachedNetworkImage(
                    imageUrl: mediaUrl!,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: ThemeColors.blue,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    if (mediaUrl == null) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Открываем файл...'),
          duration: Duration(seconds: 1),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = mediaName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
      final savePath = p.join(tempDir.path, fileName);
      
      if (!await File(savePath).exists()) {
        final client = Supabase.instance.client;
        final jwt = client.auth.currentSession?.accessToken;
        
        await Dio().download(
          Uri.encodeFull(mediaUrl!), 
          savePath,
          options: Options(
            headers: {
              if (jwt != null && !mediaUrl!.contains('/public/')) 
                'Authorization': 'Bearer $jwt',
              'apikey': SupabaseConfig.anonKey,
            },
          ),
        );
      }
      
      await OpenFile.open(savePath);
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('Dio error body: ${e.response?.data}');
      }
      debugPrint('Error opening file: $e');
      final uri = Uri.parse(mediaUrl!);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _showFileDetail(BuildContext context, bool isDark) {
    if (mediaUrl == null) return;

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: ThemeColors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_rounded,
                      color: ThemeColors.blue,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      mediaName ?? 'Файл',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (mediaType != null)
                    Text(
                      mediaType!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () => _openFile(context),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Открыть файл'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

