import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:geolocator/geolocator.dart';

import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/shared/infrastructure/analytics/analytics_service.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/routing/app_paths.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:kattrick/core/providers/complex_providers.dart';

import 'package:kattrick/widgets/input/smart_venue_search_field.dart';
import 'package:kattrick/shared/domain/models/targeting_criteria.dart';

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
  final _locationFocusNode = FocusNode();

  String? _selectedHubId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _teamCount = 2;
  bool _isLoading = false;
  GeographicPoint? _selectedLocation;
  String? _locationAddress;
  String? _selectedVenueId; // Venue ID for proper venue reference
  bool _isLoadingLocation = false;
  // Recurring game fields
  bool _isRecurring = false;
  String? _recurrencePattern; // 'weekly', 'biweekly', 'monthly'
  DateTime? _recurrenceEndDate;
  // Game rules fields
  int _durationMinutes = 8;
  final _gameEndConditionController = TextEditingController();
  // Public Game fields
  bool _isPublicGame = false;
  RangeValues _ageRange = const RangeValues(18, 55);
  GameVibe _selectedVibe = GameVibe.casual;
  PlayerGender _selectedGender = PlayerGender.any;

  // Attendance reminder setting
  bool _enableAttendanceReminder = true;

  // Hub city for venue filtering
  String? _hubCity;

  @override
  void initState() {
    super.initState();
    // Initialize hubId from parameter if provided
    _selectedHubId = widget.hubId;
    if (_selectedHubId != null) {
      // Load default venue for the hub
      _loadDefaultVenue(_selectedHubId!);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    _gameEndConditionController.dispose();
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
        final geoPoint = locationService.positionToGeographicPoint(position);
        String? address;
        try {
          address = await locationService.coordinatesToAddress(
            position.latitude,
            position.longitude,
          );
        } catch (e) {
          debugPrint('Error getting address: $e');
          // Continue with coordinates as address
        }

        setState(() {
          _selectedLocation = geoPoint;
          _locationAddress = address ??
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _locationController.text = address ?? _locationAddress!;
        });
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'לא ניתן לקבל מיקום. אנא בחר מיקום במפה או הזן כתובת ידנית.',
            action: SnackBarAction(
              label: 'פתח הגדרות',
              onPressed: () => Geolocator.openAppSettings(),
              textColor: Colors.white,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'שגיאה בקבלת מיקום: $e',
          action: SnackBarAction(
            label: 'נסה שוב',
            onPressed: _getCurrentLocation,
            textColor: Colors.white,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Load default venue from hub's mainVenueId (or first venue from venueIds)
  /// Also loads hub's city for venue filtering
  Future<void> _loadDefaultVenue(String hubId) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(hubId);

      if (hub != null && mounted) {
        setState(() {
          _hubCity = hub.city; // Load hub city for filtering
        });
        debugPrint('✅ Loaded hub city for filtering: ${hub.city}');
      }

      // Priority: mainVenueId > primaryVenueId > venueIds[0]
      String? venueIdToLoad = hub?.mainVenueId ?? hub?.primaryVenueId;

      // Fallback to first venue in venueIds if mainVenueId is null
      if ((venueIdToLoad == null || venueIdToLoad.isEmpty) &&
          hub != null &&
          hub.venueIds.isNotEmpty) {
        venueIdToLoad = hub.venueIds[0];
      }

      if (venueIdToLoad != null && venueIdToLoad.isNotEmpty) {
        // Load the venue
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final venue = await venuesRepo.getVenue(venueIdToLoad);

        if (venue != null && mounted) {
          setState(() {
            _selectedLocation = venue.location;
            _locationAddress = venue.address ?? venue.name;
            _locationController.text = venue.name;
            _selectedVenueId = venue.venueId; // Store venueId for saving
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load default venue: $e');
      // Don't show error to user, just skip defaulting
    }
  }

  Future<void> _createGame() async {
    // Hub is optional; validate form fields regardless
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = ref.read(currentUserIdProvider);
    final isAnonymous = ref.read(isAnonymousUserProvider);

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להתחבר')),
      );
      return;
    }

    if (isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אורחים לא יכולים ליצור משחקים. נא להתחבר או להירשם.'),
          duration: Duration(seconds: 4),
        ),
      );
      if (mounted) {
        context.push('/auth');
      }
      return;
    }

    final selectedHubId = _selectedHubId ?? '';

    setState(() => _isLoading = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);
      String? venueCity;

      final gameDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Validate location/venue for public games (required)
      if (_isPublicGame) {
        if (_selectedLocation == null &&
            (_selectedVenueId == null || _selectedVenueId!.isEmpty)) {
          if (mounted) {
            setState(() => _isLoading = false);
            SnackbarHelper.showError(
              context,
              'חובה לבחור מיקום או מגרש למשחק ציבורי. אנא בחר מיקום או מגרש.',
            );
          }
          return;
        }
      }

      // Generate geohash if location is provided
      String? geohash;
      if (_selectedLocation != null) {
        geohash = locationService.generateGeohash(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );
      }

      // Validate venue ID if provided
      if (_selectedVenueId != null && _selectedVenueId!.isNotEmpty) {
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final venue = await venuesRepo.getVenue(_selectedVenueId!);
        if (venue == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            SnackbarHelper.showError(
              context,
              'המגרש שנבחר לא נמצא. אנא בחר מגרש אחר.',
            );
          }
          return;
        }
        // Ensure venue has valid location if locationPoint is missing
        _selectedLocation ??= venue.location;
        venueCity = venue.city;
      }

      // Get hub to copy region (optional)
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = selectedHubId.isNotEmpty
          ? await hubsRepo.getHub(selectedHubId)
          : null;
      final hubRegion = hub?.region;
      final gameRegion = hubRegion ??
          (venueCity != null ? CityUtils.getRegionForCity(venueCity) : null);
      final gameCity = hub?.city ?? venueCity;

      // Create TargetingCriteria
      final targetingCriteria = TargetingCriteria(
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        gender: _selectedGender,
        vibe: _selectedVibe,
      );

      final game = Game(
        gameId: '',
        createdBy: currentUserId,
        hubId: _isPublicGame
            ? null
            : (selectedHubId.isEmpty ? null : selectedHubId),
        gameDate: gameDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(), // Legacy text location
        locationPoint: _selectedLocation, // New geographic location
        geohash: geohash,
        venueId: _selectedVenueId, // Save venue ID for proper venue reference
        teamCount: _teamCount,
        status: GameStatus.teamSelection,
        visibility:
            _isPublicGame ? GameVisibility.public : GameVisibility.private,
        requiresApproval: _isPublicGame
            ? true
            : false, // Public games require approval by default
        targetingCriteria: targetingCriteria,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
        recurrenceEndDate: _recurrenceEndDate,
        durationInMinutes: _durationMinutes == 0 ? null : _durationMinutes,
        gameEndCondition: _gameEndConditionController.text.trim().isNotEmpty
            ? _gameEndConditionController.text.trim()
            : null,
        region: gameRegion,
        city: gameCity,
        enableAttendanceReminder: _enableAttendanceReminder,
      );

      debugPrint('📝 Creating game with venueId: $_selectedVenueId');

      final gameId = await gamesRepo.createGame(game);

      // If recurring, schedule future games
      if (_isRecurring &&
          _recurrencePattern != null &&
          _recurrenceEndDate != null) {
        await _scheduleRecurringGames(
            gameId, gameDate, _recurrencePattern!, _recurrenceEndDate!);
      }

      final usersRepo = ref.read(usersRepositoryProvider);
      final currentUser = await usersRepo.getUser(currentUserId);

      // Get hub for notifications and reminders (already fetched above)

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

      // Create feed post (hub-based only)
      if (selectedHubId.isNotEmpty) {
        try {
          final feedRepo = ref.read(feedRepositoryProvider);
          final feedPost = FeedPost(
            postId: '',
            hubId: selectedHubId,
            authorId: currentUserId,
            type: 'game',
            gameId: gameId,
            createdAt: DateTime.now(),
            authorName: currentUser?.name,
            authorPhotoUrl: currentUser?.photoUrl,
            hubName: hub?.name,
            hubLogoUrl: hub?.logoUrl,
            region: hub?.region,
            city: hub?.city,
          );
          await feedRepo.createPost(feedPost);
        } catch (e) {
          debugPrint('Failed to create feed post: $e');
        }
      }

      // Create notifications for hub members (only if hub exists)
      if (hub != null) {
        // Send push notifications to hub members
        try {
          final pushIntegration =
              ref.read(pushNotificationIntegrationServiceProvider);
          final hubsRepo = ref.read(hubsRepositoryProvider);

          // Fetch member IDs from subcollection
          final memberIds = await hubsRepo.getHubMemberIds(selectedHubId);

          await pushIntegration.notifyNewGame(
            gameId: gameId,
            hubId: selectedHubId,
            creatorName: currentUser?.name ?? 'מישהו',
            hubName: hub.name,
            memberIds: memberIds,
            excludeUserId: currentUserId,
          );
        } catch (e) {
          debugPrint('Failed to create notifications: $e');
        }
      }

      // Note: Hub member notifications are already handled above via pushNotificationIntegrationService
      // The Cloud Function 'notifyHubOnNewGame' exists as an alternative but is not needed here

      // Log analytics
      try {
        final analytics = AnalyticsService();
        if (selectedHubId.isNotEmpty) {
          await analytics.logGameCreated(hubId: selectedHubId);
        }
      } catch (e) {
        debugPrint('Failed to log analytics: $e');
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

  /// Schedule recurring games based on pattern
  Future<void> _scheduleRecurringGames(
    String parentGameId,
    DateTime firstGameDate,
    String pattern,
    DateTime endDate,
  ) async {
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);

      Duration interval;
      switch (pattern) {
        case 'weekly':
          interval = const Duration(days: 7);
          break;
        case 'biweekly':
          interval = const Duration(days: 14);
          break;
        case 'monthly':
          interval = const Duration(days: 30);
          break;
        default:
          interval = const Duration(days: 7);
      }

      DateTime nextDate = firstGameDate.add(interval);
      int gameCount = 0;
      const maxGames = 52; // Limit to prevent too many games

      while (nextDate.isBefore(endDate) && gameCount < maxGames) {
        // Get the original game to copy its properties
        final originalGame = await gamesRepo.getGame(parentGameId);
        if (originalGame == null) break;

        final recurringGame = originalGame.copyWith(
          gameId: '',
          gameDate: nextDate,
          isRecurring: false, // Child games are not recurring themselves
          parentGameId: parentGameId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await gamesRepo.createGame(recurringGame);
        nextDate = nextDate.add(interval);
        gameCount++;
      }

      debugPrint('✅ Created $gameCount recurring games');
    } catch (e) {
      debugPrint('⚠️ Failed to create recurring games: $e');
      // Don't fail the main game creation if recurring games fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    final hubsAsync = currentUserId != null
        ? ref.watch(hubsByMemberStreamProvider(currentUserId))
        : const AsyncValue.data(<Hub>[]);

    return AppScaffold(
      title: 'צור משחק',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game Type Selector (Hub vs Public)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('משחק Hub'),
                    icon: Icon(Icons.group),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('משחק ציבורי'),
                    icon: Icon(Icons.public),
                  ),
                ],
                selected: {_isPublicGame},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isPublicGame = newSelection.first;
                    if (_isPublicGame) {
                      // Switching to Public Game - clear hub-specific data
                      _selectedHubId = null;
                      _hubCity = null;
                      // Clear venue selection when switching to public game
                      _selectedLocation = null;
                      _locationAddress = null;
                      _locationController.clear();
                      _selectedVenueId = null;
                    } else {
                      // Switching to Hub Game - restore hub if provided
                      _selectedHubId = widget.hubId;
                      if (_selectedHubId != null) {
                        _loadDefaultVenue(_selectedHubId!);
                      }
                    }
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 16),

              // Hub selection (Only for Hub Games)
              if (!_isPublicGame) ...[
                if (_selectedHubId == null || widget.hubId == null)
                  hubsAsync.when(
                    data: (hubs) {
                      return DropdownButtonFormField<String?>(
                        initialValue: _selectedHubId,
                        decoration: const InputDecoration(
                          labelText: 'בחר Hub',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: hubs
                            .map((hub) => DropdownMenuItem<String?>(
                                  value: hub.hubId,
                                  child: Text(hub.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedHubId = value;
                            // Clear existing venue when switching hubs
                            _selectedLocation = null;
                            _locationAddress = null;
                            _locationController.clear();
                            _selectedVenueId = null;
                          });
                          if (value != null) {
                            _loadDefaultVenue(value);
                          } else {
                            // Clear hub city when no hub selected
                            setState(() {
                              _hubCity = null;
                            });
                          }
                        },
                        validator: (value) => !_isPublicGame && value == null
                            ? 'נא לבחור Hub'
                            : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, stack) => Text('שגיאה: $err'),
                  ),
                const SizedBox(height: 16),
              ],

              // Targeting Criteria (Visible for all, emphasized for Public)
              Card(
                elevation: _isPublicGame ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: _isPublicGame
                      ? BorderSide(
                          color: Theme.of(context).primaryColor, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.track_changes,
                              color: _isPublicGame
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'קהל יעד',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isPublicGame
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                          ),
                          if (_isPublicGame)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Text(
                                '(חובה למשחק ציבורי)',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Age Range
                      Text(
                          'גילאים: ${_ageRange.start.round()} - ${_ageRange.end.round()}'),
                      RangeSlider(
                        values: _ageRange,
                        min: 16,
                        max: 60,
                        divisions: 44,
                        labels: RangeLabels(
                          _ageRange.start.round().toString(),
                          _ageRange.end.round().toString(),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _ageRange = values;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Gender
                      const Text('מגדר:'),
                      const SizedBox(height: 8),
                      SegmentedButton<PlayerGender>(
                        segments: const [
                          ButtonSegment<PlayerGender>(
                            value: PlayerGender.any,
                            label: Text('כולם'),
                            icon: Icon(Icons.people),
                          ),
                          ButtonSegment<PlayerGender>(
                            value: PlayerGender.male,
                            label: Text('גברים'),
                            icon: Icon(Icons.male),
                          ),
                          ButtonSegment<PlayerGender>(
                            value: PlayerGender.female,
                            label: Text('נשים'),
                            icon: Icon(Icons.female),
                          ),
                        ],
                        selected: {_selectedGender},
                        onSelectionChanged: (Set<PlayerGender> newSelection) {
                          setState(() {
                            _selectedGender = newSelection.first;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Vibe
                      const Text('אווירה:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: GameVibe.values.map((vibe) {
                          return ChoiceChip(
                            label: Text(vibe == GameVibe.competitive
                                ? 'תחרותי 🏆'
                                : 'כיף / קז׳ואל 🍺'),
                            selected: _selectedVibe == vibe,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _selectedVibe = vibe;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                initialValue: _teamCount,
                decoration: const InputDecoration(
                  labelText: 'מספר קבוצות',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                items: AppConstants.supportedTeamCounts
                    .map(
                      (teamCount) => DropdownMenuItem<int>(
                        value: teamCount,
                        child: Text('$teamCount קבוצות'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _teamCount = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Recurring game option
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('משחק חוזר'),
                        subtitle: const Text('צור משחק זה בכל שבוע'),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                            if (!value) {
                              _recurrencePattern = null;
                              _recurrenceEndDate = null;
                            } else {
                              _recurrencePattern = 'weekly';
                              _recurrenceEndDate =
                                  DateTime.now().add(const Duration(days: 90));
                            }
                          });
                        },
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: _recurrencePattern,
                          decoration: const InputDecoration(
                            labelText: 'תדירות',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('כל שבוע'),
                            ),
                            DropdownMenuItem(
                              value: 'biweekly',
                              child: Text('כל שבועיים'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('כל חודש'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _recurrencePattern = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('תאריך סיום'),
                          subtitle: Text(_recurrenceEndDate != null
                              ? '${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}'
                              : 'לא נבחר'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _recurrenceEndDate ??
                                  DateTime.now().add(const Duration(days: 90)),
                              firstDate: _selectedDate,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('he'),
                            );
                            if (picked != null) {
                              setState(() => _recurrenceEndDate = picked);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Game rules section (optional)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'חוקי משחק (אופציונלי)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _durationMinutes,
                        decoration: const InputDecoration(
                          labelText: 'משך המשחק (דקות)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                          helperText: 'בחר משך משחק, ברירת המחדל 8 דקות',
                        ),
                        items: const [
                          DropdownMenuItem(value: 8, child: Text('8 דקות')),
                          DropdownMenuItem(value: 10, child: Text('10 דקות')),
                          DropdownMenuItem(value: 12, child: Text('12 דקות')),
                          DropdownMenuItem(value: 15, child: Text('15 דקות')),
                          DropdownMenuItem(value: 20, child: Text('20 דקות')),
                          DropdownMenuItem(value: 30, child: Text('30 דקות')),
                          DropdownMenuItem(value: 0, child: Text('ללא הגבלה')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _durationMinutes = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gameEndConditionController,
                        decoration: const InputDecoration(
                          labelText: 'תנאי סיום',
                          hintText:
                              'לדוגמה: משחק עד 2, תיקו → הארכה של 2 דקות, המנצח נשאר',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                          helperText: 'תיאור תנאי סיום המשחק',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attendance reminder option
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('שלח תזכורת הגעה'),
                        subtitle: const Text(
                          'שלח תזכורת למשתתפים 2 שעות לפני המשחק לאישור הגעה',
                        ),
                        value: _enableAttendanceReminder,
                        onChanged: (value) {
                          setState(() {
                            _enableAttendanceReminder = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
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
                      // Smart Venue Search Field
                      SmartVenueSearchField(
                        label: _isPublicGame
                            ? 'מיקום (חובה)'
                            : 'מיקום (אופציונלי)',
                        hint: 'חפש מגרש או כתובת...',
                        initialValue: _locationController.text,
                        hubId:
                            _selectedHubId, // Pass selected hub ID if available
                        filterCity:
                            _hubCity, // Filter venues by hub city if available
                        validator: (value) {
                          if (_isPublicGame &&
                              (value == null || value.isEmpty)) {
                            return 'חובה לבחור מיקום למשחק ציבורי';
                          }
                          return null;
                        },
                        onVenueSelected: (venue) {
                          setState(() {
                            _selectedLocation = venue.location;
                            _locationAddress = venue.address ?? venue.name;
                            _locationController.text = venue.name;
                            _selectedVenueId = venue.venueId;
                          });
                          debugPrint(
                              '✅ Selected venue: ${venue.name} (${venue.venueId})');
                        },
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
                                    _locationController.clear(); // Clear the controller too
                                    _selectedVenueId = null; // Reset selected venue ID
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
                              label: Text(_isLoadingLocation
                                  ? 'מקבל מיקום...'
                                  : 'מיקום נוכחי'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await context.push(
                                  AppPaths.mapPicker,
                                  extra: _selectedLocation,
                                );
                                if (result != null &&
                                    result is Map<String, dynamic> &&
                                    mounted) {
                                  setState(() {
                                    _selectedLocation =
                                        result['location'] as GeographicPoint?;
                                    _locationAddress =
                                        result['address'] as String?;
                                    _locationController.text =
                                        result['address'] as String? ?? '';
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
