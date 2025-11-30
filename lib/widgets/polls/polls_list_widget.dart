import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/data/polls_repository.dart';
import 'package:kattrick/models/poll.dart';
import 'package:kattrick/screens/hub/create_poll_screen.dart';
import 'package:kattrick/screens/hub/poll_detail_screen.dart';
import 'package:kattrick/widgets/polls/poll_card.dart';

/// Widget for displaying polls list in a Hub
class PollsListWidget extends ConsumerWidget {
  final String hubId;
  final bool showCreateButton;

  const PollsListWidget({
    required this.hubId,
    this.showCreateButton = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsStream = ref
        .watch(pollsRepositoryProvider)
        .watchHubPolls(hubId: hubId, status: PollStatus.active, limit: 20);

    return StreamBuilder<List<Poll>>(
      stream: pollsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('שגיאה בטעינת סקרים: ${snapshot.error}'),
          );
        }

        final polls = snapshot.data ?? [];

        if (polls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.poll,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'אין סקרים פעילים',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (showCreateButton) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreatePollScreen(hubId: hubId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('צור סקר ראשון'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            if (showCreateButton) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'סקרים פעילים (${polls.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CreatePollScreen(hubId: hubId),
                          ),
                        );
                        // Refresh is automatic via Stream
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('סקר חדש'),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: polls.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final poll = polls[index];
                  return PollCard(
                    poll: poll,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              PollDetailScreen(pollId: poll.pollId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

