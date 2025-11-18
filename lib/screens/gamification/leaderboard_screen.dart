import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/leaderboard_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Leaderboard screen - shows top players
class LeaderboardScreen extends ConsumerStatefulWidget {
  final String? hubId;

  const LeaderboardScreen({super.key, this.hubId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardType _selectedType = LeaderboardType.points;
  TimePeriod _selectedPeriod = TimePeriod.allTime;

  @override
  Widget build(BuildContext context) {
    final leaderboardRepo = ref.read(leaderboardRepositoryProvider);
    
    // Use streamLeaderboard for real-time updates
    final leaderboardStream = leaderboardRepo.streamLeaderboard(
      type: _selectedType,
      hubId: widget.hubId,
      period: _selectedPeriod,
      limit: 100,
    );

    return FuturisticScaffold(
      title: 'טבלת מובילים',
      body: Column(
        children: [
          // Filters
          FuturisticCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סינון',
                  style: FuturisticTypography.techHeadline,
                ),
                const SizedBox(height: 12),
                // Type filter
                Text(
                  'סוג:',
                  style: FuturisticTypography.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<LeaderboardType>(
                  segments: const [
                    ButtonSegment(
                      value: LeaderboardType.points,
                      label: Text('נקודות'),
                    ),
                    ButtonSegment(
                      value: LeaderboardType.gamesPlayed,
                      label: Text('משחקים'),
                    ),
                    ButtonSegment(
                      value: LeaderboardType.goals,
                      label: Text('שערים'),
                    ),
                    ButtonSegment(
                      value: LeaderboardType.rating,
                      label: Text('דירוג'),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<LeaderboardType> selected) {
                    setState(() {
                      _selectedType = selected.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Period filter
                Text(
                  'תקופה:',
                  style: FuturisticTypography.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<TimePeriod>(
                  segments: const [
                    ButtonSegment(
                      value: TimePeriod.allTime,
                      label: Text('כל הזמנים'),
                    ),
                    ButtonSegment(
                      value: TimePeriod.monthly,
                      label: Text('חודשי'),
                    ),
                    ButtonSegment(
                      value: TimePeriod.weekly,
                      label: Text('שבועי'),
                    ),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<TimePeriod> selected) {
                    setState(() {
                      _selectedPeriod = selected.first;
                    });
                  },
                ),
              ],
            ),
          ),
          // Leaderboard list
          Expanded(
            child: StreamBuilder<List<LeaderboardEntry>>(
              stream: leaderboardStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const FuturisticLoadingState(
                    message: 'טוען טבלת מובילים...',
                  );
                }

                if (snapshot.hasError) {
                  return FuturisticEmptyState(
                    icon: Icons.error_outline,
                    title: 'שגיאה בטעינת טבלת מובילים',
                    message: ErrorHandlerService().handleException(
                      snapshot.error,
                      context: 'Leaderboard screen',
                    ),
                    action: ElevatedButton.icon(
                      onPressed: () {
                        // Retry by rebuilding
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('נסה שוב'),
                    ),
                  );
                }

                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return FuturisticEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'אין נתונים',
                    message: 'עדיין אין שחקנים בטבלת המובילים',
                  );
                }

                return ListView.builder(
                  itemCount: entries.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _LeaderboardCard(
                      entry: entry,
                      rank: entry.rank,
                      type: _selectedType,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final LeaderboardType type;

  const _LeaderboardCard({
    required this.entry,
    required this.rank,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    IconData? medalIcon;
    Color? medalColor;

    if (rank == 1) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.amber;
    } else if (rank == 2) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.grey;
    } else if (rank == 3) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.brown;
    }

    // Create a temporary User object for PlayerAvatar
    final user = User(
      uid: entry.userId,
      name: entry.userName,
      email: '', // Not needed for display
      photoUrl: entry.userPhotoUrl,
      createdAt: DateTime.now(), // Not needed for display
    );

    return FuturisticCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.go('/profile/${entry.userId}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank indicator
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medalColor ?? FuturisticColors.surfaceVariant,
              ),
              child: medalIcon != null
                  ? Icon(medalIcon, color: Colors.white, size: 28)
                  : Text(
                      '#$rank',
                      style: FuturisticTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Avatar
            PlayerAvatar(
              user: user,
              radius: 28,
              clickable: false,
            ),
            const SizedBox(width: 16),
            // Name and score
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.userName,
                    style: FuturisticTypography.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.score} ${_getScoreLabel()}',
                    style: FuturisticTypography.bodyMedium.copyWith(
                      color: FuturisticColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_left,
              color: FuturisticColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreLabel() {
    switch (type) {
      case LeaderboardType.points:
        return 'נקודות';
      case LeaderboardType.gamesPlayed:
        return 'משחקים';
      case LeaderboardType.goals:
        return 'שערים';
      case LeaderboardType.assists:
        return 'אסיסטים';
      case LeaderboardType.rating:
        return 'דירוג';
      case LeaderboardType.winRate:
        return '% ניצחונות';
    }
  }
}

