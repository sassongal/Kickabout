import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/poll.dart';
import 'package:kattrick/routing/app_router.dart';

/// Card widget for displaying a poll in a list
class PollCard extends ConsumerWidget {
  final Poll poll;
  final VoidCallback onTap;

  const PollCard({
    required this.poll,
    required this.onTap,
    super.key,
  });

  String _getPollTypeLabel(PollType type) {
    switch (type) {
      case PollType.singleChoice:
        return 'בחירה אחת';
      case PollType.multipleChoice:
        return 'בחירה מרובה';
      case PollType.rating:
        return 'דירוג';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final summary = PollSummary.fromPoll(poll, userId: user?.uid);

    final hasEnded =
        poll.endsAt != null && poll.endsAt!.isBefore(DateTime.now());
    final isActive = poll.status == PollStatus.active && !hasEnded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.poll,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      poll.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(_getPollTypeLabel(poll.type)),
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (summary.hasVoted)
                    const Chip(
                      label: Text('הצבעת'),
                      avatar: Icon(Icons.check_circle,
                          size: 16, color: Colors.white),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (!isActive)
                    const Chip(
                      label: Text('סגור'),
                      backgroundColor: Colors.grey,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Results preview (if voted or showResultsBeforeVote)
              if (summary.hasVoted || poll.showResultsBeforeVote) ...[
                Text(
                  'תוצאות מובילות:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (summary.winningOption != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          summary.winningOption!.text,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${summary.winningOption!.voteCount} (${summary.optionPercentages[summary.winningOption!.optionId]?.toStringAsFixed(0) ?? 0}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.how_to_vote,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${poll.totalVotes} הצבעות',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (poll.endsAt != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hasEnded
                                  ? 'הסתיים'
                                  : 'עד ${poll.endsAt!.day}/${poll.endsAt!.month}',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasEnded ? Colors.red : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
