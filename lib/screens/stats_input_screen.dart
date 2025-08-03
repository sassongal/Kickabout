import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kickabout/models/player.dart';
import 'package:kickabout/models/game.dart';
import 'package:kickabout/models/player_stats.dart';
import 'package:kickabout/services/game_service.dart';
import 'package:kickabout/services/player_service.dart';
import 'package:kickabout/services/player_stats_service.dart';
import 'package:kickabout/services/ranking_service.dart';

class StatsInputScreen extends StatefulWidget {
  final Game game;
  final List<Player> players;

  const StatsInputScreen({super.key, required this.game, required this.players});

  @override
  State<StatsInputScreen> createState() => _StatsInputScreenState();
}

class _StatsInputScreenState extends State<StatsInputScreen> with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  final PlayerService _playerService = PlayerService();
  final PlayerStatsService _statsService = PlayerStatsService();
  final PageController _pageController = PageController();
  
  int _currentPlayerIndex = 0;
  bool _isSubmitting = false;
  
  final Map<String, double> _playerRatings = {};
  
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  final List<StatCategory> _statCategories = [
    StatCategory('Defense', Icons.shield, 'How well did they defend?'),
    StatCategory('Passing', Icons.swap_horiz, 'Quality of their passes'),
    StatCategory('Shooting', Icons.sports_soccer, 'Shooting accuracy & power'),
    StatCategory('Dribbling', Icons.sports_handball, 'Ball control & dribbling skills'),
    StatCategory('Physical', Icons.fitness_center, 'Pace, strength, and stamina'),
    StatCategory('Leadership', Icons.star, 'Did they lead the team?'),
    StatCategory('Team Play', Icons.group, 'How well did they work with others?'),
    StatCategory('Consistency', Icons.trending_up, 'How consistent was their performance?'),
  ];

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeInOut),
    );
    
    // Initialize ratings
    for (final player in widget.players) {
      for (final category in _statCategories) {
        _playerRatings['${player.id}_${category.key}'] = 5.0;
      }
    }
    
    _updateProgress();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentPlayerIndex + 1) / widget.players.length;
    _progressAnimationController.animateTo(progress);
  }

  void _nextPlayer() {
    if (_currentPlayerIndex < widget.players.length - 1) {
      setState(() {
        _currentPlayerIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    } else {
      _submitAllRatings();
    }
  }

  void _previousPlayer() {
    if (_currentPlayerIndex > 0) {
      setState(() {
        _currentPlayerIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  Future<void> _submitAllRatings() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final gameStats = <PlayerStats>[];
      
      for (final player in widget.players) {
        final stats = PlayerStats(
          playerId: player.id,
          gameId: widget.game.id,
          defense: _playerRatings['${player.id}_Defense'] ?? 5.0,
          passing: _playerRatings['${player.id}_Passing'] ?? 5.0,
          shooting: _playerRatings['${player.id}_Shooting'] ?? 5.0,
          dribbling: _playerRatings['${player.id}_Dribbling'] ?? 5.0,
          physical: _playerRatings['${player.id}_Physical'] ?? 5.0,
          leadership: _playerRatings['${player.id}_Leadership'] ?? 5.0,
          teamPlay: _playerRatings['${player.id}_Team Play'] ?? 5.0,
          consistency: _playerRatings['${player.id}_Consistency'] ?? 5.0,
          gameDate: widget.game.gameDate,
          isVerified: true, // For MVP, we'll auto-verify
          submittedBy: 'current_user', // In a real app, this would be the current user's ID
        );
        gameStats.add(stats);
      }

      // Save player stats
      for (final stats in gameStats) {
        await _statsService.addPlayerStats(stats);
      }
      
      // Update game with stats
      final updatedGame = widget.game.copyWith(
        status: GameStatus.statsInput,
        gameStats: gameStats,
      );
      await _gameService.saveGame(updatedGame);

      // Update player rankings with enhanced algorithm
      await _updatePlayerRankingsEnhanced(gameStats);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚽ Game stats saved! Player rankings updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving stats: $e')),
        );
      }
    }
  }

  Future<void> _updatePlayerRankingsEnhanced(List<PlayerStats> gameStats) async {
    final allGames = await _gameService.getRecentGames(limit: 50);
    
    for (final stats in gameStats) {
      final player = widget.players.firstWhere((p) => p.id == stats.playerId);
      
      // Get all player stats for enhanced ranking calculation
      final playerStats = await _statsService.getPlayerStats(player.id);
      
      // Use the enhanced ranking service
      final updatedPlayer = RankingService.updatePlayerWithEnhancedMetrics(
        player,
        [...playerStats, stats], // Include the new stats
        allGames,
      );
      
      await _playerService.updatePlayer(updatedPlayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Players'),
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 4),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ),
      body: _isSubmitting 
          ? _buildSubmittingScreen()
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPlayerIndex = index;
                });
                _updateProgress();
              },
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                return _buildPlayerRatingPage(widget.players[index]);
              },
            ),
      bottomNavigationBar: _isSubmitting 
          ? null 
          : _buildBottomNavigation(),
    );
  }

  Widget _buildSubmittingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Saving game stats...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Updating player rankings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRatingPage(Player player) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerHeader(player),
          const SizedBox(height: 24),
          Text(
            'Rate ${player.name.split(' ').first}\'s Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate each aspect of their performance from 1-10',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ..._statCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildRatingCard(player, category),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(Player player) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  player.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.attributes.preferredPosition,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Current: ${player.currentRankScore.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${_currentPlayerIndex + 1}/${widget.players.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Player player, StatCategory category) {
    final ratingKey = '${player.id}_${category.key}';
    final currentRating = _playerRatings[ratingKey] ?? 5.0;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(currentRating).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(currentRating),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: currentRating,
              minRating: 1,
              maxRating: 10,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 10,
              itemSize: 28,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2),
              itemBuilder: (context, index) {
                return Icon(
                  Icons.star,
                  color: _getRatingColor(index + 1.0),
                );
              },
              onRatingUpdate: (rating) {
                setState(() {
                  _playerRatings[ratingKey] = rating;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Poor',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Excellent',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastPlayer = _currentPlayerIndex == widget.players.length - 1;
    
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
      child: Row(
        children: [
          if (_currentPlayerIndex > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPlayer,
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentPlayerIndex > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _nextPlayer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isLastPlayer 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                isLastPlayer ? 'Finish & Save' : 'Next Player',
                style: TextStyle(
                  color: isLastPlayer ? Colors.white : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.orange;
    if (rating >= 4) return Colors.grey;
    return Colors.red;
  }
}

class StatCategory {
  final String name;
  final IconData icon;
  final String description;

  StatCategory(this.name, this.icon, this.description);

  String get key => name;
}