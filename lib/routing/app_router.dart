import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import 'package:kattrick/routing/app_paths.dart';
import 'package:kattrick/routing/go_router_refresh_stream.dart';
import 'package:kattrick/utils/performance_utils.dart';
import 'package:kattrick/screens/auth/auth_screen.dart';
import 'package:kattrick/screens/welcome/welcome_screen.dart';
import 'package:kattrick/screens/profile/profile_setup_wizard.dart';
import 'package:kattrick/screens/hub/hub_list_screen.dart';
import 'package:kattrick/screens/hub/create_hub_screen.dart';
import 'package:kattrick/screens/hub/hub_detail_screen.dart'
    deferred as hub_detail_screen;
import 'package:kattrick/screens/hub/create_hub_event_screen.dart'
    deferred as create_hub_event_screen;
import 'package:kattrick/screens/hub/edit_hub_event_screen.dart'
    deferred as edit_hub_event_screen;
import 'package:kattrick/screens/events/event_management_screen.dart'
    deferred as hub_event_management_screen;
import 'package:kattrick/screens/hub/create_poll_screen.dart';
import 'package:kattrick/screens/hub/poll_detail_screen.dart';
import 'package:kattrick/screens/game/game_list_screen.dart'
    deferred as game_list_screen;
import 'package:kattrick/screens/game/create_game_screen.dart'
    deferred as create_game_screen;
import 'package:kattrick/screens/game/game_detail_screen.dart'
    deferred as game_detail_screen;
import 'package:kattrick/screens/game/confirm_attendance_screen.dart';
import 'package:kattrick/screens/game/attendance_monitoring_screen.dart';
import 'package:kattrick/screens/game/team_maker_screen.dart'
    deferred as team_maker_screen;
import 'package:kattrick/screens/game/log_game_screen.dart'
    deferred as log_game_screen;
import 'package:kattrick/screens/profile/player_profile_screen_futuristic.dart'
    deferred as player_profile_screen;
import 'package:kattrick/screens/profile/edit_profile_screen.dart'
    deferred as edit_profile_screen;
import 'package:kattrick/screens/profile/privacy_settings_screen.dart'
    deferred as privacy_settings_screen;
import 'package:kattrick/screens/profile/settings_screen.dart'
    deferred as settings_screen;
import 'package:kattrick/screens/profile/notification_settings_screen.dart'
    deferred as notification_settings_screen;
import 'package:kattrick/screens/profile/blocked_users_screen.dart';
import 'package:kattrick/screens/profile/performance_breakdown_screen.dart'
    deferred as performance_breakdown_screen;
import 'package:kattrick/screens/profile/hub_stats_screen.dart'
    deferred as hub_stats_screen;
import 'package:kattrick/screens/location/discover_hubs_screen.dart'
    deferred as discover_hubs_screen;
import 'package:kattrick/screens/location/map_screen.dart'
    deferred as map_screen;
import 'package:kattrick/screens/social/notifications_screen.dart'
    deferred as notifications_screen;
import 'package:kattrick/screens/social/post_detail_screen.dart'
    deferred as post_detail_screen;
import 'package:kattrick/screens/social/following_screen.dart'
    deferred as following_screen;
import 'package:kattrick/screens/social/followers_screen.dart'
    deferred as followers_screen;
import 'package:kattrick/screens/home_screen_futuristic_figma.dart';
import 'package:kattrick/screens/game/game_chat_screen.dart'
    deferred as game_chat_screen;
import 'package:kattrick/screens/community/community_screen.dart';

import 'package:kattrick/screens/social/messages_list_screen.dart'
    deferred as messages_list_screen;
import 'package:kattrick/screens/social/private_chat_screen.dart'
    deferred as private_chat_screen;
import 'package:kattrick/screens/gamification/leaderboard_screen.dart'
    deferred as leaderboard_screen;
import 'package:kattrick/screens/splash/splash_screen.dart';
import 'package:kattrick/screens/players/players_list_screen.dart'
    deferred as players_list_screen;
import 'package:kattrick/screens/players/players_map_screen.dart'
    deferred as players_map_screen;
import 'package:kattrick/screens/hubs/hubs_board_screen.dart'
    deferred as hubs_board_screen;
import 'package:kattrick/screens/admin/admin_dashboard_screen.dart'
    deferred as admin_dashboard_screen;
import 'package:kattrick/screens/admin/generate_dummy_data_screen.dart'
    deferred as generate_dummy_data_screen;
import 'package:kattrick/screens/hub/manage_roles_screen.dart'
    deferred as manage_roles_screen;
import 'package:kattrick/screens/hub/hub_settings_screen.dart';
import 'package:kattrick/screens/hub/join_by_invite_screen.dart'
    deferred as join_by_invite_screen;
import 'package:kattrick/screens/game/game_calendar_screen.dart'
    deferred as game_calendar_screen;
import 'package:kattrick/screens/social/create_post_screen.dart'
    deferred as create_post_screen;
import 'package:kattrick/screens/hub/scouting_screen.dart'
    deferred as scouting_screen;
import 'package:kattrick/screens/hub/hub_players_list_screen.dart'
    deferred as hub_players_list_screen;
import 'package:kattrick/screens/hub/hub_rules_screen.dart'
    deferred as hub_rules_screen;
import 'package:kattrick/screens/hub/edit_game_screen.dart'
    deferred as edit_game_screen;
import 'package:kattrick/screens/hub/hub_manage_requests_screen.dart'
    deferred as hub_manage_requests_screen;
import 'package:kattrick/screens/venue/venue_search_screen.dart'
    deferred as venue_search_screen;
import 'package:kattrick/screens/venue/create_manual_venue_screen.dart'
    deferred as create_manual_venue_screen;
import 'package:kattrick/screens/venues/discover_venues_screen.dart'
    deferred as discover_venues_screen;
import 'package:kattrick/screens/location/map_picker_screen.dart';
import 'package:kattrick/screens/game/log_past_game_screen.dart'
    deferred as log_past_game_screen;
import 'package:kattrick/screens/hub/hub_analytics_screen.dart'
    deferred as hub_analytics_screen;
import 'package:kattrick/screens/social/create_recruiting_post_screen.dart'
    deferred as create_recruiting_post_screen;
import 'package:kattrick/screens/activity/community_activity_feed_screen.dart'
    deferred as community_activity_feed_screen;
import 'package:kattrick/screens/weather/weather_detail_screen.dart';
import 'package:kattrick/screens/game/game_recording_screen.dart'
    deferred as game_recording_screen;
import 'package:kattrick/screens/event/event_management_screen.dart'
    deferred as event_management_screen;
import 'package:kattrick/screens/event/team_generator_config_screen.dart'
    deferred as team_generator_config_screen;
import 'package:kattrick/screens/event/team_generator_result_screen.dart'
    deferred as team_generator_result_screen;
import 'package:kattrick/screens/debug/create_dummy_players_screen.dart'
    deferred as create_dummy_players_screen;

import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kattrick/logic/team_maker.dart';

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

  return GoRouter(
    debugLogDiagnostics: PerformanceUtils.isDebugMode,
    initialLocation: AppPaths.splash,
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    // Optimize navigation performance
    restorationScopeId: 'app_router',
    redirect: (context, state) async {
      try {
        final path = state.matchedLocation;

        // Always allow splash
        if (path == AppPaths.splash) return null;

        // Auth state loading: allow auth/welcome/splash, otherwise stay put
        if (authState.isLoading) {
          if (path == AppPaths.auth || path == AppPaths.welcome) return null;
          return AppPaths.splash;
        }

        final authValue = authState.valueOrNull;
        final cachedUserId = authService.currentUserId;
        final isAuthenticated = authValue != null || cachedUserId != null;

        final currentUserAsync = ref.watch(currentUserProvider);
        if (currentUserAsync.isLoading) {
          // Avoid bouncing while user data is loading
          return null;
        }

        // Welcome flow only for unauthenticated users
        if (!isAuthenticated) {
          final prefs = await SharedPreferences.getInstance();
          final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
          if (!hasSeenWelcome && path != AppPaths.welcome) {
            return AppPaths.welcome;
          }
          if (path == AppPaths.auth || path == AppPaths.welcome) {
            return null;
          }
          return AppPaths.auth;
        }

        // Authenticated: enforce profile setup once
        final user = currentUserAsync.valueOrNull;
        final isProfileComplete = user?.isProfileComplete ?? false;
        if (!isProfileComplete && path != AppPaths.profileSetup) {
          return AppPaths.profileSetup;
        }

        // Prevent going back to auth/welcome when already authenticated
        if (path == AppPaths.auth || path == AppPaths.welcome) {
          return AppPaths.home;
        }

        return null;
      } catch (e) {
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

      // Welcome
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Legacy register path -> auth screen
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const AuthScreen(),
      ),
      // Legacy onboarding path -> welcome
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        path: '/profile/setup',
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupWizard(),
      ),

      // Home route - Futuristic Dashboard
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreenFuturisticFigma(),
      ),

      GoRoute(
        path: AppPaths.community,
        name: 'community',
        builder: (context, state) => const CommunityScreen(),
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
      // Game Recording
      GoRoute(
        path: '/hub/:hubId/event/:eventId/record',
        name: 'gameRecording',
        builder: (context, state) {
          final hubId = state.pathParameters['hubId']!;
          final event = state.extra as HubEvent;
          return LazyRouteLoader(
            loader: game_recording_screen.loadLibrary(),
            builder: () => game_recording_screen.GameRecordingScreen(
              hubId: hubId,
              event: event,
            ),
          );
        },
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

      // Admin - Dashboard
      GoRoute(
        path: '/admin/dashboard',
        name: 'adminDashboard',
        builder: (context, state) => LazyRouteLoader(
            loader: admin_dashboard_screen.loadLibrary(),
            builder: () => admin_dashboard_screen.AdminDashboardScreen()),
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
      GoRoute(
        path: AppPaths.weatherDetail,
        name: 'weatherDetail',
        builder: (context, state) => const WeatherDetailScreen(),
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

      // Discover Venues (Main venues screen)
      GoRoute(
        path: '/venues/discover',
        name: 'discoverVenues',
        builder: (context, state) => LazyRouteLoader(
            loader: discover_venues_screen.loadLibrary(),
            builder: () => discover_venues_screen.DiscoverVenuesScreen()),
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
        path: '/hubs/:hubId/events/:eventId/manage',
        name: 'eventManagement',
        builder: (context, state) => LazyRouteLoader(
            loader: event_management_screen.loadLibrary(),
            builder: () {
              final eventId = state.pathParameters['eventId']!;
              final hubId = state.pathParameters['hubId']!;
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
                  final hubId = state.pathParameters['hubId']!;
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
              // Polls routes
              GoRoute(
                path: 'polls/create',
                name: 'createPoll',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return CreatePollScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'polls/:pollId',
                name: 'pollDetail',
                builder: (context, state) {
                  final pollId = state.pathParameters['pollId']!;
                  return PollDetailScreen(pollId: pollId);
                },
              ),
              GoRoute(
                path: 'events/:eventId/manage',
                name: 'manageHubEvent',
                builder: (context, state) => LazyRouteLoader(
                    loader: hub_event_management_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      final eventId = state.pathParameters['eventId']!;
                      return hub_event_management_screen.EventManagementScreen(
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
              GoRoute(
                path: 'analytics',
                name: 'hubAnalytics',
                builder: (context, state) => LazyRouteLoader(
                    loader: hub_analytics_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return hub_analytics_screen.HubAnalyticsScreen(
                          hubId: hubId);
                    }),
              ),
              GoRoute(
                path: 'create-recruiting-post',
                name: 'createRecruitingPost',
                builder: (context, state) => LazyRouteLoader(
                    loader: create_recruiting_post_screen.loadLibrary(),
                    builder: () {
                      final hubId = state.pathParameters['id']!;
                      return create_recruiting_post_screen
                          .CreateRecruitingPostScreen(hubId: hubId);
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
                path: 'confirm-attendance',
                name: 'confirmAttendance',
                builder: (context, state) {
                  final gameId = state.pathParameters['id']!;
                  return ConfirmAttendanceScreen(gameId: gameId);
                },
              ),
              GoRoute(
                path: 'attendance',
                name: 'attendanceMonitoring',
                builder: (context, state) {
                  final gameId = state.pathParameters['id']!;
                  return AttendanceMonitoringScreen(gameId: gameId);
                },
              ),
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
              // Debug route: Create Dummy Players
              GoRoute(
                path: '/debug/create-dummy-players',
                name: 'createDummyPlayers',
                builder: (context, state) => LazyRouteLoader(
                  loader: create_dummy_players_screen.loadLibrary(),
                  builder: () =>
                      create_dummy_players_screen.CreateDummyPlayersScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Profile routes
      GoRoute(
        path: '/profile/:uid',
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
            path: 'settings',
            name: 'settings',
            builder: (context, state) => LazyRouteLoader(
                loader: settings_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return settings_screen.SettingsScreen(
                    userId: userId,
                  );
                }),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notificationSettings',
            builder: (context, state) => LazyRouteLoader(
                loader: notification_settings_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return notification_settings_screen.NotificationSettingsScreen(
                    userId: userId,
                  );
                }),
          ),
          GoRoute(
            path: 'blocked',
            name: 'blockedUsers',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
          GoRoute(
            path: 'performance',
            name: 'performanceBreakdown',
            builder: (context, state) => LazyRouteLoader(
                loader: performance_breakdown_screen.loadLibrary(),
                builder: () {
                  final userId = state.pathParameters['uid']!;
                  return performance_breakdown_screen
                      .PerformanceBreakdownScreen(userId: userId);
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
          GoRoute(
            path: 'hub-stats/:hubId',
            name: 'hubStats',
            builder: (context, state) => LazyRouteLoader(
                loader: hub_stats_screen.loadLibrary(),
                builder: () {
                  final playerId = state.pathParameters['uid']!;
                  final hubId = state.pathParameters['hubId']!;
                  return hub_stats_screen.HubStatsScreen(
                      hubId: hubId, playerId: playerId);
                }),
          ),
        ],
      ),
    ],
  );
});
