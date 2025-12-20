import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/utils/dummy_players_creator.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/data/repositories_providers.dart';

/// Debug screen to generate dummy players for testing
class CreateDummyPlayersScreen extends ConsumerStatefulWidget {
  const CreateDummyPlayersScreen({super.key});

  @override
  ConsumerState<CreateDummyPlayersScreen> createState() =>
      _CreateDummyPlayersScreenState();
}

class _CreateDummyPlayersScreenState
    extends ConsumerState<CreateDummyPlayersScreen> {
  final _hubIdController = TextEditingController();
  final _eventIdController = TextEditingController();
  final _playerCountController = TextEditingController(text: '15');
  bool _isRunning = false;
  String? _statusMessage;

  @override
  void dispose() {
    _hubIdController.dispose();
    _eventIdController.dispose();
    _playerCountController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final hubId = _hubIdController.text.trim();
    final eventId = _eventIdController.text.trim();
    final playerCountText = _playerCountController.text.trim();

    // Get current user UID
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      setState(() => _statusMessage = '❌ You must be logged in');
      return;
    }

    if (hubId.isEmpty) {
      setState(() => _statusMessage = '❌ Hub ID required');
      return;
    }

    int playerCount = 15; // Default for events
    if (playerCountText.isNotEmpty) {
      playerCount = int.tryParse(playerCountText) ?? 15;
      if (playerCount < 1 || playerCount > 50) {
        setState(() => _statusMessage = '❌ Player count must be between 1-50');
        return;
      }
    } else if (eventId.isEmpty) {
      playerCount = 10; // Default when no event specified
    }

    setState(() {
      _isRunning = true;
      _statusMessage = 'יוצר $playerCount שחקני דמה...';
    });

    try {
      final creator = DummyPlayersCreator(
        hubId: hubId,
        managerId: currentUser.uid,
      );

      List<String> playerIds;
      if (eventId.isNotEmpty) {
        // Use convenience method to create and register in one call
        playerIds = await creator.createAndRegisterToEvent(
          eventId,
          playerCount: playerCount,
        );
        setState(() => _statusMessage =
            '✅ נוצרו $playerCount שחקני דמה ונרשמו לאירוע $eventId!');
      } else {
        // Just create players
        playerIds = await creator.createDummyPlayers(count: playerCount);
        setState(() => _statusMessage =
            '✅ נוצרו ${playerIds.length} שחקני דמה בהאב $hubId!');
      }
    } catch (e) {
      setState(() => _statusMessage = '❌ שגיאה: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;

    return PremiumScaffold(
      title: 'יצירת שחקני דמה',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentUser != null) ...[
                      Text(
                        'מחובר כ: ${currentUser.email ?? currentUser.uid}',
                        style: PremiumTypography.bodySmall.copyWith(
                          color: PremiumColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _hubIdController,
                      decoration: const InputDecoration(
                        labelText: 'Hub ID',
                        hintText: 'הכנס מזהה של Hub',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _eventIdController,
                      decoration: const InputDecoration(
                        labelText: 'Event ID (אופציונלי)',
                        hintText: 'אם תרצה לרשום את השחקנים לאירוע',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _playerCountController,
                      decoration: const InputDecoration(
                        labelText: 'מספר שחקנים',
                        hintText: 'ברירת מחדל: 15 לאירוע, 10 ללא אירוע',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _run,
                        icon: _isRunning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isRunning ? 'יוצר...' : 'צור שחקני דמה'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage!,
                        style: PremiumTypography.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
