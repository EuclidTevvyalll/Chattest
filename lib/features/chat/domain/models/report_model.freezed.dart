// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportModel {

 String? get id;@JsonKey(name: 'reporter_id') String get reporterId;@JsonKey(name: 'target_id') String get targetId;@JsonKey(name: 'target_type') String get targetType; String get reason; String? get details;@JsonKey(name: 'created_at') DateTime? get createdAt; String? get status;@JsonKey(name: 'moderation_details') String? get moderationDetails;
/// Create a copy of ReportModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportModelCopyWith<ReportModel> get copyWith => _$ReportModelCopyWithImpl<ReportModel>(this as ReportModel, _$identity);

  /// Serializes this ReportModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.moderationDetails, moderationDetails) || other.moderationDetails == moderationDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reporterId,targetId,targetType,reason,details,createdAt,status,moderationDetails);

@override
String toString() {
  return 'ReportModel(id: $id, reporterId: $reporterId, targetId: $targetId, targetType: $targetType, reason: $reason, details: $details, createdAt: $createdAt, status: $status, moderationDetails: $moderationDetails)';
}


}

/// @nodoc
abstract mixin class $ReportModelCopyWith<$Res>  {
  factory $ReportModelCopyWith(ReportModel value, $Res Function(ReportModel) _then) = _$ReportModelCopyWithImpl;
@useResult
$Res call({
 String? id,@JsonKey(name: 'reporter_id') String reporterId,@JsonKey(name: 'target_id') String targetId,@JsonKey(name: 'target_type') String targetType, String reason, String? details,@JsonKey(name: 'created_at') DateTime? createdAt, String? status,@JsonKey(name: 'moderation_details') String? moderationDetails
});




}
/// @nodoc
class _$ReportModelCopyWithImpl<$Res>
    implements $ReportModelCopyWith<$Res> {
  _$ReportModelCopyWithImpl(this._self, this._then);

  final ReportModel _self;
  final $Res Function(ReportModel) _then;

/// Create a copy of ReportModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? reporterId = null,Object? targetId = null,Object? targetType = null,Object? reason = null,Object? details = freezed,Object? createdAt = freezed,Object? status = freezed,Object? moderationDetails = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,moderationDetails: freezed == moderationDetails ? _self.moderationDetails : moderationDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportModel].
extension ReportModelPatterns on ReportModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportModel value)  $default,){
final _that = this;
switch (_that) {
case _ReportModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReportModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'reporter_id')  String reporterId, @JsonKey(name: 'target_id')  String targetId, @JsonKey(name: 'target_type')  String targetType,  String reason,  String? details, @JsonKey(name: 'created_at')  DateTime? createdAt,  String? status, @JsonKey(name: 'moderation_details')  String? moderationDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportModel() when $default != null:
return $default(_that.id,_that.reporterId,_that.targetId,_that.targetType,_that.reason,_that.details,_that.createdAt,_that.status,_that.moderationDetails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id, @JsonKey(name: 'reporter_id')  String reporterId, @JsonKey(name: 'target_id')  String targetId, @JsonKey(name: 'target_type')  String targetType,  String reason,  String? details, @JsonKey(name: 'created_at')  DateTime? createdAt,  String? status, @JsonKey(name: 'moderation_details')  String? moderationDetails)  $default,) {final _that = this;
switch (_that) {
case _ReportModel():
return $default(_that.id,_that.reporterId,_that.targetId,_that.targetType,_that.reason,_that.details,_that.createdAt,_that.status,_that.moderationDetails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id, @JsonKey(name: 'reporter_id')  String reporterId, @JsonKey(name: 'target_id')  String targetId, @JsonKey(name: 'target_type')  String targetType,  String reason,  String? details, @JsonKey(name: 'created_at')  DateTime? createdAt,  String? status, @JsonKey(name: 'moderation_details')  String? moderationDetails)?  $default,) {final _that = this;
switch (_that) {
case _ReportModel() when $default != null:
return $default(_that.id,_that.reporterId,_that.targetId,_that.targetType,_that.reason,_that.details,_that.createdAt,_that.status,_that.moderationDetails);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportModel implements ReportModel {
  const _ReportModel({this.id, @JsonKey(name: 'reporter_id') required this.reporterId, @JsonKey(name: 'target_id') required this.targetId, @JsonKey(name: 'target_type') required this.targetType, required this.reason, this.details, @JsonKey(name: 'created_at') this.createdAt, this.status, @JsonKey(name: 'moderation_details') this.moderationDetails});
  factory _ReportModel.fromJson(Map<String, dynamic> json) => _$ReportModelFromJson(json);

@override final  String? id;
@override@JsonKey(name: 'reporter_id') final  String reporterId;
@override@JsonKey(name: 'target_id') final  String targetId;
@override@JsonKey(name: 'target_type') final  String targetType;
@override final  String reason;
@override final  String? details;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override final  String? status;
@override@JsonKey(name: 'moderation_details') final  String? moderationDetails;

/// Create a copy of ReportModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportModelCopyWith<_ReportModel> get copyWith => __$ReportModelCopyWithImpl<_ReportModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportModel&&(identical(other.id, id) || other.id == id)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.moderationDetails, moderationDetails) || other.moderationDetails == moderationDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reporterId,targetId,targetType,reason,details,createdAt,status,moderationDetails);

@override
String toString() {
  return 'ReportModel(id: $id, reporterId: $reporterId, targetId: $targetId, targetType: $targetType, reason: $reason, details: $details, createdAt: $createdAt, status: $status, moderationDetails: $moderationDetails)';
}


}

/// @nodoc
abstract mixin class _$ReportModelCopyWith<$Res> implements $ReportModelCopyWith<$Res> {
  factory _$ReportModelCopyWith(_ReportModel value, $Res Function(_ReportModel) _then) = __$ReportModelCopyWithImpl;
@override @useResult
$Res call({
 String? id,@JsonKey(name: 'reporter_id') String reporterId,@JsonKey(name: 'target_id') String targetId,@JsonKey(name: 'target_type') String targetType, String reason, String? details,@JsonKey(name: 'created_at') DateTime? createdAt, String? status,@JsonKey(name: 'moderation_details') String? moderationDetails
});




}
/// @nodoc
class __$ReportModelCopyWithImpl<$Res>
    implements _$ReportModelCopyWith<$Res> {
  __$ReportModelCopyWithImpl(this._self, this._then);

  final _ReportModel _self;
  final $Res Function(_ReportModel) _then;

/// Create a copy of ReportModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? reporterId = null,Object? targetId = null,Object? targetType = null,Object? reason = null,Object? details = freezed,Object? createdAt = freezed,Object? status = freezed,Object? moderationDetails = freezed,}) {
  return _then(_ReportModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,reporterId: null == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,moderationDetails: freezed == moderationDetails ? _self.moderationDetails : moderationDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
