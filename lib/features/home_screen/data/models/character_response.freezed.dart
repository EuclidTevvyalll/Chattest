// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CharacterResponse {

 Info get info; List<Character> get results;
/// Create a copy of CharacterResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterResponseCopyWith<CharacterResponse> get copyWith => _$CharacterResponseCopyWithImpl<CharacterResponse>(this as CharacterResponse, _$identity);

  /// Serializes this CharacterResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterResponse&&(identical(other.info, info) || other.info == info)&&const DeepCollectionEquality().equals(other.results, results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,info,const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'CharacterResponse(info: $info, results: $results)';
}


}

/// @nodoc
abstract mixin class $CharacterResponseCopyWith<$Res>  {
  factory $CharacterResponseCopyWith(CharacterResponse value, $Res Function(CharacterResponse) _then) = _$CharacterResponseCopyWithImpl;
@useResult
$Res call({
 Info info, List<Character> results
});


$InfoCopyWith<$Res> get info;

}
/// @nodoc
class _$CharacterResponseCopyWithImpl<$Res>
    implements $CharacterResponseCopyWith<$Res> {
  _$CharacterResponseCopyWithImpl(this._self, this._then);

  final CharacterResponse _self;
  final $Res Function(CharacterResponse) _then;

/// Create a copy of CharacterResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? info = null,Object? results = null,}) {
  return _then(_self.copyWith(
info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as Info,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<Character>,
  ));
}
/// Create a copy of CharacterResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InfoCopyWith<$Res> get info {
  
  return $InfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// Adds pattern-matching-related methods to [CharacterResponse].
extension CharacterResponsePatterns on CharacterResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterResponse value)  $default,){
final _that = this;
switch (_that) {
case _CharacterResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Info info,  List<Character> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterResponse() when $default != null:
return $default(_that.info,_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Info info,  List<Character> results)  $default,) {final _that = this;
switch (_that) {
case _CharacterResponse():
return $default(_that.info,_that.results);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Info info,  List<Character> results)?  $default,) {final _that = this;
switch (_that) {
case _CharacterResponse() when $default != null:
return $default(_that.info,_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CharacterResponse implements CharacterResponse {
  const _CharacterResponse({required this.info, required final  List<Character> results}): _results = results;
  factory _CharacterResponse.fromJson(Map<String, dynamic> json) => _$CharacterResponseFromJson(json);

@override final  Info info;
 final  List<Character> _results;
@override List<Character> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of CharacterResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterResponseCopyWith<_CharacterResponse> get copyWith => __$CharacterResponseCopyWithImpl<_CharacterResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterResponse&&(identical(other.info, info) || other.info == info)&&const DeepCollectionEquality().equals(other._results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,info,const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'CharacterResponse(info: $info, results: $results)';
}


}

/// @nodoc
abstract mixin class _$CharacterResponseCopyWith<$Res> implements $CharacterResponseCopyWith<$Res> {
  factory _$CharacterResponseCopyWith(_CharacterResponse value, $Res Function(_CharacterResponse) _then) = __$CharacterResponseCopyWithImpl;
@override @useResult
$Res call({
 Info info, List<Character> results
});


@override $InfoCopyWith<$Res> get info;

}
/// @nodoc
class __$CharacterResponseCopyWithImpl<$Res>
    implements _$CharacterResponseCopyWith<$Res> {
  __$CharacterResponseCopyWithImpl(this._self, this._then);

  final _CharacterResponse _self;
  final $Res Function(_CharacterResponse) _then;

/// Create a copy of CharacterResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? info = null,Object? results = null,}) {
  return _then(_CharacterResponse(
info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as Info,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<Character>,
  ));
}

/// Create a copy of CharacterResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InfoCopyWith<$Res> get info {
  
  return $InfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

// dart format on
