import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/error_widget.dart';
import 'package:kattrick/widgets/loading_widget.dart';

/// Man of the Match voting screen
///
/// Allows confirmed participants to vote for the best player after game completion.
/// Features:
/// - Shows all eligible players (confirmed participants, excluding self)
/// - Displays voting progress (X/Y voted)
/// - Submit vote functionality
/// - "Already voted" state showing who you voted for
class VoteMotmScreen extends ConsumerStatefulWidget {
  const VoteMotmScreen({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<VoteMotmScreen> createState() => _VoteMotmScreenState();
}

class _VoteMotmScreenState extends ConsumerState<VoteMotmScreen> {
  bool _isSubmitting = false;
  String? _selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final signupsRepo = ref.read(signupsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: 'הצבעה לשחקן המצטיין',
        body: AppErrorWidget(
          message: 'יש להתחבר כדי להצביע',
          onRetry: () => context.pop(),
        ),
      );
    }

    return AppScaffold(
      title: 'הצבעה לשחקן המצטיין',
      body: FutureBuilder<_VotingData?>(
        future: _loadVotingData(
          gamesRepo,
          signupsRepo,
          usersRepo,
          currentUserId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingWidget(message: 'טוען נתוני הצבעה...');
          }

          if (snapshot.hasError) {
            return AppErrorWidget(
              message: 'שגיאה בטעינת נתוני ההצבעה',
              onRetry: () => setState(() {}),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return AppErrorWidget(
              message: 'לא נמצאו נתוני משחק',
              onRetry: () => context.pop(),
            );
          }

          // Check if voting is closed
          if (data.game.motmVotingClosedAt != null) {
            return _buildVotingClosedState(data);
          }

          // Check if user already voted
          final hasVoted = data.game.motmVotes.containsKey(currentUserId);
          if (hasVoted) {
            return _buildAlreadyVotedState(data, currentUserId);
          }

          // Show voting UI
          return _buildVotingState(data, currentUserId);
        },
      ),
    );
  }

  Widget _buildVotingState(_VotingData data, String currentUserId) {
    final eligiblePlayers = data.eligiblePlayers
        .where((player) => player.uid != currentUserId)
        .toList();

    final totalParticipants = data.confirmedSignups.length;
    final totalVotes = data.game.motmVotes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trophy icon
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'מי היה שחקן המשחק?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Voting progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$totalVotes/$totalParticipants הצביעו',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Eligible players list
          const Text(
            'בחר שחקן:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (eligiblePlayers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'אין שחקנים זמינים להצבעה',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...eligiblePlayers.map((player) {
              final isSelected = _selectedPlayerId == player.uid;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isSelected ? Colors.amber.withValues(alpha: 0.2) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.amber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedPlayerId = player.uid),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Player photo
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: player.photoUrl != null
                              ? NetworkImage(player.photoUrl!)
                              : null,
                          child: player.photoUrl == null
                              ? Text(
                                  player.name.isNotEmpty
                                      ? player.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),

                        // Player info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (player.preferredPosition != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _positionToHebrew(player.preferredPosition),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Selection indicator
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.amber,
                            size: 32,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton.icon(
            onPressed: _selectedPlayerId != null && !_isSubmitting
                ? () => _submitVote(currentUserId)
                : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.how_to_vote),
            label: Text(
              _isSubmitting ? 'שולח הצבעה...' : 'שלח הצבעה',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey,
            ),
          ),

          const SizedBox(height: 16),

          // Cancel button
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyVotedState(_VotingData data, String currentUserId) {
    final votedPlayerId = data.game.motmVotes[currentUserId]!;
    final votedPlayer = data.eligiblePlayers
        .where((p) => p.uid == votedPlayerId)
        .firstOrNull;

    final totalParticipants = data.confirmedSignups.length;
    final totalVotes = data.game.motmVotes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success icon
          const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'תודה על ההצבעה!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Voting progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$totalVotes/$totalParticipants הצביעו',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Who you voted for
          const Text(
            'הצבעת עבור:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          if (votedPlayer != null)
            Card(
              color: Colors.green.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Player photo
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: votedPlayer.photoUrl != null
                          ? NetworkImage(votedPlayer.photoUrl!)
                          : null,
                      child: votedPlayer.photoUrl == null
                          ? Text(
                              votedPlayer.name.isNotEmpty
                                  ? votedPlayer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Player info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            votedPlayer.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (votedPlayer.preferredPosition != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _positionToHebrew(votedPlayer.preferredPosition),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'שחקן לא נמצא',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

          const SizedBox(height: 24),

          const Text(
            'ההצבעה תיסגר אוטומטית כאשר 80% מהשחקנים יצביעו או תוך שעתיים.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          // Back button
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('חזרה לפרטי המשחק'),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingClosedState(_VotingData data) {
    final winnerId = data.game.motmWinnerId;
    final winner = winnerId != null
        ? data.eligiblePlayers.where((p) => p.uid == winnerId).firstOrNull
        : null;

    final totalVotes = data.game.motmVotes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trophy icon
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'ההצבעה הסתיימה',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          if (winner != null) ...[
            const Text(
              'שחקן המשחק:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.amber, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Winner photo
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: winner.photoUrl != null
                          ? NetworkImage(winner.photoUrl!)
                          : null,
                      child: winner.photoUrl == null
                          ? Text(
                              winner.name.isNotEmpty
                                  ? winner.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 36),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Winner name
                    Text(
                      winner.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Vote count
                    Text(
                      '$totalVotes הצבעות',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Text(
              'לא נבחר שחקן מצטיין (לא היו מספיק הצבעות)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Back button
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('חזרה לפרטי המשחק'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote(String currentUserId) async {
    if (_selectedPlayerId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final game = await gamesRepo.getGame(widget.gameId);

      if (game == null) {
        throw Exception('משחק לא נמצא');
      }

      // Check if voting is still open
      if (game.motmVotingClosedAt != null) {
        throw Exception('ההצבעה כבר נסגרה');
      }

      // Update motmVotes map
      final updatedVotes = Map<String, String>.from(game.motmVotes);
      updatedVotes[currentUserId] = _selectedPlayerId!;

      await gamesRepo.updateGame(
        widget.gameId,
        {'motmVotes': updatedVotes},
      );

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'ההצבעה נשלחה בהצלחה! תודה',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'שגיאה בשליחת ההצבעה: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<_VotingData?> _loadVotingData(
    GamesRepository gamesRepo,
    SignupsRepository signupsRepo,
    UsersRepository usersRepo,
    String currentUserId,
  ) async {
    try {
      // Load game
      final game = await gamesRepo.getGame(widget.gameId);
      if (game == null) return null;

      // Load confirmed signups
      final allSignups = await signupsRepo.getSignups(widget.gameId);
      final confirmedSignups = allSignups
          .where((s) => s.status == SignupStatus.confirmed)
          .toList();

      // Load player users
      final playerIds = confirmedSignups.map((s) => s.playerId).toList();
      final players = await usersRepo.getUsers(playerIds);

      return _VotingData(
        game: game,
        confirmedSignups: confirmedSignups,
        eligiblePlayers: players,
      );
    } catch (e) {
      return null;
    }
  }

  String _positionToHebrew(String position) {
    switch (position.toUpperCase()) {
      case 'GK':
        return 'שוער';
      case 'DEF':
        return 'מגן';
      case 'MID':
        return 'קשר';
      case 'FWD':
        return 'חלוץ';
      case 'ANY':
        return 'כל עמדה';
      default:
        return position;
    }
  }
}

class _VotingData {
  _VotingData({
    required this.game,
    required this.confirmedSignups,
    required this.eligiblePlayers,
  });

  final Game game;
  final List<GameSignup> confirmedSignups;
  final List<User> eligiblePlayers;
}
