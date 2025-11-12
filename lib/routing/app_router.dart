import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickabout/routing/go_router_refresh_stream.dart';
import 'package:kickabout/screens/auth/login_screen.dart';
import 'package:kickabout/screens/auth/register_screen.dart';
import 'package:kickabout/screens/hub/hub_list_screen.dart';
import 'package:kickabout/screens/hub/create_hub_screen.dart';
import 'package:kickabout/screens/hub/hub_detail_screen.dart';
import 'package:kickabout/screens/game/game_list_screen.dart';
import 'package:kickabout/screens/game/create_game_screen.dart';
import 'package:kickabout/screens/game/game_detail_screen.dart';
import 'package:kickabout/screens/game/team_maker_screen.dart';
import 'package:kickabout/screens/game/stats_logger_screen.dart';
import 'package:kickabout/screens/stats_input/basic_rating_screen.dart';
import 'package:kickabout/screens/profile/player_profile_screen.dart';
import 'package:kickabout/screens/profile/edit_profile_screen.dart';
import 'package:kickabout/data/repositories_providers.dart';

/// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isGoingToAuth = state.matchedLocation == '/auth';

      // If not authenticated and not going to auth, redirect to auth
      if (!isAuthenticated && !isGoingToAuth) {
        return '/auth';
      }

      // If authenticated and going to auth, redirect to home
      if (isAuthenticated && isGoingToAuth) {
        return '/';
      }

      return null; // No redirect
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home route (hub list)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HubListScreen(),
      ),

      // Hub routes
      GoRoute(
        path: '/hubs',
        name: 'hubs',
        builder: (context, state) => const HubListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createHub',
            builder: (context, state) => const CreateHubScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'hubDetail',
            builder: (context, state) {
              final hubId = state.pathParameters['id']!;
              return HubDetailScreen(hubId: hubId);
            },
          ),
        ],
      ),

      // Game routes
      GoRoute(
        path: '/games',
        name: 'games',
        builder: (context, state) => const GameListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createGame',
            builder: (context, state) {
              final hubId = state.uri.queryParameters['hubId'];
              return CreateGameScreen(hubId: hubId);
            },
          ),
          GoRoute(
            path: ':id',
            name: 'gameDetail',
            builder: (context, state) {
              final gameId = state.pathParameters['id']!;
              return GameDetailScreen(gameId: gameId);
            },
            routes: [
              GoRoute(
                path: 'team-maker',
                name: 'teamMaker',
                builder: (context, state) {
                  final gameId = state.pathParameters['id']!;
                  return TeamMakerScreen(gameId: gameId);
                },
              ),
              GoRoute(
                path: 'stats',
                name: 'stats',
                builder: (context, state) {
                  final gameId = state.pathParameters['id']!;
                  return StatsLoggerScreen(gameId: gameId);
                },
              ),
              GoRoute(
                path: 'basic-rating',
                name: 'basicRating',
                builder: (context, state) {
                  final gameId = state.pathParameters['id']!;
                  return BasicRatingScreen(gameId: gameId);
                },
              ),
            ],
          ),
        ],
      ),

      // Profile routes
      GoRoute(
        path: '/profile/:uid',
        name: 'playerProfile',
        builder: (context, state) {
          final playerId = state.pathParameters['uid']!;
          return PlayerProfileScreen(playerId: playerId);
        },
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) {
              final userId = state.pathParameters['uid']!;
              return EditProfileScreen(userId: userId);
            },
          ),
        ],
      ),
    ],
  );
});

