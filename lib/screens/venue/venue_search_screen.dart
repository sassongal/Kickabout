import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/services/google_places_service.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/utils/snackbar_helper.dart';

/// Screen for searching venues (public and rental)
class VenueSearchScreen extends ConsumerStatefulWidget {
  final String? hubId; // If provided, will add selected venue to this hub
  final bool selectMode; // If true, returns selected venue

  const VenueSearchScreen({
    super.key,
    this.hubId,
    this.selectMode = false,
  });

  @override
  ConsumerState<VenueSearchScreen> createState() => _VenueSearchScreenState();
}

class _VenueSearchScreenState extends ConsumerState<VenueSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceResult> _venues = [];
  bool _isLoading = false;
  bool _isLoadingLocation = true;
  final bool _includeRentals = true;
  String _selectedFilter = 'all'; // 'all', 'public', 'rental'
  Position? _currentPosition;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _searchVenues();
      } else {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = 'לא ניתן לקבל את המיקום הנוכחי';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = 'שגיאה בקבלת מיקום: $e';
      });
    }
  }

  Future<void> _searchVenues() async {
    if (_currentPosition == null) {
      SnackbarHelper.showError(context, 'נא לאפשר גישה למיקום');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final placesService = GooglePlacesService();
      final query = _searchController.text.trim().isEmpty
          ? 'מגרש כדורגל'
          : _searchController.text.trim();

      final results = await placesService.searchVenues(
        query: query,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 10000, // 10km
        includeRentals: _includeRentals && _selectedFilter != 'public',
      );

      // Filter by type if needed
      final filteredResults = _selectedFilter == 'rental'
          ? results.where((r) => !r.isPublic).toList()
          : _selectedFilter == 'public'
              ? results.where((r) => r.isPublic).toList()
              : results;

      setState(() {
        _venues = filteredResults;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'שגיאה בחיפוש מגרשים: $e';
      });
    }
  }

  Future<void> _selectVenue(PlaceResult place) async {
    if (!widget.selectMode) {
      // Just show details
      _showVenueDetails(place);
      return;
    }

    // In selectMode, return the venue immediately (for home venue selection)
    // The caller will handle saving it to the hub
    try {
      final venuesRepo = ref.read(venuesRepositoryProvider);
      
      // Convert PlaceResult to Venue
      final venueFromGoogle = place.toVenue(
        hubId: widget.hubId ?? '',
        createdBy: ref.read(currentUserIdProvider),
      );
      
      // Use getOrCreateVenueFromGooglePlace to avoid duplicates
      // This will return existing venue if googlePlaceId matches, or create new one
      final venue = await venuesRepo.getOrCreateVenueFromGooglePlace(venueFromGoogle);
      
      // If hubId is provided, ensure venue is linked to hub
      if (widget.hubId != null) {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        final hub = await hubsRepo.getHub(widget.hubId!);
        if (hub != null && !hub.venueIds.contains(venue.venueId)) {
          // Add venue to hub's venueIds if not already there
          final updatedVenueIds = [...hub.venueIds, venue.venueId];
          await hubsRepo.updateHub(widget.hubId!, {'venueIds': updatedVenueIds});
        }
      }

      if (!mounted) return;
      // Return the venue object (existing or newly created)
      if (mounted) {
        context.pop(venue);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'שגיאה בבחירת מגרש: $e');
    }
  }

  void _showVenueDetails(PlaceResult place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (place.address != null) ...[
                Text('כתובת: ${place.address}'),
                const SizedBox(height: 8),
              ],
              if (place.phoneNumber != null) ...[
                Text('טלפון: ${place.phoneNumber}'),
                const SizedBox(height: 8),
              ],
              if (place.rating != null) ...[
                Text('דירוג: ${place.rating!.toStringAsFixed(1)} ⭐'),
                const SizedBox(height: 8),
              ],
              Text('סוג: ${place.isPublic ? "ציבורי" : "להשכרה"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
          if (widget.selectMode)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _selectVenue(place);
              },
              child: const Text('בחר'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: widget.selectMode ? 'בחר מגרש' : 'חיפוש מגרשים',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_location_alt),
          tooltip: 'מגרש לא מופיע? הוסף ידנית',
          onPressed: () async {
            final result = await context.push<Venue?>('/venues/create');
            // If a venue was created and we're in select mode, return it
            if (result != null && widget.selectMode && widget.hubId != null) {
              try {
                final hubsRepo = ref.read(hubsRepositoryProvider);
                final hub = await hubsRepo.getHub(widget.hubId!);
                if (hub != null) {
                  final updatedVenueIds = [...hub.venueIds, result.venueId];
                  await hubsRepo.updateHub(
                      widget.hubId!, {'venueIds': updatedVenueIds});
                }
                if (!mounted) return;
                SnackbarHelper.showSuccess(context, 'המגרש נוסף בהצלחה!');
                context.pop(result);
              } catch (e) {
                if (!mounted) return;
                SnackbarHelper.showError(context, 'שגיאה בהוספת מגרש: $e');
              }
            }
          },
        ),
      ],
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'חפש מגרש...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchVenues();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _searchVenues(),
                ),
                const SizedBox(height: 12),
                // Filters
                Row(
                  children: [
                    Text(
                      'סינון:',
                      style: PremiumTypography.labelMedium,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'all',
                            label: Text('הכל'),
                          ),
                          ButtonSegment(
                            value: 'public',
                            label: Text('ציבורי'),
                          ),
                          ButtonSegment(
                            value: 'rental',
                            label: Text('להשכרה'),
                          ),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedFilter = newSelection.first;
                          });
                          _searchVenues();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _searchVenues,
                  icon: const Icon(Icons.search),
                  label: const Text('חפש'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoadingLocation
                ? const PremiumLoadingState(message: 'מאתר את המיקום שלך...')
                : _errorMessage != null && _venues.isEmpty
                    ? PremiumEmptyState(
                        icon: Icons.error_outline,
                        title: 'שגיאה',
                        message: _errorMessage,
                        action: ElevatedButton.icon(
                          onPressed: () {
                            if (_currentPosition == null) {
                              _loadCurrentLocation();
                            } else {
                              _searchVenues();
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('נסה שוב'),
                        ),
                      )
                    : _isLoading
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: 5,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SkeletonLoader(height: 100),
                            ),
                          )
                        : _venues.isEmpty
                            ? PremiumEmptyState(
                                icon: Icons.location_searching,
                                title: 'לא נמצאו מגרשים',
                                message: 'נסה לשנות את החיפוש או להגדיל את הרדיוס',
                                action: ElevatedButton.icon(
                                  onPressed: _searchVenues,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('רענן חיפוש'),
                                ),
                              )
                            : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _venues.length,
                        itemBuilder: (context, index) {
                          final venue = _venues[index];
                          final distance = _currentPosition != null
                              ? Geolocator.distanceBetween(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                  venue.latitude,
                                  venue.longitude,
                                ) / 1000
                              : null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumCard(
                              onTap: () => _selectVenue(venue),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Icon(
                                  venue.isPublic
                                      ? Icons.sports_soccer
                                      : Icons.business,
                                  size: 40,
                                  color: venue.isPublic
                                      ? PremiumColors.primary
                                      : PremiumColors.secondary,
                                ),
                                title: Text(
                                  venue.name,
                                  style: PremiumTypography.labelLarge,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (venue.address != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: PremiumColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              venue.address!,
                                              style: PremiumTypography.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (distance != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${distance.toStringAsFixed(1)} ק"מ ממיקומך',
                                        style: PremiumTypography.bodySmall,
                                      ),
                                    ],
                                    if (venue.rating != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 14,
                                            color: PremiumColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${venue.rating!.toStringAsFixed(1)} (${venue.userRatingsTotal ?? 0} ביקורות)',
                                            style: PremiumTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: venue.isPublic
                                            ? PremiumColors.primary.withValues(alpha: 0.1)
                                            : PremiumColors.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        venue.isPublic ? 'ציבורי' : 'להשכרה',
                                        style: PremiumTypography.labelSmall.copyWith(
                                          color: venue.isPublic
                                              ? PremiumColors.primary
                                              : PremiumColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: widget.selectMode
                                    ? const Icon(Icons.chevron_left)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

