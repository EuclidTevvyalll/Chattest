// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      roomId: json['room_id'] as String,
      replyToMessageId: json['reply_to_message_id'] as String?,
      isEdited: json['is_edited'] as bool?,
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.parse(json['edited_at'] as String),
      isDeleted: json['is_deleted'] as bool?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      forwardedFrom: json['forwarded_from'] as String?,
      deletedBy: json['deleted_by'] as String?,
      forwardedInfo: json['forwarded_info'] as Map<String, dynamic>?,
      mediaType: json['media_type'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      mediaDuration: (json['media_duration'] as num?)?.toInt(),
      mediaSize: (json['media_size'] as num?)?.toInt(),
      mediaName: json['media_name'] as String?,
      media: json['media'] as String?,
      reactions:
          (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const {},
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profile_id': instance.profileId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'room_id': instance.roomId,
      'reply_to_message_id': instance.replyToMessageId,
      'is_edited': instance.isEdited,
      'edited_at': instance.editedAt?.toIso8601String(),
      'is_deleted': instance.isDeleted,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'forwarded_from': instance.forwardedFrom,
      'deleted_by': instance.deletedBy,
      'forwarded_info': instance.forwardedInfo,
      'media_type': instance.mediaType,
      'media_url': instance.mediaUrl,
      'media_thumbnail_url': instance.mediaThumbnailUrl,
      'media_duration': instance.mediaDuration,
      'media_size': instance.mediaSize,
      'media_name': instance.mediaName,
      'media': instance.media,
      'reactions': instance.reactions,
    };
