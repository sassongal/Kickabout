import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/data/teams_repository.dart';

/// AI-powered narrative recap generator - creates engaging Hebrew summaries
class RecapGenerator {
  /// Generate narrative Hebrew recap from game events
  static Future<String> generateNarrativeRecap(
    String gameId,
    EventsRepository eventsRepo,
    UsersRepository usersRepo,
    TeamsRepository teamsRepo,
    GamesRepository gamesRepo,
  ) async {
    final events = await eventsRepo.getEvents(gameId);
    final game = await gamesRepo.getGame(gameId);
    final teams = await teamsRepo.getTeams(gameId);

    if (events.isEmpty) {
      return 'משחק ללא אירועים מיוחדים. המשחק התנהל בצורה חלקה.';
    }

    // Get player names
    final playerIds = events.map((e) => e.playerId).toSet().toList();
    final users = await usersRepo.getUsers(playerIds);
    final playerMap = {for (var u in users) u.uid: u.name};

    // Analyze events
    final goals = events.where((e) => e.type == EventType.goal).toList();
    final assists = events.where((e) => e.type == EventType.assist).toList();
    final saves = events.where((e) => e.type == EventType.save).toList();
    final mvpVotes = events.where((e) => e.type == EventType.mvpVote).toList();

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

    // Build narrative recap
    final buffer = StringBuffer();

    // Opening - game result
    if (teams.isNotEmpty && goals.isNotEmpty) {
      final teamScores = <String, int>{};
      // Try to determine team scores from events metadata or team scores
      for (var team in teams) {
        teamScores[team.teamId] = team.totalScore.toInt();
      }
      
      if (teamScores.length >= 2) {
        final sortedTeams = teamScores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final winner = sortedTeams.first;
        final loser = sortedTeams.length > 1 ? sortedTeams[1] : null;
        
        if (loser != null && winner.value != loser.value) {
          final winnerName = teams.firstWhere((t) => t.teamId == winner.key, orElse: () => teams.first).name;
          final loserName = teams.firstWhere((t) => t.teamId == loser.key, orElse: () => teams[1]).name;
          
          final adjectives = ['מרשים', 'מדהים', 'מצוין', 'מעולה', 'מצוין'];
          final adjective = adjectives[DateTime.now().millisecond % adjectives.length];
          
          buffer.writeln('${winnerName} השיגו ניצחון $adjective ${winner.value}-${loser.value} על ${loserName}!');
        } else {
          buffer.writeln('משחק צמוד ומרתק שהסתיים בשוויון!');
        }
      } else {
        buffer.writeln('משחק מעניין עם ${goals.length} שערים בסך הכל.');
      }
    } else if (goals.isNotEmpty) {
      buffer.writeln('משחק מלא פעילות עם ${goals.length} שערים בסך הכל.');
    } else {
      buffer.writeln('משחק הגנתי ומאוזן.');
    }

    buffer.writeln('');

    // Top scorer with hat-trick mention
    if (goalsByPlayer.isNotEmpty) {
      final sortedGoals = goalsByPlayer.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topScorer = sortedGoals.first;
      final topScorerName = playerMap[topScorer.key] ?? 'שחקן לא ידוע';
      
      if (topScorer.value >= 3) {
        buffer.writeln('${topScorerName} ביצע שלושער מדהים וסיים עם ${topScorer.value} שערים!');
      } else if (topScorer.value == 2) {
        buffer.writeln('${topScorerName} כבש צמד וסיים עם ${topScorer.value} שערים.');
      } else {
        buffer.writeln('${topScorerName} הוביל את מלכות השערים עם ${topScorer.value} שערים.');
      }
    }

    // MVP mention
    if (mvpVotesByPlayer.isNotEmpty) {
      final sortedMvp = mvpVotesByPlayer.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final mvp = sortedMvp.first;
      final mvpName = playerMap[mvp.key] ?? 'שחקן לא ידוע';
      
      final mvpAdjectives = ['שלט', 'התבלט', 'הוביל', 'בלט', 'הצטיין'];
      final mvpAdjective = mvpAdjectives[DateTime.now().millisecond % mvpAdjectives.length];
      
      buffer.writeln('${mvpName} נבחר ל-MVP של המשחק ו${mvpAdjective} במגרש.');
    }

    // Assists mention
    if (assistsByPlayer.isNotEmpty) {
      final sortedAssists = assistsByPlayer.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topAssist = sortedAssists.first;
      final topAssistName = playerMap[topAssist.key] ?? 'שחקן לא ידוע';
      
      if (topAssist.value >= 2) {
        buffer.writeln('${topAssistName} ביצע ${topAssist.value} בישולים מעולים.');
      } else {
        buffer.writeln('${topAssistName} ביצע בישול מעולה.');
      }
    }

    // Saves mention
    if (saves.isNotEmpty) {
      if (saves.length >= 5) {
        buffer.writeln('שוערים ביצעו ${saves.length} הצלות מרשימות במהלך המשחק.');
      } else if (saves.length >= 3) {
        buffer.writeln('${saves.length} הצלות איכותיות בוצעו במהלך המשחק.');
      }
    }

    // Closing
    buffer.writeln('');
    buffer.writeln('משחק מהנה ומקצועי! 👏⚽');

    return buffer.toString().trim();
  }

  /// Generate simple recap (backward compatibility)
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

