import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/ui/team_builder/team_builder_page.dart';
import 'package:kickadoor/ui/team_builder/manual_team_builder.dart';

/// Team builder page with tabs for automatic and manual team division
class TeamBuilderPageWithTabs extends ConsumerStatefulWidget {
  final String gameId;
  final Game game;
  final int teamCount;
  final List<String> playerIds;
  final List<GameSignup> signups;

  const TeamBuilderPageWithTabs({
    super.key,
    required this.gameId,
    required this.game,
    required this.teamCount,
    required this.playerIds,
    required this.signups,
  });

  @override
  ConsumerState<TeamBuilderPageWithTabs> createState() => _TeamBuilderPageWithTabsState();
}

class _TeamBuilderPageWithTabsState extends ConsumerState<TeamBuilderPageWithTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _currentPlayerIds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentPlayerIds = List.from(widget.playerIds);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddPlayersDialog() async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final signupsRepo = ref.read(signupsRepositoryProvider);

      // Get hub members
      final hub = await hubsRepo.getHub(widget.game.hubId);
      if (hub == null) return;

      final allMembers = await usersRepo.getUsers(hub.memberIds);
      
      // Filter out players already signed up
      final signedUpIds = widget.signups
          .where((s) => s.status == SignupStatus.confirmed)
          .map((s) => s.playerId)
          .toSet();
      
      final availableMembers = allMembers
          .where((user) => !signedUpIds.contains(user.uid))
          .toList();

      if (availableMembers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('כל חברי ההאב כבר נרשמו למשחק')),
          );
        }
        return;
      }

      final selectedPlayers = <String>{};

      final result = await showDialog<Set<String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('הוסף שחקנים מההאב'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'בחר שחקנים להוספה (${selectedPlayers.length} נבחרו)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableMembers.length,
                        itemBuilder: (context, index) {
                          final user = availableMembers[index];
                          final isSelected = selectedPlayers.contains(user.uid);
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedPlayers.add(user.uid);
                                } else {
                                  selectedPlayers.remove(user.uid);
                                }
                              });
                            },
                            title: Text(user.name),
                            subtitle: Text('דירוג: ${user.currentRankScore.toStringAsFixed(1)}'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: selectedPlayers.isEmpty
                  ? null
                  : () => Navigator.pop(context, selectedPlayers),
              child: const Text('הוסף'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Add signups for selected players
          for (final playerId in result) {
            await signupsRepo.setSignup(
              widget.gameId,
              playerId,
              SignupStatus.confirmed,
            );
          }

          // Update local state
          setState(() {
            _currentPlayerIds = [
              ..._currentPlayerIds,
              ...result,
            ];
          });

          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${result.length} שחקנים נוספו בהצלחה'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('שגיאה בהוספת שחקנים: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add players button (admin only)
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddPlayersDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('הוסף שחקן מההאב'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'חלוקה אוטומטית',
            ),
            Tab(
              icon: Icon(Icons.drag_handle),
              text: 'חלוקה ידנית',
            ),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Automatic division tab
              TeamBuilderPage(
                gameId: widget.gameId,
                teamCount: widget.teamCount,
                playerIds: _currentPlayerIds,
              ),
              
              // Manual division tab
              ManualTeamBuilder(
                gameId: widget.gameId,
                game: widget.game,
                teamCount: widget.teamCount,
                playerIds: _currentPlayerIds,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

