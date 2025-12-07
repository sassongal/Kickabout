import 'package:flutter/material.dart';
import 'package:kattrick/widgets/polls/polls_list_widget.dart';

/// Polls Tab Widget
class HubPollsTab extends StatelessWidget {
  final String hubId;
  final bool isManager;

  const HubPollsTab({
    super.key,
    required this.hubId,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return PollsListWidget(
      hubId: hubId,
      showCreateButton: isManager,
    );
  }
}
