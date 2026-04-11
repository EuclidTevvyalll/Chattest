import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rickandmorty/core/router/router.dart';
import 'package:rickandmorty/core/providers/locale/locale_provider.dart';
import 'package:rickandmorty/core/providers/theme_mode/theme_provider.dart';
import 'package:rickandmorty/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences shared;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  shared = await SharedPreferences.getInstance();
  Intl.defaultLocale = 'ru_RU';
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends HookConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final thememode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: thememode,
        locale: locale,
        routerConfig: router,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
