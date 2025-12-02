import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/venue.dart';

/// A reusable widget for searching venues with smart autocomplete.
///
/// Features:
/// - Searches both Firestore and Google Places
/// - Displays distinct icons for Verified (Firestore) vs. Discovery (Google) results
/// - Automatically saves Google results to Firestore upon selection
class SmartVenueSearchField extends ConsumerStatefulWidget {
  final Function(Venue) onVenueSelected;
  final String? initialValue;
  final String label;
  final String hint;
  final String? hubId; // Optional hubId to set on venue when created

  const SmartVenueSearchField({
    super.key,
    required this.onVenueSelected,
    this.initialValue,
    this.label = 'כתובת או שם מגרש',
    this.hint = 'חפש מגרש קהילתי/פרטי/ציבורי...',
    this.hubId,
  });

  @override
  ConsumerState<SmartVenueSearchField> createState() =>
      _SmartVenueSearchFieldState();
}

enum VenueFilterType { all, public, private }

class _SmartVenueSearchFieldState extends ConsumerState<SmartVenueSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _searchTimer;
  Position? _currentPosition;
  List<Venue> _cachedResults = [];
  List<Venue> _nearbyVenues = [];
  String _lastQuery = '';
  VenueFilterType _selectedFilter = VenueFilterType.all;
  bool _isLoadingNearby = false;
  List<String> _searchHistory = [];
  static const String _historyKey = 'venue_search_history';
  static const int _maxHistoryItems = 10;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onSearchChanged);
    _loadSearchHistory();
    _getCurrentLocation().then((_) => _loadNearbyVenues());
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        if (mounted) {
          setState(() {
            _searchHistory = history.cast<String>().toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(_searchHistory));
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    // Remove if already exists
    _searchHistory.remove(query.trim());

    // Add to beginning
    _searchHistory.insert(0, query.trim());

    // Limit to max items
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
    }

    await _saveSearchHistory();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _clearHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _removeFromHistory(String query) async {
    _searchHistory.remove(query);
    await _saveSearchHistory();
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged() {
    // Load nearby venues when search is cleared
    if (_controller.text.trim().isEmpty) {
      _loadNearbyVenues();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      // Ignore location errors, will use default
      debugPrint('⚠️ Could not get current location: $e');
    }
  }

  @override
  void didUpdateWidget(SmartVenueSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyVenues() async {
    if (_currentPosition == null || _isLoadingNearby) return;

    setState(() => _isLoadingNearby = true);

    try {
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final venues = await venuesRepo.findVenuesNearby(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 10.0, // 10km radius
      );

      // Filter and limit to 5 closest
      final filtered = _applyFilter(venues).take(5).toList();

      if (mounted) {
        setState(() {
          _nearbyVenues = filtered;
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading nearby venues: $e');
      if (mounted) {
        setState(() => _isLoadingNearby = false);
      }
    }
  }

  List<Venue> _applyFilter(List<Venue> venues) {
    switch (_selectedFilter) {
      case VenueFilterType.public:
        return venues.where((v) => v.isPublic).toList();
      case VenueFilterType.private:
        return venues.where((v) => !v.isPublic).toList();
      case VenueFilterType.all:
        return venues;
    }
  }

  Future<void> _selectFromMap() async {
    final result = await context.push<dynamic>('/venues/discover');
    if (result != null && mounted) {
      if (result is Venue) {
        _controller.text = result.name;
        widget.onVenueSelected(result);
      } else if (result is Map<String, dynamic>) {
        // Manual location selected - need to create venue
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final location = result['location'];
        final name = result['name'] as String? ?? 'מגרש';
        final address = result['address'] as String?;

        try {
          final venue = await venuesRepo.createManualVenue(
            name: name,
            address: address,
            location: location,
            hubId: '',
            createdBy: ref.read(currentUserIdProvider),
            isPublic: false,
          );
          _controller.text = venue.name;
          widget.onVenueSelected(venue);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('שגיאה ביצירת מגרש: $e')),
            );
          }
        }
      }
    }
  }

  Widget _buildFilterChip(String label, VenueFilterType filterType) {
    final isSelected = _selectedFilter == filterType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterType;
          });
          // Trigger options rebuild by clearing and re-adding text
          final currentText = _controller.text;
          _controller.clear();
          Future.microtask(() {
            if (mounted) {
              _controller.text = currentText;
            }
          });
        }
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return '';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} מ\'';
    }
    return '${distanceKm.toStringAsFixed(1)} ק"מ';
  }

  double? _calculateDistance(Venue venue) {
    if (_currentPosition == null) return null;
    try {
      return Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            venue.location.latitude,
            venue.location.longitude,
          ) /
          1000; // Convert to km
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Venue>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            final query = textEditingValue.text.trim();

            // Show nearby venues when search is empty (no history shown in autocomplete)
            if (query.isEmpty) {
              return _applyFilter(_nearbyVenues);
            }

            // Show history when user starts typing (1 character)
            // History will be displayed in optionsViewBuilder
            if (query.length == 1) {
              return const Iterable<Venue>.empty();
            }

            if (query.length < 2) {
              return const Iterable<Venue>.empty();
            }

            // Debouncing: cancel previous search
            _searchTimer?.cancel();

            // Check cache first
            if (query == _lastQuery && _cachedResults.isNotEmpty) {
              return _applyFilter(_cachedResults);
            }

            // Debounce search
            final completer = Completer<List<Venue>>();
            _searchTimer = Timer(const Duration(milliseconds: 400), () async {
              try {
                final results = await ref
                    .read(venuesRepositoryProvider)
                    .searchVenuesCombined(query);

                // Sort by distance if we have location
                if (_currentPosition != null) {
                  results.sort((a, b) {
                    final distA = _calculateDistance(a) ?? double.infinity;
                    final distB = _calculateDistance(b) ?? double.infinity;
                    return distA.compareTo(distB);
                  });
                }

                // Cache results
                _cachedResults = results;
                _lastQuery = query;

                if (!completer.isCompleted) {
                  completer.complete(_applyFilter(results));
                }
              } catch (e) {
                if (!completer.isCompleted) {
                  completer.completeError(e);
                }
              }
            });

            return completer.future;
          },
          displayStringForOption: (Venue option) => option.name,
          onSelected: (Venue selection) async {
            // Get messenger before async operations
            final messenger = ScaffoldMessenger.maybeOf(context);

            Venue venue = selection;
            // If it's a Google result (empty ID), save it
            if (venue.venueId.isEmpty) {
              try {
                debugPrint(
                    '💾 Saving Google Places venue to Firestore: ${venue.name}');
                // If hubId is provided, set it on the venue before saving
                if (widget.hubId != null && widget.hubId!.isNotEmpty) {
                  venue = venue.copyWith(hubId: widget.hubId!);
                  debugPrint('   Setting hubId: ${widget.hubId}');
                }
                venue = await ref
                    .read(venuesRepositoryProvider)
                    .getOrCreateVenueFromGooglePlace(venue);
                debugPrint('✅ Venue saved with ID: ${venue.venueId}');
              } catch (e, stackTrace) {
                debugPrint('❌ Error creating venue: $e');
                debugPrint('Stack trace: $stackTrace');
                // Show error to user but still allow selection
                if (mounted && messenger != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('שגיאה בשמירת המגרש: $e'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                // Don't proceed if venue creation failed - user needs a valid venue
                return;
              }
            }

            // Verify venue has valid ID before proceeding
            if (venue.venueId.isEmpty) {
              debugPrint('⚠️ Venue still has empty ID after processing');
              if (mounted && messenger != null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('שגיאה: לא ניתן להוסיף מגרש ללא מזהה תקין'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              return;
            }

            if (!mounted) return;
            _controller.text = venue.name;

            // Add to search history
            await _addToHistory(venue.name);

            widget.onVenueSelected(venue);

            // Unfocus to close keyboard
            _focusNode.unfocus();
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Venue> onSelected,
              Iterable<Venue> options) {
            final optionsList = options.toList();
            final query = _controller.text.trim();
            final isEmpty = query.isEmpty;
            final showHistory = isEmpty || query.length == 1;
            final filteredHistory = showHistory && query.length == 1
                ? _searchHistory
                    .where((item) =>
                        item.toLowerCase().startsWith(query.toLowerCase()))
                    .take(5)
                    .toList()
                : (isEmpty ? _searchHistory.take(5).toList() : <String>[]);

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search history section
                      if (filteredHistory.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'היסטוריית חיפושים',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (_searchHistory.isNotEmpty)
                                TextButton(
                                  onPressed: _clearHistory,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'נקה הכל',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final historyItem = filteredHistory[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.history,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              title: Text(
                                historyItem,
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () =>
                                    _removeFromHistory(historyItem),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              onTap: () {
                                _controller.text = historyItem;
                                _controller.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: historyItem.length),
                                );
                                // Trigger search by moving cursor
                                _focusNode.requestFocus();
                              },
                            );
                          },
                        ),
                        if (optionsList.isNotEmpty || _nearbyVenues.isNotEmpty)
                          Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                      ],
                      // Filter chips (only show when there are results)
                      if (optionsList.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'סינון:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildFilterChip(
                                        'הכל',
                                        VenueFilterType.all,
                                      ),
                                      const SizedBox(width: 4),
                                      _buildFilterChip(
                                        'ציבורי',
                                        VenueFilterType.public,
                                      ),
                                      const SizedBox(width: 4),
                                      _buildFilterChip(
                                        'פרטי',
                                        VenueFilterType.private,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Results list or nearby venues
                      Flexible(
                        child: optionsList.isEmpty
                            ? (isEmpty && _nearbyVenues.isNotEmpty
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _nearbyVenues.length,
                                    itemBuilder: (context, index) {
                                      final venue = _nearbyVenues[index];
                                      final distance =
                                          _calculateDistance(venue);
                                      final isVerified =
                                          venue.venueId.isNotEmpty;
                                      final isPopular = venue.hubCount > 0;

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isVerified
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          child: Icon(
                                            isVerified
                                                ? Icons.verified
                                                : Icons.map,
                                            color: isVerified
                                                ? Colors.blue
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                venue.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            if (isPopular)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    right: 4),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${venue.hubCount}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (venue.address != null)
                                              Text(
                                                venue.address!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (distance != null) ...[
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    _formatDistance(distance),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                if (!venue.isPublic)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Text(
                                                      'פרטי',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        onTap: () => onSelected(venue),
                                      );
                                    },
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: isEmpty && _isLoadingNearby
                                          ? const CircularProgressIndicator()
                                          : Text(
                                              isEmpty
                                                  ? 'טוען מגרשים קרובים...'
                                                  : 'לא נמצאו תוצאות',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ))
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: optionsList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Venue option = optionsList[index];
                                  final distance = _calculateDistance(option);
                                  final isVerified = option.venueId.isNotEmpty;
                                  final isPopular = option.hubCount > 0;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isVerified
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      child: Icon(
                                        isVerified ? Icons.verified : Icons.map,
                                        color: isVerified
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isPopular)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${option.hubCount}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (option.address != null)
                                          Text(
                                            option.address!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (distance != null) ...[
                                              Icon(
                                                Icons.location_on,
                                                size: 12,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                _formatDistance(distance),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (!option.isPublic)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'פרטי',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map),
                  tooltip: 'בחר מהמפה',
                  onPressed: _selectFromMap,
                ),
                helperText: 'הקלד שם/כתובת או לחץ על המפה לבחירה',
              ),
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
        );
      },
    );
  }
}
