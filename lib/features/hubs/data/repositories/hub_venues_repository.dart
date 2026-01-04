import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_service.dart';
import 'package:kattrick/utils/geohash_utils.dart';

/// Repository for managing hub-venue relationships
///
/// Extracted from HubsRepository to follow Single Responsibility Principle.
/// Handles linking/unlinking venues to/from hubs.
class HubVenuesRepository {
  final FirebaseFirestore _firestore;

  HubVenuesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Set primary venue for hub
  ///
  /// This function:
  /// - Sets the hub's primaryVenueId and primaryVenueLocation
  /// - Syncs hub.location and hub.geohash with venue location
  /// - Adds venueId to hub's venueIds array
  /// - Increments new venue's hubCount
  /// - Decrements old primary venue's hubCount (if exists)
  /// - Sets isMain flag on venues
  ///
  /// Uses a transaction to ensure atomicity of all updates.
  ///
  /// Extracted from HubsRepository lines 1305-1397
  Future<void> setHubPrimaryVenue(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // 🔍 DIAGNOSTIC: Log venue save attempt
    debugPrint('🏟️ [HubVenuesRepo] setHubPrimaryVenue called:');
    debugPrint('   Hub ID: $hubId');
    debugPrint('   Venue ID: $venueId');

    try {
      await _firestore.runTransaction((transaction) async {
        // Get references
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final venueRef = _firestore.doc(FirestorePaths.venue(venueId));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final venueDoc = await transaction.get(venueRef);

        // Validate documents exist
        if (!hubDoc.exists) {
          debugPrint('❌ [HubVenuesRepo] Hub not found: $hubId');
          throw Exception('Hub not found');
        }
        if (!venueDoc.exists) {
          debugPrint('❌ [HubVenuesRepo] Venue not found: $venueId');
          throw Exception('Venue not found');
        }

        final hubData = hubDoc.data();
        final venueData = venueDoc.data();
        if (hubData == null) {
          debugPrint('❌ [HubVenuesRepo] Hub data is null');
          throw Exception('Hub data is null');
        }
        if (venueData == null) {
          debugPrint('❌ [HubVenuesRepo] Venue data is null');
          throw Exception('Venue data is null');
        }

        debugPrint('✅ [HubVenuesRepo] Documents validated successfully');

        // Get venue location (GeoPoint)
        final venueLocation = venueData['location'];
        if (venueLocation == null) {
          debugPrint('❌ [HubVenuesRepo] Venue has no location');
          throw Exception('Venue must have a location');
        }

        // Get old primary venue ID (if exists)
        final oldPrimaryVenueId = hubData['primaryVenueId'] as String?;
        debugPrint('📋 [HubVenuesRepo] Old primary venue: ${oldPrimaryVenueId ?? "none"}');

        // Prepare hub updates
        // Update both primaryVenueId and mainVenueId for consistency
        final hubUpdates = <String, dynamic>{
          'primaryVenueId': venueId,
          'primaryVenueLocation': venueLocation,
          'mainVenueId': venueId, // Also update mainVenueId
          'location': venueLocation, // Synchronize deprecated location field
          'geohash': venueData['geohash'] ??
              GeohashUtils.encode(
                venueLocation.latitude,
                venueLocation.longitude,
                precision: 8,
              ),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add venueId to venueIds array if not already present
        final venueIds = List<String>.from(hubData['venueIds'] ?? []);
        if (!venueIds.contains(venueId)) {
          hubUpdates['venueIds'] = FieldValue.arrayUnion([venueId]);
        }

        // Update hub
        transaction.update(hubRef, hubUpdates);

        // Handle old primary venue (if exists and different from new one)
        if (oldPrimaryVenueId != null && oldPrimaryVenueId != venueId) {
          final oldVenueRef =
              _firestore.doc(FirestorePaths.venue(oldPrimaryVenueId));
          final oldVenueDoc = await transaction.get(oldVenueRef);

          if (oldVenueDoc.exists) {
            // Decrement hubCount on old primary venue and set isMain to false
            transaction.update(oldVenueRef, {
              'hubCount': FieldValue.increment(-1),
              'isMain': false, // No longer the main venue
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Update new primary venue - increment hubCount, set isMain to true, and update hubId
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(1),
          'isMain': true, // This is now the main venue for this hub
          'hubId': hubId, // Ensure hubId is set correctly
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('📝 [HubVenuesRepo] Transaction updates prepared successfully');
      });

      debugPrint('✅ [HubVenuesRepo] Transaction committed successfully!');

      // Invalidate cache after successful transaction
      CacheService().clear(CacheKeys.hub(hubId));
      debugPrint('🗑️ [HubVenuesRepo] Cache cleared for hub: $hubId');
    } catch (e, stackTrace) {
      debugPrint('❌ [HubVenuesRepo] FAILED to set primary venue:');
      debugPrint('   Error: $e');
      debugPrint('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      throw Exception('Failed to set hub primary venue: $e');
    }
  }

  /// Unlink venue from hub
  ///
  /// This function:
  /// - Removes the venueId from hub's venueIds array
  /// - Decrements the venue's hubCount by 1
  /// - If the venueId is the primaryVenueId, also clears primaryVenueId and primaryVenueLocation
  ///
  /// Uses a transaction to ensure atomicity of all updates.
  ///
  /// Extracted from HubsRepository lines 1410-1472
  Future<void> unlinkVenueFromHub(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Get references
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final venueRef = _firestore.doc(FirestorePaths.venue(venueId));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final venueDoc = await transaction.get(venueRef);

        // Validate documents exist
        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }
        if (!venueDoc.exists) {
          throw Exception('Venue not found');
        }

        final hubData = hubDoc.data()!;

        // Check if venue is actually linked to this hub
        final venueIds = List<String>.from(hubData['venueIds'] ?? []);
        final primaryVenueId = hubData['primaryVenueId'] as String?;

        if (!venueIds.contains(venueId) && primaryVenueId != venueId) {
          // Venue is not linked, nothing to do
          return;
        }

        // Prepare hub updates
        final hubUpdates = <String, dynamic>{};

        // Remove venueId from venueIds array if present
        if (venueIds.contains(venueId)) {
          hubUpdates['venueIds'] = FieldValue.arrayRemove([venueId]);
        }

        // If this is the primary venue, clear primary venue fields
        if (primaryVenueId == venueId) {
          hubUpdates['primaryVenueId'] = null;
          hubUpdates['primaryVenueLocation'] = null;
        }

        // Update hub if there are changes
        if (hubUpdates.isNotEmpty) {
          transaction.update(hubRef, hubUpdates);
        }

        // Decrement hubCount on venue
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to unlink venue from hub: $e');
    }
  }
}
