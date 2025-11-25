import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/services/analytics_service.dart';
import 'package:kickadoor/screens/location/map_picker_screen.dart';

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
  GeoPoint? _selectedLocation;
  String? _locationAddress;
  bool _isLoadingLocation = false;
  String? _selectedRegion;

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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        final geoPoint = locationService.positionToGeoPoint(position);
        final address = await locationService.coordinatesToAddress(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _selectedLocation = geoPoint;
          _locationAddress = address ??
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            AppLocalizations.of(context)!.locationPermissionError,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בקבלת מיקום: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
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

    setState(() => _isLoading = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);

      // Generate geohash if location is provided
      String? geohash;
      if (_selectedLocation != null) {
        geohash = locationService.generateGeohash(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
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
        memberIds: [currentUserId], // Creator is automatically a member
        location: _selectedLocation,
        geohash: geohash,
        region: _selectedRegion,
      );

      await hubsRepo.createHub(hub);

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
              const SizedBox(height: 16),

              // Venues section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.venuesOptionalLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.venuesAddLaterInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Note: Hub ID will be available after creation
                          // For now, just show info
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.venuesAddAfterCreationInfo),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_location_alt),
                        label: Text(l10n.addVenuesButton),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location section (deprecated - use venues instead)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.locationOptionalLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_locationAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationAddress!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedLocation = null;
                                    _locationAddress = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingLocation
                                  ? null
                                  : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(
                                _isLoadingLocation
                                    ? l10n.gettingLocation
                                    : l10n.currentLocation,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result =
                                    await context.push<Map<String, dynamic>>(
                                  '/map-picker',
                                  extra: MapPickerScreen(
                                    initialLocation: _selectedLocation,
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() {
                                    _selectedLocation =
                                        result['location'] as GeoPoint;
                                    _locationAddress =
                                        result['address'] as String?;
                                  });
                                }
                              },
                              icon: const Icon(Icons.map),
                              label: Text(l10n.selectOnMap),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
