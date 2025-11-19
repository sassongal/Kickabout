import 'dart:isolate';
import 'package:flutter/foundation.dart';
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
      final List<User> allUsers = await _usersRepo.getAllUsers();
      
      // Calculate current date for age calculation
      final now = DateTime.now();
      
      // Filter players
      final candidates = allUsers.where((User user) {
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

      // Prepare data for compute (must be serializable)
      final hubLat = hubPosition?.latitude;
      final hubLng = hubPosition?.longitude;
      
      final playersData = candidates.map((player) => {
        'uid': player.uid,
        'name': player.name,
        'isActive': player.isActive,
        'totalParticipations': player.totalParticipations,
        'location': player.location != null ? {
          'latitude': player.location!.latitude,
          'longitude': player.location!.longitude,
        } : null,
        // Serialize User object (simplified for compute)
        'userJson': player.toJson(),
      }).toList();
      
      final computeParams = {
        'players': playersData,
        'hubLat': hubLat,
        'hubLng': hubLng,
        'limit': criteria.limit,
      };
      
      // Run heavy computation in isolate to prevent UI blocking
      final computedData = await compute(_computeScoutingResults, computeParams);
      final computedResults = computedData['results'] as List<dynamic>;
      
      // Reconstruct ScoutingResult objects from computed data
      final results = <ScoutingResult>[];
      for (final resultData in computedResults) {
        final resultMap = resultData as Map<String, dynamic>;
        // Find the original player object
        final player = candidates.firstWhere(
          (p) => p.uid == resultMap['uid'],
          orElse: () => candidates.first, // Fallback (shouldn't happen)
        );
        
        results.add(ScoutingResult(
          player: player,
          matchScore: resultMap['matchScore'] as double,
          distanceKm: resultMap['distanceKm'] as double?,
          matchReasons: List<String>.from(resultMap['matchReasons'] as List),
        ));
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

/// Heavy computation function for isolate (must be top-level)
/// Calculates match scores and distances for scouting results
Map<String, dynamic> _computeScoutingResults(Map<String, dynamic> params) {
  final players = params['players'] as List<dynamic>;
  final hubLat = params['hubLat'] as double?;
  final hubLng = params['hubLng'] as double?;
  final limit = params['limit'] as int?;
  
  final results = <Map<String, dynamic>>[];
  
  for (final playerData in players) {
    final playerMap = playerData as Map<String, dynamic>;
    final playerLocation = playerMap['location'] as Map<String, dynamic>?;
    
    double? distanceKm;
    if (hubLat != null && hubLng != null && playerLocation != null) {
      try {
        distanceKm = Geolocator.distanceBetween(
          hubLat,
          hubLng,
          playerLocation['latitude'] as double,
          playerLocation['longitude'] as double,
        ) / 1000; // Convert to km
      } catch (e) {
        distanceKm = null;
      }
    }
    
    // Calculate match score (0-100)
    double matchScore = 50.0; // Base score
    final matchReasons = <String>[];
    
    // Active status bonus
    if (playerMap['isActive'] == true) {
      matchScore += 20;
      matchReasons.add('פעיל');
    }
    
    // Participation bonus
    final participations = playerMap['totalParticipations'] as int? ?? 0;
    if (participations > 10) {
      matchScore += 10;
      matchReasons.add('$participations משחקים');
    }
    
    // Distance info
    if (distanceKm != null) {
      matchReasons.add('${distanceKm.toStringAsFixed(1)} ק"מ מההוב');
    }
    
    // Cap score at 100
    matchScore = matchScore.clamp(0, 100);
    
    results.add({
      'uid': playerMap['uid'] as String,
      'matchScore': matchScore,
      'distanceKm': distanceKm,
      'matchReasons': matchReasons,
    });
  }
  
  // Sort by distance (ascending - closest first), then by match score
  results.sort((a, b) {
    final aDist = a['distanceKm'] as double?;
    final bDist = b['distanceKm'] as double?;
    
    // If both have distances, sort by distance first
    if (aDist != null && bDist != null) {
      final distanceCompare = aDist.compareTo(bDist);
      if (distanceCompare != 0) return distanceCompare;
    }
    // If only one has distance, prioritize the one with distance
    if (aDist != null && bDist == null) return -1;
    if (aDist == null && bDist != null) return 1;
    // Otherwise sort by match score
    final aScore = a['matchScore'] as double;
    final bScore = b['matchScore'] as double;
    return bScore.compareTo(aScore);
  });
  
  // Apply limit
  if (limit != null && results.length > limit) {
    return {'results': results.take(limit).toList()};
  }
  
  return {'results': results};
}

