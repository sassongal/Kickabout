import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MotmVotingPopup extends ConsumerStatefulWidget {
  final Game game;
  final Map<String, User> players;

  const MotmVotingPopup({
    super.key,
    required this.game,
    required this.players,
  });

  static Future<void> show(
    BuildContext context, {
    required Game game,
    required Map<String, User> players,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MotmVotingPopup(game: game, players: players),
    );
  }

  @override
  ConsumerState<MotmVotingPopup> createState() => _MotmVotingPopupState();
}

class _MotmVotingPopupState extends ConsumerState<MotmVotingPopup> {
  String? _selectedPlayerId;
  bool _isSubmitting = false;

  Future<void> _submitVote() async {
    if (_selectedPlayerId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) throw Exception('User not logged in');

      // Perform voting using a transaction (to be safe, though gamesRepo might have its own logic)
      // Here we'll use a simplified version or call repo if available
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final gameRef = FirebaseFirestore.instance
            .collection('games')
            .doc(widget.game.gameId);
        final snapshot = await transaction.get(gameRef);

        if (!snapshot.exists) throw Exception('Game not found');

        final gameData = snapshot.data() as Map<String, dynamic>;
        final votes = Map<String, int>.from(gameData['motmVotes'] ?? {});
        final voterIds = List<String>.from(gameData['motmVoterIds'] ?? []);

        if (voterIds.contains(currentUserId)) {
          throw Exception('Already voted');
        }

        votes[_selectedPlayerId!] = (votes[_selectedPlayerId!] ?? 0) + 1;
        voterIds.add(currentUserId);

        transaction.update(gameRef, {
          'motmVotes': votes,
          'motmVoterIds': voterIds,
        });
      });

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'ההצבעה נקלטה! תודה על ההשתתפות.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בהצבעה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    // Filter out the current user (can't vote for self)
    final eligiblePlayers =
        widget.players.values.where((p) => p.uid != currentUserId).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.95),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            const Text(
              'הצבעה למצטיין המשחק',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'מי היה השחקן הכי טוב היום?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: eligiblePlayers.length,
                itemBuilder: (context, index) {
                  final player = eligiblePlayers[index];
                  final isSelected = _selectedPlayerId == player.uid;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPlayerId = player.uid);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.amber.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.amber
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: player.photoUrl != null
                                ? NetworkImage(player.photoUrl!)
                                : null,
                            child: player.photoUrl == null
                                ? Text(player.name.substring(0, 1))
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            player.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('בפעם אחרת'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedPlayerId == null || _isSubmitting
                        ? null
                        : _submitVote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('שלח הצבעה',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
