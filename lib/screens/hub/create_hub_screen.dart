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
  bool _isLoading = false;
  String? _selectedRegion;

  List<Venue> _selectedVenues = [];
  String? _mainVenueId;

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
            _selectedRegion = user.region;
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
    super.dispose();
  }

  Future<void> _createHub() async {
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

    if (_selectedVenues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור לפחות מגרש אחד')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);

      // Determine main venue and its location
      Venue? mainVenue;
      if (_mainVenueId != null) {
        mainVenue = _selectedVenues.firstWhere(
          (v) => v.venueId == _mainVenueId,
          orElse: () => _selectedVenues.first,
        );
      } else if (_selectedVenues.isNotEmpty) {
        mainVenue = _selectedVenues.first;
        _mainVenueId = mainVenue.venueId;
      }

      // Generate geohash if location is provided
      String? geohash;
      GeoPoint? location;

      if (mainVenue != null) {
        location = mainVenue.location;
        geohash = locationService.generateGeohash(
          location.latitude,
          location.longitude,
        );
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
        region: _selectedRegion,
        venueIds: _selectedVenues.map((v) => v.venueId).toList(),
        mainVenueId: _mainVenueId,
        primaryVenueId: _mainVenueId,
        primaryVenueLocation: location,
      );

      final hubId = await hubsRepo.createHub(hub);

      // Update hubCount for selected venues
      // Note: createHub doesn't do this automatically yet, so we might need to do it here
      // or update createHub. Since createHub is generic, let's do it here or via a separate call.
      // Ideally HubsRepository should handle this, but for now let's use VenuesRepository or HubsRepository helper.
      // Actually, setHubPrimaryVenue handles the primary one.
      // But we are creating a new hub.

      // Let's manually increment hubCount for all venues
      final venuesRepo = ref.read(venuesRepositoryProvider);
      for (final venue in _selectedVenues) {
        // We can use linkSecondaryVenueToHub which increments hubCount
        // But we need to be careful not to double add to venueIds (createHub already added them)
        // Actually linkSecondaryVenueToHub adds to venueIds AND increments hubCount.
        // Since createHub added venueIds, we just need to increment hubCount.
        // But we don't have a method just for that exposed easily.
        // Let's rely on a future update or just call linkSecondaryVenueToHub which checks for existence.
        await venuesRepo.linkSecondaryVenueToHub(hubId, venue.venueId);
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!.hubCreatedSuccess)),
        );
        context.pop();
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

              // Region field
              Builder(builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                final regions = {
                  'צפון': l10n.regionNorth,
                  'מרכז': l10n.regionCenter,
                  'דרום': l10n.regionSouth,
                  'ירושלים': l10n.regionJerusalem,
                };
                return DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: l10n.regionLabel,
                    hintText: l10n.regionHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.map),
                    helperText: l10n.regionHelperText,
                  ),
                  items: regions.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                  },
                );
              }),
              const SizedBox(height: 24),

              // Hub Venues Manager
              HubVenuesManager(
                initialVenues: _selectedVenues,
                initialMainVenueId: _mainVenueId,
                onChanged: (venues, mainVenueId) {
                  setState(() {
                    _selectedVenues = venues;
                    _mainVenueId = mainVenueId;
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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
