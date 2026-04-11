import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rickandmorty/features/home_screen/data/models/character.dart';
import 'package:rickandmorty/features/home_screen/data/models/info.dart';

part 'character_response.freezed.dart';
part 'character_response.g.dart';

@freezed
abstract class CharacterResponse with _$CharacterResponse {
  const factory CharacterResponse({
    required Info info,
    required List<Character> results,
  }) = _CharacterResponse;

  factory CharacterResponse.fromJson(Map<String, dynamic> json) =>
      _$CharacterResponseFromJson(json);
}
