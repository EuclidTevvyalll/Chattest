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

  void changeLocale(String locale) {
    state = Locale(locale);
    shared.setString('app_locale', locale);
  }
}
