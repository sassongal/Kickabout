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
import 'package:kickabout/screens/location/discover_hubs_screen.dart';
import 'package:kickabout/screens/location/map_screen.dart';
import 'package:kickabout/screens/social/notifications_screen.dart';
import 'package:kickabout/screens/social/post_detail_screen.dart';
import 'package:kickabout/screens/social/following_screen.dart';
import 'package:kickabout/screens/social/followers_screen.dart';
import 'package:kickabout/screens/home_screen.dart';
import 'package:kickabout/screens/game/game_chat_screen.dart';
import 'package:kickabout/screens/social/messages_list_screen.dart';
import 'package:kickabout/screens/social/private_chat_screen.dart';
import 'package:kickabout/screens/gamification/leaderboard_screen.dart';
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

      // Home route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Location/Discovery routes
      GoRoute(
        path: '/discover',
        name: 'discoverHubs',
        builder: (context, state) => const DiscoverHubsScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),

      // Notifications route
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Messages routes
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const MessagesListScreen(),
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'privateChat',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return PrivateChatScreen(conversationId: conversationId);
            },
          ),
        ],
      ),

      // Leaderboard route
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) {
          final hubId = state.uri.queryParameters['hubId'];
          return LeaderboardScreen(hubId: hubId);
        },
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
            routes: [
              GoRoute(
                path: 'feed/:postId',
                name: 'postDetail',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final postId = state.pathParameters['postId']!;
                  return PostDetailScreen(hubId: hubId, postId: postId);
                },
              ),
            ],
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
              GoRoute(
                path: 'chat',
                name: 'gameChat',
                builder: (context, state) {
                  final gameId = state.pathParameters['id']!;
                  return GameChatScreen(gameId: gameId);
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
          GoRoute(
            path: 'following',
            name: 'following',
            builder: (context, state) {
              final userId = state.pathParameters['uid']!;
              return FollowingScreen(userId: userId);
            },
          ),
          GoRoute(
            path: 'followers',
            name: 'followers',
            builder: (context, state) {
              final userId = state.pathParameters['uid']!;
              return FollowersScreen(userId: userId);
            },
          ),
        ],
      ),
    ],
  );
});

