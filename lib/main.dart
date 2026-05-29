import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forgelink/core/router/router.dart';
import 'package:forgelink/core/providers/locale/locale_provider.dart';
import 'package:forgelink/core/providers/theme_mode/theme_provider.dart';
import 'package:forgelink/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forgelink/core/config/supabase_config.dart';
import 'package:forgelink/features/auth/presentation/screens/banned_guard.dart';

late final SharedPreferences shared;
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Main: Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    debugPrint('Main: Initializing SharedPreferences...');
    shared = await SharedPreferences.getInstance();
    Intl.defaultLocale = 'ru_RU';

    debugPrint('Main: Running app...');
    runApp(ProviderScope(child: const MainApp()));
  } catch (e, stack) {
    debugPrint('Main: CRITICAL STARTUP ERROR: $e');
    debugPrint('Main: STACKTRACE: $stack');
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint('Lifecycle: Resumed. Setting user online...');
      Supabase.instance.client
          .from('profiles')
          .update({
            'is_online': true,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId)
          .catchError((_) {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      debugPrint('Lifecycle: Paused/Detached. Setting user offline...');
      Supabase.instance.client
          .from('profiles')
          .update({
            'is_online': false,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId)
          .catchError((_) {});
    }
  }
}

class MainApp extends HookConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final observer = _LifecycleObserver();
      WidgetsBinding.instance.addObserver(observer);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        debugPrint('Startup: Setting user online...');
        Supabase.instance.client
            .from('profiles')
            .update({
              'is_online': true,
              'last_seen': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', userId)
            .catchError((_) {});
      }

      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, []);

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
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return BannedGuard(child: child);
        },
        localizationsDelegates: const [
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
