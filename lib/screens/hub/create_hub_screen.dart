import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/services/analytics_service.dart';
import 'package:flutter/foundation.dart';
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
          _locationAddress = address ?? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'לא ניתן לקבל מיקום. אנא בדוק את ההרשאות.',
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
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להתחבר')),
      );
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
          const SnackBar(content: Text('ההוב נוצר בהצלחה!')),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating hub: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        String errorMessage = 'שגיאה ביצירת הוב';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'אין הרשאה ליצור הוב. נא לבדוק את הגדרות Firebase.';
        } else if (e.toString().contains('unauthenticated')) {
          errorMessage = 'נא להתחבר מחדש';
        } else {
          errorMessage = 'שגיאה ביצירת הוב: $e';
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
    return AppScaffold(
      title: 'צור הוב',
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
                decoration: const InputDecoration(
                  labelText: 'שם ההוב',
                  hintText: 'הכנס שם להוב',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'נא להכניס שם';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'תיאור (אופציונלי)',
                  hintText: 'הכנס תיאור להוב',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // Venues section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'מגרשים (אופציונלי)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'תוכל להוסיף מגרשים מאוחר יותר בהגדרות ההוב',
                        style: TextStyle(
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
                            const SnackBar(
                              content: Text('תוכל להוסיף מגרשים לאחר יצירת ההוב'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_location),
                        label: const Text('הוסף מגרשים'),
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
                      const Text(
                        'מיקום (אופציונלי)',
                        style: TextStyle(
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
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(_isLoadingLocation
                                  ? 'מקבל מיקום...'
                                  : 'מיקום נוכחי'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapPickerScreen(
                                      initialLocation: _selectedLocation,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() {
                                    _selectedLocation = result['location'] as GeoPoint;
                                    _locationAddress = result['address'] as String?;
                                  });
                                }
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('בחר במפה'),
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
                label: Text(_isLoading ? 'יוצר...' : 'צור הוב'),
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
