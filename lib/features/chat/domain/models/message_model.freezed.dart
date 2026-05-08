// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageModel {

 String get id;@JsonKey(name: 'profile_id') String get profileId; String get content;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'room_id') String get roomId;@JsonKey(name: 'reply_to_message_id') String? get replyToMessageId;@JsonKey(name: 'is_edited') bool? get isEdited;@JsonKey(name: 'edited_at') DateTime? get editedAt;@JsonKey(name: 'is_deleted') bool? get isDeleted;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'forwarded_from') String? get forwardedFrom;@JsonKey(name: 'deleted_by') String? get deletedBy;@JsonKey(name: 'forwarded_info') Map<String, dynamic>? get forwardedInfo;@JsonKey(name: 'media_type') String? get mediaType;@JsonKey(name: 'media_url') String? get mediaUrl;@JsonKey(name: 'media_thumbnail_url') String? get mediaThumbnailUrl;@JsonKey(name: 'media_duration') int? get mediaDuration;@JsonKey(name: 'media_size') int? get mediaSize;@JsonKey(name: 'media_name') String? get mediaName; String? get media; Map<String, List<String>> get reactions;
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageModelCopyWith<MessageModel> get copyWith => _$MessageModelCopyWithImpl<MessageModel>(this as MessageModel, _$identity);

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.forwardedFrom, forwardedFrom) || other.forwardedFrom == forwardedFrom)&&(identical(other.deletedBy, deletedBy) || other.deletedBy == deletedBy)&&const DeepCollectionEquality().equals(other.forwardedInfo, forwardedInfo)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaThumbnailUrl, mediaThumbnailUrl) || other.mediaThumbnailUrl == mediaThumbnailUrl)&&(identical(other.mediaDuration, mediaDuration) || other.mediaDuration == mediaDuration)&&(identical(other.mediaSize, mediaSize) || other.mediaSize == mediaSize)&&(identical(other.mediaName, mediaName) || other.mediaName == mediaName)&&(identical(other.media, media) || other.media == media)&&const DeepCollectionEquality().equals(other.reactions, reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,profileId,content,createdAt,roomId,replyToMessageId,isEdited,editedAt,isDeleted,deletedAt,forwardedFrom,deletedBy,const DeepCollectionEquality().hash(forwardedInfo),mediaType,mediaUrl,mediaThumbnailUrl,mediaDuration,mediaSize,mediaName,media,const DeepCollectionEquality().hash(reactions)]);

@override
String toString() {
  return 'MessageModel(id: $id, profileId: $profileId, content: $content, createdAt: $createdAt, roomId: $roomId, replyToMessageId: $replyToMessageId, isEdited: $isEdited, editedAt: $editedAt, isDeleted: $isDeleted, deletedAt: $deletedAt, forwardedFrom: $forwardedFrom, deletedBy: $deletedBy, forwardedInfo: $forwardedInfo, mediaType: $mediaType, mediaUrl: $mediaUrl, mediaThumbnailUrl: $mediaThumbnailUrl, mediaDuration: $mediaDuration, mediaSize: $mediaSize, mediaName: $mediaName, media: $media, reactions: $reactions)';
}


}

/// @nodoc
abstract mixin class $MessageModelCopyWith<$Res>  {
  factory $MessageModelCopyWith(MessageModel value, $Res Function(MessageModel) _then) = _$MessageModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'profile_id') String profileId, String content,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'room_id') String roomId,@JsonKey(name: 'reply_to_message_id') String? replyToMessageId,@JsonKey(name: 'is_edited') bool? isEdited,@JsonKey(name: 'edited_at') DateTime? editedAt,@JsonKey(name: 'is_deleted') bool? isDeleted,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'forwarded_from') String? forwardedFrom,@JsonKey(name: 'deleted_by') String? deletedBy,@JsonKey(name: 'forwarded_info') Map<String, dynamic>? forwardedInfo,@JsonKey(name: 'media_type') String? mediaType,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'media_thumbnail_url') String? mediaThumbnailUrl,@JsonKey(name: 'media_duration') int? mediaDuration,@JsonKey(name: 'media_size') int? mediaSize,@JsonKey(name: 'media_name') String? mediaName, String? media, Map<String, List<String>> reactions
});




}
/// @nodoc
class _$MessageModelCopyWithImpl<$Res>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._self, this._then);

  final MessageModel _self;
  final $Res Function(MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? profileId = null,Object? content = null,Object? createdAt = null,Object? roomId = null,Object? replyToMessageId = freezed,Object? isEdited = freezed,Object? editedAt = freezed,Object? isDeleted = freezed,Object? deletedAt = freezed,Object? forwardedFrom = freezed,Object? deletedBy = freezed,Object? forwardedInfo = freezed,Object? mediaType = freezed,Object? mediaUrl = freezed,Object? mediaThumbnailUrl = freezed,Object? mediaDuration = freezed,Object? mediaSize = freezed,Object? mediaName = freezed,Object? media = freezed,Object? reactions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,isEdited: freezed == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: freezed == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,forwardedFrom: freezed == forwardedFrom ? _self.forwardedFrom : forwardedFrom // ignore: cast_nullable_to_non_nullable
as String?,deletedBy: freezed == deletedBy ? _self.deletedBy : deletedBy // ignore: cast_nullable_to_non_nullable
as String?,forwardedInfo: freezed == forwardedInfo ? _self.forwardedInfo : forwardedInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaThumbnailUrl: freezed == mediaThumbnailUrl ? _self.mediaThumbnailUrl : mediaThumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaDuration: freezed == mediaDuration ? _self.mediaDuration : mediaDuration // ignore: cast_nullable_to_non_nullable
as int?,mediaSize: freezed == mediaSize ? _self.mediaSize : mediaSize // ignore: cast_nullable_to_non_nullable
as int?,mediaName: freezed == mediaName ? _self.mediaName : mediaName // ignore: cast_nullable_to_non_nullable
as String?,media: freezed == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageModel].
extension MessageModelPatterns on MessageModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'profile_id')  String profileId,  String content, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'room_id')  String roomId, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'is_edited')  bool? isEdited, @JsonKey(name: 'edited_at')  DateTime? editedAt, @JsonKey(name: 'is_deleted')  bool? isDeleted, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'forwarded_from')  String? forwardedFrom, @JsonKey(name: 'deleted_by')  String? deletedBy, @JsonKey(name: 'forwarded_info')  Map<String, dynamic>? forwardedInfo, @JsonKey(name: 'media_type')  String? mediaType, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'media_thumbnail_url')  String? mediaThumbnailUrl, @JsonKey(name: 'media_duration')  int? mediaDuration, @JsonKey(name: 'media_size')  int? mediaSize, @JsonKey(name: 'media_name')  String? mediaName,  String? media,  Map<String, List<String>> reactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.profileId,_that.content,_that.createdAt,_that.roomId,_that.replyToMessageId,_that.isEdited,_that.editedAt,_that.isDeleted,_that.deletedAt,_that.forwardedFrom,_that.deletedBy,_that.forwardedInfo,_that.mediaType,_that.mediaUrl,_that.mediaThumbnailUrl,_that.mediaDuration,_that.mediaSize,_that.mediaName,_that.media,_that.reactions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'profile_id')  String profileId,  String content, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'room_id')  String roomId, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'is_edited')  bool? isEdited, @JsonKey(name: 'edited_at')  DateTime? editedAt, @JsonKey(name: 'is_deleted')  bool? isDeleted, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'forwarded_from')  String? forwardedFrom, @JsonKey(name: 'deleted_by')  String? deletedBy, @JsonKey(name: 'forwarded_info')  Map<String, dynamic>? forwardedInfo, @JsonKey(name: 'media_type')  String? mediaType, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'media_thumbnail_url')  String? mediaThumbnailUrl, @JsonKey(name: 'media_duration')  int? mediaDuration, @JsonKey(name: 'media_size')  int? mediaSize, @JsonKey(name: 'media_name')  String? mediaName,  String? media,  Map<String, List<String>> reactions)  $default,) {final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that.id,_that.profileId,_that.content,_that.createdAt,_that.roomId,_that.replyToMessageId,_that.isEdited,_that.editedAt,_that.isDeleted,_that.deletedAt,_that.forwardedFrom,_that.deletedBy,_that.forwardedInfo,_that.mediaType,_that.mediaUrl,_that.mediaThumbnailUrl,_that.mediaDuration,_that.mediaSize,_that.mediaName,_that.media,_that.reactions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'profile_id')  String profileId,  String content, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'room_id')  String roomId, @JsonKey(name: 'reply_to_message_id')  String? replyToMessageId, @JsonKey(name: 'is_edited')  bool? isEdited, @JsonKey(name: 'edited_at')  DateTime? editedAt, @JsonKey(name: 'is_deleted')  bool? isDeleted, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'forwarded_from')  String? forwardedFrom, @JsonKey(name: 'deleted_by')  String? deletedBy, @JsonKey(name: 'forwarded_info')  Map<String, dynamic>? forwardedInfo, @JsonKey(name: 'media_type')  String? mediaType, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'media_thumbnail_url')  String? mediaThumbnailUrl, @JsonKey(name: 'media_duration')  int? mediaDuration, @JsonKey(name: 'media_size')  int? mediaSize, @JsonKey(name: 'media_name')  String? mediaName,  String? media,  Map<String, List<String>> reactions)?  $default,) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.profileId,_that.content,_that.createdAt,_that.roomId,_that.replyToMessageId,_that.isEdited,_that.editedAt,_that.isDeleted,_that.deletedAt,_that.forwardedFrom,_that.deletedBy,_that.forwardedInfo,_that.mediaType,_that.mediaUrl,_that.mediaThumbnailUrl,_that.mediaDuration,_that.mediaSize,_that.mediaName,_that.media,_that.reactions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageModel implements MessageModel {
  const _MessageModel({required this.id, @JsonKey(name: 'profile_id') required this.profileId, required this.content, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'room_id') required this.roomId, @JsonKey(name: 'reply_to_message_id') this.replyToMessageId, @JsonKey(name: 'is_edited') this.isEdited, @JsonKey(name: 'edited_at') this.editedAt, @JsonKey(name: 'is_deleted') this.isDeleted, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'forwarded_from') this.forwardedFrom, @JsonKey(name: 'deleted_by') this.deletedBy, @JsonKey(name: 'forwarded_info') final  Map<String, dynamic>? forwardedInfo, @JsonKey(name: 'media_type') this.mediaType, @JsonKey(name: 'media_url') this.mediaUrl, @JsonKey(name: 'media_thumbnail_url') this.mediaThumbnailUrl, @JsonKey(name: 'media_duration') this.mediaDuration, @JsonKey(name: 'media_size') this.mediaSize, @JsonKey(name: 'media_name') this.mediaName, this.media, final  Map<String, List<String>> reactions = const {}}): _forwardedInfo = forwardedInfo,_reactions = reactions;
  factory _MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'profile_id') final  String profileId;
@override final  String content;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'room_id') final  String roomId;
@override@JsonKey(name: 'reply_to_message_id') final  String? replyToMessageId;
@override@JsonKey(name: 'is_edited') final  bool? isEdited;
@override@JsonKey(name: 'edited_at') final  DateTime? editedAt;
@override@JsonKey(name: 'is_deleted') final  bool? isDeleted;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'forwarded_from') final  String? forwardedFrom;
@override@JsonKey(name: 'deleted_by') final  String? deletedBy;
 final  Map<String, dynamic>? _forwardedInfo;
@override@JsonKey(name: 'forwarded_info') Map<String, dynamic>? get forwardedInfo {
  final value = _forwardedInfo;
  if (value == null) return null;
  if (_forwardedInfo is EqualUnmodifiableMapView) return _forwardedInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'media_type') final  String? mediaType;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;
@override@JsonKey(name: 'media_thumbnail_url') final  String? mediaThumbnailUrl;
@override@JsonKey(name: 'media_duration') final  int? mediaDuration;
@override@JsonKey(name: 'media_size') final  int? mediaSize;
@override@JsonKey(name: 'media_name') final  String? mediaName;
@override final  String? media;
 final  Map<String, List<String>> _reactions;
@override@JsonKey() Map<String, List<String>> get reactions {
  if (_reactions is EqualUnmodifiableMapView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reactions);
}


/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageModelCopyWith<_MessageModel> get copyWith => __$MessageModelCopyWithImpl<_MessageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.forwardedFrom, forwardedFrom) || other.forwardedFrom == forwardedFrom)&&(identical(other.deletedBy, deletedBy) || other.deletedBy == deletedBy)&&const DeepCollectionEquality().equals(other._forwardedInfo, _forwardedInfo)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaThumbnailUrl, mediaThumbnailUrl) || other.mediaThumbnailUrl == mediaThumbnailUrl)&&(identical(other.mediaDuration, mediaDuration) || other.mediaDuration == mediaDuration)&&(identical(other.mediaSize, mediaSize) || other.mediaSize == mediaSize)&&(identical(other.mediaName, mediaName) || other.mediaName == mediaName)&&(identical(other.media, media) || other.media == media)&&const DeepCollectionEquality().equals(other._reactions, _reactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,profileId,content,createdAt,roomId,replyToMessageId,isEdited,editedAt,isDeleted,deletedAt,forwardedFrom,deletedBy,const DeepCollectionEquality().hash(_forwardedInfo),mediaType,mediaUrl,mediaThumbnailUrl,mediaDuration,mediaSize,mediaName,media,const DeepCollectionEquality().hash(_reactions)]);

@override
String toString() {
  return 'MessageModel(id: $id, profileId: $profileId, content: $content, createdAt: $createdAt, roomId: $roomId, replyToMessageId: $replyToMessageId, isEdited: $isEdited, editedAt: $editedAt, isDeleted: $isDeleted, deletedAt: $deletedAt, forwardedFrom: $forwardedFrom, deletedBy: $deletedBy, forwardedInfo: $forwardedInfo, mediaType: $mediaType, mediaUrl: $mediaUrl, mediaThumbnailUrl: $mediaThumbnailUrl, mediaDuration: $mediaDuration, mediaSize: $mediaSize, mediaName: $mediaName, media: $media, reactions: $reactions)';
}


}

/// @nodoc
abstract mixin class _$MessageModelCopyWith<$Res> implements $MessageModelCopyWith<$Res> {
  factory _$MessageModelCopyWith(_MessageModel value, $Res Function(_MessageModel) _then) = __$MessageModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'profile_id') String profileId, String content,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'room_id') String roomId,@JsonKey(name: 'reply_to_message_id') String? replyToMessageId,@JsonKey(name: 'is_edited') bool? isEdited,@JsonKey(name: 'edited_at') DateTime? editedAt,@JsonKey(name: 'is_deleted') bool? isDeleted,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'forwarded_from') String? forwardedFrom,@JsonKey(name: 'deleted_by') String? deletedBy,@JsonKey(name: 'forwarded_info') Map<String, dynamic>? forwardedInfo,@JsonKey(name: 'media_type') String? mediaType,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'media_thumbnail_url') String? mediaThumbnailUrl,@JsonKey(name: 'media_duration') int? mediaDuration,@JsonKey(name: 'media_size') int? mediaSize,@JsonKey(name: 'media_name') String? mediaName, String? media, Map<String, List<String>> reactions
});




}
/// @nodoc
class __$MessageModelCopyWithImpl<$Res>
    implements _$MessageModelCopyWith<$Res> {
  __$MessageModelCopyWithImpl(this._self, this._then);

  final _MessageModel _self;
  final $Res Function(_MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? profileId = null,Object? content = null,Object? createdAt = null,Object? roomId = null,Object? replyToMessageId = freezed,Object? isEdited = freezed,Object? editedAt = freezed,Object? isDeleted = freezed,Object? deletedAt = freezed,Object? forwardedFrom = freezed,Object? deletedBy = freezed,Object? forwardedInfo = freezed,Object? mediaType = freezed,Object? mediaUrl = freezed,Object? mediaThumbnailUrl = freezed,Object? mediaDuration = freezed,Object? mediaSize = freezed,Object? mediaName = freezed,Object? media = freezed,Object? reactions = null,}) {
  return _then(_MessageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as String?,isEdited: freezed == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: freezed == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,forwardedFrom: freezed == forwardedFrom ? _self.forwardedFrom : forwardedFrom // ignore: cast_nullable_to_non_nullable
as String?,deletedBy: freezed == deletedBy ? _self.deletedBy : deletedBy // ignore: cast_nullable_to_non_nullable
as String?,forwardedInfo: freezed == forwardedInfo ? _self._forwardedInfo : forwardedInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaThumbnailUrl: freezed == mediaThumbnailUrl ? _self.mediaThumbnailUrl : mediaThumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaDuration: freezed == mediaDuration ? _self.mediaDuration : mediaDuration // ignore: cast_nullable_to_non_nullable
as int?,mediaSize: freezed == mediaSize ? _self.mediaSize : mediaSize // ignore: cast_nullable_to_non_nullable
as int?,mediaName: freezed == mediaName ? _self.mediaName : mediaName // ignore: cast_nullable_to_non_nullable
as String?,media: freezed == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}


}

// dart format on
