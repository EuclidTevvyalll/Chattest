import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/core/router/routes.dart';
import 'package:rickandmorty/features/main_layout/presentation/screens/main_screen.dart';
import 'package:rickandmorty/widgets/navigation_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider.autoDispose<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainLayout(
          bnb: BottomNavBar(
            currentIndex: _calculateSelectedIndex(state.uri.path),
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go(Routes.home);
                  break;
                case 1:
                  context.go(Routes.favorite);
                  break;
              }
            },
          ),
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (context, state) =>
                const Center(child: Text('Home Screen')),
          ),
          GoRoute(
            path: Routes.favorite,
            builder: (context, state) =>
                const Center(child: Text('Favorite Screen')),
          ),
        ],
      ),
    ],
  );
});

int _calculateSelectedIndex(String location) {
  if (location.startsWith(Routes.home)) return 1;
  if (location.startsWith(Routes.favorite)) return 2;
  return 0;
}
