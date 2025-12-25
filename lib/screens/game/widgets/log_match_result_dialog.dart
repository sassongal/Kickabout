import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/features/games/presentation/notifiers/log_match_result_dialog_notifier.dart';
import 'package:uuid/uuid.dart';

class LogMatchResultDialog extends ConsumerStatefulWidget {
  final HubEvent event;
  final List<User> players;
  final String currentUserId;

  const LogMatchResultDialog({
    super.key,
    required this.event,
    required this.players,
    required this.currentUserId,
  });

  @override
  ConsumerState<LogMatchResultDialog> createState() => _LogMatchResultDialogState();
}

class _LogMatchResultDialogState extends ConsumerState<LogMatchResultDialog> {
  final _pageController = PageController();
  final _uuid = const Uuid();
  late FixedExtentScrollController _teamAScrollController;
  late FixedExtentScrollController _teamBScrollController;

  @override
  void initState() {
    super.initState();
    _teamAScrollController = FixedExtentScrollController(initialItem: 0);
    _teamBScrollController = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _teamAScrollController.dispose();
    _teamBScrollController.dispose();
    super.dispose();
  }

  LogMatchResultDialogParams get _params => LogMatchResultDialogParams(
        event: widget.event,
        players: widget.players,
      );

  void _onNext() {
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);
    final state = ref.read(logMatchResultDialogNotifierProvider(_params));
    
    // --- Step 1 Validation ---
    if (state.currentPage == 0) {
      final error = notifier.validateStep1();
      if (error != null) {
        SnackbarHelper.showError(context, error);
        return;
      }
      
      // Set winning/losing teams
      notifier.setWinningLosingTeams();
    }

    if (state.currentPage < 4) {
      // 4 is the confirmation page
      final nextPage = state.currentPage + 1;
      notifier.setCurrentPage(nextPage);
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _onBack() {
    final state = ref.read(logMatchResultDialogNotifierProvider(_params));
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);
    
    if (state.currentPage > 0) {
      final prevPage = state.currentPage - 1;
      notifier.setCurrentPage(prevPage);
      _pageController.animateToPage(
        prevPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _submit() {
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);
    
    try {
      final result = notifier.createMatchResult(
        _uuid.v4(),
        widget.currentUserId,
      );
      Navigator.pop(context, result);
    } catch (e) {
      SnackbarHelper.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logMatchResultDialogNotifierProvider(_params));
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.grey.shade900.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Log Match Result',
          style: PremiumTypography.techHeadline.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              ref.read(logMatchResultDialogNotifierProvider(_params).notifier)
                  .setCurrentPage(page);
            },
            children: [
              _buildScoreSelector(state),
              _buildMvpSelector(state),
              _buildScorersSelector(state),
              _buildAssistsSelector(state),
              _buildConfirmationView(state),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: _onBack,
            child: const Text('Back', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(state.currentPage == 4 ? 'Confirm & Save' : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSelector(LogMatchResultDialogState state) {
    final scores = List.generate(6, (i) => i); // 0-5
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);

    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Step 1: Score',
            style: PremiumTypography.labelLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTeamDropdown(
                  team: state.selectedTeamA,
                  otherSelectedTeam: state.selectedTeamB,
                  onChanged: (team) {
                    final teamAPlayers = widget.players
                        .where((p) => team?.playerIds.contains(p.uid) ?? false)
                        .toList();
                    notifier.setSelectedTeamA(team, teamAPlayers);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child:
                    Text('vs', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
              Expanded(
                child: _buildTeamDropdown(
                  team: state.selectedTeamB,
                  otherSelectedTeam: state.selectedTeamA,
                  onChanged: (team) {
                    final teamBPlayers = widget.players
                        .where((p) => team?.playerIds.contains(p.uid) ?? false)
                        .toList();
                    notifier.setSelectedTeamB(team, teamBPlayers);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamColumn(
                  state.selectedTeamA?.name ?? 'Team A', _teamAScrollController, scores,
                  (index) {
                notifier.setTeamAScore(scores[index]);
              }),
              const Padding(
                padding: EdgeInsets.only(top: 100.0),
                child: Text(':',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ),
              _buildTeamColumn(
                  state.selectedTeamB?.name ?? 'Team B', _teamBScrollController, scores,
                  (index) {
                notifier.setTeamBScore(scores[index]);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDropdown({
    required Team? team,
    required Team? otherSelectedTeam,
    required ValueChanged<Team?> onChanged,
  }) {
    final availableTeams = widget.event.teams
        .where((t) => t.teamId != otherSelectedTeam?.teamId)
        .toList();

    return DropdownButtonFormField<Team>(
      value: team,
      onChanged: onChanged,
      items: availableTeams.map((t) {
        return DropdownMenuItem<Team>(
          value: t,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(t.colorValue ?? 0xFFFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(t.name,
                  style: const TextStyle(
                      color: Colors.white, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.grey[800],
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildTeamColumn(String teamName,
      FixedExtentScrollController controller, List<int> scores,
      ValueChanged<int> onSelectedItemChanged) {
    return Column(
      children: [
        Text(
          teamName,
          style: const TextStyle(
              color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          height: 200,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 60,
            diameterRatio: 1.2,
            onSelectedItemChanged: onSelectedItemChanged,
            selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
              background: PremiumColors.primary.withOpacity(0.2),
              capStartEdge: false,
              capEndEdge: false,
            ),
            children: scores
                .map((score) => Center(
                      child: Text(
                        score.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 40),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMvpSelector(LogMatchResultDialogState state) {
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);
    
    if (state.winningTeamPlayers.isEmpty) {
      return Center(
        child: Text(
          'No players on the winning team to select MVP from.',
          style: PremiumTypography.bodyMedium.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        Text(
          'Step 2: Select MVP (from ${state.winningTeam?.name ?? 'Winning Team'})',
          style: PremiumTypography.labelLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: state.winningTeamPlayers.length,
            itemBuilder: (context, index) {
              final player = state.winningTeamPlayers[index];
              return RadioListTile<String>(
                title: Row(children: [
                  PlayerAvatar(user: player, radius: 20),
                  const SizedBox(width: 12),
                  Text(player.name, style: const TextStyle(color: Colors.white)),
                ]),
                value: player.uid,
                groupValue: state.mvpPlayerId,
                onChanged: (value) {
                  notifier.setMvpPlayerId(value);
                },
                activeColor: PremiumColors.primary,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScorersSelector(LogMatchResultDialogState state) {
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);
    final allPlayers = [...state.teamAPlayers, ...state.teamBPlayers];
    
    return Column(
      children: [
        Text(
          'Step 3: Select Scorers',
          style: PremiumTypography.labelLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final player = allPlayers[index];
              return CheckboxListTile(
                title: Row(children: [
                  PlayerAvatar(user: player, radius: 20),
                  const SizedBox(width: 12),
                  Text(player.name, style: const TextStyle(color: Colors.white)),
                ]),
                value: state.scorerIds.contains(player.uid),
                onChanged: (selected) {
                  notifier.toggleScorer(player.uid);
                },
                activeColor: PremiumColors.primary,
                checkColor: Colors.black,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssistsSelector(LogMatchResultDialogState state) {
    final notifier = ref.read(logMatchResultDialogNotifierProvider(_params).notifier);
    final allPlayers = [...state.teamAPlayers, ...state.teamBPlayers];
    
    return Column(
      children: [
        Text(
          'Step 4: Select Assists',
          style: PremiumTypography.labelLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final player = allPlayers[index];
              return CheckboxListTile(
                title: Row(children: [
                  PlayerAvatar(user: player, radius: 20),
                  const SizedBox(width: 12),
                  Text(player.name, style: const TextStyle(color: Colors.white)),
                ]),
                value: state.assistIds.contains(player.uid),
                onChanged: (selected) {
                  notifier.toggleAssist(player.uid);
                },
                activeColor: PremiumColors.primary,
                checkColor: Colors.black,
              );
            },
          ),
        ),
      ],
    );
  }

  String _generateConfirmationSummary(LogMatchResultDialogState state) {
    if (state.winningTeam == null || state.losingTeam == null) return "Confirm details.";

    final winnerName = state.winningTeam!.name;
    final loserName = state.losingTeam!.name;
    final winnerScore =
        state.winningTeam == state.selectedTeamA ? state.teamAScore : state.teamBScore;
    final loserScore =
        state.losingTeam == state.selectedTeamA ? state.teamAScore : state.teamBScore;

    String summary = '$winnerName beat $loserName $winnerScore - $loserScore.';

    if (state.mvpPlayerId != null) {
      final mvp = widget.players.firstWhere(
        (p) => p.uid == state.mvpPlayerId,
        orElse: () => User(
          uid: '',
          name: 'Unknown',
          email: '',
          birthDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      summary += '\n${mvp.name} was the MVP.';
    }

    if (state.scorerIds.isNotEmpty) {
      final scorerNames = state.scorerIds.map((id) {
        return widget.players
            .firstWhere(
              (p) => p.uid == id,
              orElse: () => User(
                uid: '',
                name: 'Unknown',
                email: '',
                birthDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            )
            .name;
      }).join(', ');
      summary += '\nGoals by: $scorerNames.';
    }
     if (state.assistIds.isNotEmpty) {
      final assistNames = state.assistIds.map((id) {
        return widget.players
            .firstWhere(
              (p) => p.uid == id,
              orElse: () => User(
                uid: '',
                name: 'Unknown',
                email: '',
                birthDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            )
            .name;
      }).join(', ');
      summary += '\nAssists by: $assistNames.';
    }

    return summary;
  }

  Widget _buildConfirmationView(LogMatchResultDialogState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 5: Confirmation',
            style: PremiumTypography.labelLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _generateConfirmationSummary(state),
              style: PremiumTypography.bodyLarge.copyWith(color: Colors.white, height: 1.5),
            ),
          )
        ],
      ),
    );
  }
}
