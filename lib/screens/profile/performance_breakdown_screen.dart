import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

/// Performance breakdown by hub for a player
class PerformanceBreakdownScreen extends ConsumerStatefulWidget {
  final String userId;

  const PerformanceBreakdownScreen({super.key, required this.userId});

  @override
  ConsumerState<PerformanceBreakdownScreen> createState() =>
      _PerformanceBreakdownScreenState();
}

class _PerformanceBreakdownScreenState
    extends ConsumerState<PerformanceBreakdownScreen> {
  late Future<List<_HubPerformance>> _data;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<List<_HubPerformance>> _loadData() async {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final hubs = await hubsRepo.getHubsByMember(widget.userId);

    final List<_HubPerformance> results = [];
    for (final hub in hubs) {
      try {
        final games = await gamesRepo.getGamesByHub(hub.hubId);
        final myGames = games
            .where((g) => g.confirmedPlayerIds.contains(widget.userId))
            .toList();
        results.add(_HubPerformance(
          hub: hub,
          gamesPlayed: myGames.length,
        ));
      } catch (_) {
        // Skip hub if fetching fails
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'ביצועים לפי הוב',
      body: FutureBuilder<List<_HubPerformance>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FuturisticLoadingState(message: 'טוען נתונים...');
          }

          if (snapshot.hasError) {
            return FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת נתונים',
              message: snapshot.error.toString(),
              action: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _data = _loadData();
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            );
          }

          final hubs = snapshot.data ?? [];
          if (hubs.isEmpty) {
            return FuturisticEmptyState(
              icon: Icons.sports_soccer,
              title: 'אין נתונים',
              message: 'לא נמצאו משחקים עבור הובים שלך',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hubs.length,
            itemBuilder: (context, index) {
              final item = hubs[index];
              return FuturisticCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => context.push('/hubs/${item.hub.hubId}'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: FuturisticColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.hub.name,
                            style: FuturisticTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${item.gamesPlayed} משחקים',
                            style: FuturisticTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HubPerformance {
  final Hub hub;
  final int gamesPlayed;

  _HubPerformance({required this.hub, required this.gamesPlayed});
}
