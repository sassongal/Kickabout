import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/error_widget.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/models/targeting_criteria.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/widgets/optimized_image.dart';
import 'package:kattrick/services/weather_service.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/logic/session_logic.dart';
import 'package:kattrick/widgets/loading_widget.dart';
import 'package:kattrick/services/game_management_service.dart';
import 'package:kattrick/widgets/dialogs/edit_game_result_dialog.dart';

/// Game detail screen
class GameDetailScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    // Use ref.read for repositories - they don't change, so no need to watch
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final signupsRepo = ref.read(signupsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    final gameStream = gamesRepo.watchGame(widget.gameId);
    final signupsStream = signupsRepo.watchSignups(widget.gameId);

    return AppScaffold(
      title: 'פרטי משחק',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingWidget(message: 'טוען משחק...');
          }

          if (gameSnapshot.hasError) {
            return AppErrorWidget(
              message: 'שגיאה בטעינת המשחק',
              onRetry: () {
                // Stream will automatically retry
              },
            );
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const AppEmptyWidget(
              message: 'משחק לא נמצא',
              icon: Icons.sports_soccer,
            );
          }

          final isCreator = currentUserId == game.createdBy;
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

          // ✅ Show attendance monitoring button for organizers
          final showAttendanceButton = isCreator &&
              game.status == GameStatus.teamSelection &&
              game.enableAttendanceReminder;

          // Get user role for this hub (or determine admin if public)
          final AsyncValue<UserRole> roleAsync;
          if (game.hubId != null) {
            roleAsync = ref.watch(hubRoleProvider(game.hubId!));
          } else {
            // For public games, creator is admin, others are members
            roleAsync = AsyncValue.data(
              isCreator ? UserRole.admin : UserRole.member,
            );
          }

          return roleAsync.when(
            data: (role) {
              return StreamBuilder<List<GameSignup>>(
                stream: signupsStream,
                builder: (context, signupsSnapshot) {
                  final signups = signupsSnapshot.data ?? [];
                  final confirmedSignups = signups
                      .where((s) => s.status == SignupStatus.confirmed)
                      .toList();
                  final pendingSignups = signups
                      .where((s) => s.status == SignupStatus.pending)
                      .toList();

                  final isSignedUp = currentUserId != null &&
                      signups.any((s) => s.playerId == currentUserId);

                  // Check if game is full
                  final maxPlayers =
                      game.teamCount * 3; // 3 players per team minimum
                  final isGameFull = confirmedSignups.length >= maxPlayers;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ✅ Attendance Monitoring Button (for organizers)
                        if (showAttendanceButton)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .push('/games/${widget.gameId}/attendance');
                              },
                              icon: const Icon(Icons.people),
                              label: const Text('ניטור הגעה'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        // Game info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(game.gameDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                // Load and display venue if venueId exists, otherwise show text location
                                if (game.venueId != null &&
                                    game.venueId!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  StreamBuilder<Venue?>(
                                    stream: ref
                                        .read(venuesRepositoryProvider)
                                        .watchVenue(game.venueId!),
                                    builder: (context, venueSnapshot) {
                                      final venue = venueSnapshot.data;
                                      final locationText = venue?.name ??
                                          game.location ??
                                          'מיקום לא צוין';

                                      if (locationText.isEmpty ||
                                          locationText == 'מיקום לא צוין') {
                                        return const SizedBox.shrink();
                                      }

                                      return Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  locationText,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                if (venue?.address != null &&
                                                    venue!.address !=
                                                        locationText)
                                                  Text(
                                                    venue.address!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6),
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ] else if (game.location?.isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(game.location ?? ''),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(_getStatusText(game.status)),
                                      backgroundColor:
                                          _getStatusColor(game.status, context)
                                              .withValues(alpha: 0.1),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${game.teamCount} קבוצות'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${signups.length} נרשמו${isGameFull ? ' (מלא)' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                // Game rules (if defined)
                                if (game.durationInMinutes != null ||
                                    game.gameEndCondition != null) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'חוקי המשחק',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (game.durationInMinutes != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'משך: ${game.durationInMinutes} דקות',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (game.gameEndCondition != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'תנאי סיום: ${game.gameEndCondition}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Weather for game date and location
                        if (game.locationPoint != null)
                          _buildGameWeatherWidget(game),
                        const SizedBox(height: 24),

                        // State-aware content based on game status
                        _buildStateAwareContent(
                          context,
                          game,
                          role,
                          isCreator,
                          isSignedUp,
                          isGameFull,
                          confirmedSignups,
                          pendingSignups,
                          usersRepo,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoadingWidget(message: 'בודק הרשאות...'),
            error: (error, stack) => AppErrorWidget(
              message: 'שגיאה בבדיקת הרשאות: $error',
              onRetry: () {
                // Stream will automatically retry
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignupTile(
    BuildContext context,
    GameSignup signup,
    UsersRepository usersRepo,
    bool isConfirmed, {
    bool isAdmin = false,
  }) {
    return FutureBuilder<User?>(
      future: usersRepo.getUser(signup.playerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const ListTile(
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('טוען...'),
          );
        }
        return ListTile(
          leading: PlayerAvatar(
            user: user,
            radius: 20,
            clickable: true,
          ),
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConfirmed)
                const Chip(
                  label: Text('מאושר'),
                  backgroundColor: Colors.green,
                )
              else
                const Chip(
                  label: Text('ממתין'),
                  backgroundColor: Colors.orange,
                ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: () => _rejectPlayer(signup.playerId),
                  tooltip: 'הסר שחקן',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleSignup(
    BuildContext context,
    Game game,
    bool isSignedUp,
  ) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final signupsRepo = ref.read(signupsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    try {
      if (isSignedUp) {
        await signupsRepo.removeSignup(widget.gameId, currentUserId);
        // Decrement participation counter
        await usersRepo.updateUser(currentUserId, {
          'totalParticipations': FieldValue.increment(-1),
        });
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'הסרת הרשמה');
        }
      } else {
        await signupsRepo.setSignup(
            widget.gameId, currentUserId, SignupStatus.confirmed);
        // Increment participation counter
        await usersRepo.updateUser(currentUserId, {
          'totalParticipations': FieldValue.increment(1),
        });

        // Log analytics
        try {
          final analytics = AnalyticsService();
          await analytics.logGameJoined(gameId: widget.gameId);
        } catch (e) {
          debugPrint('Failed to log analytics: $e');
        }

        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'נרשמת למשחק');
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _startGame(BuildContext context, Game game) async {
    if (game.createdBy != ref.read(currentUserIdProvider)) {
      SnackbarHelper.showWarning(context, 'רק יוצר המשחק יכול להתחיל');
      return;
    }

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.inProgress);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק התחיל');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _endGame(BuildContext context, Game game) async {
    if (game.createdBy != ref.read(currentUserIdProvider)) {
      SnackbarHelper.showWarning(context, 'רק יוצר המשחק יכול לסיים');
      return;
    }

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.completed);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק הסתיים');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Color _getStatusColor(GameStatus status, BuildContext context) {
    switch (status) {
      case GameStatus.completed:
        return Colors.green;
      case GameStatus.inProgress:
        return Colors.blue;
      case GameStatus.teamsFormed:
        return Colors.orange;
      case GameStatus.statsInput:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.draft:
        return 'טיוטה';
      case GameStatus.scheduled:
        return 'מתוכנן';
      case GameStatus.recruiting:
        return 'גיוס שחקנים';
      case GameStatus.teamSelection:
        return 'בחירת קבוצות';
      case GameStatus.teamsFormed:
        return 'קבוצות נוצרו';
      case GameStatus.fullyBooked:
        return 'מלא';
      case GameStatus.inProgress:
        return 'במהלך';
      case GameStatus.completed:
        return 'הושלם';
      case GameStatus.statsInput:
        return 'הזנת סטטיסטיקות';
      case GameStatus.cancelled:
        return 'בוטל';
      case GameStatus.archivedNotPlayed:
        return 'ארכיון - לא שוחק';
    }
  }

  /// Build state-aware content based on game status
  Widget _buildStateAwareContent(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    bool isSignedUp,
    bool isGameFull,
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
    UsersRepository usersRepo,
  ) {
    switch (game.status) {
      // New statuses - default to pending state behavior
      case GameStatus.draft:
      case GameStatus.scheduled:
      case GameStatus.recruiting:
      case GameStatus.teamSelection:
        return _buildPendingState(
          context,
          game,
          role,
          isCreator,
          isSignedUp,
          isGameFull,
          confirmedSignups,
          pendingSignups,
          usersRepo,
        );

      case GameStatus.fullyBooked:
      case GameStatus.teamsFormed:
        final maxPlayers = game.teamCount * 3; // 3 players per team minimum
        return _buildConfirmedState(
          context,
          game,
          role,
          isCreator,
          confirmedSignups,
          pendingSignups,
          usersRepo,
          isGameFull,
          maxPlayers,
        );

      case GameStatus.inProgress:
        return _buildInProgressState(
          context,
          game,
          role,
          isCreator,
          confirmedSignups,
          usersRepo,
        );

      case GameStatus.completed:
        return _buildCompletedState(
          context,
          game,
          role,
          confirmedSignups,
          usersRepo,
        );

      case GameStatus.statsInput:
        return _buildStatsInputState(
          context,
          game,
          role,
          isCreator,
          confirmedSignups,
          usersRepo,
        );

      case GameStatus.cancelled:
      case GameStatus.archivedNotPlayed:
        return _buildCompletedState(
          context,
          game,
          role,
          confirmedSignups,
          usersRepo,
        );
    }
  }

  /// Build content for pending/teamSelection state
  Widget _buildPendingState(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    bool isSignedUp,
    bool isGameFull,
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
    UsersRepository usersRepo,
  ) {
    final currentUserId = ref.read(currentUserIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Targeting Mismatch Warning (for joiners)
        if (!isCreator &&
            !isSignedUp &&
            game.targetingCriteria != null &&
            currentUserId != null)
          FutureBuilder<User?>(
            future: usersRepo.getUser(currentUserId),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) return const SizedBox.shrink();

              final age = DateTime.now().year - user.birthDate.year;
              final criteria = game.targetingCriteria!;
              final isAgeMatch =
                  (criteria.minAge == null || age >= criteria.minAge!) &&
                      (criteria.maxAge == null || age <= criteria.maxAge!);

              // TODO: Add gender to User model to enable this check
              final isGenderMatch = true;
              /* criteria.gender == PlayerGender.any ||
                  (user.gender == 'male' &&
                      criteria.gender == PlayerGender.male) ||
                  (user.gender == 'female' &&
                      criteria.gender == PlayerGender.female); */

              if (!isAgeMatch || !isGenderMatch) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'שים לב: המשחק מיועד לגילאים ${criteria.minAge}-${criteria.maxAge} ${criteria.gender == PlayerGender.male ? '(גברים)' : criteria.gender == PlayerGender.female ? '(נשים)' : ''}',
                          style: const TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

        // Action buttons
        if (currentUserId != null) ...[
          // Chat button
          OutlinedButton.icon(
            onPressed: () => context.push('/games/${widget.gameId}/chat'),
            icon: const Icon(Icons.chat),
            label: const Text('צ\'אט משחק'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Sign up button logic
          if (!isCreator && !isSignedUp && !isGameFull)
            ElevatedButton.icon(
              onPressed: () => _toggleSignup(context, game, isSignedUp),
              icon: const Icon(Icons.person_add),
              label: Text(game.requiresApproval ? 'בקש להצטרף' : 'הירשם למשחק'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),

          // Pending Approval State
          if (!isCreator &&
              isSignedUp &&
              pendingSignups.any((s) => s.playerId == currentUserId))
            ElevatedButton.icon(
              onPressed: null, // Disabled
              icon: const Icon(Icons.hourglass_empty),
              label: const Text('בקשה נשלחה - ממתין לאישור'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                disabledForegroundColor: Colors.grey,
              ),
            ),

          if (!isCreator &&
              isSignedUp &&
              confirmedSignups.any((s) => s.playerId == currentUserId))
            ElevatedButton.icon(
              onPressed: () => _toggleSignup(context, game, isSignedUp),
              icon: const Icon(Icons.person_remove),
              label: const Text('בטל הרשמה'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),

          if (isGameFull && !isSignedUp)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('המשחק מלא - ניתן להירשם לרשימת המתנה'),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],

        // Pending Approvals Section (Admin Only)
        if ((isCreator || role == UserRole.admin) &&
            pendingSignups.isNotEmpty) ...[
          Card(
            color: Colors.orange.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'בקשות ממתינות (${pendingSignups.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...pendingSignups.map((signup) => _buildPendingApprovalTile(
                        context,
                        signup,
                        usersRepo,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Signups section
        _buildSignupsSection(
          context,
          confirmedSignups,
          [], // Don't show pending in regular list if admin (shown above)
          usersRepo,
          isAdmin: isCreator || role == UserRole.admin,
        ),
      ],
    );
  }

  /// Build content for confirmed/teamsFormed state
  Widget _buildConfirmedState(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
    UsersRepository usersRepo,
    bool isGameFull,
    int maxPlayers,
  ) {
    final currentUserId = ref.read(currentUserIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action buttons
        if (currentUserId != null) ...[
          // Chat button
          OutlinedButton.icon(
            onPressed: () => context.push('/games/${widget.gameId}/chat'),
            icon: const Icon(Icons.chat),
            label: const Text('צ\'אט משחק'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Admin buttons
          if (role == UserRole.admin) ...[
            // Find Missing Players button (if game is private and not full)
            if (game.visibility == GameVisibility.private && !isGameFull)
              ElevatedButton.icon(
                onPressed: () => _findMissingPlayers(
                    context, game, confirmedSignups.length, maxPlayers),
                icon: const Icon(Icons.person_add),
                label: const Text('מצא שחקנים חסרים'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            if (game.visibility == GameVisibility.private && !isGameFull)
              const SizedBox(height: 12),

            // If teams not created yet
            if (game.teams.isEmpty)
              ElevatedButton.icon(
                onPressed: () =>
                    context.push('/games/${widget.gameId}/team-maker'),
                icon: const Icon(Icons.group),
                label: const Text('צור קבוצות'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            // If teams created, show stats logger button
            if (game.teams.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => context.push('/games/${widget.gameId}/stats'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('תעד תוצאה וסטטיסטיקות'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

            // Start game button (creator only)
            if (isCreator && game.teams.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _startGame(context, game),
                icon: const Icon(Icons.play_arrow),
                label: const Text('התחל משחק'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],

        // Display teams if created
        if (game.teams.isNotEmpty) ...[
          _TeamsDisplayWidget(teams: game.teams, usersRepo: usersRepo),
          const SizedBox(height: 24),
        ],

        // Signups section
        _buildSignupsSection(
          context,
          confirmedSignups,
          pendingSignups,
          usersRepo,
        ),
      ],
    );
  }

  /// Build content for inProgress state
  Widget _buildInProgressState(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    List<GameSignup> confirmedSignups,
    UsersRepository usersRepo,
  ) {
    final currentUserId = ref.read(currentUserIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action buttons
        if (currentUserId != null) ...[
          // Chat button
          OutlinedButton.icon(
            onPressed: () => context.push('/games/${widget.gameId}/chat'),
            icon: const Icon(Icons.chat),
            label: const Text('צ\'אט משחק'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Admin buttons
          if (role == UserRole.admin) ...[
            ElevatedButton.icon(
              onPressed: () => context.push('/games/${widget.gameId}/stats'),
              icon: const Icon(Icons.bar_chart),
              label: const Text('רישום סטטיסטיקות'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Creator-only: End game button
          if (isCreator)
            ElevatedButton.icon(
              onPressed: () => _endGame(context, game),
              icon: const Icon(Icons.stop),
              label: const Text('סיים משחק'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 24),
        ],

        // Display teams
        if (game.teams.isNotEmpty) ...[
          _TeamsDisplayWidget(teams: game.teams, usersRepo: usersRepo),
          const SizedBox(height: 24),
        ],

        // Signups section
        _buildSignupsSection(
          context,
          confirmedSignups,
          [],
          usersRepo,
        ),
      ],
    );
  }

  /// Build content for completed state
  Widget _buildCompletedState(
    BuildContext context,
    Game game,
    UserRole role,
    List<GameSignup> confirmedSignups,
    UsersRepository usersRepo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Final score widget (prominent) - Show Session Summary if matches exist, otherwise legacy score
        if (game.session.matches.isNotEmpty ||
            game.session.aggregateWins.isNotEmpty)
          _SessionSummaryWidget(game: game)
        else if (game.session.legacyTeamAScore != null &&
            game.session.legacyTeamBScore != null)
          _FinalScoreWidget(game: game),
        const SizedBox(height: 24),

        // Display teams
        if (game.teams.isNotEmpty) ...[
          _TeamsDisplayWidget(teams: game.teams, usersRepo: usersRepo),
          const SizedBox(height: 24),
        ],

        // Manager-only: Edit Result button
        if (role == UserRole.admin) ...[
          OutlinedButton.icon(
            onPressed: () => _showEditResultDialog(context, game, usersRepo),
            icon: const Icon(Icons.edit),
            label: const Text('ערוך תוצאה'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // View full statistics button
        ElevatedButton.icon(
          onPressed: () => context.push('/games/${widget.gameId}/stats'),
          icon: const Icon(Icons.bar_chart),
          label: const Text('צפה בסטטיסטיקות המלאות'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Signups section
        _buildSignupsSection(
          context,
          confirmedSignups,
          [],
          usersRepo,
        ),
      ],
    );
  }

  /// Build content for statsInput state
  Widget _buildStatsInputState(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    List<GameSignup> confirmedSignups,
    UsersRepository usersRepo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Admin buttons
        if (role == UserRole.admin) ...[
          ElevatedButton.icon(
            onPressed: () => context.push('/games/${widget.gameId}/stats'),
            icon: const Icon(Icons.bar_chart),
            label: const Text('רישום סטטיסטיקות'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Display teams
        if (game.teams.isNotEmpty) ...[
          _TeamsDisplayWidget(teams: game.teams, usersRepo: usersRepo),
          const SizedBox(height: 24),
        ],

        // Signups section
        _buildSignupsSection(
          context,
          confirmedSignups,
          [],
          usersRepo,
        ),
      ],
    );
  }

  /// Build signups section
  Widget _buildSignupsSection(
    BuildContext context,
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
    UsersRepository usersRepo, {
    bool isAdmin = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'נרשמים',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Confirmed signups
        if (confirmedSignups.isNotEmpty) ...[
          Text(
            'מאושרים (${confirmedSignups.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...confirmedSignups.map((signup) => _buildSignupTile(
                context,
                signup,
                usersRepo,
                true,
                isAdmin: isAdmin,
              )),
          const SizedBox(height: 16),
        ],

        // Pending signups
        if (pendingSignups.isNotEmpty) ...[
          Text(
            'ממתינים (${pendingSignups.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...pendingSignups.map((signup) => _buildSignupTile(
                context,
                signup,
                usersRepo,
                false,
                isAdmin: isAdmin,
              )),
        ],

        if (confirmedSignups.isEmpty && pendingSignups.isEmpty)
          const AppEmptyWidget(
            message: 'אין נרשמים',
            icon: Icons.people_outline,
          ),
      ],
    );
  }

  Widget _buildPendingApprovalTile(
    BuildContext context,
    GameSignup signup,
    UsersRepository usersRepo,
  ) {
    return FutureBuilder<User?>(
      future: usersRepo.getUser(signup.playerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: PlayerAvatar(user: user, radius: 20),
            title: Text(user.name),
            subtitle: Text(
                'ביקש להצטרף • ${DateFormat('HH:mm dd/MM').format(signup.signedUpAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _approvePlayer(signup.playerId),
                  tooltip: 'אשר',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _rejectPlayer(signup.playerId),
                  tooltip: 'דחה',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _approvePlayer(String playerId) async {
    try {
      final service = GameManagementService();
      await service.approvePlayer(
        gameId: widget.gameId,
        userId: playerId,
      );
      if (mounted) SnackbarHelper.showSuccess(context, 'שחקן אושר בהצלחה');
    } catch (e) {
      if (mounted) SnackbarHelper.showErrorFromException(context, e);
    }
  }

  Future<void> _rejectPlayer(String playerId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('דחיית בקשה'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'סיבת הדחייה (חובה)',
            hintText: 'לדוגמה: המשחק מלא, לא מתאים לרמה...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('דחה בקשה'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = GameManagementService();
        await service.kickPlayer(
          gameId: widget.gameId,
          userId: playerId,
          reason: reasonController.text.trim(),
        );
        if (mounted) SnackbarHelper.showSuccess(context, 'בקשה נדחתה');
      } catch (e) {
        if (mounted) SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  /// Find missing players - change game to recruiting and post to feed
  Future<void> _findMissingPlayers(
    BuildContext context,
    Game game,
    int currentPlayers,
    int maxPlayers,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מצא שחקנים חסרים'),
        content: Text(
          'המשחק יהפוך ל-"מגייס שחקנים" ויוצג בפיד האזורי.\n'
          'נדרשים ${maxPlayers - currentPlayers} שחקנים נוספים.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('אישור'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final feedRepo = ref.read(feedRepositoryProvider);

      // Update game visibility to recruiting
      await gamesRepo.updateGame(widget.gameId, {
        'visibility': GameVisibility.recruiting.toFirestore(),
      });

      // Create feed post only if game belongs to a hub
      if (game.hubId != null) {
        // Get hub name
        final hub = await hubsRepo.getHub(game.hubId!);
        final hubName = hub?.name ?? 'Hub';

        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          final post = FeedPost(
            postId: '', // Will be generated by repository
            hubId: game.hubId!,
            authorId: currentUserId,
            type: 'game_recruitment',
            content:
                'Hub $hubName צריך ${maxPlayers - currentPlayers} שחקנים למשחק ב-${DateFormat('dd/MM/yyyy HH:mm', 'he').format(game.gameDate)}',
            createdAt: DateTime.now(),
            gameId: widget.gameId,
            region: game.region ?? hub?.region,
          );

          await feedRepo.createPost(post);
        }
      }

      if (context.mounted) {
        SnackbarHelper.showSuccess(
          context,
          game.hubId != null
              ? 'המשחק הוצג בפיד האזורי למציאת שחקנים'
              : 'המשחק פתוח כעת לגיוס שחקנים',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  /// Build weather widget for game date and location
  Widget _buildGameWeatherWidget(Game game) {
    // If no locationPoint but we have venueId, load venue to get location
    if (game.locationPoint == null &&
        game.venueId != null &&
        game.venueId!.isNotEmpty) {
      return StreamBuilder<Venue?>(
        stream: ref.read(venuesRepositoryProvider).watchVenue(game.venueId!),
        builder: (context, venueSnapshot) {
          final venue = venueSnapshot.data;
          if (venue?.location == null) {
            return const SizedBox.shrink();
          }
          // Use venue location for weather
          final weatherService = ref.read(weatherServiceProvider);
          final weatherFuture = weatherService.getWeatherForDate(
            latitude: venue!.location.latitude,
            longitude: venue.location.longitude,
            date: game.gameDate,
          );

          return FutureBuilder<WeatherData?>(
            future: weatherFuture,
            builder: (context, weatherSnapshot) {
              if (weatherSnapshot.connectionState == ConnectionState.waiting) {
                return FuturisticCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'טוען תנאי מזג אוויר...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final weather = weatherSnapshot.data;
              if (weather == null) return const SizedBox.shrink();

              return FuturisticCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'תנאי מזג אוויר למשחק',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weather.summary,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${weather.temperature}°C',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    final locationPoint = game.locationPoint;
    if (locationPoint == null) return const SizedBox.shrink();

    final weatherService = ref.read(weatherServiceProvider);
    final weatherFuture = weatherService.getWeatherForDate(
      latitude: locationPoint.latitude,
      longitude: locationPoint.longitude,
      date: game.gameDate,
    );

    return FutureBuilder<WeatherData?>(
      future: weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FuturisticCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'טוען תנאי מזג אוויר...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final weather = snapshot.data;
        if (weather == null) return const SizedBox.shrink();

        return FuturisticCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.wb_sunny,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'תנאי מזג אוויר למשחק',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.summary,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${weather.temperature}°C',
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows the edit result dialog for managers
  Future<void> _showEditResultDialog(
    BuildContext context,
    Game game,
    UsersRepository usersRepo,
  ) async {
    try {
      // Fetch all players involved in the game (from both teams)
      final allPlayerIds =
          game.teams.expand((t) => t.playerIds).toSet().toList();
      final players = await usersRepo.getUsers(allPlayerIds);

      if (!mounted) return;

      final service = GameManagementService();
      // Capture ScaffoldMessenger before async gap
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => EditGameResultDialog(
          game: game,
          players: players,
          onSave: ({
            required int teamAScore,
            required int teamBScore,
            required Map<String, int> goalScorerIds,
            Map<String, int>? assistPlayerIds,
            String? mvpPlayerId,
          }) async {
            await service.editGameResult(
              gameId: game.gameId,
              newTeamAScore: teamAScore,
              newTeamBScore: teamBScore,
              newGoalScorerIds: goalScorerIds,
              newAssistPlayerIds: assistPlayerIds,
              newMvpPlayerId: mvpPlayerId,
            );
          },
        ),
      );

      // If edit was successful, show success message
      if (result == true && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('התוצאה עודכנה בהצלחה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בעדכון התוצאה: $e')),
        );
      }
    }
  }
}

/// Widget to display teams in two columns
class _TeamsDisplayWidget extends StatelessWidget {
  final List<Team> teams;
  final UsersRepository usersRepo;

  const _TeamsDisplayWidget({
    required this.teams,
    required this.usersRepo,
  });

  Color _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'black':
        return Colors.black;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'הקבוצות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: teams.take(2).map((team) {
                final index = teams.indexOf(team);
                final teamColor = _getColorFromString(team.color);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == 0 ? 8 : 0,
                      left: index == 1 ? 8 : 0,
                    ),
                    child: _buildTeamColumn(
                      context,
                      team,
                      teamColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(BuildContext context, Team team, Color teamColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: teamColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: teamColor,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${team.playerIds.length})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<List<User>>(
              future: usersRepo.getUsers(team.playerIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(
                    child: Text('אין שחקנים'),
                  );
                }

                return Column(
                  children: users.map((user) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: teamColor.withValues(alpha: 0.2),
                            child: user.photoUrl != null
                                ? OptimizedImage(
                                    imageUrl: user.photoUrl ?? '',
                                    fit: BoxFit.cover,
                                    width: 24,
                                    height: 24,
                                    borderRadius: BorderRadius.circular(12),
                                    errorWidget: Icon(
                                      Icons.person,
                                      size: 12,
                                      color: teamColor,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 12,
                                    color: teamColor,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display session summary (for multi-match games)
class _SessionSummaryWidget extends StatelessWidget {
  final Game game;

  const _SessionSummaryWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    final isSessionMode = SessionLogic.isSessionMode(game);
    if (!isSessionMode) {
      return const SizedBox.shrink();
    }

    final teamStats = SessionLogic.getAllTeamStats(game);
    final seriesScore = SessionLogic.getSeriesScoreDisplay(game);
    final winner = SessionLogic.calculateSessionWinner(game);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'סיכום סשן',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              seriesScore,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            if (winner != null) ...[
              const SizedBox(height: 8),
              Text(
                'מנצח: ${winner.displayName}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            // Team stats table
            if (teamStats.isNotEmpty) ...[
              Text(
                'סטטיסטיקות קבוצות',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...teamStats.values.map((stats) {
                final team = game.teams.firstWhere(
                  (t) => (t.color ?? '') == stats.teamColor,
                  orElse: () => game.teams.first,
                );
                final colorValue = team.colorValue ?? 0xFF2196F3;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name.isNotEmpty
                                  ? team.name
                                  : stats.teamColor,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'ניצחונות: ${stats.wins} | תיקו: ${stats.draws} | הפסדים: ${stats.losses}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                            Text(
                              'שערים: ${stats.goalsFor} | הפרש: ${stats.goalDifference > 0 ? '+' : ''}${stats.goalDifference}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${stats.points} נק\'',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (game.session.matches.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'סה"כ ${game.session.matches.length} משחקים',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget to display final score prominently
class _FinalScoreWidget extends StatelessWidget {
  final Game game;

  const _FinalScoreWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    final teamAScore = game.session.legacyTeamAScore ?? 0;
    final teamBScore = game.session.legacyTeamBScore ?? 0;
    final teamAName = game.teams.isNotEmpty ? game.teams[0].name : 'קבוצה א\'';
    final teamBName = game.teams.length > 1 ? game.teams[1].name : 'קבוצה ב\'';

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'תוצאה סופית',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        teamAName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamAScore',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ':',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        teamBName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamBScore',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
