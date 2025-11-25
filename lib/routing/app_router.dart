import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/routing/app_paths.dart';
import 'package:kickadoor/routing/go_router_refresh_stream.dart';
import 'package:kickadoor/utils/performance_utils.dart';
import 'package:kickadoor/screens/auth/login_screen.dart';
import 'package:kickadoor/screens/auth/register_screen.dart';
import 'package:kickadoor/screens/hub/hub_list_screen.dart';
import 'package:kickadoor/screens/hub/create_hub_screen.dart';
import 'package:kickadoor/screens/hub/hub_detail_screen.dart'
    deferred as hub_detail_screen;
import 'package:kickadoor/screens/hub/create_hub_event_screen.dart'
    deferred as create_hub_event_screen;
import 'package:kickadoor/screens/hub/edit_hub_event_screen.dart'
    deferred as edit_hub_event_screen;
import 'package:kickadoor/screens/game/game_list_screen.dart'
    deferred as game_list_screen;
import 'package:kickadoor/screens/game/create_game_screen.dart'
    deferred as create_game_screen;
import 'package:kickadoor/screens/game/game_detail_screen.dart'
    deferred as game_detail_screen;
import 'package:kickadoor/screens/game/team_maker_screen.dart'
    deferred as team_maker_screen;
import 'package:kickadoor/screens/game/log_game_screen.dart'
    deferred as log_game_screen;
import 'package:kickadoor/screens/profile/player_profile_screen_futuristic.dart'
    deferred as player_profile_screen;
import 'package:kickadoor/screens/profile/edit_profile_screen.dart'
    deferred as edit_profile_screen;
import 'package:kickadoor/screens/profile/privacy_settings_screen.dart'
    deferred as privacy_settings_screen;
import 'package:kickadoor/screens/location/discover_hubs_screen.dart'
    deferred as discover_hubs_screen;
import 'package:kickadoor/screens/location/map_screen.dart'
    deferred as map_screen;
import 'package:kickadoor/screens/social/notifications_screen.dart'
    deferred as notifications_screen;
import 'package:kickadoor/screens/social/post_detail_screen.dart'
    deferred as post_detail_screen;
import 'package:kickadoor/screens/social/following_screen.dart'
    deferred as following_screen;
import 'package:kickadoor/screens/social/followers_screen.dart'
    deferred as followers_screen;
import 'package:kickadoor/screens/social/feed_screen.dart'
    deferred as feed_screen;
import 'package:kickadoor/screens/home_screen_futuristic_figma.dart';
import 'package:kickadoor/screens/game/game_chat_screen.dart'
    deferred as game_chat_screen;
import 'package:kickadoor/screens/social/messages_list_screen.dart'
    deferred as messages_list_screen;
import 'package:kickadoor/screens/social/private_chat_screen.dart'
    deferred as private_chat_screen;
import 'package:kickadoor/screens/gamification/leaderboard_screen.dart'
    deferred as leaderboard_screen;
import 'package:kickadoor/screens/splash/splash_screen.dart';
import 'package:kickadoor/screens/players/players_list_screen.dart'
    deferred as players_list_screen;
import 'package:kickadoor/screens/players/players_map_screen.dart'
    deferred as players_map_screen;
import 'package:kickadoor/screens/hubs/hubs_board_screen.dart'
    deferred as hubs_board_screen;
import 'package:kickadoor/screens/admin/generate_dummy_data_screen.dart'
    deferred as generate_dummy_data_screen;
import 'package:kickadoor/screens/hub/manage_roles_screen.dart'
    deferred as manage_roles_screen;
import 'package:kickadoor/screens/hub/hub_settings_screen.dart';
import 'package:kickadoor/screens/hub/join_by_invite_screen.dart'
    deferred as join_by_invite_screen;
import 'package:kickadoor/screens/game/game_calendar_screen.dart'
    deferred as game_calendar_screen;
import 'package:kickadoor/screens/social/create_post_screen.dart'
    deferred as create_post_screen;
import 'package:kickadoor/screens/hub/scouting_screen.dart'
    deferred as scouting_screen;
import 'package:kickadoor/screens/hub/hub_players_list_screen.dart'
    deferred as hub_players_list_screen;
import 'package:kickadoor/screens/hub/hub_rules_screen.dart'
    deferred as hub_rules_screen;
import 'package:kickadoor/screens/hub/edit_game_screen.dart'
    deferred as edit_game_screen;
import 'package:kickadoor/screens/hub/hub_manage_requests_screen.dart'
    deferred as hub_manage_requests_screen;
import 'package:kickadoor/screens/venue/venue_search_screen.dart'
    deferred as venue_search_screen;
import 'package:kickadoor/screens/venue/create_manual_venue_screen.dart'
    deferred as create_manual_venue_screen;
import 'package:kickadoor/screens/location/map_picker_screen.dart';
import 'package:kickadoor/screens/onboarding/onboarding_screen.dart';
import 'package:kickadoor/screens/game/log_past_game_screen.dart'
    deferred as log_past_game_screen;
import 'package:kickadoor/screens/weather/weather_detail_screen.dart'
    deferred as weather_detail_screen;
import 'package:kickadoor/screens/activity/community_activity_feed_screen.dart'
    deferred as community_activity_feed_screen;
import 'package:kickadoor/screens/event/event_management_screen.dart'
    deferred as event_management_screen;
import 'package:kickadoor/screens/event/team_generator_config_screen.dart'
    deferred as team_generator_config_screen;
import 'package:kickadoor/screens/event/team_generator_result_screen.dart'
    deferred as team_generator_result_screen;
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kickadoor/logic/team_maker.dart';

/// Auth state stream provider
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final usersRepo = ref.watch(usersRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return usersRepo.watchUser(firebaseUser.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

/// Onboarding status provider - loads once and caches the value
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  } catch (e) {
    debugPrint('Failed to load onboarding status: $e');
    return false; // Default to not completed if error
  }
});

/// Helper widget for lazy loading routes.
class LazyRouteLoader extends StatefulWidget {
  final Future<void> loader;
  final Widget Function() builder;

  const LazyRouteLoader(
      {super.key, required this.loader, required this.builder});

  @override
  State<LazyRouteLoader> createState() => _LazyRouteLoaderState();
}

class _LazyRouteLoaderState extends State<LazyRouteLoader> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.builder();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);

  // Pre-load onboarding status to cache it before redirect runs
  ref.read(onboardingStatusProvider);

  return GoRouter(
    debugLogDiagnostics: PerformanceUtils.isDebugMode,
    initialLocation: AppPaths.auth,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    // Optimize navigation performance
    restorationScopeId: 'app_router',
    redirect: (context, state) {
      try {
        // Check if auth state is still loading - if so, allow auth/register screens
        if (authState.isLoading) {
          // If going to auth/register/splash, allow it (they will show loading state)
          if (state.matchedLocation == AppPaths.auth ||
              state.matchedLocation == AppPaths.register ||
              state.matchedLocation == AppPaths.splash) {
            return null;
          }
          // Otherwise, redirect to auth while loading
          return AppPaths.auth;
        }

        // Wait for auth state to be available
        final authValue = authState.valueOrNull;
        final isAuthenticated = authValue != null;

        final isGoingToAuth = state.matchedLocation == AppPaths.auth ||
            state.matchedLocation == AppPaths.register;
        final isGoingToOnboarding =
            state.matchedLocation == AppPaths.onboarding;
        final isGoingToSplash = state.matchedLocation == AppPaths.splash;

        // Allow splash screen
        if (isGoingToSplash) {
          return null;
        }

        // Check if user is anonymous - if so, redirect to auth immediately
        if (isAuthenticated) {
          final authService = ref.read(authServiceProvider);
          if (authService.isAnonymous) {
            authService.signOut().then((_) {
              debugPrint('�� Router: Signed out anonymous user');
            }).catchError((e) {
              debugPrint('⚠️ Router: Error signing out anonymous user: $e');
            });
            return AppPaths.auth;
          }
        }

        // If not authenticated and not going to auth/onboarding/splash, redirect to auth
        if (!isAuthenticated &&
            !isGoingToAuth &&
            !isGoingToOnboarding &&
            !isGoingToSplash) {
          return AppPaths.auth;
        }

        // Check onboarding status (only for authenticated non-anonymous users)
        if (isAuthenticated && !isGoingToOnboarding && !isGoingToSplash) {
          final onboardingStatus = ref.read(onboardingStatusProvider);

          // If still loading, don't redirect (allow navigation to proceed)
          if (onboardingStatus.isLoading) {
            return null;
          }

          // Handle async loading state
          if (onboardingStatus.hasValue) {
            final onboardingCompleted = onboardingStatus.value ?? false;

            if (!onboardingCompleted) {
              return AppPaths.onboarding;
            }
          }
        }

        // If authenticated (non-anonymous) and going to auth, redirect to home
        // Allow access to register screen even if authenticated (e.g. to create new account)
        if (isAuthenticated && state.matchedLocation == AppPaths.auth) {
          return AppPaths.home;
        }

        return null; // No redirect
      } catch (e) {
        // If redirect fails, go to auth screen
        debugPrint('Router redirect error: $e');
        return AppPaths.auth;
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
        builder: (context, state) => const LoginScreen(),
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
        builder: (context, state) => const HomeScreenFuturisticFigma(),
      ),

      // Location/Discovery routes
      GoRoute(
        path: AppPaths.discoverHubs,
        name: 'discoverHubs',
        builder: (context, state) => LazyRouteLoader(
            loader: discover_hubs_screen.loadLibrary(),
            builder: () => discover_hubs_screen.DiscoverHubsScreen()),
      ),
      GoRoute(
        path: AppPaths.map,
        name: 'map',
        builder: (context, state) => LazyRouteLoader(
            loader: map_screen.loadLibrary(),
            builder: () => map_screen.MapScreen()),
      ),
      GoRoute(
        path: AppPaths.weatherDetail,
        name: 'weatherDetail',
        builder: (context, state) => LazyRouteLoader(
            loader: weather_detail_screen.loadLibrary(),
            builder: () => weather_detail_screen.WeatherDetailScreen()),
      ),

      // Players Board
      GoRoute(
        path: AppPaths.playersBoard,
        name: 'playersBoard',
        builder: (context, state) => LazyRouteLoader(
            loader: players_list_screen.loadLibrary(),
            builder: () => players_list_screen.PlayersListScreen()),
      ),

      // Players Map
      GoRoute(
        path: AppPaths.playersMap,
        name: 'playersMap',
        builder: (context, state) => LazyRouteLoader(
            loader: players_map_screen.loadLibrary(),
            builder: () => players_map_screen.PlayersMapScreen()),
      ),

      // Hubs Board
      GoRoute(
        path: AppPaths.hubsBoard,
        name: 'hubsBoard',
        builder: (context, state) => LazyRouteLoader(
            loader: hubs_board_screen.loadLibrary(),
            builder: () => hubs_board_screen.HubsBoardScreen()),
      ),

      // Admin - Generate dummy data
      GoRoute(
        path: '/admin/generate-dummy-data',
        name: 'generateDummyData',
        builder: (context, state) => LazyRouteLoader(
            loader: generate_dummy_data_screen.loadLibrary(),
            builder: () =>
                generate_dummy_data_screen.GenerateDummyDataScreen()),
      ),

      // Join by invitation
      GoRoute(
        path: '/invite/:code',
        name: 'joinByInvite',
        builder: (context, state) => LazyRouteLoader(
            loader: join_by_invite_screen.loadLibrary(),
            builder: () {
              final code = state.pathParameters['code']!;
              return join_by_invite_screen.JoinByInviteScreen(
                  invitationCode: code);
            }),
      ),

      // Community Activity Feed
      GoRoute(
        path: '/activity',
        name: 'activityFeed',
        builder: (context, state) => LazyRouteLoader(
            loader: community_activity_feed_screen.loadLibrary(),
            builder: () =>
                community_activity_feed_screen.CommunityActivityFeedScreen()),
      ),

      // Game Calendar
      GoRoute(
        path: '/calendar',
        name: 'gameCalendar',
        builder: (context, state) => LazyRouteLoader(
            loader: game_calendar_screen.loadLibrary(),
            builder: () {
              final hubId = state.uri.queryParameters['hubId'];
              return game_calendar_screen.GameCalendarScreen(hubId: hubId);
            }),
      ),

      // Venue Search
      GoRoute(
        path: '/venues/search',
        name: 'venueSearch',
        builder: (context, state) => LazyRouteLoader(
            loader: venue_search_screen.loadLibrary(),
            builder: () {
              final hubId = state.uri.queryParameters['hubId'];
              final selectMode =
                  state.uri.queryParameters['selectMode'] == 'true' ||
                      state.uri.queryParameters['select'] ==
                          'true'; // Support both for backward compatibility
              return venue_search_screen.VenueSearchScreen(
                hubId: hubId,
                selectMode: selectMode,
              );
            }),
      ),

      // Create Manual Venue
      GoRoute(
        path: '/venues/create',
        name: 'createManualVenue',
        builder: (context, state) => LazyRouteLoader(
            loader: create_manual_venue_screen.loadLibrary(),
            builder: () =>
                create_manual_venue_screen.CreateManualVenueScreen()),
      ),

      // Map Picker
      GoRoute(
        path: AppPaths.mapPicker,
        name: 'mapPicker',
        builder: (context, state) {
          final extra = state.extra;
          final initialLocation =
              extra is MapPickerScreen ? extra.initialLocation : null;
          return MapPickerScreen(initialLocation: initialLocation);
        },
      ),

      // Notifications route
      GoRoute(
        path: AppPaths.notifications,
        name: 'notifications',
        builder: (context, state) => LazyRouteLoader(
            loader: notifications_screen.loadLibrary(),
            builder: () => notifications_screen.NotificationsScreen()),
      ),

      // Messages routes
      GoRoute(
        path: AppPaths.messages,
        name: 'messages',
        builder: (context, state) => LazyRouteLoader(
            loader: messages_list_screen.loadLibrary(),
            builder: () => messages_list_screen.MessagesListScreen()),
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'privateChat',
            builder: (context, state) => LazyRouteLoader(
                loader: private_chat_screen.loadLibrary(),
                builder: () {
                  final conversationId =
                      state.pathParameters['conversationId']!;
                  return private_chat_screen.PrivateChatScreen(
                      conversationId: conversationId);
                }),
          ),
        ],
      ),

      // Event Management routes
      GoRoute(
        path: '/events/:eventId/manage',
        name: 'eventManagement',
        builder: (context, state) => LazyRouteLoader(
            loader: event_management_screen.loadLibrary(),
            builder: () {
              final eventId = state.pathParameters['eventId']!;
              final extra = state.extra as Map<String, dynamic>?;
              final hubId = extra?['hubId'] as String?;
              if (hubId == null) {
                throw Exception('hubId is required for event management');
              }
              return event_management_screen.EventManagementScreen(
                hubId: hubId,
                eventId: eventId,
              );
            }),
        routes: [
          GoRoute(
            path: 'team-generator/config',
            name: 'teamGeneratorConfig',
            builder: (context, state) => LazyRouteLoader(
                loader: team_generator_config_screen.loadLibrary(),
                builder: () {
                  final eventId = state.pathParameters['eventId']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  final hubId = extra?['hubId'] as String?;
                  if (hubId == null) {
                    throw Exception('hubId is required for team generator');
                  }
                  return team_generator_config_screen.TeamGeneratorConfigScreen(
                    hubId: hubId,
                    eventId: eventId,
                  );
                }),
          ),
          GoRoute(
            path: 'team-generator/result',
            name: 'teamGeneratorResult',
            builder: (context, state) => LazyRouteLoader(
                loader: team_generator_result_screen.loadLibrary(),
                builder: () {
                  final eventId = state.pathParameters['eventId']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  if (extra == null) {
                    throw Exception(
                        'Extra data required for team generator result');
                  }
                  final hubId = extra['hubId'] as String?;
                  final players = extra['players'] as List<PlayerForTeam>?;
                  final teamCount = extra['teamCount'] as int?;

                  if (hubId == null || players == null || teamCount == null) {
                    throw Exception(
                        'hubId, players, and teamCount are required');
                  }

                  return team_generator_result_screen.TeamGeneratorResultScreen(
                    hubId: hubId,
                    eventId: eventId,
                    players: players,
                    teamCount: teamCount,
                  );
                }),
          ),
        ],
      ),

      // Leaderboard route
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => LazyRouteLoader(
            loader: leaderboard_screen.loadLibrary(),
            builder: () => leaderboard_screen.LeaderboardScreen()),
      ),

      // Feed route - requires hubId as query parameter
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => LazyRouteLoader(
            loader: feed_screen.loadLibrary(),
            builder: () {
              final hubId = state.uri.queryParameters['hubId'];
              if (hubId == null || hubId.isEmpty) {
                // If no hubId, redirect to hubs list
                return const HubListScreen();
              }
              return feed_screen.FeedScreen(hubId: hubId);
            }),
      ),
      // Hub routes
      GoRoute(
        path: AppPaths.hubs,
        name: 'hubs',
        builder: (context, state) => const HubListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createHub',
            builder: (context, state) => const CreateHubScreen(),
          ),
          GoRoute(
            path: AppPaths.hubDetail.split('/').last, // ':id'
            name: 'hubDetail',
            builder: (context, state) => LazyRouteLoader(
                loader: hub_detail_screen.loadLibrary(),
                builder: () {
                  final hubId = state.pathParameters['id'];
                  if (hubId == null || hubId.isEmpty) {
                    return const HubListScreen();
                  }
                  return hub_detail_screen.HubDetailScreen(hubId: hubId);
                }),
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
                builder: (context, state) => LazyRouteLoader(
                    loader: manage_roles_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return manage_roles_screen.ManageRolesScreen(
                          hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'feed/:postId',
                name: 'postDetail',
                builder: (context, state) => LazyRouteLoader(
                    loader: post_detail_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final postId = state.pathParameters['postId']!;
                      return post_detail_screen.PostDetailScreen(
                          hubId: hubId, postId: postId);
                    }),
              ),
              GoRoute(
                path: 'create-post',
                name: 'createPost',
                builder: (context, state) => LazyRouteLoader(
                    loader: create_post_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return create_post_screen.CreatePostScreen(hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'events/create',
                name: 'createHubEvent',
                builder: (context, state) => LazyRouteLoader(
                    loader: create_hub_event_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return create_hub_event_screen.CreateHubEventScreen(
                        hubId: hubId,
                        hub: Hub(
                          hubId: hubId,
                          name: '',
                          createdBy: '',
                          createdAt: DateTime.now(),
                        ),
                      );
                    }),
              ),
              GoRoute(
                path: 'events/:eventId/edit',
                name: 'editHubEvent',
                builder: (context, state) => LazyRouteLoader(
                    loader: edit_hub_event_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final eventId = state.pathParameters['eventId']!;
                      return edit_hub_event_screen.EditHubEventScreen(
                          hubId: hubId, eventId: eventId);
                    }),
              ),
              GoRoute(
                path: 'events/:eventId/log-game',
                name: 'logGame',
                builder: (context, state) => LazyRouteLoader(
                    loader: log_game_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final eventId = state.pathParameters['eventId']!;
                      return log_game_screen.LogGameScreen(
                          hubId: hubId, eventId: eventId);
                    }),
              ),
              GoRoute(
                path: 'events/:eventId/team-maker',
                name: 'eventTeamMaker',
                builder: (context, state) => LazyRouteLoader(
                    loader: team_maker_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final eventId = state.pathParameters['eventId']!;
                      return team_maker_screen.TeamMakerScreen(
                          gameId: eventId, isEvent: true, hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'scouting',
                name: 'scouting',
                builder: (context, state) => LazyRouteLoader(
                    loader: scouting_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final gameId = state.uri.queryParameters['gameId'];
                      return scouting_screen.ScoutingScreen(
                          hubId: hubId, gameId: gameId);
                    }),
              ),
              GoRoute(
                path: 'players',
                name: 'hubPlayers',
                builder: (context, state) => LazyRouteLoader(
                    loader: hub_players_list_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return hub_players_list_screen.HubPlayersListScreen(
                          hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'log-past-game',
                name: 'logPastGame',
                builder: (context, state) => LazyRouteLoader(
                    loader: log_past_game_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return log_past_game_screen.LogPastGameScreen(
                          hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'rules',
                name: 'hubRules',
                builder: (context, state) => LazyRouteLoader(
                    loader: hub_rules_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return hub_rules_screen.HubRulesScreen(hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'requests',
                name: 'hubManageRequests',
                builder: (context, state) => LazyRouteLoader(
                    loader: hub_manage_requests_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return hub_manage_requests_screen.HubManageRequestsScreen(
                          hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'games/:gameId/edit',
                name: 'editGame',
                builder: (context, state) => LazyRouteLoader(
                    loader: edit_game_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final gameId = state.pathParameters['gameId']!;
                      return edit_game_screen.EditGameScreen(
                          hubId: hubId, gameId: gameId);
                    }),
              ),
            ],
          ),
        ],
      ),

      // Game routes
      GoRoute(
        path: '/games', // Corrected from AppPaths.games which does not exist
        name: 'games',
        builder: (context, state) => LazyRouteLoader(
            loader: game_list_screen.loadLibrary(),
            builder: () => game_list_screen.GameListScreen()),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createGame',
            builder: (context, state) => LazyRouteLoader(
                loader: create_game_screen.loadLibrary(),
                builder: () {
                  final hubId = state.uri.queryParameters['hubId'];
                  return create_game_screen.CreateGameScreen(hubId: hubId);
                }),
          ),
          GoRoute(
            path: AppPaths.gameDetail.split('/').last, // ':id'
            name: 'gameDetail',
            builder: (context, state) => LazyRouteLoader(
                loader: game_detail_screen.loadLibrary(),
                builder: () {
                  final gameId = state.pathParameters['id']!;
                  return game_detail_screen.GameDetailScreen(gameId: gameId);
                }),
            routes: [
              GoRoute(
                path: 'team-maker',
                name: 'teamMaker',
                builder: (context, state) => LazyRouteLoader(
                    loader: team_maker_screen.loadLibrary(),
                    builder: () {
                      final gameId = state.pathParameters['id']!;
                      return team_maker_screen.TeamMakerScreen(gameId: gameId);
                    }),
              ),
              // Removed: stats and basic-rating routes - replaced by LogGameScreen
              GoRoute(
                path: 'chat',
                name: 'gameChat',
                builder: (context, state) => LazyRouteLoader(
                    loader: game_chat_screen.loadLibrary(),
                    builder: () {
                      final gameId = state.pathParameters['id']!;
                      return game_chat_screen.GameChatScreen(gameId: gameId);
                    }),
              ),
            ],
          ),
        ],
      ),

      // Profile routes
      GoRoute(
        path: AppPaths.playerProfile,
        name: 'playerProfile',
        builder: (context, state) => LazyRouteLoader(
            loader: player_profile_screen.loadLibrary(),
            builder: () {
              final playerId = state.pathParameters['uid']!;
              return player_profile_screen.PlayerProfileScreenFuturistic(
                  playerId: playerId);
            }),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => LazyRouteLoader(
                loader: edit_profile_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return edit_profile_screen.EditProfileScreen(userId: userId);
                }),
          ),
          GoRoute(
            path: 'privacy',
            name: 'privacySettings',
            builder: (context, state) => LazyRouteLoader(
                loader: privacy_settings_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return privacy_settings_screen.PrivacySettingsScreen(
                      userId: userId);
                }),
          ),
          GoRoute(
            path: 'following',
            name: 'following',
            builder: (context, state) => LazyRouteLoader(
                loader: following_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return following_screen.FollowingScreen(userId: userId);
                }),
          ),
          GoRoute(
            path: 'followers',
            name: 'followers',
            builder: (context, state) => LazyRouteLoader(
                loader: followers_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return followers_screen.FollowersScreen(userId: userId);
                }),
          ),
        ],
      ),
    ],
  );
});
