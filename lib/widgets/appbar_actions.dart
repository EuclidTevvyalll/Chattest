import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickandmorty/widgets/locale_button.dart';
import 'package:rickandmorty/widgets/theme_button.dart';

class AppbarActions extends ConsumerWidget {
  final double padding;
  final bool isDark;
  const AppbarActions({super.key, required this.isDark, this.padding = 8});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        spacing: 4,
        children: [
          ThemeButton(isDark: isDark),
          LocaleButton(isDark: isDark),
        ],
      ),
    );
  }
}
