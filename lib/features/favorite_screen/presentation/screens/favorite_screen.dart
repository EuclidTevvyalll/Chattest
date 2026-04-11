import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/home_screen/presentation/providers/favorites_notifier.dart';
import 'package:rickandmorty/features/home_screen/presentation/widgets/character_card.dart';
import 'package:rickandmorty/features/home_screen/presentation/widgets/character_detail_modal.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/l10n/app_localizations.dart';
import 'package:rickandmorty/widgets/appbar_actions.dart';

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.favorites_title,
          style: ThemeTextStyles.h3(isDark: isDark),
        ),
        actions: [AppbarActions(isDark: isDark)],
      ),
      extendBodyBehindAppBar: true,
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: isDark
                        ? Colors.white24
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.no_favorites,
                    style: ThemeTextStyles.bodyLarge(isDark: isDark),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 110),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final character = favorites[index];
                return CharacterCard(
                  character: character,
                  onTap: () => CharacterDetailModal.show(context, character),
                );
              },
            ),
    );
  }
}
