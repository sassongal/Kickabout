import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/location_service.dart';

/// Scouting criteria
class ScoutingCriteria {
  final String hubId;
  final int? minAge; // Minimum age (default: 18)
  final int? maxAge; // Maximum age (default: 45)
  final String? region; // איזור מגורים: צפון, מרכז, דרום, ירושלים
  final bool activeOnly; // Only active players (isActive = true)
  final int? limit;

  const ScoutingCriteria({
    required this.hubId,
    this.minAge,
    this.maxAge,
    this.region,
    this.activeOnly = true,
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
      
      // Calculate current date for age calculation
      final now = DateTime.now();
      
      // Filter players
      final candidates = allUsers.where((user) {
        // Exclude hub members
        if (excludedPlayerIds.contains(user.uid)) {
          return false;
        }

        // Filter by active status
        if (criteria.activeOnly && !user.isActive) {
          return false;
        }

        // Filter by age
        if (user.birthDate != null) {
          final age = now.year - user.birthDate!.year;
          final monthDiff = now.month - user.birthDate!.month;
          final dayDiff = now.day - user.birthDate!.day;
          final actualAge = age - (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0) ? 1 : 0);
          
          if (criteria.minAge != null && actualAge < criteria.minAge!) {
            return false;
          }
          if (criteria.maxAge != null && actualAge > criteria.maxAge!) {
            return false;
          }
        } else {
          // If no birthDate, exclude if age filter is set
          if (criteria.minAge != null || criteria.maxAge != null) {
            return false;
          }
        }

        // Filter by region
        if (criteria.region != null && user.region != criteria.region) {
          return false;
        }

        return true;
      }).toList();

      // Get hub location for distance calculation (always calculate distance for sorting)
      Position? hubPosition;
      if (hub.primaryVenueLocation != null) {
        try {
          hubPosition = Position(
            latitude: hub.primaryVenueLocation!.latitude,
            longitude: hub.primaryVenueLocation!.longitude,
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
          hubPosition = null;
        }
      } else if (hub.location != null) {
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
          } catch (e) {
            // If distance calculation fails, skip distance filtering for this player
            distanceKm = null;
          }
        }

        // Calculate match score (0-100) - simpler scoring
        double matchScore = 50.0; // Base score
        final matchReasons = <String>[];

        // Active status bonus
        if (player.isActive) {
          matchScore += 20;
          matchReasons.add('פעיל');
        }

        // Participation bonus (more games = more reliable)
        if (player.totalParticipations > 10) {
          matchScore += 10;
          matchReasons.add('${player.totalParticipations} משחקים');
        }

        // Distance info (will be used for sorting, not scoring)
        if (distanceKm != null) {
          matchReasons.add('${distanceKm.toStringAsFixed(1)} ק"מ מההוב');
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

      // Sort by distance (ascending - closest first), then by match score
      results.sort((a, b) {
        // If both have distances, sort by distance first
        if (a.distanceKm != null && b.distanceKm != null) {
          final distanceCompare = a.distanceKm!.compareTo(b.distanceKm!);
          if (distanceCompare != 0) return distanceCompare;
        }
        // If only one has distance, prioritize the one with distance
        if (a.distanceKm != null && b.distanceKm == null) return -1;
        if (a.distanceKm == null && b.distanceKm != null) return 1;
        // Otherwise sort by match score
        return b.matchScore.compareTo(a.matchScore);
      });

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

