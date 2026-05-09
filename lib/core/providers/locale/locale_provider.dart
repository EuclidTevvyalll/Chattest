import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/core/providers/locale/locale_notifier.dart';

final localeProvider = NotifierProvider.autoDispose<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
