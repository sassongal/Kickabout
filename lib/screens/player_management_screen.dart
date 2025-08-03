import 'package:flutter/material.dart';
import 'package:kickabout/models/player.dart';
import 'package:kickabout/services/player_service.dart';
import 'package:kickabout/widgets/player_card.dart';
import 'package:kickabout/screens/player_profile_screen.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final PlayerService _playerService = PlayerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Player> _allPlayers = [];
  List<Player> _filteredPlayers = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // 'name', 'rank', 'position'

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _searchController.addListener(_filterPlayers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await _playerService.getPlayers();
      setState(() {
        _allPlayers = players;
        _filteredPlayers = players;
        _isLoading = false;
      });
      _sortPlayers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPlayers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlayers = _allPlayers.where((player) {
        return player.name.toLowerCase().contains(query) ||
               player.attributes.preferredPosition.toLowerCase().contains(query);
      }).toList();
    });
    _sortPlayers();
  }

  void _sortPlayers() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredPlayers.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'rank':
          _filteredPlayers.sort((a, b) => b.currentRankScore.compareTo(a.currentRankScore));
          break;
        case 'position':
          _filteredPlayers.sort((a, b) => a.attributes.preferredPosition.compareTo(b.attributes.preferredPosition));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortPlayers();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'rank', child: Text('Sort by Rank')),
              const PopupMenuItem(value: 'position', child: Text('Sort by Position')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayerDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildPlayerStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlayers.isEmpty
                    ? _buildEmptyState()
                    : _buildPlayersList(),
          ),
        ],
      ),
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

  Widget _buildPlayerStats() {
    if (_allPlayers.isEmpty) return const SizedBox.shrink();
    
    final avgRank = _allPlayers.fold<double>(0, (sum, p) => sum + p.currentRankScore) / _allPlayers.length;
    final positions = <String, int>{};
    for (final player in _allPlayers) {
      positions[player.attributes.preferredPosition] = 
          (positions[player.attributes.preferredPosition] ?? 0) + 1;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${_allPlayers.length}',
            'Total Players',
            Icons.people,
          ),
          _buildStatItem(
            avgRank.toStringAsFixed(1),
            'Avg Rank',
            Icons.star,
          ),
          _buildStatItem(
            '${positions.length}',
            'Positions',
            Icons.sports,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty 
                ? 'No players yet'
                : 'No players found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Add your first player to get started'
                : 'Try a different search term',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddPlayerDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = _filteredPlayers[index];
        return PlayerCard(
          player: player,
          showRank: _sortBy == 'rank',
          rank: _sortBy == 'rank' ? index + 1 : null,
          onTap: () => _navigateToPlayerProfile(player),
          onLongPress: () => _showPlayerOptions(player),
        );
      },
    );
  }

  void _showPlayerOptions(Player player) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                _navigateToPlayerProfile(player);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Player'),
              onTap: () {
                Navigator.pop(context);
                _showEditPlayerDialog(player);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Player', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(player);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => _PlayerFormDialog(
        onSave: (player) async {
          await _playerService.addPlayer(player);
          _loadPlayers();
        },
      ),
    );
  }

  void _showEditPlayerDialog(Player player) {
    showDialog(
      context: context,
      builder: (context) => _PlayerFormDialog(
        player: player,
        onSave: (updatedPlayer) async {
          await _playerService.updatePlayer(updatedPlayer);
          _loadPlayers();
        },
      ),
    );
  }

  void _showDeleteConfirmation(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text('Are you sure you want to delete ${player.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _playerService.deletePlayer(player.id);
              _loadPlayers();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToPlayerProfile(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerProfileScreen(player: player),
      ),
    );
  }
}

class _PlayerFormDialog extends StatefulWidget {
  final Player? player;
  final Function(Player) onSave;

  const _PlayerFormDialog({
    this.player,
    required this.onSave,
  });

  @override
  State<_PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<_PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedPosition = 'Midfielder';
  int _speed = 5;
  int _strength = 5;

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.player != null) {
      _nameController.text = widget.player!.name;
      _selectedPosition = widget.player!.attributes.preferredPosition;
      _speed = widget.player!.attributes.speed;
      _strength = widget.player!.attributes.strength;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.player == null ? 'Add Player' : 'Edit Player'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPosition,
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
              ),
              items: _positions.map((position) {
                return DropdownMenuItem(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPosition = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildStatSlider('Speed', _speed, (value) => setState(() => _speed = value)),
            const SizedBox(height: 8),
            _buildStatSlider('Strength', _strength, (value) => setState(() => _strength = value)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePlayer,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildStatSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value/10'),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (val) => onChanged(val.round()),
        ),
      ],
    );
  }

  void _savePlayer() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final player = Player(
      id: widget.player?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      currentRankScore: widget.player?.currentRankScore ?? 5.0,
      attributes: PlayerAttributes(
        preferredPosition: _selectedPosition,
        speed: _speed,
        strength: _strength,
      ),
      createdAt: widget.player?.createdAt ?? DateTime.now(),
      rankingHistory: widget.player?.rankingHistory ?? [],
    );

    widget.onSave(player);
    Navigator.pop(context);
  }
}