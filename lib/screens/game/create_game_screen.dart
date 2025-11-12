import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/models/notification.dart' as app_notification;
import 'package:kickabout/core/constants.dart';
import 'package:kickabout/services/location_service.dart';
import 'package:kickabout/screens/location/map_picker_screen.dart';
import 'package:flutter/foundation.dart';

/// Create game screen
class CreateGameScreen extends ConsumerStatefulWidget {
  final String? hubId;

  const CreateGameScreen({super.key, this.hubId});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  
  String? _selectedHubId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _teamCount = 2;
  bool _isLoading = false;
  GeoPoint? _selectedLocation;
  String? _locationAddress;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Initialize hubId from parameter if provided
    _selectedHubId = widget.hubId;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('he'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
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
          _locationController.text = address ?? '';
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

  Future<void> _createGame() async {
    if (_selectedHubId == null) {
      if (!_formKey.currentState!.validate()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור הוב')),
      );
      return;
    }
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
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);
      
      final gameDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Generate geohash if location is provided
      String? geohash;
      if (_selectedLocation != null) {
        geohash = locationService.generateGeohash(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );
      }

      final game = Game(
        gameId: '',
        createdBy: currentUserId,
        hubId: _selectedHubId!,
        gameDate: gameDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(), // Legacy text location
        locationPoint: _selectedLocation, // New geographic location
        geohash: geohash,
        teamCount: _teamCount,
        status: GameStatus.teamSelection,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final gameId = await gamesRepo.createGame(game);

      // Get hub for notifications and reminders
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(_selectedHubId!);

      // Schedule game reminders
      try {
        final reminderService = ref.read(gameReminderServiceProvider);
        await reminderService.initialize();
        await reminderService.scheduleGameReminders(
          game.copyWith(gameId: gameId),
          hub?.name ?? 'Hub',
        );
      } catch (e) {
        debugPrint('Failed to schedule game reminders: $e');
      }

      // Create feed post
      try {
        final feedRepo = ref.read(feedRepositoryProvider);
        final feedPost = FeedPost(
          postId: '',
          hubId: _selectedHubId!,
          authorId: currentUserId,
          type: 'game',
          gameId: gameId,
          createdAt: DateTime.now(),
        );
        await feedRepo.createPost(feedPost);
      } catch (e) {
        // Log error but don't fail game creation
        debugPrint('Failed to create feed post: $e');
      }

      // Create notifications for hub members (using integration service)
      try {
        final pushIntegration = ref.read(pushNotificationIntegrationServiceProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final currentUser = await usersRepo.getUser(currentUserId);
        
        if (hub != null) {
          await pushIntegration.notifyNewGame(
            gameId: gameId,
            hubId: _selectedHubId!,
            creatorName: currentUser?.name ?? 'מישהו',
            hubName: hub.name,
            memberIds: hub.memberIds,
            excludeUserId: currentUserId,
          );
        }
      } catch (e) {
        // Log error but don't fail game creation
        debugPrint('Failed to create notifications: $e');
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'המשחק נוצר בהצלחה! התראה נשלחה לחברי ההאב.',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה ביצירת משחק: $e')),
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
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    final hubsStream = currentUserId != null
        ? hubsRepo.watchHubsByMember(currentUserId)
        : Stream.value(<Hub>[]);

    return AppScaffold(
      title: 'צור משחק',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hub selection (only show if hubId not provided)
              if (_selectedHubId == null)
                StreamBuilder<List<Hub>>(
                  stream: hubsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }

                    final hubs = snapshot.data ?? [];

                    if (hubs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'אין הובס. צור הוב לפני יצירת משחק.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedHubId,
                      decoration: const InputDecoration(
                        labelText: 'הוב',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      items: hubs.map((hub) => DropdownMenuItem<String>(
                        value: hub.hubId,
                        child: Text(hub.name),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedHubId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'נא לבחור הוב';
                        }
                        return null;
                      },
                    );
                  },
                ),
              if (_selectedHubId == null) const SizedBox(height: 16),
              const SizedBox(height: 16),

              // Date selection
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'תאריך',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time selection
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'שעה',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Team count
              DropdownButtonFormField<int>(
                value: _teamCount,
                decoration: const InputDecoration(
                  labelText: 'מספר קבוצות',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                items: AppConstants.supportedTeamCounts.map((count) =>
                  DropdownMenuItem<int>(
                    value: count,
                    child: Text('$count קבוצות'),
                  ),
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _teamCount = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Location section
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
                      // Text location field (legacy support)
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'כתובת או שם מקום',
                          hintText: 'הכנס מיקום המשחק',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 8),
                      // Geographic location
                      if (_locationAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'מיקום גיאוגרפי: $_locationAddress',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
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
                                    _locationController.text = result['address'] as String? ?? '';
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
                onPressed: _isLoading ? null : _createGame,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'יוצר...' : 'צור משחק'),
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
