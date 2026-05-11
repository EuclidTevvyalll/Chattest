import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/core/providers/theme_mode/theme_notifier.dart';

final themeProvider = NotifierProvider.autoDispose<ThemeNotifier, ThemeMode>(
  () {
    return ThemeNotifier();
  },
);


