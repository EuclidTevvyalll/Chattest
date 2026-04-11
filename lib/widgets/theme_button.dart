import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/core/providers/theme_mode/theme_provider.dart';

class ThemeButton extends ConsumerWidget {
  final bool isDark;
  const ThemeButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: isDark ? Colors.white : const Color.fromARGB(255, 32, 32, 32),
      ),
      onPressed: () {
        ref.read(themeProvider.notifier).switchTheme();
      },
    );
  }
}
