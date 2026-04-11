import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/home_screen/data/models/character.dart';
import 'package:rickandmorty/main.dart';

class FavoritesNotifier extends Notifier<List<Character>> {
  static const _storageKey = 'favorites_characters';

  @override
  List<Character> build() {
    return _loadFavorites();
  }

  List<Character> _loadFavorites() {
    final jsonString = shared.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Character.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  void toggleFavorite(Character character) {
    final isFav = state.any((c) => c.id == character.id);

    if (isFav) {
      state = state.where((c) => c.id != character.id).toList();
    } else {
      state = [character, ...state];
    }

    _saveFavorites();
  }

  bool isFavorite(int id) {
    return state.any((c) => c.id == id);
  }

  void _saveFavorites() {
    final jsonString = jsonEncode(state.map((c) => c.toJson()).toList());
    shared.setString(_storageKey, jsonString);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Character>>(
  FavoritesNotifier.new,
);
