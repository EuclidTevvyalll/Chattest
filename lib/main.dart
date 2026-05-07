import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rickandmorty/core/router/router.dart';
import 'package:rickandmorty/core/providers/locale/locale_provider.dart';
import 'package:rickandmorty/core/providers/theme_mode/theme_provider.dart';
import 'package:rickandmorty/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late final SharedPreferences shared;
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qhrcpooazwkdckusqcvx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFocmNwb29hendrZGNrdXNxY3Z4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNDQ2MTUsImV4cCI6MjA5MzYyMDYxNX0.8XPliDnwo_-63kqqbMRSvC0oi_M8Biw2Rt4hjLpipx8',
  );

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
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.white,
        ),
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
