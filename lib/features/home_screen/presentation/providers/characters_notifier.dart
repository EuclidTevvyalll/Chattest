import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/home_screen/data/models/character.dart';
import 'package:rickandmorty/features/home_screen/data/providers/repository_provider.dart';

class CharactersNotifier extends AsyncNotifier<List<Character>> {
  int _currentPage = 1;
  bool _isFetchingMore = false;

  bool hasMore = true;

  @override
  FutureOr<List<Character>> build() async {
    return _fetchFirstPage();
  }

  Future<List<Character>> _fetchFirstPage() async {
    _currentPage = 1;
    hasMore = true;
    _isFetchingMore = false;

    final repository = ref.read(characterRepositoryProvider);
    final result = await repository.getCharacters(page: _currentPage);

    return result.fold((failure) => throw failure.message, (response) {
      hasMore = response.info.next != null;
      return response.results;
    });
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || !hasMore) return;

    _isFetchingMore = true;
    _currentPage++;

    final repository = ref.read(characterRepositoryProvider);
    final result = await repository.getCharacters(page: _currentPage);

    result.fold(
      (failure) {
        _currentPage--;
        _isFetchingMore = false;
      },
      (response) {
        hasMore = response.info.next != null;

        final previousState = state.value ?? [];
        state = AsyncValue.data([...previousState, ...response.results]);
        _isFetchingMore = false;
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFirstPage());
  }
}

final charactersNotifierProvider =
    AsyncNotifierProvider<CharactersNotifier, List<Character>>(
      CharactersNotifier.new,
    );
