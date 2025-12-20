import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/data/polls_repository.dart';
import 'package:kattrick/models/poll.dart';
import 'package:kattrick/routing/app_router.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/premium/gradient_button.dart';

/// Screen for viewing and voting on a poll
class PollDetailScreen extends ConsumerStatefulWidget {
  final String pollId;

  const PollDetailScreen({
    required this.pollId,
    super.key,
  });

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  final Set<String> _selectedOptions = {};
  int? _rating;
  bool _isVoting = false;

  Future<void> _vote(Poll poll) async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) {
      SnackbarHelper.showError(context, 'משתמש לא מחובר');
      return;
    }

    // Validation
    if (poll.type == PollType.singleChoice && _selectedOptions.length != 1) {
      SnackbarHelper.showWarning(context, 'יש לבחור אפשרות אחת');
      return;
    }

    if (poll.type == PollType.multipleChoice && _selectedOptions.isEmpty) {
      SnackbarHelper.showWarning(context, 'יש לבחור לפחות אפשרות אחת');
      return;
    }

    if (poll.type == PollType.rating && _rating == null) {
      SnackbarHelper.showWarning(context, 'יש לבחור דירוג');
      return;
    }

    setState(() => _isVoting = true);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      await functions.httpsCallable('votePoll').call({
        'pollId': widget.pollId,
        'selectedOptionIds': _selectedOptions.toList(),
        'rating': _rating,
      });

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'ההצבעה נשמרה בהצלחה! 🎉');

      // Clear selection
      setState(() {
        _selectedOptions.clear();
        _rating = null;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      String message = 'שגיאה בהצבעה';
      if (e.code == 'already-voted') {
        message = 'כבר הצבעת בסקר זה';
      } else if (e.code == 'poll-closed') {
        message = 'הסקר סגור להצבעות';
      } else if (e.code == 'resource-exhausted') {
        message = 'יותר מדי הצבעות. נסה שוב בעוד דקה';
      } else if (e.message != null) {
        message = e.message!;
      }

      SnackbarHelper.showError(context, message);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'שגיאה בהצבעה: $e');
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  Widget _buildVotingInterface(Poll poll, String? userId) {
    switch (poll.type) {
      case PollType.singleChoice:
        return Column(
          children: poll.options.map((option) {
            return RadioListTile<String>(
              title: Text(option.text),
              value: option.optionId,
              groupValue:
                  _selectedOptions.isEmpty ? null : _selectedOptions.first,
              onChanged: poll.status == PollStatus.active
                  ? (value) {
                      setState(() {
                        _selectedOptions.clear();
                        if (value != null) _selectedOptions.add(value);
                      });
                    }
                  : null,
            );
          }).toList(),
        );

      case PollType.multipleChoice:
        return Column(
          children: poll.options.map((option) {
            return CheckboxListTile(
              title: Text(option.text),
              value: _selectedOptions.contains(option.optionId),
              onChanged: poll.status == PollStatus.active
                  ? (value) {
                      setState(() {
                        if (value == true) {
                          _selectedOptions.add(option.optionId);
                        } else {
                          _selectedOptions.remove(option.optionId);
                        }
                      });
                    }
                  : null,
            );
          }).toList(),
        );

      case PollType.rating:
        return Column(
          children: poll.options.map((option) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (poll.status == PollStatus.active)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return IconButton(
                            icon: Icon(
                              starValue <= (_rating ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = starValue;
                                _selectedOptions.clear();
                                _selectedOptions.add(option.optionId);
                              });
                            },
                          );
                        }),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
    }
  }

  Widget _buildResults(Poll poll, String? userId) {
    final summary = PollSummary.fromPoll(poll, userId: userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'תוצאות (${poll.totalVotes} הצבעות)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...summary.sortedOptions.map((option) {
          final percentage = summary.optionPercentages[option.optionId] ?? 0.0;
          final isWinning = summary.winningOption?.optionId == option.optionId;
          final isUserVote =
              summary.userVotes?.contains(option.optionId) ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isWinning || isUserVote
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isWinning) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.emoji_events,
                                color: Colors.amber, size: 20),
                          ],
                          if (isUserVote) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${option.voteCount} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: poll.totalVotes > 0 ? percentage / 100 : 0,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWinning
                          ? Colors.green
                          : isUserVote
                              ? Colors.blue
                              : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pollStream =
        ref.watch(pollsRepositoryProvider).watchPoll(widget.pollId);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('סקר'),
        elevation: 0,
      ),
      body: StreamBuilder<Poll?>(
        stream: pollStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('הסקר לא נמצא'),
            );
          }

          final poll = snapshot.data!;
          final summary = PollSummary.fromPoll(poll, userId: user?.uid);
          final hasEnded =
              poll.endsAt != null && poll.endsAt!.isBefore(DateTime.now());
          final canVote = poll.status == PollStatus.active &&
              !hasEnded &&
              (!summary.hasVoted || poll.allowMultipleVotes);
          final showResults = summary.hasVoted ||
              poll.showResultsBeforeVote ||
              poll.status != PollStatus.active ||
              hasEnded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Question
              Text(
                poll.question,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              if (poll.description != null && poll.description!.isNotEmpty) ...[
                Text(
                  poll.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Status chips
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      poll.status == PollStatus.active ? 'פעיל' : 'סגור',
                    ),
                    backgroundColor: poll.status == PollStatus.active
                        ? Colors.green
                        : Colors.grey,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  if (poll.endsAt != null)
                    Chip(
                      label: Text(
                        hasEnded
                            ? 'הסתיים'
                            : 'מסתיים ב-${poll.endsAt!.day}/${poll.endsAt!.month}',
                      ),
                      backgroundColor: hasEnded ? Colors.red : Colors.blue,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  if (poll.isAnonymous)
                    const Chip(
                      label: Text('אנונימי'),
                      backgroundColor: Colors.purple,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Voting Interface or Results
              if (canVote && !showResults) ...[
                _buildVotingInterface(poll, user?.uid),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'הצבע',
                  onPressed: _isVoting ? null : () => _vote(poll),
                  isLoading: _isVoting,
                ),
              ] else if (showResults) ...[
                _buildResults(poll, user?.uid),
              ],

              const SizedBox(height: 16),

              // Show "Vote to see results" message
              if (!showResults && !canVote)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.grey),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'הצבע כדי לראות תוצאות',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
