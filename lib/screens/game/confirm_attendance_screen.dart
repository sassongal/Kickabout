import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:intl/intl.dart';

/// Screen for confirming/canceling attendance to a game
class ConfirmAttendanceScreen extends ConsumerStatefulWidget {
  final String gameId;

  const ConfirmAttendanceScreen({
    super.key,
    required this.gameId,
  });

  @override
  ConsumerState<ConfirmAttendanceScreen> createState() =>
      _ConfirmAttendanceScreenState();
}

class _ConfirmAttendanceScreenState
    extends ConsumerState<ConfirmAttendanceScreen> {
  bool _isLoading = false;
  bool? _currentStatus; // null = pending, true = confirmed, false = cancelled

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final signupsRepo = ref.read(signupsRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) return;

      final signup = await signupsRepo.getSignup(widget.gameId, currentUserId);
      if (signup != null && mounted) {
        setState(() {
          _currentStatus = signup.status == SignupStatus.confirmed;
        });
      }
    } catch (e) {
      debugPrint('Failed to load current status: $e');
    }
  }

  Future<void> _confirmAttendance() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      SnackbarHelper.showError(
        context,
        'נא להתחבר כדי לאשר הגעה',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final signupsRepo = ref.read(signupsRepositoryProvider);
      await signupsRepo.setSignup(
        widget.gameId,
        currentUserId,
        SignupStatus.confirmed,
      );

      if (mounted) {
        setState(() {
          _currentStatus = true;
          _isLoading = false;
        });
        SnackbarHelper.showSuccess(
          context,
          'הגעה אושרה בהצלחה!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _cancelAttendance() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      SnackbarHelper.showError(
        context,
        'נא להתחבר כדי לבטל הגעה',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול הגעה'),
        content: const Text('האם אתה בטוח שברצונך לבטל את הגעתך למשחק?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('אישור'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final signupsRepo = ref.read(signupsRepositoryProvider);
      await signupsRepo.setSignup(
        widget.gameId,
        currentUserId,
        SignupStatus.pending,
      );

      if (mounted) {
        setState(() {
          _currentStatus = false;
          _isLoading = false;
        });
        SnackbarHelper.showSuccess(
          context,
          'הגעה בוטלה',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final gameStream = gamesRepo.watchGame(widget.gameId);

    return AppScaffold(
      title: 'אישור הגעה',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = snapshot.data;
          if (game == null) {
            return const Center(
              child: Text('משחק לא נמצא'),
            );
          }

          final gameDate = DateFormat('dd/MM/yyyy HH:mm').format(game.gameDate);
          final isPast = game.gameDate.isBefore(DateTime.now());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Game info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.denormalized.hubName ?? 'משחק',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(gameDate),
                          ],
                        ),
                        if (game.denormalized.venueName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(game.denormalized.venueName!)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status indicator
                if (_currentStatus != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _currentStatus == true
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentStatus == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _currentStatus == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _currentStatus == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentStatus == true
                                ? 'הגעה מאושרת'
                                : 'הגעה בוטלה',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _currentStatus == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                if (!isPast) ...[
                  if (_currentStatus != true)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _confirmAttendance,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('אשר הגעה'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  if (_currentStatus != false) ...[
                    if (_currentStatus != true) const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _cancelAttendance,
                      icon: const Icon(Icons.cancel),
                      label: const Text('בטל הגעה'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'המשחק כבר התקיים',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
