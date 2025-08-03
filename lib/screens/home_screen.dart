import 'package:flutter/material.dart';
import 'package:kickabout/models/player.dart';
import 'package:kickabout/models/game.dart';
import 'package:kickabout/services/player_service.dart';
import 'package:kickabout/services/game_service.dart';
import 'package:kickabout/services/player_stats_service.dart';
import 'package:kickabout/models/player_stats.dart';
import 'package:kickabout/screens/player_management_screen.dart';
import 'package:kickabout/screens/team_formation_screen.dart';
import 'package:kickabout/widgets/player_card.dart';\nimport 'package:kickabout/screens/player_profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final PlayerService _playerService = PlayerService();
  final GameService _gameService = GameService();
  final PlayerStatsService _statsService = PlayerStatsService();
  
  List<Player> _players = [];
  List<Game> _recentGames = [];
  Map<String, PlayerStats?> _latestStats = {};
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final players = await _playerService.getPlayers();
      final games = await _gameService.getRecentGames(limit: 5);
      
      // Load latest stats for each player
      final latestStats = <String, PlayerStats?>{};
      for (final player in players) {
        latestStats[player.id] = await _statsService.getLatestPlayerStats(player.id);
      }
      
      setState(() {
        _players = players;
        _recentGames = games;
        _latestStats = latestStats;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, size: 28),
            const SizedBox(width: 8),
            Text(
              'Kickabout',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => _navigateToPlayerManagement(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildTopPlayers(),
                      const SizedBox(height: 24),
                      _buildRecentGames(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚽ Ready to Play?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Organize fair teams and track your soccer performance',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_players.length} Players',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.sports,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_recentGames.length} Recent Games',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Start New Game',
                subtitle: 'Form teams & play',
                icon: Icons.add_circle,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _navigateToTeamFormation(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Manage Players',
                subtitle: 'Add or edit players',
                icon: Icons.group_add,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _navigateToPlayerManagement(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPlayers() {
    if (_players.isEmpty) {
      return const SizedBox.shrink();
    }

    final topPlayers = List<Player>.from(_players)
      ..sort((a, b) => b.currentRankScore.compareTo(a.currentRankScore))
      ..take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Players',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToPlayerManagement(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topPlayers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < topPlayers.length - 1 ? 12 : 0),
                child: PlayerCard(
                  player: topPlayers[index],
                  showRank: true,
                  rank: index + 1,
                  showRadarChart: false,
                  latestStats: _latestStats[topPlayers[index].id],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerProfileScreen(player: topPlayers[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGames() {
    if (_recentGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Games',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_recentGames.length, (index) {
          final game = _recentGames[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Game ${game.gameDate.day}/${game.gameDate.month}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text('${game.playerIds.length} players'),
              trailing: Chip(
                label: Text(
                  game.status.name,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: _getStatusColor(game.status).withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.completed:
        return Colors.green;
      case GameStatus.inProgress:
        return Colors.blue;
      case GameStatus.teamsFormed:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _navigateToPlayerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerManagementScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToTeamFormation() {
    if (_players.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least 4 players to start a game'),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamFormationScreen(availablePlayers: _players),
      ),
    ).then((_) => _loadData());
  }
}