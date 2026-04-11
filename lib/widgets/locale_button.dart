import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/core/providers/locale/locale_provider.dart';

class LocaleButton extends ConsumerWidget {
  final bool isDark;
  const LocaleButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        Icons.translate,
        color: isDark ? Colors.white : const Color.fromARGB(255, 32, 32, 32),
      ),
      onPressed: () {
        ref.read(localeProvider.notifier).switchLocale();
      },
    );
  }
}
