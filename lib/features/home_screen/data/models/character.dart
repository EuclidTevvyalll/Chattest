import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rickandmorty/features/home_screen/data/models/location.dart';
import 'package:rickandmorty/features/home_screen/data/models/origin.dart';

part 'character.freezed.dart';
part 'character.g.dart';

@freezed
abstract class Character with _$Character {
  const factory Character({
    required int id,
    required String name,
    required String status,
    required String species,
    required String type,
    required String gender,
    required Origin origin,
    required Location location,
    required String image,
    required List<String> episode,
    required String url,
    required DateTime created,
  }) = _Character;

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
}
