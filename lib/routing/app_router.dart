import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:kickadoor/routing/go_router_refresh_stream.dart';
import 'package:kickadoor/utils/performance_utils.dart';
import 'package:kickadoor/screens/auth/login_screen.dart';
import 'package:kickadoor/screens/auth/register_screen.dart';
import 'package:kickadoor/screens/hub/hub_list_screen.dart';
import 'package:kickadoor/screens/hub/create_hub_screen.dart';
import 'package:kickadoor/screens/hub/hub_detail_screen.dart';
import 'package:kickadoor/screens/hub/create_hub_event_screen.dart';
import 'package:kickadoor/screens/hub/edit_hub_event_screen.dart';
import 'package:kickadoor/screens/game/game_list_screen.dart';
import 'package:kickadoor/screens/game/create_game_screen.dart';
import 'package:kickadoor/screens/game/game_detail_screen.dart';
import 'package:kickadoor/screens/game/team_maker_screen.dart';
import 'package:kickadoor/screens/game/log_game_screen.dart';
// Removed: stats_logger_screen.dart, basic_rating_screen.dart - replaced by LogGameScreen
import 'package:kickadoor/screens/profile/player_profile_screen_futuristic.dart';
import 'package:kickadoor/screens/profile/edit_profile_screen.dart';
import 'package:kickadoor/screens/profile/privacy_settings_screen.dart';
import 'package:kickadoor/screens/location/discover_hubs_screen.dart';
import 'package:kickadoor/screens/location/map_screen.dart';
import 'package:kickadoor/screens/social/notifications_screen.dart';
import 'package:kickadoor/screens/social/post_detail_screen.dart';
import 'package:kickadoor/screens/social/following_screen.dart';
import 'package:kickadoor/screens/social/followers_screen.dart';
import 'package:kickadoor/screens/social/feed_screen.dart';
import 'package:kickadoor/screens/home_screen_futuristic_figma.dart';
import 'package:kickadoor/screens/game/game_chat_screen.dart';
import 'package:kickadoor/screens/social/messages_list_screen.dart';
import 'package:kickadoor/screens/social/private_chat_screen.dart';
import 'package:kickadoor/screens/gamification/leaderboard_screen.dart';
import 'package:kickadoor/screens/splash/splash_screen.dart';
import 'package:kickadoor/screens/players/players_list_screen.dart';
import 'package:kickadoor/screens/players/players_map_screen.dart';
import 'package:kickadoor/screens/hubs/hubs_board_screen.dart';
import 'package:kickadoor/screens/admin/generate_dummy_data_screen.dart';
import 'package:kickadoor/screens/hub/manage_roles_screen.dart';
import 'package:kickadoor/screens/hub/hub_settings_screen.dart';
import 'package:kickadoor/screens/hub/join_by_invite_screen.dart';
import 'package:kickadoor/screens/game/game_calendar_screen.dart';
import 'package:kickadoor/screens/social/create_post_screen.dart';
import 'package:kickadoor/screens/hub/scouting_screen.dart';
import 'package:kickadoor/screens/hub/hub_players_list_screen.dart';
import 'package:kickadoor/screens/hub/hub_rules_screen.dart';
import 'package:kickadoor/screens/hub/edit_game_screen.dart';
import 'package:kickadoor/screens/hub/hub_manage_requests_screen.dart';
import 'package:kickadoor/screens/venue/venue_search_screen.dart';
import 'package:kickadoor/screens/venue/create_manual_venue_screen.dart';
import 'package:kickadoor/screens/location/map_picker_screen.dart';
import 'package:kickadoor/screens/onboarding/onboarding_screen.dart';
import 'package:kickadoor/screens/game/log_past_game_screen.dart';
import 'package:kickadoor/screens/weather/weather_detail_screen.dart';
import 'package:kickadoor/screens/activity/community_activity_feed_screen.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth state stream provider
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
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

/// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);
  
  // Pre-load onboarding status to cache it before redirect runs
  ref.read(onboardingStatusProvider);

  return GoRouter(
    debugLogDiagnostics: PerformanceUtils.isDebugMode,
    initialLocation: '/auth', // Start with auth screen (splash can be added later if needed)
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    // Optimize navigation performance
    restorationScopeId: 'app_router',
    redirect: (context, state) {
      try {
        // Check if auth state is still loading - if so, allow auth/register screens
        if (authState.isLoading) {
          // If going to auth/register/splash, allow it (they will show loading state)
          if (state.matchedLocation == '/auth' || 
              state.matchedLocation == '/register' || 
              state.matchedLocation == '/splash') {
            return null;
          }
          // Otherwise, redirect to auth while loading
          return '/auth';
        }
        
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

        // Check if user is anonymous - if so, redirect to auth immediately
        if (isAuthenticated) {
          final authService = ref.read(authServiceProvider);
          if (authService.isAnonymous) {
            authService.signOut().then((_) {
              debugPrint('�� Router: Signed out anonymous user');
            }).catchError((e) {
              debugPrint('⚠️ Router: Error signing out anonymous user: $e');
            });
            return '/auth';
          }
        }

        // If not authenticated and not going to auth/onboarding/splash, redirect to auth
        if (!isAuthenticated && !isGoingToAuth && !isGoingToOnboarding && !isGoingToSplash) {
          return '/auth';
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
              return '/onboarding';
            }
          }
        }

        // If authenticated (non-anonymous) and going to auth, redirect to home
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
        path: '/discover',
        name: 'discoverHubs',
        builder: (context, state) => const DiscoverHubsScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/weather',
        name: 'weatherDetail',
        builder: (context, state) => const WeatherDetailScreen(),
      ),

      // Players Board
      GoRoute(
        path: '/players',
        name: 'playersBoard',
        builder: (context, state) => const PlayersListScreen(),
      ),
      
      // Players Map
      GoRoute(
        path: '/players/map',
        name: 'playersMap',
        builder: (context, state) => const PlayersMapScreen(),
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

      // Community Activity Feed
      GoRoute(
        path: '/activity',
        name: 'activityFeed',
        builder: (context, state) => const CommunityActivityFeedScreen(),
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

      // Venue Search
      GoRoute(
        path: '/venues/search',
        name: 'venueSearch',
        builder: (context, state) {
          final hubId = state.uri.queryParameters['hubId'];
          final selectMode = state.uri.queryParameters['selectMode'] == 'true' || 
                            state.uri.queryParameters['select'] == 'true'; // Support both for backward compatibility
          return VenueSearchScreen(
            hubId: hubId,
            selectMode: selectMode,
          );
        },
      ),
      
      // Create Manual Venue
      GoRoute(
        path: '/venues/create',
        name: 'createManualVenue',
        builder: (context, state) => const CreateManualVenueScreen(),
      ),
      
      // Map Picker
      GoRoute(
        path: '/map-picker',
        name: 'mapPicker',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialLocation = extra?['initialLocation'];
          return MapPickerScreen(initialLocation: initialLocation);
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

      // Feed route - requires hubId as query parameter
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) {
          final hubId = state.uri.queryParameters['hubId'];
          if (hubId == null || hubId.isEmpty) {
            // If no hubId, redirect to hubs list
            return const HubListScreen();
          }
          return FeedScreen(hubId: hubId);
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
              final hubId = state.pathParameters['id'];
              if (hubId == null || hubId.isEmpty) {
                // Redirect to hubs list if hubId is missing
                return const HubListScreen();
              }
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
                path: 'events/create',
                name: 'createHubEvent',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  // Hub will be loaded in the screen itself
                  return CreateHubEventScreen(
                    hubId: hubId,
                    hub: Hub(
                      hubId: hubId,
                      name: '',
                      createdBy: '',
                      createdAt: DateTime.now(),
                    ), // Temporary - will be loaded in screen
                  );
                },
              ),
              GoRoute(
                path: 'events/:eventId/edit',
                name: 'editHubEvent',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final eventId = state.pathParameters['eventId']!;
                  return EditHubEventScreen(hubId: hubId, eventId: eventId);
                },
              ),
              GoRoute(
                path: 'events/:eventId/log-game',
                name: 'logGame',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final eventId = state.pathParameters['eventId']!;
                  return LogGameScreen(hubId: hubId, eventId: eventId);
                },
              ),
              GoRoute(
                path: 'events/:eventId/team-maker',
                name: 'eventTeamMaker',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final eventId = state.pathParameters['eventId']!;
                  // Use eventId as gameId for TeamMakerScreen (it will handle events differently)
                  return TeamMakerScreen(gameId: eventId, isEvent: true, hubId: hubId);
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
              GoRoute(
                path: 'log-past-game',
                name: 'logPastGame',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return LogPastGameScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'rules',
                name: 'hubRules',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return HubRulesScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'requests',
                name: 'hubManageRequests',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  return HubManageRequestsScreen(hubId: hubId);
                },
              ),
              GoRoute(
                path: 'games/:gameId/edit',
                name: 'editGame',
                builder: (context, state) {
                  final hubId = state.pathParameters['id']!;
                  final gameId = state.pathParameters['gameId']!;
                  return EditGameScreen(hubId: hubId, gameId: gameId);
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
              // Removed: stats and basic-rating routes - replaced by LogGameScreen
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
          return PlayerProfileScreenFuturistic(playerId: playerId);
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
            path: 'privacy',
            name: 'privacySettings',
            builder: (context, state) {
              final userId = state.pathParameters['uid']!;
              return PrivacySettingsScreen(userId: userId);
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

