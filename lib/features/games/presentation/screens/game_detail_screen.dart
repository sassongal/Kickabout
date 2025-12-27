import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/error_widget.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/shared/infrastructure/analytics/analytics_service.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_role.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/services/weather_service.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/loading_widget.dart';
import 'package:kattrick/features/games/infrastructure/services/game_management_service.dart';
import 'package:kattrick/widgets/dialogs/edit_game_result_dialog.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/features/games/presentation/widgets/strategies/active_game_state.dart';
import 'package:kattrick/features/games/presentation/widgets/strategies/completed_game_state.dart';
import 'package:kattrick/features/games/presentation/widgets/strategies/pending_game_state.dart';

@immutable
class _TeamUsersRequest {
  final String gameId;
  final List<String> playerIds;

  _TeamUsersRequest({
    required this.gameId,
    required List<String> playerIds,
  }) : playerIds = List.unmodifiable(playerIds);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TeamUsersRequest &&
        other.gameId == gameId &&
        listEquals(other.playerIds, playerIds);
  }

  @override
  int get hashCode => Object.hash(gameId, Object.hashAll(playerIds));
}

final _teamUsersProvider = FutureProvider.autoDispose
    .family<Map<String, User>, _TeamUsersRequest>((ref, request) async {
  if (request.playerIds.isEmpty) {
    return {};
  }
  final usersRepo = ref.watch(usersRepositoryProvider);
  final users = await usersRepo.getUsers(request.playerIds);
  return {for (final user in users) user.uid: user};
});

/// Game detail screen
class GameDetailScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  static final DateFormat _gameDateFormat =
      DateFormat('dd/MM/yyyy HH:mm', 'he');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    // Use ref.read for repositories - they don't change, so no need to watch
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final signupsRepo = ref.read(signupsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    final gameStream = gamesRepo.watchGame(widget.gameId);
    final signupsStream = signupsRepo.watchSignups(widget.gameId);

    return AppScaffold(
      title: l10n.gameDetailsTitle,
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingWidget(message: l10n.gameLoadingMessage);
          }

          if (gameSnapshot.hasError) {
            return AppErrorWidget(
              message: l10n.gameLoadingError,
              onRetry: () {
                // Stream will automatically retry
              },
            );
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return AppEmptyWidget(
              message: l10n.gameNotFound,
              icon: Icons.sports_soccer,
            );
          }

          final isCreator = currentUserId == game.createdBy;

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
                  final teamUsersAsync = ref.watch(
                    _teamUsersProvider(_buildTeamUsersRequest(game)),
                  );

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              // ✅ Attendance Monitoring Button (for organizers)
                              if (showAttendanceButton)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      context.push(
                                          '/games/${widget.gameId}/attendance');
                                    },
                                    icon: const Icon(Icons.people),
                                    label: Text(l10n.attendanceMonitoring),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              // Game info card
                              Hero(
                                tag: 'game_card_${game.gameId}',
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _gameDateFormat.format(game.gameDate),
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
                                              final l10n =
                                                  AppLocalizations.of(
                                                      context)!;
                                              final venue =
                                                  venueSnapshot.data;
                                              final locationText =
                                                  venue?.name ??
                                                      game.location ??
                                                      l10n
                                                          .locationNotSpecified;

                                              if (locationText.isEmpty ||
                                                  locationText ==
                                                      l10n
                                                          .locationNotSpecified) {
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
                                                        .withValues(
                                                            alpha: 0.6),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          locationText,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                        if (venue?.address !=
                                                                null &&
                                                            venue!.address !=
                                                                locationText)
                                                          Text(
                                                            venue.address!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                          context)
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
                                                child:
                                                    Text(game.location ?? ''),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(_getStatusText(
                                                  game.status, l10n)),
                                              backgroundColor: _getStatusColor(
                                                      game.status, context)
                                                  .withValues(alpha: 0.1),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(l10n
                                                .teamCountLabel(game.teamCount)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          isGameFull
                                              ? l10n.signupsCountFull(
                                                  signups.length)
                                              : l10n.signupsCount(
                                                  signups.length),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        // Game rules (if defined)
                                        if (game.durationInMinutes != null ||
                                            game.gameEndCondition != null) ...[
                                          const SizedBox(height: 16),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.gameRulesTitle,
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
                                                  l10n.gameDurationLabel(
                                                      game.durationInMinutes!),
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
                                                    l10n.gameEndConditionLabel(
                                                        game.gameEndCondition!),
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
                              ),
                              const SizedBox(height: 16),

                              // Weather for game date and location
                              if (game.locationPoint != null)
                                _buildGameWeatherWidget(game),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        sliver: _buildStateAwareContent(
                          context,
                          game,
                          role,
                          isCreator,
                          currentUserId,
                          isSignedUp,
                          isGameFull,
                          confirmedSignups,
                          pendingSignups,
                          usersRepo,
                          teamUsersAsync,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => AppLoadingWidget(message: l10n.checkingPermissions),
            error: (error, stack) => AppErrorWidget(
              message: l10n.permissionCheckErrorDetails(error.toString()),
              onRetry: () {
                // Stream will automatically retry
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleSignup(
    BuildContext context,
    Game game,
    bool isSignedUp,
  ) async {
    final l10n = AppLocalizations.of(context)!;
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
          SnackbarHelper.showSuccess(context, l10n.signupRemovedSuccess);
        }
      } else {
        final signupService = ref.read(gameSignupServiceProvider);
        await signupService.setSignup(
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
          SnackbarHelper.showSuccess(context, l10n.signupSuccess);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _startGame(BuildContext context, Game game) async {
    final l10n = AppLocalizations.of(context)!;
    if (game.createdBy != ref.read(currentUserIdProvider)) {
      SnackbarHelper.showWarning(context, l10n.onlyCreatorCanStartGame);
      return;
    }

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.inProgress);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, l10n.gameStartedSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _endGame(BuildContext context, Game game) async {
    final l10n = AppLocalizations.of(context)!;
    if (game.createdBy != ref.read(currentUserIdProvider)) {
      SnackbarHelper.showWarning(context, l10n.onlyCreatorCanEndGame);
      return;
    }

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.completed);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, l10n.gameEndedSuccess);
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

  String _getStatusText(GameStatus status, AppLocalizations l10n) {
    switch (status) {
      case GameStatus.draft:
        return l10n.gameStatusDraft;
      case GameStatus.scheduled:
        return l10n.gameStatusScheduled;
      case GameStatus.recruiting:
        return l10n.gameStatusRecruiting;
      case GameStatus.teamSelection:
        return l10n.gameStatusTeamSelection;
      case GameStatus.teamsFormed:
        return l10n.gameStatusTeamsFormed;
      case GameStatus.fullyBooked:
        return l10n.gameStatusFull;
      case GameStatus.inProgress:
        return l10n.gameStatusInProgress;
      case GameStatus.completed:
        return l10n.gameStatusCompleted;
      case GameStatus.statsInput:
        return l10n.gameStatusStatsInput;
      case GameStatus.cancelled:
        return l10n.gameStatusCancelled;
      case GameStatus.archivedNotPlayed:
        return l10n.gameStatusArchivedNotPlayed;
    }
  }

  _TeamUsersRequest _buildTeamUsersRequest(Game game) {
    final uniqueIds = <String>{};
    for (final team in game.teams) {
      uniqueIds.addAll(team.playerIds.where((id) => id.isNotEmpty));
    }
    final sortedIds = uniqueIds.toList()..sort();
    return _TeamUsersRequest(gameId: game.gameId, playerIds: sortedIds);
  }

  /// Build state-aware content based on game status
  Widget _buildStateAwareContent(
    BuildContext context,
    Game game,
    UserRole role,
    bool isCreator,
    String? currentUserId,
    bool isSignedUp,
    bool isGameFull,
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
    UsersRepository usersRepo,
    AsyncValue<Map<String, User>> teamUsersAsync,
  ) {
    final Widget child;
    switch (game.status) {
      case GameStatus.draft:
      case GameStatus.scheduled:
      case GameStatus.recruiting:
      case GameStatus.teamSelection:
        child = PendingGameState(
          game: game,
          gameId: widget.gameId,
          role: role,
          isCreator: isCreator,
          isSignedUp: isSignedUp,
          isGameFull: isGameFull,
          confirmedSignups: confirmedSignups,
          pendingSignups: pendingSignups,
          usersRepo: usersRepo,
          currentUserId: currentUserId,
          onToggleSignup: _toggleSignup,
          onApprovePlayer: _approvePlayer,
          onRejectPlayer: _rejectPlayer,
        );

      case GameStatus.fullyBooked:
      case GameStatus.teamsFormed:
      case GameStatus.inProgress:
      case GameStatus.statsInput:
        child = ActiveGameState(
          game: game,
          gameId: widget.gameId,
          status: game.status,
          role: role,
          isCreator: isCreator,
          isGameFull: isGameFull,
          confirmedSignups: confirmedSignups,
          pendingSignups: pendingSignups,
          usersRepo: usersRepo,
          currentUserId: currentUserId,
          teamUsersAsync: teamUsersAsync,
          onStartGame: _startGame,
          onEndGame: _endGame,
          onRejectPlayer: _rejectPlayer,
          onFindMissingPlayers: _findMissingPlayers,
        );

      case GameStatus.completed:
      case GameStatus.cancelled:
      case GameStatus.archivedNotPlayed:
        child = CompletedGameState(
          game: game,
          gameId: widget.gameId,
          role: role,
          confirmedSignups: confirmedSignups,
          usersRepo: usersRepo,
          teamUsersAsync: teamUsersAsync,
          onEditResult: (context, game) =>
              _showEditResultDialog(context, game, usersRepo),
        );
    }
    return SliverToBoxAdapter(child: child);
  }

  Future<void> _approvePlayer(String playerId) async {
    try {
      final service = GameManagementService();
      await service.approvePlayer(
        gameId: widget.gameId,
        userId: playerId,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showSuccess(context, l10n.playerApprovedSuccess);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showErrorFromException(context, e);
    }
  }

  Future<void> _rejectPlayer(String playerId) async {
    final reasonController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.rejectRequestTitle),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: l10n.rejectionReasonLabel,
              hintText: l10n.rejectionReasonHint,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: Text(l10n.rejectRequestButton),
            ),
          ],
        ),
      );

      final reason = reasonController.text.trim();
      if (confirmed == true && reason.isNotEmpty) {
        try {
          final service = GameManagementService();
          await service.kickPlayer(
            gameId: widget.gameId,
            userId: playerId,
            reason: reason,
          );
          if (mounted) {
            SnackbarHelper.showSuccess(context, l10n.requestRejectedSuccess);
          }
        } catch (e) {
          if (mounted) SnackbarHelper.showErrorFromException(context, e);
        }
      }
    } finally {
      reasonController.dispose();
    }
  }

  /// Find missing players - change game to recruiting and post to feed
  Future<void> _findMissingPlayers(
    BuildContext context,
    Game game,
    int currentPlayers,
    int maxPlayers,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var isLoading = false;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(l10n.findMissingPlayers),
              content: Text(
                l10n.findMissingPlayersDescription(
                  maxPlayers - currentPlayers,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final gamesRepo =
                                ref.read(gamesRepositoryProvider);
                            final hubsRepo = ref.read(hubsRepositoryProvider);
                            final feedRepo = ref.read(feedRepositoryProvider);
                            final usersRepo = ref.read(usersRepositoryProvider);

                            // Update game visibility to recruiting
                            await gamesRepo.updateGame(widget.gameId, {
                              'visibility':
                                  GameVisibility.recruiting.toFirestore(),
                            });

                            // Create feed post only if game belongs to a hub
                            if (game.hubId != null) {
                              // Get hub name
                              final hub = await hubsRepo.getHub(game.hubId!);
                              final hubName =
                                  hub?.name ?? l10n.hubFallbackName;

                              final currentUserId =
                                  ref.read(currentUserIdProvider);
                              if (currentUserId != null) {
                                final currentUser =
                                    await usersRepo.getUser(currentUserId);
                                final gameDateLabel =
                                    _gameDateFormat.format(game.gameDate);
                                final post = FeedPost(
                                  postId: '', // Will be generated by repository
                                  hubId: game.hubId!,
                                  authorId: currentUserId,
                                  type: 'game_recruitment',
                                  content: l10n.recruitingFeedContent(
                                    hubName,
                                    maxPlayers - currentPlayers,
                                    gameDateLabel,
                                  ),
                                  createdAt: DateTime.now(),
                                  gameId: widget.gameId,
                                  region: game.region ?? hub?.region,
                                  city: hub?.city,
                                  hubName: hub?.name,
                                  hubLogoUrl: hub?.logoUrl,
                                  authorName: currentUser?.name,
                                  authorPhotoUrl: currentUser?.photoUrl,
                                );

                                await feedRepo.createPost(post);
                              }
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                              SnackbarHelper.showSuccess(
                                dialogContext,
                                game.hubId != null
                                    ? l10n.gamePromotedToRegionalFeed
                                    : l10n.gameOpenForRecruiting,
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => isLoading = false);
                              SnackbarHelper.showErrorFromException(
                                  dialogContext, e);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build weather widget for game date and location
  Widget _buildGameWeatherWidget(Game game) {
    final l10n = AppLocalizations.of(context)!;
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
                return PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: KineticLoadingAnimation(size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.loadingWeather,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final weather = weatherSnapshot.data;
              if (weather == null) return const SizedBox.shrink();

              return PremiumCard(
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
                            l10n.gameWeatherTitle,
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
                      l10n.temperatureCelsius(weather.temperature),
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
          return PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: KineticLoadingAnimation(size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.loadingWeather,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final weather = snapshot.data;
        if (weather == null) return const SizedBox.shrink();

        return PremiumCard(
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
                      l10n.gameWeatherTitle,
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
                l10n.temperatureCelsius(weather.temperature),
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
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.resultUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resultUpdateError(e.toString())),
          ),
        );
      }
    }
  }
}
