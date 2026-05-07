import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';

part 'room_model.freezed.dart';
part 'room_model.g.dart';

enum RoomType {
  @JsonValue('direct') room,
  @JsonValue('group') group,
  @JsonValue('channel') channel
}

@freezed
abstract class RoomModel with _$RoomModel {

  const factory RoomModel({
    required String id,
    @Default(RoomType.room) RoomType type,
    String? name,
    String? description,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    String? lastMessage,
    @JsonKey(name: 'created_by') String? createdBy,

    @Default([]) List<ProfileModel> participants,
  }) = _RoomModel;


  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);
}
