import 'package:flutter/material.dart';
import 'package:kickabout/models/player.dart';
import 'package:kickabout/models/game.dart';
import 'package:kickabout/services/game_service.dart';
import 'package:kickabout/utils/team_algorithm.dart';
import 'package:kickabout/widgets/player_card.dart';
import 'package:kickabout/screens/stats_input_screen.dart';

class TeamFormationScreen extends StatefulWidget {
  final List<Player> availablePlayers;

  const TeamFormationScreen({super.key, required this.availablePlayers});

  @override
  State<TeamFormationScreen> createState() => _TeamFormationScreenState();
}

class _TeamFormationScreenState extends State<TeamFormationScreen> with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  final TextEditingController _searchController = TextEditingController();
  
  final List<Player> _selectedPlayers = [];
  List<Player> _filteredPlayers = [];
  Map<String, Team>? _formedTeams;
  bool _isFormingTeams = false;
  Game? _currentGame;
  
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _filteredPlayers = widget.availablePlayers;
    _searchController.addListener(_filterPlayers);
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _filterPlayers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlayers = widget.availablePlayers.where((player) {
        return player.name.toLowerCase().contains(query) ||
               player.attributes.preferredPosition.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _togglePlayerSelection(Player player) {
    setState(() {
      if (_selectedPlayers.contains(player)) {
        _selectedPlayers.remove(player);
      } else {
        _selectedPlayers.add(player);
      }
    });
  }

  Future<void> _formTeams() async {
    if (_selectedPlayers.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 4 players to form teams')),
      );
      return;
    }

    setState(() {
      _isFormingTeams = true;
    });

    try {
      // Simulate team formation processing
      await Future.delayed(const Duration(milliseconds: 800));
      
      final teams = TeamAlgorithm.createBalancedTeams(_selectedPlayers);
      
      // Create and save the game
      final game = Game(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        gameDate: DateTime.now(),
        playerIds: _selectedPlayers.map((p) => p.id).toList(),
        teams: teams,
        status: GameStatus.teamsFormed,
      );
      
      await _gameService.saveGame(game);
      
      setState(() {
        _formedTeams = teams;
        _currentGame = game;
        _isFormingTeams = false;
      });
      
      _slideAnimationController.forward();
    } catch (e) {
      setState(() {
        _isFormingTeams = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error forming teams: $e')),
        );
      }
    }
  }

  void _shuffleTeams() async {
    setState(() {
      _isFormingTeams = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    
    final teams = TeamAlgorithm.createBalancedTeams(_selectedPlayers);
    
    if (_currentGame != null) {
      final updatedGame = _currentGame!.copyWith(teams: teams);
      await _gameService.saveGame(updatedGame);
      setState(() {
        _formedTeams = teams;
        _currentGame = updatedGame;
      });
    }
    
    setState(() {
      _isFormingTeams = false;
    });
  }

  void _startGame() async {
    if (_currentGame != null) {
      final updatedGame = _currentGame!.copyWith(status: GameStatus.inProgress);
      await _gameService.saveGame(updatedGame);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game started! Have fun playing!')),
        );
      }
    }
  }

  void _finishGame() async {
    if (_currentGame != null) {
      final updatedGame = _currentGame!.copyWith(status: GameStatus.completed);
      await _gameService.saveGame(updatedGame);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StatsInputScreen(game: updatedGame, players: _selectedPlayers),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formedTeams == null ? 'Select Players' : 'Teams Formed'),
        actions: _formedTeams == null ? [] : [
          if (_currentGame?.status == GameStatus.teamsFormed)
            TextButton(
              onPressed: _startGame,
              child: const Text('Start Game'),
            ),
          if (_currentGame?.status == GameStatus.inProgress)
            TextButton(
              onPressed: _finishGame,
              child: const Text('Finish Game'),
            ),
        ],
      ),
      body: _formedTeams == null 
          ? _buildPlayerSelection()
          : _buildTeamsDisplay(),
      bottomNavigationBar: _formedTeams == null 
          ? _buildSelectionBottomBar()
          : null,
    );
  }

  Widget _buildPlayerSelection() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildSelectedPlayersChips(),
        Expanded(
          child: _filteredPlayers.isEmpty
              ? _buildEmptyState()
              : _buildPlayersList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search players...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildSelectedPlayersChips() {
    if (_selectedPlayers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected (${_selectedPlayers.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedPlayers.map((player) {
              return Chip(
                label: Text(player.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _togglePlayerSelection(player),
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = _filteredPlayers[index];
        final isSelected = _selectedPlayers.contains(player);
        
        return PlayerCard(
          player: player,
          isSelected: isSelected,
          onTap: () => _togglePlayerSelection(player),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No players found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBottomBar() {
    final canFormTeams = _selectedPlayers.length >= 4;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedPlayers.length} players selected',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!canFormTeams)
                Text(
                  'Need ${4 - _selectedPlayers.length} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormingTeams || !canFormTeams ? null : _formTeams,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isFormingTeams
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Forming Teams...'),
                      ],
                    )
                  : const Text('Form Teams'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsDisplay() {
    if (_formedTeams == null) return const SizedBox.shrink();
    
    final analysis = TeamAlgorithm.getTeamBalanceAnalysis(_formedTeams!);
    final isBalanced = TeamAlgorithm.areTeamsBalanced(_formedTeams!);
    
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceIndicator(isBalanced, analysis),
            const SizedBox(height: 24),
            ..._formedTeams!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTeamCard(entry.key, entry.value),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isFormingTeams ? null : _shuffleTeams,
                    icon: _isFormingTeams 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shuffle),
                    label: const Text('Shuffle Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentGame?.status == GameStatus.inProgress 
                        ? _finishGame 
                        : _startGame,
                    icon: Icon(
                      _currentGame?.status == GameStatus.inProgress 
                          ? Icons.stop 
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      _currentGame?.status == GameStatus.inProgress 
                          ? 'Finish Game' 
                          : 'Start Game',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceIndicator(bool isBalanced, Map<String, double> analysis) {
    return Card(
      elevation: 0,
      color: isBalanced 
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isBalanced ? Icons.check_circle : Icons.warning,
              color: isBalanced ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBalanced ? 'Teams are Balanced!' : 'Teams Slightly Unbalanced',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isBalanced ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ${(analysis['balancePercentage']! * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(String teamName, Team team) {
    final teamPlayers = _selectedPlayers.where((p) => team.playerIds.contains(p.id)).toList();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getTeamColor(teamName).withValues(alpha: 0.1),
              _getTeamColor(teamName).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTeamColor(teamName),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _getTeamColor(teamName),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team.totalScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getTeamColor(teamName),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...teamPlayers.map((player) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getTeamColor(teamName).withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Text(
                          player.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getTeamColor(teamName),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${player.attributes.preferredPosition} • ${player.currentRankScore.toStringAsFixed(1)}★',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getTeamColor(String teamName) {
    switch (teamName) {
      case 'Team A':
        return Colors.blue;
      case 'Team B':
        return Colors.red;
      case 'Team C':
        return Colors.green;
      case 'Team D':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}