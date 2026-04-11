import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/main.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final savedMode = shared.getString('app_theme_mode') == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    return savedMode;
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      shared.setString('app_theme_mode', 'light');
    } else {
      state = ThemeMode.dark;
      shared.setString('app_theme_mode', 'dark');
    }
  }
}
