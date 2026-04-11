import 'package:freezed_annotation/freezed_annotation.dart';

part 'origin.freezed.dart';
part 'origin.g.dart';

@freezed
abstract class Origin with _$Origin {
  const factory Origin({required String name, required String url}) = _Origin;

  factory Origin.fromJson(Map<String, dynamic> json) => _$OriginFromJson(json);
}
