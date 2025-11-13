import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/hub_event.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/data/users_repository.dart';

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
              onPressed: () => _showCreateEventDialog(context),
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
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('שגיאה: ${snapshot.error}'),
                );
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_note, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'אין אירועים',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isManager
                            ? 'צור אירוע חדש כדי להתחיל'
                            : 'אין אירועים זמינים כרגע',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.description != null && event.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(event.description!),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Text(dateFormat.format(event.eventDate)),
                            ],
                          ),
                          if (event.location != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 4),
                                Expanded(child: Text(event.location!)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${event.registeredPlayerIds.length} נרשמו',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: currentUserId != null && !isPast
                          ? ElevatedButton(
                              onPressed: isRegistered
                                  ? () => _unregisterFromEvent(event)
                                  : () => _registerToEvent(event),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isRegistered
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(isRegistered ? 'בוטל' : 'הירשם'),
                            )
                          : widget.isManager
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editEvent(context, event),
                                      tooltip: 'ערוך',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteEvent(event),
                                      color: Colors.red,
                                      tooltip: 'מחק',
                                    ),
                                  ],
                                )
                              : null,
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

  Future<void> _showCreateEventDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('צור אירוע'),
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
                    selectedDate = picked;
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
                    selectedTime = picked;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
              Navigator.pop(context, true);
            },
            child: const Text('צור'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) return;

      final eventDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final event = HubEvent(
        eventId: '',
        hubId: widget.hubId,
        createdBy: currentUserId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        eventDate: eventDate,
        location: locationController.text.trim().isEmpty
            ? null
            : locationController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
        await hubEventsRepo.createHubEvent(event);
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'אירוע נוצר בהצלחה!');
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showErrorFromException(context, e);
        }
      }
    }
  }

  Future<void> _registerToEvent(HubEvent event) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      await hubEventsRepo.registerToEvent(widget.hubId, event.eventId, currentUserId);
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'נרשמת לאירוע!');
      }
    } catch (e) {
      if (context.mounted) {
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
      if (context.mounted) {
        SnackbarHelper.showSuccess(context, 'ביטלת הרשמה לאירוע');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
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
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'אירוע עודכן בהצלחה!');
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showError(context, 'שגיאה בעדכון אירוע: $e');
        }
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
        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'אירוע נמחק');
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showErrorFromException(context, e);
        }
      }
    }
  }
}

