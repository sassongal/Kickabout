import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/routing/go_router_refresh_stream.dart';
import 'package:kickadoor/utils/performance_utils.dart';
import 'package:kickadoor/screens/auth/login_screen_futuristic.dart';
import 'package:kickadoor/screens/auth/register_screen.dart';
import 'package:kickadoor/screens/hub/hub_list_screen.dart';
import 'package:kickadoor/screens/hub/create_hub_screen.dart';
import 'package:kickadoor/screens/hub/hub_detail_screen.dart';
import 'package:kickadoor/screens/game/game_list_screen.dart';
import 'package:kickadoor/screens/game/create_game_screen.dart';
import 'package:kickadoor/screens/game/game_detail_screen.dart';
import 'package:kickadoor/screens/game/team_maker_screen.dart';
import 'package:kickadoor/screens/game/stats_logger_screen.dart';
import 'package:kickadoor/screens/stats_input/basic_rating_screen.dart';
import 'package:kickadoor/screens/profile/player_profile_screen.dart';
import 'package:kickadoor/screens/profile/edit_profile_screen.dart';
import 'package:kickadoor/screens/location/discover_hubs_screen.dart';
import 'package:kickadoor/screens/location/map_screen.dart';
import 'package:kickadoor/screens/social/notifications_screen.dart';
import 'package:kickadoor/screens/social/post_detail_screen.dart';
import 'package:kickadoor/screens/social/following_screen.dart';
import 'package:kickadoor/screens/social/followers_screen.dart';
import 'package:kickadoor/screens/home_screen_futuristic.dart';
import 'package:kickadoor/screens/game/game_chat_screen.dart';
import 'package:kickadoor/screens/social/messages_list_screen.dart';
import 'package:kickadoor/screens/social/private_chat_screen.dart';
import 'package:kickadoor/screens/gamification/leaderboard_screen.dart';
import 'package:kickadoor/screens/splash/splash_screen.dart';
import 'package:kickadoor/screens/players/players_list_screen.dart';
import 'package:kickadoor/screens/hubs/hubs_board_screen.dart';
import 'package:kickadoor/screens/admin/generate_dummy_data_screen.dart';
import 'package:kickadoor/screens/hub/manage_roles_screen.dart';
import 'package:kickadoor/screens/hub/hub_settings_screen.dart';
import 'package:kickadoor/screens/hub/join_by_invite_screen.dart';
import 'package:kickadoor/screens/game/game_calendar_screen.dart';
import 'package:kickadoor/screens/social/create_post_screen.dart';
import 'package:kickadoor/screens/hub/scouting_screen.dart';
import 'package:kickadoor/screens/hub/hub_players_list_screen.dart';
import 'package:kickadoor/screens/onboarding/onboarding_screen.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    debugLogDiagnostics: PerformanceUtils.isDebugMode,
    initialLocation: '/auth', // Start with auth screen
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    // Optimize navigation performance
    restorationScopeId: 'app_router',
    redirect: (context, state) async {
      try {
        // Wait for auth state to be available
        final authValue = authState.valueOrNull;
        final isAuthenticated = authValue != null;
        final isGoingToAuth = state.matchedLocation == '/auth' || state.matchedLocation == '/register';
        final isGoingToOnboarding = state.matchedLocation == '/onboarding';
        final isGoingToSplash = state.matchedLocation == '/splash';

        // Allow splash screen
        if (isGoingToSplash) {
          return null;
        }

        // Check onboarding status (only for authenticated users)
        if (isAuthenticated && !isGoingToOnboarding && !isGoingToSplash) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
            
            if (!onboardingCompleted) {
              return '/onboarding';
            }
          } catch (e) {
            // If SharedPreferences fails, continue without onboarding check
            debugPrint('Failed to check onboarding status: $e');
          }
        }

        // If not authenticated and not going to auth/onboarding/splash, redirect to auth
        if (!isAuthenticated && !isGoingToAuth && !isGoingToOnboarding && !isGoingToSplash) {
          return '/auth';
        }

        // If authenticated and going to auth, redirect to home
        if (isAuthenticated && isGoingToAuth) {
          return '/';
        }

        return null; // No redirect
      } catch (e) {
        // If redirect fails, go to auth screen
        debugPrint('Router redirect error: $e');
        return '/auth';
      }
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginScreenFuturistic(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home route - Futuristic Dashboard
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreenFuturistic(),
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

      // Players Board
      GoRoute(
        path: '/players',
        name: 'playersBoard',
        builder: (context, state) => const PlayersListScreen(),
      ),

      // Hubs Board
      GoRoute(
        path: '/hubs-board',
        name: 'hubsBoard',
        builder: (context, state) => const HubsBoardScreen(),
      ),

      // Admin - Generate dummy data
      GoRoute(
        path: '/admin/generate-dummy-data',
        name: 'generateDummyData',
        builder: (context, state) => const GenerateDummyDataScreen(),
      ),

      // Join by invitation
      GoRoute(
        path: '/invite/:code',
        name: 'joinByInvite',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return JoinByInviteScreen(invitationCode: code);
        },
      ),

      // Game Calendar
      GoRoute(
        path: '/calendar',
        name: 'gameCalendar',
        builder: (context, state) {
          final hubId = state.uri.queryParameters['hubId'];
          return GameCalendarScreen(hubId: hubId);
        },
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
                path: 'settings',
                name: 'hubSettings',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return HubSettingsScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'manage-roles',
                name: 'manageHubRoles',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return ManageRolesScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'feed/:postId',
                name: 'postDetail',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final postId = state.pathParameters['postId']!;
                  return PostDetailScreen(hubId: hubId, postId: postId);
                },
              ),
              GoRoute(
                path: 'create-post',
                name: 'createPost',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return CreatePostScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'scouting',
                name: 'scouting',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final gameId = state.uri.queryParameters['gameId'];
                  return ScoutingScreen(hubId: hubId, gameId: gameId);
                },
              ),
              GoRoute(
                path: 'players',
                name: 'hubPlayers',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return HubPlayersListScreen(hubId: hubId);
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

