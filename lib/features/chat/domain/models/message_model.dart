import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    @JsonKey(name: 'profile_id') required String profileId,
    required String content,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'room_id') required String roomId,
    @JsonKey(name: 'reply_to_message_id') String? replyToMessageId,
    @JsonKey(name: 'is_edited') bool? isEdited,
    @JsonKey(name: 'edited_at') DateTime? editedAt,
    @JsonKey(name: 'is_deleted') bool? isDeleted,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'forwarded_from') String? forwardedFrom,
    @JsonKey(name: 'deleted_by') String? deletedBy,
    @JsonKey(name: 'forwarded_info') Map<String, dynamic>? forwardedInfo,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'media_thumbnail_url') String? mediaThumbnailUrl,
    @JsonKey(name: 'media_duration') int? mediaDuration,
    @JsonKey(name: 'media_size') int? mediaSize,
    @JsonKey(name: 'media_name') String? mediaName,
    String? media,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}
