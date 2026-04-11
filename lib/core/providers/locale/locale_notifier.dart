import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/main.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final locale = shared.getString('app_locale') == 'ru'
        ? Locale('ru')
        : Locale('en');
    return locale;
  }

  void switchLocale() {
    if (state == Locale('ru')) {
      state = Locale('en');
      shared.setString('app_language', 'en');
    } else {
      state = Locale('ru');
      shared.setString('app_language', 'ru');
    }
  }
}
