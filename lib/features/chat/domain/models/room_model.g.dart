// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomModel _$RoomModelFromJson(Map<String, dynamic> json) => _RoomModel(
  id: json['id'] as String,
  type: $enumDecodeNullable(_$RoomTypeEnumMap, json['type']) ?? RoomType.room,
  name: json['name'] as String?,
  description: json['description'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastMessageAt: json['last_message_at'] == null
      ? null
      : DateTime.parse(json['last_message_at'] as String),
  lastMessage: json['lastMessage'] as String?,
  createdBy: json['created_by'] as String?,
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$RoomModelToJson(_RoomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$RoomTypeEnumMap[instance.type]!,
      'name': instance.name,
      'description': instance.description,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'lastMessage': instance.lastMessage,
      'created_by': instance.createdBy,
      'participants': instance.participants,
    };

const _$RoomTypeEnumMap = {
  RoomType.room: 'direct',
  RoomType.group: 'group',
  RoomType.channel: 'channel',
};
