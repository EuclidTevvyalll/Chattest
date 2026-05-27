import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forgelink/core/router/routes.dart';
import 'package:forgelink/features/main_layout/presentation/screens/main_screen.dart';
import 'package:forgelink/widgets/navigation_bar.dart';
import 'package:forgelink/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:forgelink/features/chat/presentation/screens/chat_detail_screen.dart';

import 'dart:async';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';
import 'package:forgelink/features/chat/domain/models/room_model.dart';

import 'package:forgelink/features/chat/presentation/screens/create_chat_screen.dart';
import 'package:forgelink/features/auth/presentation/screens/auth_screen.dart';
import 'package:forgelink/features/profile/presentation/screens/profile_screen.dart';
import 'package:forgelink/features/chat/presentation/screens/chat_info_screen.dart';
import 'package:forgelink/features/chat/presentation/screens/edit_room_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AuthListenable extends ChangeNotifier {
  AuthListenable(Stream<AuthState> authStateStream) {
    _subscription = authStateStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authListenableProvider = Provider<AuthListenable>((ref) {
  final stream = ref.watch(authRepositoryProvider).onAuthStateChange;
  return AuthListenable(stream);
});

final routerProvider = Provider<GoRouter>((ref) {
  // Use listen to ensure we don't recreate the router if authListenable changes
  // (though it shouldn't as it's not autoDispose now)
  final authListenable = ref.read(authListenableProvider);

  return GoRouter(
    initialLocation: Routes.auth,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: authListenable,

    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.uri.path == Routes.auth;

      if (!isAuth && !isAuthRoute) {
        return Routes.auth;
      }
      if (isAuth && isAuthRoute) {
        return Routes.chat;
      }
      return null;
    },

    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainLayout(
          bnb: BottomNavBar(
            currentIndex: _calculateSelectedIndex(state.uri.path),
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go(Routes.chat);
                  break;
                case 1:
                  context.go(Routes.profile);
                  break;
              }
            },
          ),
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.chat,
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        name: 'chat_detail',
        path: '/chat/:roomId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['roomId']!;
          final typeStr = state.uri.queryParameters['type'];
          final type = RoomType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => RoomType.room,
          );
          return ChatDetailScreen(roomId: id, type: type);
        },
      ),
      GoRoute(
        name: 'chat_info',
        path: '/chat/:roomId/info',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['roomId']!;
          return ChatInfoScreen(roomId: id);
        },
      ),
      GoRoute(
        name: 'edit_room',
        path: '/chat/:roomId/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['roomId']!;
          return EditRoomScreen(roomId: id);
        },
      ),
      GoRoute(
        path: Routes.userProfile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),

      GoRoute(
        path: Routes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/create-chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final typeStr = state.uri.queryParameters['type'];
          final type = RoomType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => RoomType.room,
          );
          return CreateChatScreen(initialType: type);
        },
      ),
    ],
  );
});

int _calculateSelectedIndex(String location) {
  if (location == Routes.chat) return 0;
  if (location == Routes.profile) return 1;
  return 0;
}
