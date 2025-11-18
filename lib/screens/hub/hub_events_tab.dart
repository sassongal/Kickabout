import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/hub_event.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Hub Events Tab - shows events and allows registration
class HubEventsTab extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;
  final bool isManager;

  const HubEventsTab({
    super.key,
    required this.hubId,
    required this.hub,
    required this.isManager,
  });

  @override
  ConsumerState<HubEventsTab> createState() => _HubEventsTabState();
}

class _HubEventsTabState extends ConsumerState<HubEventsTab> {
  @override
  Widget build(BuildContext context) {
    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final eventsStream = hubEventsRepo.watchHubEvents(widget.hubId);

    return Column(
      children: [
        // Create event button (managers only)
        if (widget.isManager) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/hubs/${widget.hubId}/events/create'),
              icon: const Icon(Icons.add),
              label: const Text('צור אירוע'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        // Events list
        Expanded(
          child: StreamBuilder<List<HubEvent>>(
            stream: eventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SkeletonLoader(height: 150),
                  ),
                );
              }

              if (snapshot.hasError) {
                return FuturisticEmptyState(
                  icon: Icons.error_outline,
                  title: 'שגיאה בטעינת אירועים',
                  message: ErrorHandlerService().handleException(
                    snapshot.error,
                    context: 'Hub events tab',
                  ),
                  action: ElevatedButton.icon(
                    onPressed: () {
                      // Retry by rebuilding
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('נסה שוב'),
                  ),
                );
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return FuturisticEmptyState(
                  icon: Icons.event_note,
                  title: 'אין אירועים',
                  message: widget.isManager
                      ? 'צור אירוע חדש כדי להתחיל'
                      : 'אין אירועים זמינים כרגע',
                  action: widget.isManager
                      ? ElevatedButton.icon(
                          onPressed: () => context.push('/hubs/${widget.hubId}/events/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('צור אירוע'),
                        )
                      : null,
                );
              }

              final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isRegistered = currentUserId != null &&
                      event.registeredPlayerIds.contains(currentUserId);
                  final isPast = event.eventDate.isBefore(DateTime.now());

                  return FuturisticCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: FuturisticTypography.techHeadline.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              if (isPast)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FuturisticColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'עבר',
                                    style: FuturisticTypography.labelSmall.copyWith(
                                      color: FuturisticColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Description
                          if (event.description != null && event.description!.isNotEmpty) ...[
                            Text(
                              event.description!,
                              style: FuturisticTypography.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Date and time
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: FuturisticColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(event.eventDate),
                                style: FuturisticTypography.bodyMedium,
                              ),
                            ],
                          ),
                          // Location
                          if (event.location != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: FuturisticColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event.location!,
                                    style: FuturisticTypography.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Registered count with max participants
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 18,
                                color: FuturisticColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${event.registeredPlayerIds.length}/${event.maxParticipants} נרשמו',
                                style: FuturisticTypography.bodySmall.copyWith(
                                  color: FuturisticColors.textSecondary,
                                ),
                              ),
                              if (event.registeredPlayerIds.length >= event.maxParticipants) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'הרשמה סגורה',
                                    style: FuturisticTypography.labelSmall.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Show registered participants list (expandable)
                          if (event.registeredPlayerIds.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _RegisteredParticipantsList(
                              event: event,
                              hubId: widget.hubId,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (currentUserId != null && !isPast) ...[
                                ElevatedButton.icon(
                                  onPressed: (event.registeredPlayerIds.length >= event.maxParticipants && !isRegistered)
                                      ? null
                                      : (isRegistered
                                          ? () => _unregisterFromEvent(event)
                                          : () => _registerToEvent(event)),
                                  icon: Icon(
                                    isRegistered ? Icons.cancel : Icons.check_circle,
                                  ),
                                  label: Text(isRegistered ? 'ביטל הרשמה' : 'הירשם'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRegistered
                                        ? FuturisticColors.surfaceVariant
                                        : FuturisticColors.primary,
                                    foregroundColor: isRegistered
                                        ? FuturisticColors.textSecondary
                                        : Colors.white,
                                  ),
                                ),
                              ] else if (widget.isManager) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editEvent(context, event),
                                  tooltip: 'ערוך',
                                  color: FuturisticColors.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteEvent(event),
                                  color: FuturisticColors.error,
                                  tooltip: 'מחק',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _registerToEvent(HubEvent event) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    // Check if event is full
    if (event.registeredPlayerIds.length >= event.maxParticipants) {
      if (!mounted || !context.mounted) return;
      SnackbarHelper.showError(context, 'האירוע מלא, אין מקום להרשמה נוספת');
      return;
    }

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final registrationNumber = await hubEventsRepo.registerToEvent(widget.hubId, event.eventId, currentUserId);
      
      // Create feed post about registration
      try {
        final feedRepo = ref.read(feedRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final user = await usersRepo.getUser(currentUserId);
        final userName = user?.name ?? 'מישהו';
        
        final feedPost = FeedPost(
          postId: '',
          hubId: widget.hubId,
          authorId: currentUserId,
          type: 'event_registration',
          text: '$userName נרשם לאירוע "${event.title}" בתאריך ${DateFormat('dd/MM/yyyy', 'he').format(DateTime.now())} ($registrationNumber/${event.maxParticipants})',
          entityId: event.eventId,
          createdAt: DateTime.now(),
        );
        await feedRepo.createPost(feedPost);
      } catch (e) {
        debugPrint('Failed to create feed post for event registration: $e');
        // Don't fail registration if feed post fails
      }
      
      if (!mounted || !context.mounted) return;
      SnackbarHelper.showSuccess(context, 'נרשמת לאירוע!');
    } catch (e) {
      if (!mounted || !context.mounted) return;
      if (e.toString().contains('full')) {
        SnackbarHelper.showError(context, 'האירוע מלא, אין מקום להרשמה נוספת');
      } else {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _unregisterFromEvent(HubEvent event) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      await hubEventsRepo.unregisterFromEvent(widget.hubId, event.eventId, currentUserId);
      if (!mounted || !context.mounted) return;
      SnackbarHelper.showSuccess(context, 'ביטלת הרשמה לאירוע');
    } catch (e) {
      if (!mounted || !context.mounted) return;
      SnackbarHelper.showErrorFromException(context, e);
    }
  }

  Future<void> _editEvent(BuildContext context, HubEvent event) async {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    final locationController = TextEditingController(text: event.location ?? '');
    DateTime selectedDate = event.eventDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(event.eventDate);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('ערוך אירוע'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'כותרת',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'תיאור (אופציונלי)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'מיקום (אופציונלי)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('תאריך'),
                    subtitle: Text(DateFormat('dd/MM/yyyy', 'he').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('he'),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('שעה'),
                    subtitle: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('נא למלא כותרת')),
                    );
                    return;
                  }
                  final eventDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  Navigator.pop(
                    context,
                    {
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'location': locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      'eventDate': eventDate,
                    },
                  );
                },
                child: const Text('שמור'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      try {
        final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
        await hubEventsRepo.updateEvent(
          widget.hubId,
          event.eventId,
          {
            'title': result['title'],
            'description': result['description'],
            'location': result['location'],
            'eventDate': Timestamp.fromDate(result['eventDate'] as DateTime),
          },
        );
        if (!mounted || !context.mounted) return;
        SnackbarHelper.showSuccess(context, 'אירוע עודכן בהצלחה!');
      } catch (e) {
        if (!mounted || !context.mounted) return;
        SnackbarHelper.showError(context, 'שגיאה בעדכון אירוע: $e');
      }
    }
  }

  Future<void> _deleteEvent(HubEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת אירוע'),
        content: Text('האם אתה בטוח שברצונך למחוק את האירוע "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
        await hubEventsRepo.deleteEvent(widget.hubId, event.eventId);
        if (!mounted || !context.mounted) return;
        SnackbarHelper.showSuccess(context, 'אירוע נמחק');
      } catch (e) {
        if (!mounted || !context.mounted) return;
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }
}

/// Widget to show registered participants list
class _RegisteredParticipantsList extends ConsumerStatefulWidget {
  final HubEvent event;
  final String hubId;

  const _RegisteredParticipantsList({
    required this.event,
    required this.hubId,
  });

  @override
  ConsumerState<_RegisteredParticipantsList> createState() => _RegisteredParticipantsListState();
}

class _RegisteredParticipantsListState extends ConsumerState<_RegisteredParticipantsList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: FuturisticColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'משתתפים שנרשמו (${widget.event.registeredPlayerIds.length})',
                style: FuturisticTypography.bodySmall.copyWith(
                  color: FuturisticColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          FutureBuilder<List<User>>(
            future: ref.read(usersRepositoryProvider).getUsers(widget.event.registeredPlayerIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('שגיאה בטעינת משתתפים'),
                );
              }
              
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('אין משתתפים'),
                );
              }
              
              return Column(
                children: users.map((user) {
                  final index = widget.event.registeredPlayerIds.indexOf(user.uid) + 1;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null ? Text(user.name[0]) : null,
                    ),
                    title: Text(user.name),
                    trailing: Text(
                      '#$index',
                      style: FuturisticTypography.bodySmall.copyWith(
                        color: FuturisticColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

