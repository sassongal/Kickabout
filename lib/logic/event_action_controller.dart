import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller for handling "Start Event" actions with smart navigation logic
class EventActionController {
  final Ref ref;

  EventActionController(this.ref);

  /// Handle "Start Event" button click with smart navigation
  /// 
  /// Logic:
  /// - If teams are empty: Show explanation dialog and navigate to TeamGeneratorConfigScreen
  /// - If teams exist and valid: Ask for confirmation, then start event and navigate to LiveMatchScreen
  /// - If teams exist but invalid: Show error and navigate to TeamGeneratorConfigScreen
  Future<void> handleStartEvent({
    required BuildContext context,
    required String hubId,
    required String eventId,
    required HubEvent event,
  }) async {
    try {
      // Check if teams exist and are valid
      if (event.teams.isEmpty || 
          event.teams.any((t) => t.playerIds.isEmpty)) {
        // No teams or empty teams - show explanation and navigate to team generator
        if (context.mounted) {
          final shouldCreateTeams = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('חובה ליצור כוחות'),
              content: const Text(
                'לא ניתן להתחיל את האירוע ללא יצירת כוחות.\n\n'
                'אנא צור כוחות לפני התחלת האירוע.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('צור כוחות עכשיו'),
                ),
              ],
            ),
          );
          
          if (shouldCreateTeams == true && context.mounted) {
            context.push('/hubs/$hubId/events/$eventId/team-generator');
          }
        }
        return;
      }

      // Validate teams before starting
      final minPlayersPerTeam = 2; // Minimum 2 players per team
      final validationErrors = TeamMaker.validateTeamsForGameStart(
        event.teams,
        event.teamCount,
        minPlayersPerTeam,
      );
      
      if (validationErrors.isNotEmpty) {
        if (context.mounted) {
          final shouldFixTeams = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('שגיאה באימות הכוחות'),
              content: Text(
                'הכוחות שנוצרו אינם תקינים:\n${validationErrors.join('\n')}\n\n'
                'אנא צור כוחות מחדש.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('תקן כוחות'),
                ),
              ],
            ),
          );
          
          if (shouldFixTeams == true && context.mounted) {
            context.push('/hubs/$hubId/events/$eventId/team-generator');
          }
        }
        return;
      }

      // Teams are valid - ask for confirmation before starting
      // Only managers can start events
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'נדרש להתחבר כדי להתחיל אירוע');
        }
        return;
      }

      // Check manager permission
      final canStart = await canStartEvent(
        hubId: hubId,
        userId: currentUserId,
      );
      
      if (!canStart) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context,
            'רק מנהל האירוע יכול להתחיל את האירוע',
          );
        }
        return;
      }

      // Ask for confirmation with warning
      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, 
                    color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'אישור התחלת אירוע',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'האם אתה בטוח שאתה רוצה להתחיל את האירוע?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'חשוב לדעת:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• לאחר התחלת האירוע לא ניתן להתחרט\n'
                    '• כל המשתתפים יקבלו גישה למסך המשחק החי\n'
                    '• תועבר אוטומטית למסך המשחק החי\n'
                    '• האירוע יועבר לסטטוס "מתקיים"',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'האם אתה בטוח?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ביטול', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('כן, התחל אירוע', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return; // User cancelled
        }
      }

      // Start event after confirmation
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      await eventsRepo.updateHubEvent(
        hubId,
        eventId,
        {
          'isStarted': true,
          'status': 'ongoing',
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'האירוע התחיל!');
        // Navigate to live match screen
        context.push('/hubs/$hubId/events/$eventId/live');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(
          context,
          'שגיאה בהתחלת האירוע: $e',
        );
      }
    }
  }

  /// Check if user can start event (manager permission check)
  Future<bool> canStartEvent({
    required String hubId,
    required String userId,
  }) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(hubId);
      
      if (hub == null) return false;

      // Creator is always manager
      if (hub.createdBy == userId) return true;

      // Check if user is in managerIds
      return hub.managerIds.contains(userId);
    } catch (e) {
      debugPrint('Error checking start event permission: $e');
      return false;
    }
  }
}

/// Provider for EventActionController
final eventActionControllerProvider = Provider<EventActionController>((ref) {
  return EventActionController(ref);
});

