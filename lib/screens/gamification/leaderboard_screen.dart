import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/leaderboard_repository.dart';

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
  bool _isLoading = false;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final leaderboardRepo = ref.read(leaderboardRepositoryProvider);
      final entries = await leaderboardRepo.getLeaderboard(
        type: _selectedType,
        hubId: widget.hubId,
        period: _selectedPeriod,
      );
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת לידר בורד: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'שולחן מובילים',
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Type filter
                  Row(
                    children: [
                      const Text('סוג: '),
                      Expanded(
                        child: SegmentedButton<LeaderboardType>(
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
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (Set<LeaderboardType> selected) {
                            setState(() {
                              _selectedType = selected.first;
                            });
                            _loadLeaderboard();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Period filter
                  Row(
                    children: [
                      const Text('תקופה: '),
                      Expanded(
                        child: SegmentedButton<TimePeriod>(
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
                            _loadLeaderboard();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Leaderboard list
          Expanded(
            child: _isLoading
                ? const FuturisticLoadingState(message: 'טוען טבלת ליגה...')
                : _entries.isEmpty
                    ? FuturisticEmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'אין נתונים',
                        message: 'עדיין אין שחקנים בטבלת הליגה',
                      )
                    : ListView.builder(
                        itemCount: _entries.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _LeaderboardCard(
                            entry: entry,
                            rank: entry.rank,
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

  const _LeaderboardCard({
    required this.entry,
    required this.rank,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (medalIcon != null)
              Icon(medalIcon, color: medalColor, size: 24)
            else
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: entry.userPhotoUrl != null
                  ? NetworkImage(entry.userPhotoUrl!)
                  : null,
              child: entry.userPhotoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ],
        ),
        title: Text(entry.userName),
        subtitle: Text('${entry.score} ${_getScoreLabel()}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.push('/profile/${entry.userId}'),
      ),
    );
  }

  String _getScoreLabel() {
    // This should match the LeaderboardType
    // For now, return generic label
    return 'נקודות';
  }
}

