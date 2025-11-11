import 'package:kickabout/models/models.dart';
import 'package:kickabout/data/repositories.dart';

/// Simple recap generator (no AI) - composes Hebrew summary from events
class RecapGenerator {
  /// Generate Hebrew recap from game events
  static Future<String> generateRecap(
    String gameId,
    EventsRepository eventsRepo,
    UsersRepository usersRepo,
  ) async {
    final events = await eventsRepo.getEvents(gameId);

    if (events.isEmpty) {
      return 'אין אירועים במשחק זה.';
    }

    // Count goals per team (simplified - assumes teams from events)
    final goals = events.where((e) => e.type == EventType.goal).toList();
    final assists = events.where((e) => e.type == EventType.assist).toList();
    final saves = events.where((e) => e.type == EventType.save).toList();
    final mvpVotes = events.where((e) => e.type == EventType.mvpVote).toList();

    // Get player names
    final playerIds = events.map((e) => e.playerId).toSet().toList();
    final users = await usersRepo.getUsers(playerIds);
    final playerMap = {for (var u in users) u.uid: u.name};

    // Count goals by player
    final goalsByPlayer = <String, int>{};
    for (var goal in goals) {
      goalsByPlayer[goal.playerId] = (goalsByPlayer[goal.playerId] ?? 0) + 1;
    }

    // Count assists by player
    final assistsByPlayer = <String, int>{};
    for (var assist in assists) {
      assistsByPlayer[assist.playerId] = (assistsByPlayer[assist.playerId] ?? 0) + 1;
    }

    // Count MVP votes by player
    final mvpVotesByPlayer = <String, int>{};
    for (var vote in mvpVotes) {
      mvpVotesByPlayer[vote.playerId] = (mvpVotesByPlayer[vote.playerId] ?? 0) + 1;
    }

    // Build recap
    final buffer = StringBuffer();

    // Goals summary
    if (goals.isNotEmpty) {
      buffer.writeln('סה"כ שערים: ${goals.length}');
      
      if (goalsByPlayer.isNotEmpty) {
        final sortedGoals = goalsByPlayer.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        buffer.write('מלך השערים: ');
        final topScorers = sortedGoals.take(3).map((e) {
          final name = playerMap[e.key] ?? 'שחקן לא ידוע';
          return '$name (${e.value})';
        }).join(', ');
        buffer.writeln(topScorers);
      }
    }

    // Assists summary
    if (assists.isNotEmpty) {
      if (assistsByPlayer.isNotEmpty) {
        final sortedAssists = assistsByPlayer.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        buffer.write('בישולים: ');
        final topAssists = sortedAssists.take(3).map((e) {
          final name = playerMap[e.key] ?? 'שחקן לא ידוע';
          return '$name (${e.value})';
        }).join(', ');
        buffer.writeln(topAssists);
      }
    }

    // Saves summary
    if (saves.isNotEmpty) {
      buffer.writeln('סה"כ הצלות: ${saves.length}');
    }

    // MVP summary
    if (mvpVotesByPlayer.isNotEmpty) {
      final sortedMvp = mvpVotesByPlayer.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topMvp = sortedMvp.first;
      final mvpName = playerMap[topMvp.key] ?? 'שחקן לא ידוע';
      buffer.writeln('MVP: $mvpName');
    }

    return buffer.toString().trim();
  }
}

