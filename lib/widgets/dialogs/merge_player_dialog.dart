import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/services/player_merge_service.dart';

/// Dialog for merging a manual player into a real user account
///
/// Allows hub managers to:
/// - Select a manual player
/// - Select or search for a real user
/// - Preview combined statistics
/// - Confirm the merge operation
class MergePlayerDialog extends ConsumerStatefulWidget {
  final String hubId;
  final List<User> manualPlayers;
  final UsersRepository usersRepo;

  const MergePlayerDialog({
    super.key,
    required this.hubId,
    required this.manualPlayers,
    required this.usersRepo,
  });

  @override
  ConsumerState<MergePlayerDialog> createState() => _MergePlayerDialogState();
}

class _MergePlayerDialogState extends ConsumerState<MergePlayerDialog> {
  User? _selectedManualPlayer;
  User? _selectedRealUser;
  bool _isLoading = false;
  bool _isValidating = false;
  String? _validationError;
  List<Game> _conflictingGames = [];

  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRealUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Search for users by name or email (excluding manual players)
      final allUsers = await widget.usersRepo.searchUsers(query);
      final realUsers =
          allUsers.where((u) => !u.email.startsWith('manual_')).toList();

      setState(() {
        _searchResults = realUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _validateMerge() async {
    if (_selectedManualPlayer == null || _selectedRealUser == null) {
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
      _conflictingGames = [];
    });

    try {
      final service = PlayerMergeService();
      final result = await service.validateMerge(
        manualPlayerId: _selectedManualPlayer!.uid,
        realUserId: _selectedRealUser!.uid,
      );

      setState(() {
        _isValidating = false;
        if (!result.isValid) {
          _validationError = result.errorMessage;
          _conflictingGames = result.conflictingGames;
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = 'שגיאה בבדיקה: $e';
      });
    }
  }

  Future<void> _performMerge() async {
    if (_selectedManualPlayer == null || _selectedRealUser == null) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('אישור מיזוג'),
        content: Text(
          'האם אתה בטוח שברצונך למזג את "${_selectedManualPlayer!.name}" '
          'אל "${_selectedRealUser!.name}"?\n\n'
          'פעולה זו לא ניתנת לביטול.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('מזג'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final service = PlayerMergeService();
      await service.mergePlayers(
        manualPlayerId: _selectedManualPlayer!.uid,
        realUserId: _selectedRealUser!.uid,
        hubId: widget.hubId,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה במיזוג: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canMerge = _selectedManualPlayer != null &&
        _selectedRealUser != null &&
        _validationError == null &&
        !_isValidating;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.merge_type, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text('מזג שחקן ידני', style: theme.textTheme.headlineMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: Select Manual Player
            Text('1. בחר שחקן ידני:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<User>(
              initialValue: _selectedManualPlayer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'שחקן ידני',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: widget.manualPlayers.map((player) {
                return DropdownMenuItem(
                  value: player,
                  child: Text('${player.name} (${player.gamesPlayed} משחקים)'),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (user) {
                      setState(() {
                        _selectedManualPlayer = user;
                        _validationError = null;
                        _conflictingGames = [];
                      });
                      if (_selectedRealUser != null) {
                        _validateMerge();
                      }
                    },
            ),
            const SizedBox(height: 24),

            // Step 2: Search Real User
            Text('2. חפש משתמש אמיתי:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              enabled: !_isLoading && _selectedManualPlayer != null,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'חפש לפי שם או אימייל',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _searchRealUsers,
            ),
            const SizedBox(height: 8),

            // Search Results
            if (_searchResults.isNotEmpty) ...[
              const Text('תוצאות חיפוש:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isSelected = _selectedRealUser?.uid == user.uid;
                    return ListTile(
                      selected: isSelected,
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle:
                          Text('${user.email}\n${user.gamesPlayed} משחקים'),
                      isThreeLine: true,
                      onTap: () {
                        setState(() {
                          _selectedRealUser = user;
                          _searchResults = [];
                          _searchController.clear();
                          _validationError = null;
                          _conflictingGames = [];
                        });
                        _validateMerge();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Selected Real User
            if (_selectedRealUser != null) ...[
              const Text('משתמש נבחר:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _selectedRealUser!.photoUrl != null
                        ? NetworkImage(_selectedRealUser!.photoUrl!)
                        : null,
                    child: _selectedRealUser!.photoUrl == null
                        ? Text(_selectedRealUser!.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(_selectedRealUser!.name),
                  subtitle: Text(_selectedRealUser!.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _selectedRealUser = null;
                              _validationError = null;
                              _conflictingGames = [];
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Validation Status
            if (_isValidating) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('בודק אפשרות למיזוג...'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (_validationError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_validationError!,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              if (_conflictingGames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('משחקים סותרים (${_conflictingGames.length}):',
                    style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
            ],

            // Preview (if both selected and valid)
            if (_selectedManualPlayer != null &&
                _selectedRealUser != null &&
                _validationError == null) ...[
              const Text('תצוגה מקדימה:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'משחקים',
                        _selectedManualPlayer!.gamesPlayed,
                        _selectedRealUser!.gamesPlayed,
                      ),
                      _buildStatRow(
                        'ניצחונות',
                        _selectedManualPlayer!.wins,
                        _selectedRealUser!.wins,
                      ),
                      _buildStatRow(
                        'שערים',
                        _selectedManualPlayer!.goals,
                        _selectedRealUser!.goals,
                      ),
                      _buildStatRow(
                        'בישולים',
                        _selectedManualPlayer!.assists,
                        _selectedRealUser!.assists,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('ביטול'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: canMerge && !_isLoading ? _performMerge : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('מזג שחקנים'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int manualValue, int realValue) {
    final combined = manualValue + realValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text('$manualValue', style: const TextStyle(color: Colors.grey)),
              const Text(' + ', style: TextStyle(color: Colors.grey)),
              Text('$realValue', style: const TextStyle(color: Colors.grey)),
              const Text(' = '),
              Text('$combined',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
