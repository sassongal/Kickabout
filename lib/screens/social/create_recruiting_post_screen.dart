import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/hub_events_repository.dart';
import 'package:kattrick/models/models.dart';

import 'package:kattrick/utils/snackbar_helper.dart';

class CreateRecruitingPostScreen extends ConsumerStatefulWidget {
  final String hubId;

  const CreateRecruitingPostScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<CreateRecruitingPostScreen> createState() =>
      _CreateRecruitingPostScreenState();
}

class _CreateRecruitingPostScreenState
    extends ConsumerState<CreateRecruitingPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isUrgent = false;
  DateTime? _recruitingUntil;
  String? _linkedGameId;
  String? _linkedEventId;
  int _neededPlayersCount = 1;
  int _maxPlayersAllowed = 50;

  List<Game> _upcomingGames = [];
  HubEvent? _linkedEvent;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadUpcomingGamesAndEvents();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUpcomingGamesAndEvents() async {
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);

      // Fetch upcoming games
      final games = await gamesRepo.listGamesByHub(widget.hubId, limit: 20);
      final now = DateTime.now();
      final upcomingGames = games
          .where((g) =>
              g.gameDate.isAfter(now) &&
              (g.status == GameStatus.teamSelection ||
                  g.status == GameStatus.teamsFormed))
          .toList();

      if (mounted) {
        setState(() {
          _upcomingGames = upcomingGames;
        });
      }
    } catch (e) {
      debugPrint('Error loading games and events: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'יש להתחבר כדי לפרסם גיוס שחקנים');
        Navigator.pop(context);
      }
      return;
    }

    try {
      final perms = await ref
          .read(hubPermissionsProvider(
                  (hubId: widget.hubId, userId: currentUserId))
              .future);
      final allowed = perms.isManager || perms.isModerator;
      if (!allowed && mounted) {
        SnackbarHelper.showError(
            context, 'רק מנהלים/מודרטורים יכולים לפרסם גיוס שחקנים');
        Navigator.pop(context);
      } else if (mounted) {
        setState(() => _hasPermission = true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
            context, 'שגיאה בבדיקת הרשאות: ${e.toString()}');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadEventDetails(String eventId) async {
    try {
      final eventsRepo = HubEventsRepository();
      final event = await eventsRepo.getHubEvent(widget.hubId, eventId);

      if (event != null && mounted) {
        final availableSpots = event.maxParticipants - event.registeredPlayerIds.length;
        setState(() {
          _linkedEvent = event;
          _maxPlayersAllowed = availableSpots > 0 ? availableSpots : 1;
          // Auto-set the needed players to available spots if it exceeds
          if (_neededPlayersCount > _maxPlayersAllowed) {
            _neededPlayersCount = _maxPlayersAllowed;
          }
          // Auto-set recruiting until to event date if not already set
          _recruitingUntil ??= event.eventDate;
        });
      }
    } catch (e) {
      debugPrint('Error loading event details: $e');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      setState(() => _recruitingUntil = picked);
    }
  }


  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'he').format(date);
  }

  Future<void> _showNumberPickerDialog() async {
    int selectedValue = _neededPlayersCount;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _linkedEvent != null
            ? 'בחר מספר שחקנים (עד $_maxPlayersAllowed)'
            : 'בחר מספר שחקנים'
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            height: 200,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                selectedValue = index + 1;
              },
              controller: FixedExtentScrollController(
                initialItem: _neededPlayersCount - 1,
              ),
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final value = index + 1;
                  return Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: value == selectedValue
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                  );
                },
                childCount: _maxPlayersAllowed,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _neededPlayersCount = selectedValue);
              Navigator.pop(context);
            },
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRecruitingPost() async {
    if (!_hasPermission) return;
    if (!_formKey.currentState!.validate()) return;

    // Check if event is full
    if (_linkedEvent != null && _maxPlayersAllowed <= 0) {
      if (mounted) {
        SnackbarHelper.showError(context, 'האירוע מלא - לא ניתן לפרסם');
      }
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final hubsRepo = ref.read(hubsRepositoryProvider);
    final hub = await hubsRepo.getHub(widget.hubId);

    if (hub == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Hub לא נמצא');
      }
      return;
    }

    // Check permissions - fetch asynchronously with membership data
    try {
      final hubPermissionsAsync = await ref.read(
        hubPermissionsProvider((hubId: widget.hubId, userId: currentUserId))
            .future,
      );

      if (!hubPermissionsAsync.canCreatePosts) {
        if (mounted) {
          SnackbarHelper.showError(context, 'אין לך הרשאה לפרסם');
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בבדיקת הרשאות');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user data for denormalization
      final usersRepo = ref.read(usersRepositoryProvider);
      final currentUser = await usersRepo.getUser(currentUserId);

      final post = FeedPost(
        postId: '',
        hubId: widget.hubId,
        authorId: currentUserId,
        type: 'hub_recruiting',
        content: _descriptionController.text.trim(),
        photoUrls: [],
        createdAt: DateTime.now(),
        gameId: _linkedGameId,
        eventId: _linkedEventId,
        isUrgent: _isUrgent,
        recruitingUntil: _recruitingUntil,
        neededPlayers: _neededPlayersCount,
        region: hub.region,
        city: hub.city, // Add city for display
        hubName: hub.name,
        hubLogoUrl: hub.logoUrl,
        authorName: currentUser?.name,
        authorPhotoUrl: currentUser?.photoUrl,
      );

      await ref.read(feedRepositoryProvider).createPost(post);

      // Analytics: hook in a dedicated recruiting event when available
      // try {
      //   await AnalyticsService()
      //       .logRecruitingPostCreated(hubId: widget.hubId);
      // } catch (e) {
      //   debugPrint('Failed to log analytics: $e');
      // }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הפוסט פורסם בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'מחפש שחקנים',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hub Info
              StreamBuilder<Hub?>(
                stream: ref.read(hubsRepositoryProvider).watchHub(widget.hubId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const PremiumLoadingState(
                        message: 'טוען פרטי Hub...');
                  }
                  final hub = snapshot.data!;
                  return Card(
                    child: ListTile(
                      leading: hub.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: hub.logoUrl!,
                              imageBuilder: (context, provider) => CircleAvatar(
                                radius: 24,
                                backgroundImage: provider,
                              ),
                              placeholder: (context, url) => const SizedBox(
                                height: 48,
                                width: 48,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  const CircleAvatar(
                                radius: 24,
                                child: Icon(Icons.error),
                              ),
                            )
                          : CircleAvatar(
                              radius: 24,
                              child: Text(hub.name[0]),
                            ),
                      title: Text(hub.name),
                      subtitle: Text('${hub.memberCount} שחקנים'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Link to Game/Event
              Text(
                'קישור לאירוע (אופציונלי)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'בחר משחק או אירוע',
                  hintText: 'לא חובה - ניתן להשאיר ריק',
                  border: OutlineInputBorder(),
                ),
                initialValue: _linkedGameId != null
                    ? 'game_$_linkedGameId'
                    : _linkedEventId != null
                        ? 'event_$_linkedEventId'
                        : null,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('כללי (ללא קישור)'),
                  ),
                  ..._upcomingGames.map((game) => DropdownMenuItem(
                        value: 'game_${game.gameId}',
                        child: Text('משחק: ${_formatDate(game.gameDate)}'),
                      )),
                ],
                onChanged: (value) async {
                  setState(() {
                    if (value?.startsWith('game_') == true) {
                      _linkedGameId = value!.replaceFirst('game_', '');
                      _linkedEventId = null;
                      _linkedEvent = null;
                      _maxPlayersAllowed = 50; // Reset to default
                    } else if (value?.startsWith('event_') == true) {
                      _linkedEventId = value!.replaceFirst('event_', '');
                      _linkedGameId = null;
                    } else {
                      _linkedGameId = null;
                      _linkedEventId = null;
                      _linkedEvent = null;
                      _maxPlayersAllowed = 50; // Reset to default
                    }
                  });

                  // Load event details if an event was selected
                  if (_linkedEventId != null) {
                    await _loadEventDetails(_linkedEventId!);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'תיאור',
                  hintText: 'למשל: מחפשים שחקנים למשחק מחר בערב!',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 300,
                validator: (value) =>
                    value == null || value.isEmpty ? 'שדה חובה' : null,
              ),

              const SizedBox(height: 16),

              // Number of Players Needed - Number Picker
              Card(
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('כמה שחקנים צריך?'),
                  subtitle: Text(
                    _linkedEvent != null
                        ? '$_neededPlayersCount שחקנים (מקסימום: $_maxPlayersAllowed)'
                        : '$_neededPlayersCount שחקנים'
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _neededPlayersCount > 1
                            ? () => setState(() => _neededPlayersCount--)
                            : null,
                      ),
                      Text(
                        '$_neededPlayersCount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _neededPlayersCount < _maxPlayersAllowed
                            ? () => setState(() => _neededPlayersCount++)
                            : null,
                      ),
                    ],
                  ),
                  onTap: () => _showNumberPickerDialog(),
                ),
              ),

              const SizedBox(height: 16),

              // Urgency Toggle
              SwitchListTile(
                title: const Text('דחוף'),
                subtitle: const Text('הצג תג "דחוף" בפוסט'),
                value: _isUrgent,
                onChanged: (value) => setState(() => _isUrgent = value),
                secondary: Icon(Icons.warning_amber,
                    color: _isUrgent ? Colors.red : Colors.grey),
              ),

              const SizedBox(height: 16),

              // Recruiting Until
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('מחפשים עד:'),
                subtitle: Text(_recruitingUntil == null
                    ? 'לא נקבע'
                    : _formatDate(_recruitingUntil!)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recruitingUntil != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _recruitingUntil = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createRecruitingPost,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'מפרסם...' : 'פרסם'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
