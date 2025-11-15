import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/location_service.dart';

/// Scouting criteria
class ScoutingCriteria {
  final String hubId;
  final String? requiredPosition;
  final double? minRating;
  final double? maxRating;
  final double? maxDistanceKm; // Maximum distance in kilometers
  final bool availableOnly;
  final int? limit;

  const ScoutingCriteria({
    required this.hubId,
    this.requiredPosition,
    this.minRating,
    this.maxRating,
    this.maxDistanceKm,
    this.availableOnly = true,
    this.limit,
  });
}

/// Scouting result with match score
class ScoutingResult {
  final User player;
  final double matchScore; // 0-100, how well the player matches
  final double? distanceKm;
  final List<String> matchReasons; // Why this player was suggested

  ScoutingResult({
    required this.player,
    required this.matchScore,
    this.distanceKm,
    required this.matchReasons,
  });
}

/// Service for AI-powered player scouting and matchmaking
class ScoutingService {
  final UsersRepository _usersRepo;
  final HubsRepository _hubsRepo;

  ScoutingService({
    required UsersRepository usersRepo,
    required HubsRepository hubsRepo,
    required LocationService locationService,
  })  : _usersRepo = usersRepo,
        _hubsRepo = hubsRepo;

  /// Find players matching scouting criteria
  Future<List<ScoutingResult>> scoutPlayers(ScoutingCriteria criteria) async {
    if (!Env.isFirebaseAvailable) {
      return [];
    }

    try {
      // Get hub to exclude its members
      final hub = await _hubsRepo.getHub(criteria.hubId);
      if (hub == null) {
        return [];
      }

      final excludedPlayerIds = hub.memberIds.toSet();
      final allUsers = await _usersRepo.getAllUsers();
      
      // Filter players
      final candidates = allUsers.where((user) {
        // Exclude hub members
        if (excludedPlayerIds.contains(user.uid)) {
          return false;
        }

        // Filter by availability
        if (criteria.availableOnly && user.availabilityStatus != 'available') {
          return false;
        }

        // Filter by position
        if (criteria.requiredPosition != null &&
            user.preferredPosition != criteria.requiredPosition) {
          return false;
        }

        // Filter by rating
        if (criteria.minRating != null && user.currentRankScore < criteria.minRating!) {
          return false;
        }
        if (criteria.maxRating != null && user.currentRankScore > criteria.maxRating!) {
          return false;
        }

        return true;
      }).toList();

      // Get hub location for distance calculation
      Position? hubPosition;
      if (criteria.maxDistanceKm != null && hub.location != null) {
        try {
          hubPosition = Position(
            latitude: hub.location!.latitude,
            longitude: hub.location!.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        } catch (e) {
          // If Position creation fails, continue without distance filtering
          hubPosition = null;
        }
      }

      // Calculate match scores and distances
      final results = <ScoutingResult>[];
      for (final player in candidates) {
        double? distanceKm;
        if (hubPosition != null && player.location != null) {
          try {
            final playerPosition = Position(
              latitude: player.location!.latitude,
              longitude: player.location!.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
            
            distanceKm = Geolocator.distanceBetween(
              hubPosition.latitude,
              hubPosition.longitude,
              playerPosition.latitude,
              playerPosition.longitude,
            ) / 1000; // Convert to km

            // Filter by distance
            if (criteria.maxDistanceKm != null && distanceKm > criteria.maxDistanceKm!) {
              continue;
            }
          } catch (e) {
            // If distance calculation fails, skip distance filtering for this player
            distanceKm = null;
          }
        }

        // Calculate match score (0-100)
        double matchScore = 50.0; // Base score
        final matchReasons = <String>[];

        // Availability bonus
        if (player.availabilityStatus == 'available') {
          matchScore += 20;
          matchReasons.add('זמין למשחק');
        }

        // Position match bonus
        if (criteria.requiredPosition != null &&
            player.preferredPosition == criteria.requiredPosition) {
          matchScore += 15;
          matchReasons.add('תואם לעמדה: ${_getPositionName(player.preferredPosition)}');
        }

        // Rating bonus (higher rating = higher score, but not too high)
        if (criteria.minRating != null && criteria.maxRating != null) {
          final ratingRange = criteria.maxRating! - criteria.minRating!;
          final ratingPosition = (player.currentRankScore - criteria.minRating!) / ratingRange;
          matchScore += ratingPosition * 10; // Up to 10 points
          matchReasons.add('דירוג: ${player.currentRankScore.toStringAsFixed(1)}');
        } else {
          // General rating bonus
          matchScore += (player.currentRankScore / 10) * 10;
          matchReasons.add('דירוג: ${player.currentRankScore.toStringAsFixed(1)}');
        }

        // Distance bonus (closer = higher score)
        if (distanceKm != null && criteria.maxDistanceKm != null) {
          final distanceRatio = 1 - (distanceKm / criteria.maxDistanceKm!);
          matchScore += distanceRatio * 15; // Up to 15 points
          matchReasons.add('${distanceKm.toStringAsFixed(1)} ק"מ מההוב');
        }

        // Participation bonus (more games = more reliable)
        if (player.totalParticipations > 10) {
          matchScore += 5;
          matchReasons.add('${player.totalParticipations} משחקים');
        }

        // Cap score at 100
        matchScore = matchScore.clamp(0, 100);

        results.add(ScoutingResult(
          player: player,
          matchScore: matchScore,
          distanceKm: distanceKm,
          matchReasons: matchReasons,
        ));
      }

      // Sort by match score (descending)
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      // Apply limit
      if (criteria.limit != null && results.length > criteria.limit!) {
        return results.take(criteria.limit!).toList();
      }

      return results;
    } catch (e) {
      throw Exception('Failed to scout players: $e');
    }
  }

  String _getPositionName(String position) {
    const positionNames = {
      'Goalkeeper': 'שוער',
      'Defender': 'מגן',
      'Midfielder': 'קשר',
      'Forward': 'חלוץ',
    };
    return positionNames[position] ?? position;
  }
}

