import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/ui/team_builder/team_builder_page.dart';
import 'package:kattrick/ui/team_builder/manual_team_builder.dart';

/// Team builder page with tabs for automatic and manual team division
class TeamBuilderPageWithTabs extends ConsumerStatefulWidget {
  final String gameId;
  final Game game;
  final int teamCount;
  final List<String> playerIds;
  final List<GameSignup> signups;
  final bool isEvent; // If true, save teams to Event instead of Game
  final String? eventId; // Event ID if isEvent == true
  final String? hubId; // Hub ID if isEvent == true

  const TeamBuilderPageWithTabs({
    super.key,
    required this.gameId,
    required this.game,
    required this.teamCount,
    required this.playerIds,
    required this.signups,
    this.isEvent = false,
    this.eventId,
    this.hubId,
  });

  @override
  ConsumerState<TeamBuilderPageWithTabs> createState() =>
      _TeamBuilderPageWithTabsState();
}

class _TeamBuilderPageWithTabsState
    extends ConsumerState<TeamBuilderPageWithTabs>
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
    // TODO: Implement getHubMembersAsUsers or use alternative approach
    // This feature is temporarily disabled until the proper hub members query is implemented
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('תכונה זו בהכנה')),
      );
    }
    return;

    /* Original code - needs refactoring
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final signupsRepo = ref.read(signupsRepositoryProvider);

      // Get hub members
      final hubUsers =
          await hubsRepo.getHubMembersAsUsers(widget.game.hubId, limit: 200);
      if (hubUsers.isEmpty) return;

      // Filter out players already signed up
      final signedUpIds = widget.signups
          .where((s) => s.status == SignupStatus.confirmed)
          .map((s) => s.playerId)
          .toSet();
      
      final availableMembers = hubUsers
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
                            subtitle: FutureBuilder<Hub?>(
                              future: ref.read(hubsRepositoryProvider).getHub(widget.game.hubId),
                              builder: (context, hubSnapshot) {
                                final hub = hubSnapshot.data;
                                final rating = (hub?.managerRatings != null && hub!.managerRatings.containsKey(user.uid))
                                    ? hub.managerRatings[user.uid]!
                                    : user.currentRankScore;
                                return Text('דירוג: ${rating.toStringAsFixed(1)}');
                              },
                            ),
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
          final signupService = ref.read(gameSignupServiceProvider);
          for (final playerId in result) {
            await signupService.setSignup(
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
    */
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
                hubId: widget.game.hubId,
                teamCount: widget.teamCount,
                playerIds: _currentPlayerIds,
              ),

              // Manual division tab
              ManualTeamBuilder(
                gameId: widget.gameId,
                game: widget.game,
                teamCount: widget.teamCount,
                playerIds: _currentPlayerIds,
                isEvent: widget.isEvent,
                eventId: widget.eventId,
                hubId: widget.hubId,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
