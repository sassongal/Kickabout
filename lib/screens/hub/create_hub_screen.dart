import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/widgets/hub/hub_venues_manager.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:image/image.dart' as img; // For image processing
import 'dart:io'; // For File
import 'dart:typed_data';
// Import the new StorageService
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/input/city_autocomplete_field.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:kattrick/widgets/input/smart_venue_search_field.dart';

/// Create hub screen
class CreateHubScreen extends ConsumerStatefulWidget {
  const CreateHubScreen({super.key});

  @override
  ConsumerState<CreateHubScreen> createState() => _CreateHubScreenState();
}

class _CreateHubScreenState extends ConsumerState<CreateHubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = false;
  String? _selectedRegion;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _logoUrl; // To store the uploaded logo URL

  List<Venue> _selectedVenues = [];
  String? _mainVenueId;
  Venue? _homeVenue;

  @override
  void initState() {
    super.initState();
    _loadUserRegion();
  }

  Future<void> _loadUserRegion() async {
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId != null) {
        final usersRepo = ref.read(usersRepositoryProvider);
        final user = await usersRepo.getUser(currentUserId);
        if (user != null && mounted) {
          setState(() {
            // Load city if available, otherwise just region
            if (user.city != null && user.city!.isNotEmpty) {
              _cityController.text = user.city!;
              _selectedRegion = CityUtils.getRegionForCity(user.city!);
            } else {
              _selectedRegion = user.region;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load user region: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _setHomeVenue(Venue venue) {
    if (venue.venueId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה: למגרש אין מזהה תקין')),
      );
      return;
    }

    // Respect max 3 venues list; ensure home is part of the list
    final alreadyInList =
        _selectedVenues.any((v) => v.venueId == venue.venueId);
    if (!alreadyInList && _selectedVenues.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ניתן להוסיף עד 3 מגרשים. הסר אחד כדי לבחור חדש.'),
        ),
      );
      return;
    }

    setState(() {
      _homeVenue = venue;
      _mainVenueId = venue.venueId;

      if (!alreadyInList) {
        _selectedVenues = [..._selectedVenues, venue];
      }

      // If city not chosen yet, fill from venue.city and derive region
      if (_cityController.text.isEmpty &&
          venue.city != null &&
          venue.city!.isNotEmpty) {
        _cityController.text = venue.city!;
        _selectedRegion = CityUtils.getRegionForCity(venue.city!);
      }
    });
  }

  Future<void> _createHub() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = ref.read(currentUserIdProvider);
    final isAnonymous = ref.read(isAnonymousUserProvider);

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseLogin)),
      );
      return;
    }

    if (isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.guestsCannotCreateHubs),
          duration: Duration(seconds: 4),
        ),
      );
      // Navigate to login
      if (mounted) {
        context.push('/login');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);

      // If home venue selected, ensure it is part of the venues list and set as main
      if (_homeVenue != null &&
          !_selectedVenues.any((v) => v.venueId == _homeVenue!.venueId)) {
        _selectedVenues = [..._selectedVenues, _homeVenue!];
      }
      if (_homeVenue != null) {
        _mainVenueId = _homeVenue!.venueId;
      }

      // Determine main venue and its location (optional)
      Venue? mainVenue;
      if (_mainVenueId != null &&
          _mainVenueId!.isNotEmpty &&
          _selectedVenues.isNotEmpty) {
        try {
          mainVenue = _selectedVenues.firstWhere(
            (v) => v.venueId == _mainVenueId && v.venueId.isNotEmpty,
          );
          debugPrint('✅ Found main venue: ${mainVenue.name} ($_mainVenueId)');
        } catch (e) {
          // If not found, use first venue if available
          debugPrint(
              '⚠️ Main venue $_mainVenueId not found in selected venues, using first');
          if (_selectedVenues.isNotEmpty) {
            mainVenue = _selectedVenues.first;
            _mainVenueId = mainVenue.venueId;
            debugPrint('✅ Setting main venue to first venue: $_mainVenueId');
          }
        }
      } else if (_selectedVenues.isNotEmpty) {
        // If no main venue selected but venues exist, use first one
        mainVenue = _selectedVenues.first;
        _mainVenueId = mainVenue.venueId;
        debugPrint('✅ Setting main venue to first venue: $_mainVenueId');
      }

      // Generate geohash and location if venue is provided (optional)
      String? geohash;
      GeoPoint? location;

      if (mainVenue != null) {
        location = mainVenue.location;
        geohash = locationService.generateGeohash(
          location.latitude,
          location.longitude,
        );
        debugPrint(
            '✅ Main venue location: ${location.latitude}, ${location.longitude}');
      } else {
        debugPrint(
            'ℹ️ No venue selected - hub will be created without location');
      }

      // --- Image Upload Logic ---
      // Filter out any venues with empty IDs
      final validVenueIds = _selectedVenues
          .map((v) => v.venueId)
          .where((id) => id.isNotEmpty)
          .toList();

      debugPrint('📝 Creating hub with:');
      debugPrint('   mainVenueId: $_mainVenueId');
      debugPrint('   primaryVenueId: $_mainVenueId');
      debugPrint('   venueIds: $validVenueIds');
      debugPrint('   location: $location');

      // Auto-calculate region from city if city is provided
      String? finalRegion = _selectedRegion;
      String? finalCity = _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim();

      if (finalCity != null && finalCity.isNotEmpty) {
        finalRegion = CityUtils.getRegionForCity(finalCity);
      }

      final hub = Hub(
        hubId: '', // Will be generated
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdBy: currentUserId,
        createdAt: DateTime.now(),
        // memberIds removed - creator added via transaction in repository
        location: location,
        geohash: geohash,
        region: finalRegion,
        city: finalCity,
        venueIds: validVenueIds,
        mainVenueId: _mainVenueId,
        primaryVenueId: _mainVenueId,
        primaryVenueLocation: location,
        logoUrl: null, // Will be updated after upload (if available)
      );

      debugPrint('📦 Hub object created:');
      debugPrint('   hub.mainVenueId: ${hub.mainVenueId}');
      debugPrint('   hub.primaryVenueId: ${hub.primaryVenueId}');
      debugPrint('   hub.venueIds: ${hub.venueIds}');

      final hubId = await hubsRepo.createHub(hub);
      debugPrint('✅ Hub created with ID: $hubId');
      debugPrint('   Verifying hub data...');

      // Upload logo after hub is created (Hub doc exists; user is manager)
      if (_selectedImage != null) {
        try {
          final imageBytes = await _selectedImage!.readAsBytes();
          final decodedImage = img.decodeImage(imageBytes);
          if (decodedImage == null) {
            throw Exception('Could not decode image.');
          }

          final resizedImage =
              img.copyResize(decodedImage, width: 512, height: 512);
          final compressedBytes =
              img.encodeJpg(resizedImage, quality: 85); // Compress to JPEG

          final storageService = ref.read(storageServiceProvider);
          final fileName = 'logo.jpg';

          _logoUrl = await storageService.uploadHubPhoto(
            hubId: hubId,
            fileName: fileName,
            fileBytes: Uint8List.fromList(compressedBytes),
            contentType: 'image/jpeg',
          );

          await hubsRepo.updateHub(hubId, {'logoUrl': _logoUrl});
          debugPrint('✅ Hub logo uploaded and saved');
        } catch (e) {
          debugPrint('Error uploading hub logo: $e');
          _logoUrl = null;
        }
      }
      // --- End Image Upload Logic ---

      // Verify the hub was created correctly
      final createdHub = await hubsRepo.getHub(hubId);
      if (createdHub != null) {
        debugPrint('✅ Hub verification:');
        debugPrint(
            '   mainVenueId: ${createdHub.mainVenueId ?? 'null (optional)'}');
        debugPrint(
            '   primaryVenueId: ${createdHub.primaryVenueId ?? 'null (optional)'}');
        debugPrint('   venueIds: ${createdHub.venueIds}');
      } else {
        debugPrint('❌ ERROR: Could not retrieve created hub!');
      }

      // Update hubCount for selected venues (if any)
      if (_selectedVenues.isNotEmpty) {
        final venuesRepo = ref.read(venuesRepositoryProvider);
        for (final venue in _selectedVenues) {
          // linkSecondaryVenueToHub increments hubCount and adds to venueIds
          // Since createHub already added venueIds, this will just increment hubCount
          await venuesRepo.linkSecondaryVenueToHub(hubId, venue.venueId);
        }
      }

      // Log analytics
      try {
        final analytics = AnalyticsService();
        await analytics.logHubCreated();
      } catch (e) {
        debugPrint('Failed to log analytics: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.hubCreatedSuccess)),
        );
        // Navigate to the newly created hub's detail screen
        context.go('/hubs/$hubId');
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating hub: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)!.hubCreationError;
        if (e.toString().contains('permission-denied')) {
          errorMessage =
              AppLocalizations.of(context)!.hubCreationPermissionError;
        } else if (e.toString().contains('unauthenticated')) {
          errorMessage = AppLocalizations.of(context)!.pleaseReLogin;
        } else {
          errorMessage = AppLocalizations.of(context)!
              .hubCreationErrorDetails(e.toString());
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
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
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.createHubTitle,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              // Hub Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null,
                    child: _selectedImage == null
                        ? Icon(Icons.camera_alt,
                            size: 40,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.hubNameLabel,
                  hintText: l10n.hubNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.group),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.hubNameValidator;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.hubDescriptionLabel,
                  hintText: l10n.hubDescriptionHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // City field (replaces region dropdown - region is auto-calculated)
              CityAutocompleteField(
                controller: _cityController,
                labelText: 'עיר ראשית של ההאב',
                hintText: 'בחר עיר...',
                helperText: 'האזור יחושב אוטומטית לפי העיר',
                onCitySelected: (city) {
                  setState(() {
                    _selectedRegion = CityUtils.getRegionForCity(city);
                  });
                },
              ),
              const SizedBox(height: 8),

              // Display calculated region
              if (_selectedRegion != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    'אזור: $_selectedRegion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              const SizedBox(height: 24),

              // Home venue selector
              Text(
                'מגרש בית',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              SmartVenueSearchField(
                onVenueSelected: _setHomeVenue,
                label: 'בחר מגרש בית',
                hint: 'חפש מגרש בית ופתח מפה...',
                initialValue: _homeVenue?.name,
                hubId: null,
                filterCity: _cityController.text.isNotEmpty
                    ? _cityController.text
                    : null,
              ),
              if (_homeVenue != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: ListTile(
                    leading: const Icon(Icons.home_work),
                    title: Text(_homeVenue!.name),
                    subtitle: _homeVenue!.address != null
                        ? Text(_homeVenue!.address!)
                        : null,
                    trailing: TextButton(
                      onPressed: () => setState(() => _homeVenue = null),
                      child: const Text('נקה'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Hub Venues Manager (optional)
              Text(
                'מגרשים (אופציונלי)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'ניתן להוסיף מגרשים מאוחר יותר במסך ההאב',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              HubVenuesManager(
                initialVenues: _selectedVenues,
                initialMainVenueId: _mainVenueId,
                onChanged: (venues, mainVenueId) {
                  setState(() {
                    // Validate venue IDs are not empty
                    _selectedVenues =
                        venues.where((v) => v.venueId.isNotEmpty).toList();
                    _mainVenueId = mainVenueId;

                    // Verify main venue is still in selected venues (optional)
                    if (_mainVenueId != null && _mainVenueId!.isNotEmpty) {
                      final mainVenueExists =
                          _selectedVenues.any((v) => v.venueId == _mainVenueId);
                      if (!mainVenueExists && _selectedVenues.isNotEmpty) {
                        _mainVenueId = _selectedVenues.first.venueId;
                        debugPrint(
                            '⚠️ Main venue not found in selected venues, resetting to first venue: $_mainVenueId');
                      } else if (!mainVenueExists) {
                        // If no venues selected, clear main venue
                        _mainVenueId = null;
                        debugPrint(
                            'ℹ️ No venues selected, clearing main venue');
                      }
                    } else if (_selectedVenues.isNotEmpty) {
                      // If no main venue selected but venues exist, use first one
                      _mainVenueId = _selectedVenues.first.venueId;
                      debugPrint(
                          '✅ Setting main venue to first venue: $_mainVenueId');
                    } else {
                      // No venues selected - clear main venue
                      _mainVenueId = null;
                      debugPrint('ℹ️ No venues selected, clearing main venue');
                    }

                    if (_mainVenueId != null) {
                      try {
                        _homeVenue = _selectedVenues
                            .firstWhere((v) => v.venueId == _mainVenueId);
                      } catch (_) {
                        // keep existing home venue if not in list
                      }
                    }
                  });
                },
              ),

              const SizedBox(height: 32),

              // Create button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createHub,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: KineticLoadingAnimation(size: 20),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? l10n.creating : l10n.createHub),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
