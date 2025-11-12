import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/widgets/error_widget.dart';
import 'package:kickabout/widgets/loading_widget.dart';
import 'package:kickabout/widgets/player_avatar.dart';
import 'package:kickabout/widgets/game_photos_gallery.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/data/repositories.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/models/hub_role.dart';
import 'package:kickabout/data/hubs_repository.dart';
import 'package:kickabout/core/constants.dart';
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
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final signupsRepo = ref.watch(signupsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

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
          final hubsRepo = ref.watch(hubsRepositoryProvider);

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
                              '${signups.length} נרשמו',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                      // Sign up / Remove signup button
                      if (!isCreator)
                        ElevatedButton.icon(
                          onPressed: () => _toggleSignup(context, game, isSignedUp),
                          icon: Icon(isSignedUp ? Icons.person_remove : Icons.person_add),
                          label: Text(isSignedUp ? 'מסיר הרשמה' : 'נרשם'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: isSignedUp
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: isSignedUp
                                ? Theme.of(context).colorScheme.onError
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      if (!isCreator) const SizedBox(height: 12),

                      // Hub manager-only buttons (Team Maker)
                      FutureBuilder<bool>(
                        future: _checkIfHubManager(hubsRepo, game.hubId, currentUserId),
                        builder: (context, managerSnapshot) {
                          final isHubManager = managerSnapshot.data ?? false;
                          if (isHubManager && (game.status == GameStatus.teamSelection ||
                              game.status == GameStatus.teamsFormed)) {
                            return ElevatedButton.icon(
                              onPressed: () => context.push('/games/${widget.gameId}/team-maker'),
                              icon: const Icon(Icons.group),
                              label: const Text('בחר קבוצות'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // Creator-only buttons
                      if (isCreator) ...[
                        const SizedBox(height: 12),

                        if (game.status == GameStatus.teamsFormed)
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
                        if (game.status == GameStatus.teamsFormed) const SizedBox(height: 12),

                        if (game.status == GameStatus.inProgress)
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
                        if (game.status == GameStatus.inProgress) const SizedBox(height: 12),

                        if (game.status == GameStatus.inProgress ||
                            game.status == GameStatus.completed)
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
                        if (game.status == GameStatus.inProgress ||
                            game.status == GameStatus.completed)
                          const SizedBox(height: 12),
                      ],
                    ],
                    const SizedBox(height: 24),

                    // Game Photos Gallery
                    GamePhotosGallery(
                      photoUrls: game.photoUrls,
                      canAddPhotos: currentUserId != null,
                      onAddPhoto: () => _addPhoto(context, game),
                      canDelete: isCreator,
                      onDeletePhoto: (photoUrl) => _deletePhoto(context, photoUrl),
                    ),
                    if (game.photoUrls.isNotEmpty) const SizedBox(height: 24),

                    // Signups section
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

                    if (signups.isEmpty)
                      const AppEmptyWidget(
                        message: 'אין נרשמים',
                        icon: Icons.people_outline,
                      ),
                  ],
                ),
              );
            },
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
            leading: CircularProgressIndicator(),
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
          child: CircularProgressIndicator(),
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
