import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/core/providers/network/dio_provider.dart';
import 'package:rickandmorty/features/home_screen/data/repositories/character_repository_impl.dart';
import 'package:rickandmorty/features/home_screen/domain/repositories/i_character_repository.dart';

final characterRepositoryProvider = Provider<ICharacterRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CharacterRepositoryImpl(dio);
});
