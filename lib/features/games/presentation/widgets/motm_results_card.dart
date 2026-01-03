import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';

/// MOTM Results Card Widget
///
/// Displays the Man of the Match voting results after voting has closed.
/// Features:
/// - Trophy-themed card with gold/amber colors
/// - Winner name and photo
/// - Vote count
/// - Voting closed timestamp
class MotmResultsCard extends StatelessWidget {
  const MotmResultsCard({
    required this.game,
    required this.winnerUser,
    super.key,
  });

  final Game game;
  final User? winnerUser;

  @override
  Widget build(BuildContext context) {
    // Only show if voting is enabled, closed, and has a winner
    if (!game.motmVotingEnabled ||
        game.motmVotingClosedAt == null ||
        game.motmWinnerId == null) {
      return const SizedBox.shrink();
    }

    final winner = winnerUser;
    final totalVotes = game.motmVotes.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.amber.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'שחקן המשחק',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                // Trophy badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🏆',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (winner != null) ...[
              // Winner card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Winner photo
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: winner.photoUrl != null
                            ? NetworkImage(winner.photoUrl!)
                            : null,
                        child: winner.photoUrl == null
                            ? Text(
                                winner.name.isNotEmpty
                                    ? winner.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Winner info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            winner.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.how_to_vote,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$totalVotes ${totalVotes == 1 ? 'הצבעה' : 'הצבעות'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Trophy icon
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 48,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No winner found (shouldn't happen normally)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'שחקן המצטיין לא נמצא',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Voting closed timestamp
            if (game.motmVotingClosedAt != null)
              Text(
                'ההצבעה נסגרה ב-${_formatDateTime(game.motmVotingClosedAt!)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inHours < 24) {
      return 'לפני ${difference.inHours} שעות';
    } else if (difference.inDays < 7) {
      return 'לפני ${difference.inDays} ימים';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
  }
}
