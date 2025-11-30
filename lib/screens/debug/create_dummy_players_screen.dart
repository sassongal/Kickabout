import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/utils/dummy_players_creator.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
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
  bool _isRunning = false;
  String? _statusMessage;

  @override
  void dispose() {
    _hubIdController.dispose();
    _eventIdController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final hubId = _hubIdController.text.trim();
    final eventId = _eventIdController.text.trim();

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

    setState(() {
      _isRunning = true;
      _statusMessage = 'Creating dummy players...';
    });

    try {
      final creator = DummyPlayersCreator(
        hubId: hubId,
        managerId: currentUser.uid,
      );
      final playerIds = await creator.createDummyPlayers();
      if (eventId.isNotEmpty) {
        await creator.registerPlayersToEvent(eventId, playerIds);
      }
      setState(() => _statusMessage =
          '✅ Created ${playerIds.length} dummy players${eventId.isNotEmpty ? ' and registered to event' : ''}!');
    } catch (e) {
      setState(() => _statusMessage = '❌ Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;

    return FuturisticScaffold(
      title: 'יצירת שחקני דמה',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentUser != null) ...[
                      Text(
                        'מחובר כ: ${currentUser.email ?? currentUser.uid}',
                        style: FuturisticTypography.bodySmall.copyWith(
                          color: FuturisticColors.accent,
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
                          backgroundColor: FuturisticColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage!,
                        style: FuturisticTypography.bodyMedium,
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
