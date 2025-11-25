import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Event Management Screen - "The Session Dashboard"
///
/// This screen allows managers to:
/// 1. View aggregate wins scoreboard (Blue: 6, Red: 4, Green: 2)
/// 2. Log individual match results during the session
/// 3. Keep the screen open during the 2-hour session
class EventManagementScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const EventManagementScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<EventManagementScreen> createState() =>
      _EventManagementScreenState();
}

class _EventManagementScreenState extends ConsumerState<EventManagementScreen> {
  HubEvent? _event;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final event =
          await hubEventsRepo.getHubEvent(widget.hubId, widget.eventId);

      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _logMatchResult() async {
    if (_event == null || _event!.teams.isEmpty) {
      SnackbarHelper.showError(context, 'אין קבוצות מוגדרות לאירוע');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _LogMatchDialog(event: _event!),
    );

    if (result == null) return;

    setState(() => _isSubmitting = true);

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final firestore = FirebaseFirestore.instance;
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      final teamAColor = result['teamAColor'] as String;
      final teamBColor = result['teamBColor'] as String;
      final scoreA = result['scoreA'] as int;
      final scoreB = result['scoreB'] as int;

      // Determine winner
      String? winnerColor;
      if (scoreA > scoreB) {
        winnerColor = teamAColor;
      } else if (scoreB > scoreA) {
        winnerColor = teamBColor;
      }

      // Create match result
      final matchId = firestore.collection('temp').doc().id; // Generate ID
      final matchResult = MatchResult(
        matchId: matchId,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
        scoreA: scoreA,
        scoreB: scoreB,
        createdAt: DateTime.now(),
        loggedBy: currentUserId,
      );

      // Update aggregate wins
      final currentWins = Map<String, int>.from(_event!.aggregateWins);
      if (winnerColor != null) {
        currentWins[winnerColor] = (currentWins[winnerColor] ?? 0) + 1;
      }

      // Add match to list
      final updatedMatches = List<MatchResult>.from(_event!.matches)
        ..add(matchResult);

      // Update event
      await hubEventsRepo.updateHubEvent(
        widget.hubId,
        widget.eventId,
        {
          'matches': updatedMatches.map((m) => m.toJson()).toList(),
          'aggregateWins': currentWins,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Reload event
      await _loadEvent();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'תוצאה נרשמה בהצלחה!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        title: 'ניהול אירוע',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return AppScaffold(
        title: 'ניהול אירוע',
        body: const Center(child: Text('אירוע לא נמצא')),
      );
    }

    return AppScaffold(
      title: _event!.title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _event!.title,
                            style: FuturisticTypography.techHeadline.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ),
                        if (_event!.status == 'ongoing')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'מתקיים',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: FuturisticColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm', 'he')
                              .format(_event!.eventDate),
                          style: FuturisticTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Aggregate Wins Scoreboard
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'תוצאות מצטברות',
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_event!.aggregateWins.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('עדיין לא נרשמו תוצאות'),
                        ),
                      )
                    else
                      ..._event!.teams.map((team) {
                        final wins =
                            _event!.aggregateWins[team.color ?? ''] ?? 0;
                        final colorValue = team.colorValue ?? 0xFF2196F3;
                        final maxWins = _event!.aggregateWins.values.isEmpty
                            ? 1
                            : _event!.aggregateWins.values
                                .reduce((a, b) => a > b ? a : b);
                        final percentage = maxWins > 0 ? (wins / maxWins) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Color(colorValue),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        team.color ?? team.name,
                                        style: FuturisticTypography.bodyLarge
                                            .copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$wins ניצחונות',
                                    style: FuturisticTypography.heading2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 24,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(colorValue)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Teams Button
            if (_event!.registeredPlayerIds.isNotEmpty && _event!.teams.isEmpty)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/events/${widget.eventId}/team-generator/config',
                        extra: {
                          'hubId': widget.hubId,
                          'eventId': widget.eventId,
                        },
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('צור כוחות אוטומטי'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: FuturisticColors.primary),
                        foregroundColor: FuturisticColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Log Match Result Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _logMatchResult,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSubmitting ? 'שומר...' : 'רישום תוצאה'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: FuturisticColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Matches
            if (_event!.matches.isNotEmpty) ...[
              FuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'משחקים אחרונים',
                        style: FuturisticTypography.techHeadline.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._event!.matches.reversed.take(10).map((match) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColorForTeam(match.teamAColor),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    match.teamAColor,
                                    style: FuturisticTypography.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${match.scoreA}',
                                    style: FuturisticTypography.heading2,
                                  ),
                                ],
                              ),
                              Text(
                                'VS',
                                style: FuturisticTypography.bodyMedium.copyWith(
                                  color: FuturisticColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${match.scoreB}',
                                    style: FuturisticTypography.heading2,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    match.teamBColor,
                                    style: FuturisticTypography.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColorForTeam(match.teamBColor),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForTeam(String? colorName) {
    if (colorName == null) return Colors.grey;

    final team = _event?.teams.firstWhere(
      (t) => t.color == colorName,
      orElse: () => Team(teamId: '', name: '', colorValue: 0xFF2196F3),
    );

    return Color(team?.colorValue ?? 0xFF2196F3);
  }
}

/// Dialog for logging a match result
class _LogMatchDialog extends StatefulWidget {
  final HubEvent event;

  const _LogMatchDialog({required this.event});

  @override
  State<_LogMatchDialog> createState() => _LogMatchDialogState();
}

class _LogMatchDialogState extends State<_LogMatchDialog> {
  String? _selectedTeamA;
  String? _selectedTeamB;
  int _scoreA = 0;
  int _scoreB = 0;

  @override
  void initState() {
    super.initState();
    if (widget.event.teams.isNotEmpty) {
      _selectedTeamA =
          widget.event.teams[0].color ?? widget.event.teams[0].name;
      if (widget.event.teams.length > 1) {
        _selectedTeamB =
            widget.event.teams[1].color ?? widget.event.teams[1].name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('רישום תוצאה'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team A selection
            DropdownButtonFormField<String>(
              value: _selectedTeamA,
              decoration: const InputDecoration(
                labelText: 'קבוצה א',
                border: OutlineInputBorder(),
              ),
              items: widget.event.teams.map((team) {
                final colorName = team.color ?? team.name;
                return DropdownMenuItem(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(team.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTeamA = value),
            ),
            const SizedBox(height: 16),
            // Team B selection
            DropdownButtonFormField<String>(
              value: _selectedTeamB,
              decoration: const InputDecoration(
                labelText: 'קבוצה ב',
                border: OutlineInputBorder(),
              ),
              items: widget.event.teams.where((team) {
                final colorName = team.color ?? team.name;
                return colorName != _selectedTeamA;
              }).map((team) {
                final colorName = team.color ?? team.name;
                return DropdownMenuItem(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(team.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTeamB = value),
            ),
            const SizedBox(height: 24),
            // Score input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Score A
                Column(
                  children: [
                    const Text('קבוצה א'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _scoreA > 0
                              ? () => setState(() => _scoreA--)
                              : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_scoreA',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _scoreA++),
                        ),
                      ],
                    ),
                  ],
                ),
                const Text('VS'),
                // Score B
                Column(
                  children: [
                    const Text('קבוצה ב'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _scoreB > 0
                              ? () => setState(() => _scoreB--)
                              : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_scoreB',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _scoreB++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _selectedTeamA != null && _selectedTeamB != null
              ? () => Navigator.pop(
                    context,
                    {
                      'teamAColor': _selectedTeamA,
                      'teamBColor': _selectedTeamB,
                      'scoreA': _scoreA,
                      'scoreB': _scoreB,
                    },
                  )
              : null,
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
