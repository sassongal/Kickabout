import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';

/// Analytics service for hub insights
/// Optimized to avoid N+1 queries
class HubAnalyticsService {
  final FirebaseFirestore _firestore;

  HubAnalyticsService(this._firestore);

  /// Get comprehensive hub insights
  Future<HubInsights> getHubInsights(String hubId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    // Execute all queries in parallel
    final results = await Future.wait([
      _getMembershipTrends(hubId, ninetyDaysAgo, now),
      _getGameFrequencyOptimized(hubId, thirtyDaysAgo, now),
      _getActiveMembers(hubId, thirtyDaysAgo),
      _getChurnRiskOptimized(hubId, thirtyDaysAgo),
    ]);

    final membershipTrends = results[0] as MembershipTrends;
    final gameFrequency = results[1] as GameFrequencyStats;
    final activeMemberCount = results[2] as int;
    final churnRisk = results[3] as ChurnRiskAnalysis;

    // Calculate engagement score
    final totalMembers = membershipTrends.totalMembers;
    final engagementScore = totalMembers > 0
        ? (activeMemberCount / totalMembers * 100).clamp(0.0, 100.0)
        : 0.0;

    // Determine health status
    final healthStatus = _calculateHealthStatus(
      engagementScore,
      churnRisk.atRiskCount,
      gameFrequency.gamesPerWeek,
    );

    return HubInsights(
      hubId: hubId,
      generatedAt: now,
      membershipTrends: membershipTrends,
      gameFrequency: gameFrequency,
      activeMemberCount: activeMemberCount,
      churnRisk: churnRisk,
      engagementScore: engagementScore,
      healthStatus: healthStatus,
    );
  }

  /// Get membership growth trends
  Future<MembershipTrends> _getMembershipTrends(
    String hubId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final membersSnapshot = await _firestore
        .collection('hubs/$hubId/members')
        .where('status', isEqualTo: 'active')
        .get();

    final totalMembers = membersSnapshot.docs.length;

    // Calculate weekly growth
    final weeklyData = <DateTime, int>{};
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);

    while (currentDate.isBefore(endDate)) {
      final weekEnd = currentDate.add(const Duration(days: 7));

      final weekMembers = membersSnapshot.docs.where((doc) {
        final data = doc.data();
        final joinedAt = (data['joinedAt'] as Timestamp?)?.toDate();
        return joinedAt != null &&
            joinedAt.isAfter(currentDate) &&
            joinedAt.isBefore(weekEnd);
      }).length;

      weeklyData[currentDate] = weekMembers;
      currentDate = weekEnd;
    }

    // Calculate growth rate
    final firstWeekCount = weeklyData.values.first;
    final lastWeekCount = weeklyData.values.last;
    final growthRate = firstWeekCount > 0
        ? ((lastWeekCount - firstWeekCount) / firstWeekCount * 100)
        : 0.0;

    return MembershipTrends(
      totalMembers: totalMembers,
      weeklyData: weeklyData,
      growthRatePercent: growthRate,
    );
  }

  /// OPTIMIZED: Get game frequency with batch query
  Future<GameFrequencyStats> _getGameFrequencyOptimized(
    String hubId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Get all games for the hub in the time range
    final gamesSnapshot = await _firestore
        .collection('games')
        .where('hubId', isEqualTo: hubId)
        .where('gameDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('gameDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    if (gamesSnapshot.docs.isEmpty) {
      return GameFrequencyStats(
        totalGames: 0,
        gamesPerWeek: 0.0,
        averageAttendance: 0.0,
        completedGames: 0,
      );
    }

    final games = gamesSnapshot.docs
        .map((doc) => Game.fromJson(doc.data()))
        .toList();

    // OPTIMIZED: Batch query all signups at once (instead of N queries)
    final gameIds = games.map((g) => g.gameId).toList();

    // Firestore whereIn has limit of 10, so batch if needed
    final signupsByGame = <String, int>{};

    for (var i = 0; i < gameIds.length; i += 10) {
      final batch = gameIds.skip(i).take(10).toList();

      final signupsSnapshot = await _firestore
          .collection('signups')
          .where('gameId', whereIn: batch)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (final doc in signupsSnapshot.docs) {
        final gameId = doc['gameId'] as String;
        signupsByGame[gameId] = (signupsByGame[gameId] ?? 0) + 1;
      }
    }

    // Calculate stats
    final totalGames = games.length;
    final completedGames =
        games.where((g) => g.status == GameStatus.completed).length;

    final totalAttendance = signupsByGame.values.fold(0, (a, b) => a + b);
    final averageAttendance =
        totalGames > 0 ? totalAttendance / totalGames : 0.0;

    // Calculate actual games per week based on date range
    final days = endDate.difference(startDate).inDays;
    final weeks = days / 7.0;
    final gamesPerWeek = weeks > 0 ? totalGames / weeks : 0.0;

    return GameFrequencyStats(
      totalGames: totalGames,
      gamesPerWeek: gamesPerWeek,
      averageAttendance: averageAttendance,
      completedGames: completedGames,
    );
  }

  /// Get active members count
  Future<int> _getActiveMembers(String hubId, DateTime since) async {
    // Get all signups since the date
    final signupsSnapshot = await _firestore
        .collection('signups')
        .where('hubId', isEqualTo: hubId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    // Count unique user IDs
    final activeUserIds = signupsSnapshot.docs
        .map((doc) => doc['userId'] as String)
        .toSet();

    return activeUserIds.length;
  }

  /// OPTIMIZED: Get churn risk with single batch query
  Future<ChurnRiskAnalysis> _getChurnRiskOptimized(
    String hubId,
    DateTime thirtyDaysAgo,
  ) async {
    final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));

    // Get all active members
    final membersSnapshot = await _firestore
        .collection('hubs/$hubId/members')
        .where('status', isEqualTo: 'active')
        .get();

    if (membersSnapshot.docs.isEmpty) {
      return ChurnRiskAnalysis(atRiskCount: 0, atRiskUserIds: []);
    }

    // OPTIMIZED: Get ALL recent signups in one query
    final allRecentSignups = await _firestore
        .collection('signups')
        .where('hubId', isEqualTo: hubId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sixtyDaysAgo))
        .get();

    // Group signups by userId
    final signupsByUser = <String, List<DocumentSnapshot>>{};
    for (final doc in allRecentSignups.docs) {
      final userId = doc['userId'] as String;
      signupsByUser.putIfAbsent(userId, () => []).add(doc);
    }

    // Identify at-risk members (no signups in last 30 days but active 30-60 days ago)
    final atRiskUserIds = <String>[];

    for (final memberDoc in membersSnapshot.docs) {
      final userId = memberDoc.id;
      final userSignups = signupsByUser[userId] ?? [];

      // Check if user has recent signups (last 30 days)
      final hasRecentActivity = userSignups.any((doc) {
        final createdAt = (doc['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(thirtyDaysAgo);
      });

      // Check if user was active 30-60 days ago
      final wasActiveEarlier = userSignups.any((doc) {
        final createdAt = (doc['createdAt'] as Timestamp).toDate();
        return createdAt.isBefore(thirtyDaysAgo) &&
            createdAt.isAfter(sixtyDaysAgo);
      });

      if (!hasRecentActivity && wasActiveEarlier) {
        atRiskUserIds.add(userId);
      }
    }

    return ChurnRiskAnalysis(
      atRiskCount: atRiskUserIds.length,
      atRiskUserIds: atRiskUserIds,
    );
  }

  /// Calculate hub health status
  HubHealthStatus _calculateHealthStatus(
    double engagementScore,
    int atRiskCount,
    double gamesPerWeek,
  ) {
    if (engagementScore >= 80 && atRiskCount < 5 && gamesPerWeek >= 2) {
      return HubHealthStatus.excellent;
    } else if (engagementScore >= 60 && atRiskCount < 10 && gamesPerWeek >= 1) {
      return HubHealthStatus.good;
    } else if (engagementScore >= 40 || gamesPerWeek >= 0.5) {
      return HubHealthStatus.needsAttention;
    } else {
      return HubHealthStatus.critical;
    }
  }
}

/// Hub insights data model
class HubInsights {
  final String hubId;
  final DateTime generatedAt;
  final MembershipTrends membershipTrends;
  final GameFrequencyStats gameFrequency;
  final int activeMemberCount;
  final ChurnRiskAnalysis churnRisk;
  final double engagementScore;
  final HubHealthStatus healthStatus;

  HubInsights({
    required this.hubId,
    required this.generatedAt,
    required this.membershipTrends,
    required this.gameFrequency,
    required this.activeMemberCount,
    required this.churnRisk,
    required this.engagementScore,
    required this.healthStatus,
  });
}

/// Membership growth trends
class MembershipTrends {
  final int totalMembers;
  final Map<DateTime, int> weeklyData;
  final double growthRatePercent;

  MembershipTrends({
    required this.totalMembers,
    required this.weeklyData,
    required this.growthRatePercent,
  });
}

/// Game frequency statistics
class GameFrequencyStats {
  final int totalGames;
  final double gamesPerWeek;
  final double averageAttendance;
  final int completedGames;

  GameFrequencyStats({
    required this.totalGames,
    required this.gamesPerWeek,
    required this.averageAttendance,
    required this.completedGames,
  });
}

/// Churn risk analysis
class ChurnRiskAnalysis {
  final int atRiskCount;
  final List<String> atRiskUserIds;

  ChurnRiskAnalysis({
    required this.atRiskCount,
    required this.atRiskUserIds,
  });
}

/// Hub health status enum
enum HubHealthStatus {
  excellent,
  good,
  needsAttention,
  critical,
}
