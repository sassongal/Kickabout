import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_fonts/google_fonts.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/services/google_places_service.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog for searching and selecting a location using Google Places Autocomplete
class LocationSearchDialog extends ConsumerStatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  ConsumerState<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends ConsumerState<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get autocomplete predictions from Google Places API
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final placesService = ref.read(googlePlacesServiceProvider);
      final predictions = await placesService.getAutocomplete(query);
      
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
      debugPrint('Error searching places: $e');
    }
  }

  /// Handle place selection
  Future<void> _selectPlace(AutocompletePrediction prediction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placesService = ref.read(googlePlacesServiceProvider);
      final placeDetails = await placesService.getPlaceDetails(prediction.placeId);
      
      if (placeDetails == null) {
        throw Exception('Could not get place details');
      }

      // Update user location in Firestore
      final auth = firebase_auth.FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      
      final locationService = ref.read(locationServiceProvider);
      final geohash = locationService.generateGeohash(
        placeDetails.latitude,
        placeDetails.longitude,
      );
      
      // Extract city name from address
      String? cityName = placeDetails.address;
      if (cityName != null) {
        // Try to extract just the city name (before comma)
        final parts = cityName.split(',');
        if (parts.isNotEmpty) {
          cityName = parts[0].trim();
        }
      }
      
      // Determine region from city name
      String? region;
      if (cityName != null) {
        if (cityName.contains('חיפה') || 
            cityName.contains('קריית') || 
            cityName.contains('נשר') ||
            cityName.contains('טירת')) {
          region = 'צפון';
        } else if (cityName.contains('תל אביב') || 
                   cityName.contains('רמת גן') ||
                   cityName.contains('גבעתיים')) {
          region = 'מרכז';
        } else if (cityName.contains('באר שבע') ||
                   cityName.contains('אשדוד') ||
                   cityName.contains('אשקלון')) {
          region = 'דרום';
        } else if (cityName.contains('ירושלים')) {
          region = 'ירושלים';
        }
      }

      await userRef.update({
        'location': GeoPoint(placeDetails.latitude, placeDetails.longitude),
        'geohash': geohash,
        'city': cityName ?? placeDetails.address,
        'manualLocationCity': cityName ?? placeDetails.address,
        'hasManualLocation': true,
        if (region != null) 'region': region,
      });

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('manual_location_city', cityName ?? placeDetails.address ?? '');
      await prefs.setBool('location_permission_skipped', true);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('מיקום עודכן: ${cityName ?? placeDetails.address}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בעדכון מיקום: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'חיפוש מיקום',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FuturisticColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'הזן שם עיר או כתובת...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: FuturisticColors.surface,
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchPlaces(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Results list
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_predictions.isEmpty && _searchController.text.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'לא נמצאו תוצאות',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: FuturisticColors.textSecondary,
                    ),
                  ),
                ),
              )
            else if (_predictions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'התחל להקליד כדי לחפש...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: FuturisticColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: FuturisticColors.primary),
                      title: Text(
                        prediction.description,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FuturisticColors.textPrimary,
                        ),
                      ),
                      subtitle: prediction.structuredFormatting?.secondaryText != null
                          ? Text(
                              prediction.structuredFormatting!.secondaryText!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: FuturisticColors.textSecondary,
                              ),
                            )
                          : null,
                      onTap: () => _selectPlace(prediction),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

