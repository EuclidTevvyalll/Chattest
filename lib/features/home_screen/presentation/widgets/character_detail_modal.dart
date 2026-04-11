import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rickandmorty/features/home_screen/data/models/character.dart';
import 'package:rickandmorty/features/home_screen/presentation/providers/favorites_notifier.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';
import 'package:rickandmorty/l10n/app_localizations.dart';
import 'package:bounceable/bounceable.dart';

class CharacterDetailModal extends ConsumerWidget {
  final Character character;

  const CharacterDetailModal({super.key, required this.character});

  static void show(BuildContext context, Character character) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CharacterDetailModal(character: character),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isFavorite = ref
        .watch(favoritesProvider)
        .any((c) => c.id == character.id);

    final l10n = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.9),
      child: GlassBox(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        blur: 25,
        opacity: isDark ? 0.8 : 0.9,
        color: isDark ? const Color(0xff121212) : Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      character.image,
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Bounceable(
                      onTap: () {
                        ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(character);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            key: ValueKey(isFavorite),
                            color: isFavorite ? Colors.yellow : Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                character.name,
                style: ThemeTextStyles.h2(isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildInfoRow(context, l10n.status, character.status, isDark),
              _buildInfoRow(context, l10n.species, character.species, isDark),
              _buildInfoRow(context, l10n.gender, character.gender, isDark),
              _buildInfoRow(
                context,
                l10n.origin,
                character.origin.name,
                isDark,
              ),
              _buildInfoRow(
                context,
                l10n.last_location,
                character.location.name,
                isDark,
              ),
              _buildInfoRow(
                context,
                l10n.created_at,
                DateFormat('dd MMM yyyy').format(character.created),
                isDark,
              ),
              const SizedBox(height: 32),
              Bounceable(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ThemeColors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.close,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ThemeTextStyles.bodyMedium(
              color: ThemeColors.grey,
              isDark: isDark,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: ThemeTextStyles.bodyMedium(isDark: isDark),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
