import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:uuid/uuid.dart';

class LogMatchResultDialog extends StatefulWidget {
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
  State<LogMatchResultDialog> createState() => _LogMatchResultDialogState();
}

class _LogMatchResultDialogState extends State<LogMatchResultDialog> {
  final _pageController = PageController();
  final _uuid = const Uuid();
  int _currentPage = 0;

  // Step 1: Score & Teams
  late FixedExtentScrollController _teamAScrollController;
  late FixedExtentScrollController _teamBScrollController;
  int _teamAScore = 0;
  int _teamBScore = 0;
  Team? _selectedTeamA;
  Team? _selectedTeamB;

  List<User> _teamAPlayers = [];
  List<User> _teamBPlayers = [];
  List<User> _winningTeamPlayers = [];
  Team? _winningTeam;
  Team? _losingTeam;

  // Step 2: MVP
  String? _mvpPlayerId;

  // Step 3: Scorers
  final Set<String> _scorerIds = {};

  // Step 4: Assists
  final Set<String> _assistIds = {};

  @override
  void initState() {
    super.initState();
    _teamAScrollController = FixedExtentScrollController(initialItem: 0);
    _teamBScrollController = FixedExtentScrollController(initialItem: 0);

    if (widget.event.teams.length >= 2) {
      _selectedTeamA = widget.event.teams[0];
      _selectedTeamB = widget.event.teams[1];
      _updatePlayerLists();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _teamAScrollController.dispose();
    _teamBScrollController.dispose();
    super.dispose();
  }

  void _updatePlayerLists() {
    setState(() {
      _teamAPlayers = widget.players
          .where((p) => _selectedTeamA?.playerIds.contains(p.uid) ?? false)
          .toList();
      _teamBPlayers = widget.players
          .where((p) => _selectedTeamB?.playerIds.contains(p.uid) ?? false)
          .toList();
    });
  }

  void _onNext() {
    // --- Step 1 Validation ---
    if (_currentPage == 0) {
      if (_selectedTeamA == null || _selectedTeamB == null) {
        SnackbarHelper.showError(context, 'Please select both teams.');
        return;
      }
      if (_teamAScore == _teamBScore) {
        SnackbarHelper.showError(context, 'Scores cannot be a draw.');
        return;
      }

      final isTeamAWinner = _teamAScore > _teamBScore;
      final winnerScore = isTeamAWinner ? _teamAScore : _teamBScore;
      final loserScore = isTeamAWinner ? _teamBScore : _teamAScore;

      if (winnerScore > 5) {
        SnackbarHelper.showError(
            context, 'Winning team score cannot exceed 5.');
        return;
      }
      if (loserScore > 4) {
        SnackbarHelper.showError(context, 'Losing team score cannot exceed 4.');
        return;
      }

      // Set state for next steps
      setState(() {
        _winningTeam = isTeamAWinner ? _selectedTeamA : _selectedTeamB;
        _losingTeam = isTeamAWinner ? _selectedTeamB : _selectedTeamA;
        _winningTeamPlayers =
            isTeamAWinner ? _teamAPlayers : _teamBPlayers;
      });
    }

    if (_currentPage < 4) {
      // 4 is the confirmation page
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _submit() {
    if (_winningTeam == null || _losingTeam == null) return;

    final winningScore =
        _winningTeam == _selectedTeamA ? _teamAScore : _teamBScore;
    final losingScore =
        _losingTeam == _selectedTeamA ? _teamAScore : _teamBScore;

    final result = MatchResult(
      matchId: _uuid.v4(),
      teamAColor: _winningTeam!.color ?? _winningTeam!.name,
      teamBColor: _losingTeam!.color ?? _losingTeam!.name,
      scoreA: winningScore,
      scoreB: losingScore,
      mvpId: _mvpPlayerId,
      scorerIds: _scorerIds.toList(),
      assistIds: _assistIds.toList(),
      createdAt: DateTime.now(),
      loggedBy: widget.currentUserId,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
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
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildScoreSelector(),
              _buildMvpSelector(),
              _buildScorersSelector(),
              _buildAssistsSelector(),
              _buildConfirmationView(),
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
            child: Text(_currentPage == 4 ? 'Confirm & Save' : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSelector() {
    final scores = List.generate(6, (i) => i); // 0-5
    final teams = widget.event.teams;

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
                  team: _selectedTeamA,
                  otherSelectedTeam: _selectedTeamB,
                  onChanged: (team) {
                    setState(() {
                      _selectedTeamA = team;
                      _updatePlayerLists();
                    });
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
                  team: _selectedTeamB,
                  otherSelectedTeam: _selectedTeamA,
                  onChanged: (team) {
                    setState(() {
                      _selectedTeamB = team;
                      _updatePlayerLists();
                    });
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
                  _selectedTeamA?.name ?? 'Team A', _teamAScrollController, scores,
                  (index) {
                setState(() => _teamAScore = scores[index]);
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
                  _selectedTeamB?.name ?? 'Team B', _teamBScrollController, scores,
                  (index) {
                setState(() => _teamBScore = scores[index]);
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

  Widget _buildMvpSelector() {
    if (_winningTeamPlayers.isEmpty) {
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
          'Step 2: Select MVP (from ${_winningTeam?.name ?? 'Winning Team'})',
          style: PremiumTypography.labelLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _winningTeamPlayers.length,
            itemBuilder: (context, index) {
              final player = _winningTeamPlayers[index];
              return RadioListTile<String>(
                title: Row(children: [
                  PlayerAvatar(user: player, radius: 20),
                  const SizedBox(width: 12),
                  Text(player.name, style: const TextStyle(color: Colors.white)),
                ]),
                value: player.uid,
                groupValue: _mvpPlayerId,
                onChanged: (value) {
                  setState(() {
                    _mvpPlayerId = value;
                  });
                },
                activeColor: PremiumColors.primary,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScorersSelector() {
    final allPlayers = [..._teamAPlayers, ..._teamBPlayers];
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
                value: _scorerIds.contains(player.uid),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _scorerIds.add(player.uid);
                    } else {
                      _scorerIds.remove(player.uid);
                    }
                  });
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

  Widget _buildAssistsSelector() {
    final allPlayers = [..._teamAPlayers, ..._teamBPlayers];
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
                value: _assistIds.contains(player.uid),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _assistIds.add(player.uid);
                    } else {
                      _assistIds.remove(player.uid);
                    }
                  });
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

  String _generateConfirmationSummary() {
    if (_winningTeam == null || _losingTeam == null) return "Confirm details.";

    final winnerName = _winningTeam!.name;
    final loserName = _losingTeam!.name;
    final winnerScore =
        _winningTeam == _selectedTeamA ? _teamAScore : _teamBScore;
    final loserScore =
        _losingTeam == _selectedTeamA ? _teamAScore : _teamBScore;

    String summary = '$winnerName beat $loserName $winnerScore - $loserScore.';

    if (_mvpPlayerId != null) {
      final mvp = widget.players.firstWhere((p) => p.uid == _mvpPlayerId,
          orElse: () => User(uid: '', name: 'Unknown'));
      summary += '\n${mvp.name} was the MVP.';
    }

    if (_scorerIds.isNotEmpty) {
      final scorerNames = _scorerIds.map((id) {
        return widget.players
            .firstWhere((p) => p.uid == id,
                orElse: () => User(uid: '', name: 'Unknown'))
            .name;
      }).join(', ');
      summary += '\nGoals by: $scorerNames.';
    }
     if (_assistIds.isNotEmpty) {
      final assistNames = _assistIds.map((id) {
        return widget.players
            .firstWhere((p) => p.uid == id,
                orElse: () => User(uid: '', name: 'Unknown'))
            .name;
      }).join(', ');
      summary += '\nAssists by: $assistNames.';
    }

    return summary;
  }

  Widget _buildConfirmationView() {
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
              _generateConfirmationSummary(),
              style: PremiumTypography.bodyLarge.copyWith(color: Colors.white, height: 1.5),
            ),
          )
        ],
      ),
    );
  }
}
