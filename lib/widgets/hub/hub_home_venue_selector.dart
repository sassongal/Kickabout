import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/geohash_utils.dart';

/// Home Venue Selector - allows managers to select the hub's home field
class HubHomeVenueSelector extends ConsumerWidget {
  final String hubId;
  final VenuesRepository venuesRepo;

  const HubHomeVenueSelector({
    super.key,
    required this.hubId,
    required this.venuesRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final hubStream = hubsRepo.watchHub(hubId);

    return StreamBuilder<Hub?>(
      stream: hubStream,
      builder: (context, hubSnapshot) {
        final hub = hubSnapshot.data;
        if (hub == null) {
          return const SizedBox.shrink();
        }

        return _HubHomeVenueSelectorContent(
          hubId: hubId,
          hub: hub,
          venuesRepo: venuesRepo,
        );
      },
    );
  }
}

class _HubHomeVenueSelectorContent extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;
  final VenuesRepository venuesRepo;

  const _HubHomeVenueSelectorContent({
    required this.hubId,
    required this.hub,
    required this.venuesRepo,
  });

  @override
  ConsumerState<_HubHomeVenueSelectorContent> createState() =>
      _HubHomeVenueSelectorContentState();
}

class _HubHomeVenueSelectorContentState
    extends ConsumerState<_HubHomeVenueSelectorContent> {
  bool _isLoading = false;
  String? _lastMainVenueId;

  @override
  void initState() {
    super.initState();
    _lastMainVenueId = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
  }

  @override
  void didUpdateWidget(_HubHomeVenueSelectorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If mainVenueId changed, update the last known ID to trigger FutureBuilder refresh
    final newMainVenueId = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
    if (newMainVenueId != _lastMainVenueId) {
      _lastMainVenueId = newMainVenueId;
      // Force rebuild to reload venue
      setState(() {});
    }
  }

  Future<void> _selectHomeVenue() async {
    setState(() => _isLoading = true);

    try {
      // Navigate to discover venues screen
      final result = await context.push<dynamic>('/venues/discover');

      if (result != null && mounted) {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        final currentUserId = ref.read(currentUserIdProvider);

        if (result is Venue) {
          // Existing venue selected - use setHubPrimaryVenue for transaction and hubCount update
          // This function already updates primaryVenueId, mainVenueId, and primaryVenueLocation
          await hubsRepo.setHubPrimaryVenue(widget.hubId, result.venueId);

          // Also update location and geohash for consistency (mainVenueId is already updated by setHubPrimaryVenue)
          final geohash = GeohashUtils.encode(
            result.location.latitude,
            result.location.longitude,
            precision: 8,
          );

          await hubsRepo.updateHub(widget.hubId, {
            'location': result.location,
            'geohash': geohash,
          });
        } else if (result is Map<String, dynamic>) {
          // Manual location selected
          final location = result['location'] as GeoPoint;
          final name = result['name'] as String? ?? 'מגרש הבית';

          // Create venue first
          final venuesRepo = widget.venuesRepo;
          final newVenue = await venuesRepo.createManualVenue(
            name: name,
            address: result['address'] as String?,
            location: location,
            hubId: widget.hubId,
            createdBy: currentUserId,
            isPublic: false, // Hub's private venue
          );

          // Update hub with new venue - use setHubPrimaryVenue for transaction and hubCount update
          await hubsRepo.setHubPrimaryVenue(widget.hubId, newVenue.venueId);

          // Also update mainVenueId, location, and geohash for consistency
          final geohash = GeohashUtils.encode(
            location.latitude,
            location.longitude,
            precision: 8,
          );

          await hubsRepo.updateHub(widget.hubId, {
            'mainVenueId': newVenue.venueId,
            'location': location,
            'geohash': geohash,
          });
        }

        if (mounted) {
          // Force rebuild to reload venue after save
          setState(() {
            _lastMainVenueId =
                widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('מגרש הבית עודכן בהצלחה!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בעדכון מגרש הבית: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use primaryVenueId if mainVenueId is not set (for backward compatibility)
    final venueIdToLoad = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;

    // Update last known ID to track changes and force rebuild if changed
    if (venueIdToLoad != _lastMainVenueId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastMainVenueId = venueIdToLoad;
          });
        }
      });
    }

    return FutureBuilder<Venue?>(
      key: ValueKey(
          'home_venue_${venueIdToLoad ?? 'none'}'), // Force rebuild when venueId changes
      future: venueIdToLoad != null && venueIdToLoad.isNotEmpty
          ? widget.venuesRepo.getVenue(venueIdToLoad)
          : Future.value(null),
      builder: (context, snapshot) {
        final homeVenue = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'מגרש בית',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        homeVenue != null ? homeVenue.name : 'לא נבחר',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (homeVenue?.address != null)
                        Text(
                          homeVenue!.address!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: _selectHomeVenue,
                    tooltip:
                        homeVenue != null ? 'ערוך מגרש בית' : 'בחר מגרש בית',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
