import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/home_screen/presentation/providers/characters_notifier.dart';
import 'package:rickandmorty/features/home_screen/presentation/widgets/character_card.dart';
import 'package:rickandmorty/features/home_screen/presentation/widgets/character_detail_modal.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/l10n/app_localizations.dart';
import 'package:rickandmorty/widgets/appbar_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(charactersNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.app_title, style: ThemeTextStyles.h3(isDark: isDark)),
        actions: [AppbarActions(isDark: isDark)],
      ),

      extendBodyBehindAppBar: true,
      body: charactersAsync.when(
        data: (characters) {
          final notifier = ref.read(charactersNotifierProvider.notifier);

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent * 0.9) {
                notifier.loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 110),
                itemCount: characters.length + (notifier.hasMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == characters.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final character = characters[index];
                  return CharacterCard(
                    character: character,
                    onTap: () => CharacterDetailModal.show(context, character),
                  );
                },
              ),
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l10n.error_oops} $error',
                style: ThemeTextStyles.bodyMedium(isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(charactersNotifierProvider.notifier).refresh(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
