import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
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
  final _neededPlayersController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isUrgent = false;
  DateTime? _recruitingUntil;
  String? _photoUrl;
  String? _linkedGameId;
  String? _linkedEventId;

  List<Game> _upcomingGames = [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingGamesAndEvents();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _neededPlayersController.dispose();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (image == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final storageService = ref.read(storageServiceProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        setState(() => _isUploading = false);
        if (mounted) {
          SnackbarHelper.showError(context, 'נא להתחבר');
        }
        return;
      }

      final photoUrl = await storageService.uploadFeedPhoto(
        widget.hubId,
        currentUserId,
        image,
      );

      setState(() {
        _photoUrl = photoUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בהעלאת תמונה: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'he').format(date);
  }

  Future<void> _createRecruitingPost() async {
    if (!_formKey.currentState!.validate()) return;

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

    // Check permissions
    final hubPermissions = HubPermissions(hub: hub, userId: currentUserId);
    if (!hubPermissions.canCreatePosts()) {
      if (mounted) {
        SnackbarHelper.showError(context, 'אין לך הרשאה לפרסם');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final neededPlayers =
          int.tryParse(_neededPlayersController.text.trim()) ?? 0;

      // Get user data for denormalization
      final usersRepo = ref.read(usersRepositoryProvider);
      final currentUser = await usersRepo.getUser(currentUserId);

      final post = FeedPost(
        postId: '',
        hubId: widget.hubId,
        authorId: currentUserId,
        type: 'hub_recruiting',
        content: _descriptionController.text.trim(),
        photoUrls: _photoUrl != null ? [_photoUrl!] : [],
        createdAt: DateTime.now(),
        gameId: _linkedGameId,
        eventId: _linkedEventId,
        isUrgent: _isUrgent,
        recruitingUntil: _recruitingUntil,
        neededPlayers: neededPlayers,
        region: hub.region,
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
    return FuturisticScaffold(
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
                    return const FuturisticLoadingState(
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                value: _linkedGameId != null
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
                onChanged: (value) {
                  setState(() {
                    if (value?.startsWith('game_') == true) {
                      _linkedGameId = value!.replaceFirst('game_', '');
                      _linkedEventId = null;
                    } else if (value?.startsWith('event_') == true) {
                      _linkedEventId = value!.replaceFirst('event_', '');
                      _linkedGameId = null;
                    } else {
                      _linkedGameId = null;
                      _linkedEventId = null;
                    }
                  });
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

              // Number of Players Needed
              TextFormField(
                controller: _neededPlayersController,
                decoration: const InputDecoration(
                  labelText: 'כמה שחקנים צריך?',
                  hintText: 'למשל: 3',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // Optional
                  final num = int.tryParse(value);
                  if (num == null || num < 1) return 'מספר לא תקין';
                  return null;
                },
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

              const SizedBox(height: 16),

              // Photo Upload (simplified for now)
              Text(
                'תמונה (אופציונלי)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_photoUrl != null) ...[
                CachedNetworkImage(
                  imageUrl: _photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('הסר תמונה'),
                  onPressed: () => setState(() => _photoUrl = null),
                ),
              ] else
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('הוסף תמונה'),
                  onPressed: _isUploading ? null : _pickImage,
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
