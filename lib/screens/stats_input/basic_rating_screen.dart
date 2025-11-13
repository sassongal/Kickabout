import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/services/gamification_service.dart';

/// Basic rating screen for simple 1-7 rating system
class BasicRatingScreen extends ConsumerStatefulWidget {
  final String gameId;

  const BasicRatingScreen({super.key, required this.gameId});

  @override
  ConsumerState<BasicRatingScreen> createState() => _BasicRatingScreenState();
}

class _BasicRatingScreenState extends ConsumerState<BasicRatingScreen> {
  final Map<String, double> _playerRatings = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final signupsRepo = ref.watch(signupsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final ratingsRepo = ref.watch(ratingsRepositoryProvider);

    final gameStream = gamesRepo.watchGame(widget.gameId);
    final signupsStream = signupsRepo.watchSignups(widget.gameId);

    return AppScaffold(
      title: 'דירוג שחקנים',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: Text('משחק לא נמצא'));
          }

          return StreamBuilder<List<GameSignup>>(
            stream: signupsStream,
            builder: (context, signupsSnapshot) {
              if (signupsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final signups = signupsSnapshot.data ?? [];
              final confirmedPlayers = signups
                  .where((s) => s.status == SignupStatus.confirmed)
                  .map((s) => s.playerId)
                  .toList();

              if (confirmedPlayers.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('אין שחקנים שהשתתפו במשחק'),
                  ),
                );
              }

              return FutureBuilder<List<User>>(
                future: usersRepo.getUsers(confirmedPlayers),
                builder: (context, usersSnapshot) {
                  if (usersSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final players = usersSnapshot.data ?? [];

                  // Initialize ratings if not already done
                  if (_playerRatings.isEmpty && players.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        for (final player in players) {
                          _playerRatings[player.uid] = AppConstants.defaultBasicRating;
                        }
                      });
                    });
                  }

                  return _isSubmitting
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('שומר דירוגים...'),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'דירוג בסיסי (1-7)',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'דרג כל שחקן שהשתתף במשחק',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...players.map((player) => _buildPlayerRatingCard(
                                    context,
                                    player,
                                    _playerRatings[player.uid] ?? AppConstants.defaultBasicRating,
                                  )),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _submitRatings(
                                          context,
                                          ref,
                                          game,
                                          players,
                                          currentUserId,
                                          ratingsRepo,
                                        ),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(_isSubmitting ? 'שומר...' : 'שמור דירוגים'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlayerRatingCard(
    BuildContext context,
    User player,
    double currentRating,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerAvatar(
                  user: player,
                  radius: 30,
                  clickable: false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(currentRating).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(currentRating),
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: currentRating,
                minRating: AppConstants.minBasicRating,
                maxRating: AppConstants.maxBasicRating,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 7,
                itemSize: 36,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, index) {
                  return Icon(
                    Icons.star,
                    color: _getRatingColor(index + 1.0),
                  );
                },
                onRatingUpdate: (rating) {
                  setState(() {
                    _playerRatings[player.uid] = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 - חלש',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
                Text(
                  '7 - מצוין',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 6) return Colors.green;
    if (rating >= 4) return Colors.blue;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }

  Future<void> _submitRatings(
    BuildContext context,
    WidgetRef ref,
    Game game,
    List<User> players,
    String? currentUserId,
    RatingsRepository ratingsRepo,
  ) async {
    if (currentUserId == null) {
      SnackbarHelper.showError(context, 'נא להתחבר');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate average rating for each player (from all ratings they received)
      final playerRatingsMap = <String, List<double>>{};
      for (final player in players) {
        final rating = _playerRatings[player.uid] ?? AppConstants.defaultBasicRating;
        playerRatingsMap.putIfAbsent(player.uid, () => []).add(rating);
      }

      // Save ratings
      for (final player in players) {
        final rating = _playerRatings[player.uid] ?? AppConstants.defaultBasicRating;

        final snapshot = RatingSnapshot(
          ratingId: '',
          gameId: widget.gameId,
          playerId: player.uid,
          basicScore: rating,
          submittedBy: currentUserId,
          submittedAt: DateTime.now(),
          isVerified: false,
        );

        await ratingsRepo.addRatingSnapshot(player.uid, snapshot);
      }

      // Update gamification for each player
      final gamificationRepo = ref.read(gamificationRepositoryProvider);
      final eventsRepo = ref.read(eventsRepositoryProvider);
      
      // Get game events to count goals, assists, saves
      final events = await eventsRepo.getEvents(widget.gameId);
      
      for (final player in players) {
        try {
          // Count player's events
          final playerGoals = events.where((e) => e.playerId == player.uid && e.type == EventType.goal).length;
          final playerAssists = events.where((e) => e.playerId == player.uid && e.type == EventType.assist).length;
          final playerSaves = events.where((e) => e.playerId == player.uid && e.type == EventType.save).length;
          
          // Get average rating for this player (simplified - use their rating from this submission)
          final averageRating = _playerRatings[player.uid] ?? AppConstants.defaultBasicRating;
          
          // Check if MVP (simplified - highest rating)
          final isMVP = players.every((p) => 
            (_playerRatings[p.uid] ?? AppConstants.defaultBasicRating) <= averageRating
          );
          
          // Calculate points
          final pointsEarned = GamificationService.calculateGamePoints(
            won: false, // TODO: Determine win/loss from game result
            goals: playerGoals,
            assists: playerAssists,
            saves: playerSaves,
            isMVP: isMVP,
            averageRating: averageRating,
          );
          
          // Update gamification
          await gamificationRepo.updateGamification(
            userId: player.uid,
            pointsEarned: pointsEarned,
            won: false, // TODO: Determine from game result
            goals: playerGoals,
            assists: playerAssists,
            saves: playerSaves,
          );
        } catch (e) {
          debugPrint('Error updating gamification for ${player.uid}: $e');
          // Continue with other players even if one fails
        }
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הדירוגים נשמרו בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
        setState(() => _isSubmitting = false);
      }
    }
  }
}

