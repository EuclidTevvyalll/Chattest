import 'package:fpdart/fpdart.dart';
import 'package:rickandmorty/core/error/failure.dart';
import 'package:rickandmorty/features/home_screen/data/models/character.dart';
import 'package:rickandmorty/features/home_screen/data/models/character_response.dart';

abstract class ICharacterRepository {
  Future<Either<Failure, CharacterResponse>> getCharacters({int page = 1});
  Future<Either<Failure, Character>> getCharacterById(int id);
}
