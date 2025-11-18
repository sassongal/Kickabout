import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/error_widget.dart';
import 'package:kickadoor/widgets/loading_widget.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/widgets/game_photos_gallery.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/services/analytics_service.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:image_picker/image_picker.dart';

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
          
          // Get user role for this hub
          final roleAsync = ref.watch(hubRoleProvider(game.hubId));

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
                  final maxPlayers = game.teamCount * 3; // 3 players per team minimum
                  final isGameFull = confirmedSignups.length >= maxPlayers;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Game info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(game.gameDate),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (game.location != null && game.location!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(game.location!),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(_getStatusText(game.status)),
                                      backgroundColor: _getStatusColor(game.status, context)
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
                                if (game.durationInMinutes != null || game.gameEndCondition != null) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'חוקי המשחק',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'משך: ${game.durationInMinutes} דקות',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (game.gameEndCondition != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'תנאי סיום: ${game.gameEndCondition}',
                                            style: Theme.of(context).textTheme.bodySmall,
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
    bool isConfirmed,
  ) {
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
          trailing: isConfirmed
              ? const Chip(
                  label: Text('מאושר'),
                  backgroundColor: Colors.green,
                )
              : const Chip(
                  label: Text('ממתין'),
                  backgroundColor: Colors.orange,
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
        await signupsRepo.setSignup(widget.gameId, currentUserId, SignupStatus.confirmed);
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

  Future<void> _addPhoto(BuildContext context, Game game) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!context.mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );

      try {
        final storageService = ref.read(storageServiceProvider);
        final gamesRepo = ref.read(gamesRepositoryProvider);

        // Upload photo
        final photoUrl = await storageService.uploadGamePhoto(widget.gameId, image);

        // Add to game
        await gamesRepo.addGamePhoto(widget.gameId, photoUrl);

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          SnackbarHelper.showSuccess(context, 'התמונה הועלתה בהצלחה!');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          SnackbarHelper.showErrorFromException(context, e);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _deletePhoto(
    BuildContext context,
    String photoUrl,
  ) async {
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.removeGamePhoto(widget.gameId, photoUrl);

      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'התמונה נמחקה');
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
      case GameStatus.teamSelection:
        return 'בחירת קבוצות';
      case GameStatus.teamsFormed:
        return 'קבוצות נוצרו';
      case GameStatus.inProgress:
        return 'במהלך';
      case GameStatus.completed:
        return 'הושלם';
      case GameStatus.statsInput:
        return 'הזנת סטטיסטיקות';
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

      case GameStatus.teamsFormed:
        return _buildConfirmedState(
          context,
          game,
          role,
          isCreator,
          confirmedSignups,
          pendingSignups,
          usersRepo,
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
          // Sign up button (if not creator and not signed up and not full)
          if (!isCreator && !isSignedUp && !isGameFull)
            ElevatedButton.icon(
              onPressed: () => _toggleSignup(context, game, isSignedUp),
              icon: const Icon(Icons.person_add),
              label: const Text('נרשם'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          if (!isCreator && isSignedUp)
            ElevatedButton.icon(
              onPressed: () => _toggleSignup(context, game, isSignedUp),
              icon: const Icon(Icons.person_remove),
              label: const Text('מסיר הרשמה'),
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
                  Text('המשחק מלא'),
                ],
              ),
            ),
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

  /// Build content for confirmed/teamsFormed state
  Widget _buildConfirmedState(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
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
            // If teams not created yet
            if (game.teams.isEmpty)
              ElevatedButton.icon(
                onPressed: () => context.push('/games/${widget.gameId}/team-maker'),
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
    List<GameSignup> confirmedSignups,
    UsersRepository usersRepo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Final score widget (prominent)
        if (game.teamAScore != null && game.teamBScore != null)
          _FinalScoreWidget(game: game),
        const SizedBox(height: 24),

        // Display teams
        if (game.teams.isNotEmpty) ...[
          _TeamsDisplayWidget(teams: game.teams, usersRepo: usersRepo),
          const SizedBox(height: 24),
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
    UsersRepository usersRepo,
  ) {
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
                                ? ClipOval(
                                    child: Image.network(
                                      user.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person,
                                        size: 12,
                                        color: teamColor,
                                      ),
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

/// Widget to display final score prominently
class _FinalScoreWidget extends StatelessWidget {
  final Game game;

  const _FinalScoreWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    final teamAScore = game.teamAScore ?? 0;
    final teamBScore = game.teamBScore ?? 0;
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamAScore',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamBScore',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
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

/// Helper function to check if user is hub manager
Future<bool> _checkIfHubManager(HubsRepository hubsRepo, String hubId, String? userId) async {
  if (userId == null) return false;
  try {
    final hub = await hubsRepo.getHub(hubId);
    if (hub == null) return false;
    final permissions = HubPermissions(hub: hub, userId: userId);
    return permissions.isManager();
  } catch (e) {
    return false;
  }
}
