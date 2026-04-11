import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rickandmorty/core/error/failure.dart';
import 'package:rickandmorty/features/home_screen/data/models/character.dart';
import 'package:rickandmorty/features/home_screen/data/models/character_response.dart';
import 'package:rickandmorty/features/home_screen/domain/repositories/i_character_repository.dart';
import 'package:rickandmorty/main.dart';

class CharacterRepositoryImpl implements ICharacterRepository {
  final Dio _dio;
  static final List<Character> _localCharacters = [];

  CharacterRepositoryImpl(this._dio);

  static const _cachePrefix = 'cache_characters_page_';

  @override
  Future<Either<Failure, CharacterResponse>> getCharacters({
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/character',
        queryParameters: {'page': page},
      );

      final characterResponse = CharacterResponse.fromJson(response.data);

      shared.setString('$_cachePrefix$page', jsonEncode(response.data));

      return Right(_mergeLocal(characterResponse, page));
    } on DioException catch (e) {
      final cachedData = shared.getString('$_cachePrefix$page');
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        final characterResponse = CharacterResponse.fromJson(decoded);
        return Right(_mergeLocal(characterResponse, page));
      }
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  CharacterResponse _mergeLocal(CharacterResponse response, int page) {
    if (page == 1 && _localCharacters.isNotEmpty) {
      return response.copyWith(
        results: [..._localCharacters, ...response.results],
        info: response.info.copyWith(
          count: response.info.count + _localCharacters.length,
        ),
      );
    }
    return response;
  }

  @override
  Future<Either<Failure, Character>> getCharacterById(int id) async {
    final local = _localCharacters.where((c) => c.id == id).firstOrNull;
    if (local != null) return Right(local);

    try {
      final response = await _dio.get('/character/$id');
      return Right(Character.fromJson(response.data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ConnectionFailure();
      case DioExceptionType.badResponse:
        return ServerFailure('Ошибка сервера: ${error.response?.statusCode}');
      default:
        return const UnknownFailure();
    }
  }
}
