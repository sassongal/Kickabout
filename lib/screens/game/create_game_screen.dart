import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/screens/location/map_picker_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  GeoPoint? _selectedLocation;
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
  // Attendance reminder setting
  bool _enableAttendanceReminder = true;

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
        final geoPoint = locationService.positionToGeoPoint(position);
        final address = await locationService.coordinatesToAddress(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _selectedLocation = geoPoint;
          _locationAddress = address ??
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
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

  /// Load default venue from hub's mainVenueId
  Future<void> _loadDefaultVenue(String hubId) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(hubId);

      if (hub?.mainVenueId != null && hub!.mainVenueId!.isNotEmpty) {
        // Load the main venue
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final venue = await venuesRepo.getVenue(hub.mainVenueId!);

        if (venue != null && mounted) {
          setState(() {
            _selectedLocation = venue.location;
            _locationAddress = venue.address ?? venue.name;
            _locationController.text = venue.name;
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
        context.push('/login');
      }
      return;
    }

    final selectedHubId = _selectedHubId ?? '';

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
        if (_selectedLocation == null && venue.location != null) {
          _selectedLocation = venue.location;
        }
      }

      // Get hub to copy region (optional)
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = selectedHubId.isNotEmpty
          ? await hubsRepo.getHub(selectedHubId)
          : null;
      final hubRegion = hub?.region;

      final game = Game(
        gameId: '',
        createdBy: currentUserId,
        hubId: selectedHubId,
        gameDate: gameDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(), // Legacy text location
        locationPoint: _selectedLocation, // New geographic location
        geohash: geohash,
        venueId: _selectedVenueId, // Save venue ID for proper venue reference
        teamCount: _teamCount,
        status: GameStatus.teamSelection,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
        recurrenceEndDate: _recurrenceEndDate,
        durationInMinutes: _durationMinutes == 0 ? null : _durationMinutes,
        gameEndCondition: _gameEndConditionController.text.trim().isNotEmpty
            ? _gameEndConditionController.text.trim()
            : null,
        region: hubRegion, // Copy region from hub
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
          final usersRepo = ref.read(usersRepositoryProvider);
          final hubsRepo = ref.read(hubsRepositoryProvider);
          final currentUser = await usersRepo.getUser(currentUserId);

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

      // Call Cloud Function to notify hub members
      try {
        final functions = FirebaseFunctions.instance;
        final notifyFunction = functions.httpsCallable('notifyHubOnNewGame');

        final gameDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final gameTime =
            DateFormat('dd MMMM yyyy, HH:mm', 'he').format(gameDate);

        if (selectedHubId.isNotEmpty) {
          await notifyFunction.call({
            'hubId': selectedHubId,
            'gameId': gameId,
            'gameTitle': 'משחק חדש',
            'gameTime': gameTime,
          });

          debugPrint('✅ Notified hub members via Cloud Function');
        }
      } catch (e) {
        // Log error but don't fail game creation
        debugPrint('⚠️ Failed to call notifyHubOnNewGame: $e');
      }

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
              // Hub selection (optional)
              if (_selectedHubId == null) ...[
                StreamBuilder<List<Hub>>(
                  stream: hubsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }

                    final hubs = snapshot.data ?? [];

                    return DropdownButtonFormField<String?>(
                      value: _selectedHubId,
                      decoration: const InputDecoration(
                        labelText: 'הוב (אופציונלי)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('ללא Hub'),
                        ),
                        ...hubs.map((hub) => DropdownMenuItem<String?>(
                              value: hub.hubId,
                              child: Text(hub.name),
                            ))
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedHubId = value;
                        });
                        if (value != null) {
                          _loadDefaultVenue(value);
                        }
                      },
                      validator: (_) => null, // optional
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
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
                        value: _durationMinutes,
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
                      // Text location field (legacy support)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return RawAutocomplete<Venue>(
                            textEditingController: _locationController,
                            focusNode: _locationFocusNode,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.length < 2) {
                                return const Iterable<Venue>.empty();
                              }
                              return await ref
                                  .read(venuesRepositoryProvider)
                                  .searchVenuesCombined(textEditingValue.text);
                            },
                            displayStringForOption: (Venue option) =>
                                option.name,
                            onSelected: (Venue selection) async {
                              Venue venue = selection;
                              // If it's a Google result (empty ID), save it
                              if (venue.venueId.isEmpty) {
                                try {
                                  venue = await ref
                                      .read(venuesRepositoryProvider)
                                      .getOrCreateVenueFromGooglePlace(
                                          selection);
                                  debugPrint('✅ Venue saved with ID: ${venue.venueId}');
                                } catch (e) {
                                  debugPrint('❌ Error creating venue: $e');
                                  // Don't proceed if venue creation failed
                                  return;
                                }
                              }

                              // Verify venue has valid ID
                              if (venue.venueId.isEmpty) {
                                debugPrint('⚠️ Venue still has empty ID after processing');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('שגיאה: לא ניתן להוסיף מגרש ללא מזהה תקין'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _selectedLocation = venue.location;
                                _locationAddress = venue.address ?? venue.name;
                                _locationController.text = venue.name;
                                _selectedVenueId = venue.venueId; // Save venue ID
                              });
                              debugPrint('✅ Selected venue: ${venue.name} (${venue.venueId})');
                              // Unfocus to close keyboard
                              _locationFocusNode.unfocus();
                            },
                            optionsViewBuilder: (BuildContext context,
                                AutocompleteOnSelected<Venue> onSelected,
                                Iterable<Venue> options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    height: 200.0,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final Venue option =
                                            options.elementAt(index);
                                        return ListTile(
                                          leading: Icon(
                                            option.venueId.isNotEmpty
                                                ? Icons.verified
                                                : Icons.map,
                                            color: option.venueId.isNotEmpty
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                          title: Text(option.name),
                                          subtitle: Text(option.address ?? ''),
                                          onTap: () => onSelected(option),
                                        );
                                      },
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
                                decoration: const InputDecoration(
                                  labelText: 'כתובת או שם מגרש',
                                  hintText: 'חפש מגרש קהילתי/פרטי/ציבורי...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search),
                                  helperText:
                                      'הקלד שם/כתובת כדי ששחקנים יוכלו לנווט לשם',
                                ),
                                onFieldSubmitted: (String value) {
                                  onFieldSubmitted();
                                },
                              );
                            },
                          );
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
                                    _selectedLocation =
                                        result['location'] as GeoPoint;
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
