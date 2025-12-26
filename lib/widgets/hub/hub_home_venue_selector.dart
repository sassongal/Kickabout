import 'package:flutter/material.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/venues_repository.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/widgets/input/smart_venue_search_field.dart';
import 'package:kattrick/utils/city_utils.dart';

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
    final hubAsync = ref.watch(hubStreamProvider(hubId));

    return hubAsync.when(
      data: (hub) {
        if (hub == null) {
          return const SizedBox.shrink();
        }
        return _HubHomeVenueSelectorContent(
          hubId: hubId,
          hub: hub,
          venuesRepo: venuesRepo,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
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

  Future<void> _selectHomeVenue() async {
    showModalBottomSheet<Venue>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'בחר מגרש בית',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SmartVenueSearchField(
                    onVenueSelected: (venue) {
                      Navigator.pop(context, venue);
                    },
                    label: 'חפש או בחר ממפה',
                    hint: 'שם מגרש, כתובת או גלילה במפה',
                    hubId: widget.hubId,
                    filterCity: widget.hub.city,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((venue) async {
      if (venue == null) return;
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await _handleVenueSelection(venue);
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
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _handleVenueSelection(Venue result) async {
    final hubsRepo = ref.read(hubsRepositoryProvider);

    debugPrint('🏟️ Setting home venue: ${result.name} (${result.venueId})');

    await hubsRepo.setHubPrimaryVenue(widget.hubId, result.venueId);

    // If hub city is empty, populate from venue city (and region)
    if ((widget.hub.city == null || widget.hub.city!.isEmpty) &&
        result.city != null &&
        result.city!.isNotEmpty) {
      final region = CityUtils.getRegionForCity(result.city!);
      await hubsRepo.updateHub(widget.hubId, {
        'city': result.city,
        'region': region,
      });
    }

    debugPrint('✅ Home venue saved successfully');

    if (mounted) {
      setState(() {
        _lastMainVenueId = result.venueId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('מגרש הבית עודכן בהצלחה!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(_HubHomeVenueSelectorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMainVenueId = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
    if (newMainVenueId != _lastMainVenueId) {
      _lastMainVenueId = newMainVenueId;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final venueIdToLoad = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;

    if (venueIdToLoad != _lastMainVenueId) {
      debugPrint('🔄 Venue ID changed: $_lastMainVenueId → $venueIdToLoad');
    }

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
      key: ValueKey('home_venue_${venueIdToLoad ?? 'none'}'),
      future: venueIdToLoad != null && venueIdToLoad.isNotEmpty
          ? widget.venuesRepo.getVenue(venueIdToLoad)
          : Future.value(null),
      builder: (context, snapshot) {
        final homeVenue = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'מגרש בית',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        homeVenue != null ? homeVenue.name : 'לא נבחר',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
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
                    width: 20,
                    height: 20,
                    child: KineticLoadingAnimation(size: 20),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _selectHomeVenue,
                    tooltip:
                        homeVenue != null ? 'ערוך מגרש בית' : 'בחר מגרש בית',
                    padding: const EdgeInsets.all(8),
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

/// Dialog for selecting a venue with sorting capabilities
class _VenueSelectionDialog extends StatefulWidget {
  final String city;
  final List<Venue> venues;
  final VenuesRepository venuesRepo;

  const _VenueSelectionDialog({
    required this.city,
    required this.venues,
    required this.venuesRepo,
  });

  @override
  State<_VenueSelectionDialog> createState() => _VenueSelectionDialogState();
}

enum _SortType { name, distance }

class _VenueSelectionDialogState extends State<_VenueSelectionDialog> {
  List<Venue> _sortedVenues = [];
  _SortType _sortType = _SortType.distance;
  bool _isLoading = true;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get user location
      try {
        _userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Could not get user location: $e');
      }

      // Load venues for the city
      final venues = await widget.venuesRepo.getVenuesForMap();
      final cityVenues = venues.where((v) {
        return v.isActive &&
            v.city?.trim().toLowerCase() == widget.city.trim().toLowerCase();
      }).toList();

      setState(() {
        _sortedVenues = cityVenues;
        _isLoading = false;
      });

      _sortVenues();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת מגרשים: $e')),
        );
      }
    }
  }

  void _sortVenues() {
    setState(() {
      if (_sortType == _SortType.name) {
        _sortedVenues.sort((a, b) => a.name.compareTo(b.name));
      } else if (_sortType == _SortType.distance && _userPosition != null) {
        _sortedVenues.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            a.location.latitude,
            a.location.longitude,
          );
          final distB = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            b.location.latitude,
            b.location.longitude,
          );
          return distA.compareTo(distB);
        });
      }
    });
  }

  String _getDistance(Venue venue) {
    if (_userPosition == null) return '';
    final distance = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      venue.location.latitude,
      venue.location.longitude,
    );
    if (distance < 1000) {
      return '${distance.round()} מ\'';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} ק"מ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('בחר מגרש בית מ${widget.city}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Sort buttons
            Row(
              children: [
                const Text('מיון לפי:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('שם'),
                  selected: _sortType == _SortType.name,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _sortType = _SortType.name);
                      _sortVenues();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('מרחק'),
                  selected: _sortType == _SortType.distance,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _sortType = _SortType.distance);
                      _sortVenues();
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            // Venue list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sortedVenues.isEmpty
                      ? Center(
                          child: Text('לא נמצאו מגרשים ב${widget.city}'),
                        )
                      : ListView.builder(
                          itemCount: _sortedVenues.length,
                          itemBuilder: (context, index) {
                            final venue = _sortedVenues[index];
                            final distance = _getDistance(venue);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: venue.isPublic
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    venue.isPublic
                                        ? Icons.public
                                        : Icons.lock,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  venue.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (venue.address != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              venue.address!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (distance.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_walk,
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text(distance),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () => Navigator.pop(context, venue),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
      ],
    );
  }
}
