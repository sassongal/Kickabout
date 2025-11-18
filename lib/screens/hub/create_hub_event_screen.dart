import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/hub_event.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/services/push_notification_integration_service.dart';

/// Create hub event screen
class CreateHubEventScreen extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;

  const CreateHubEventScreen({
    super.key,
    required this.hubId,
    required this.hub,
  });

  @override
  ConsumerState<CreateHubEventScreen> createState() => _CreateHubEventScreenState();
}

class _CreateHubEventScreenState extends ConsumerState<CreateHubEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _teamCount = 3; // Default: 3 teams
  String? _gameType; // 3v3, 4v4, etc.
  int _durationMinutes = 12; // Default: 12 minutes
  int _maxParticipants = 15; // Default: 15, required
  bool _notifyMembers = false;
  bool _isLoading = false;
  Hub? _hub;

  final List<String> _gameTypes = ['3v3', '4v4', '5v5', '6v6', '7v7', '8v8', '9v9', '10v10', '11v11'];

  @override
  void initState() {
    super.initState();
    _loadHub();
  }

  Future<void> _loadHub() async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId);
      if (mounted) {
        setState(() {
          _hub = hub;
        });
      }
    } catch (e) {
      debugPrint('Failed to load hub: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _showDurationPicker() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _DurationPickerDialog(initialValue: _durationMinutes),
    );
    if (result != null) {
      setState(() {
        _durationMinutes = result;
      });
    }
  }

  Future<void> _showParticipantsPicker() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _ParticipantsPickerDialog(initialValue: _maxParticipants),
    );
    if (result != null) {
      setState(() {
        _maxParticipants = result;
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    // Load hub if not loaded
    if (_hub == null) {
      await _loadHub();
    }
    if (_hub == null) {
      SnackbarHelper.showError(context, 'שגיאה בטעינת פרטי ההאב');
      return;
    }

    // Check permissions
    final hubPermissions = HubPermissions(hub: _hub!, userId: currentUserId);
    if (!hubPermissions.canCreateEvents()) {
      // Get manager names
      final managers = await _getManagerNames();
      if (mounted) {
        _showPermissionDeniedDialog(managers);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final event = HubEvent(
        eventId: '',
        hubId: widget.hubId,
        createdBy: currentUserId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        eventDate: eventDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        teamCount: _teamCount,
        gameType: _gameType,
        durationMinutes: _durationMinutes,
        maxParticipants: _maxParticipants,
        notifyMembers: _notifyMembers,
      );

      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final eventId = await hubEventsRepo.createHubEvent(event);

      // Send notifications if requested
      if (_notifyMembers) {
        try {
          final pushIntegration = ref.read(pushNotificationIntegrationServiceProvider);
          final usersRepo = ref.read(usersRepositoryProvider);
          final currentUser = await usersRepo.getUser(currentUserId);
          
          await pushIntegration.notifyNewEvent(
            eventId: eventId,
            hubId: widget.hubId,
            creatorName: currentUser?.name ?? 'מישהו',
            hubName: _hub?.name ?? 'האב',
            memberIds: _hub?.memberIds ?? [],
            excludeUserId: currentUserId,
            eventTitle: event.title,
            eventDate: eventDate,
          );
        } catch (e) {
          debugPrint('Failed to send event notifications: $e');
          // Don't fail event creation if notification fails
        }
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'אירוע נוצר בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<String>> _getManagerNames() async {
    final managers = <String>[];
    final usersRepo = ref.read(usersRepositoryProvider);
    
    if (_hub == null) return managers;
    
    // Add creator
    try {
      final creator = await usersRepo.getUser(_hub!.createdBy);
      if (creator != null) {
        managers.add(creator.name);
      }
    } catch (e) {
      debugPrint('Failed to get creator name: $e');
    }

    // Add managers from roles (max 2 more to total 3)
    final managerIds = _hub!.roles.entries
        .where((e) => e.value == 'manager' && e.key != _hub!.createdBy)
        .take(2)
        .map((e) => e.key)
        .toList();

    for (final managerId in managerIds) {
      try {
        final manager = await usersRepo.getUser(managerId);
        if (manager != null) {
          managers.add(manager.name);
        }
      } catch (e) {
        debugPrint('Failed to get manager name: $e');
      }
    }

    return managers;
  }

  void _showPermissionDeniedDialog(List<String> managerNames) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('אין הרשאה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('רק מנהל ההאב מוגדר כיכול לבצע פעולה זו.'),
            if (managerNames.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('מנהלי ההאב:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...managerNames.map((name) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $name'),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hub == null) {
      return AppScaffold(
        title: 'צור אירוע',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'צור אירוע',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'כותרת *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'נא למלא כותרת';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'תיאור (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'מיקום (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                title: const Text('תאריך *'),
                subtitle: Text(DateFormat('dd/MM/yyyy', 'he').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 8),

              // Time
              ListTile(
                title: const Text('שעה *'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Team Count
              DropdownButtonFormField<int>(
                value: _teamCount,
                decoration: const InputDecoration(
                  labelText: 'מספר קבוצות *',
                  border: OutlineInputBorder(),
                ),
                items: [2, 3, 4].map((count) {
                  return DropdownMenuItem(
                    value: count,
                    child: Text('$count קבוצות'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _teamCount = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Game Type
              DropdownButtonFormField<String>(
                value: _gameType,
                decoration: const InputDecoration(
                  labelText: 'סוג משחק (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                items: _gameTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gameType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Duration (minutes) - Vertical picker
              ListTile(
                title: const Text('משך דקות המשחק *'),
                subtitle: Text('$_durationMinutes דקות'),
                trailing: const Icon(Icons.timer),
                onTap: _showDurationPicker,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Max Participants - Vertical picker
              ListTile(
                title: const Text('מספר משתתפים *'),
                subtitle: Text('$_maxParticipants משתתפים'),
                trailing: const Icon(Icons.people),
                onTap: _showParticipantsPicker,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Notify Members
              CheckboxListTile(
                title: const Text('שלח הודעה אוטומטית לכל חברי ההאב'),
                subtitle: const Text('חברי ההאב יקבלו התראה על האירוע החדש'),
                value: _notifyMembers,
                onChanged: (value) {
                  setState(() {
                    _notifyMembers = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Create Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('צור אירוע'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Duration picker dialog with vertical scroll
class _DurationPickerDialog extends StatefulWidget {
  final int initialValue;

  const _DurationPickerDialog({required this.initialValue});

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late FixedExtentScrollController _scrollController;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    // Start from 12 minutes (index 0)
    final initialIndex = _selectedValue >= 12 ? _selectedValue - 12 : 0;
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = List.generate(89, (i) => i + 12); // 12 to 100 minutes

    return AlertDialog(
      title: const Text('בחר משך דקות'),
      content: SizedBox(
        width: double.maxFinite,
        height: 200,
        child: ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedValue = values[index];
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final value = values[index];
              final isSelected = value == _selectedValue;
              return Center(
                child: Text(
                  '$value דקות',
                  style: TextStyle(
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
              );
            },
            childCount: values.length,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedValue),
          child: const Text('אישור'),
        ),
      ],
    );
  }
}

/// Participants picker dialog with vertical scroll
class _ParticipantsPickerDialog extends StatefulWidget {
  final int initialValue;

  const _ParticipantsPickerDialog({required this.initialValue});

  @override
  State<_ParticipantsPickerDialog> createState() => _ParticipantsPickerDialogState();
}

class _ParticipantsPickerDialogState extends State<_ParticipantsPickerDialog> {
  late FixedExtentScrollController _scrollController;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    // Start from 15 (index 0)
    final initialIndex = _selectedValue >= 6 ? _selectedValue - 6 : 0;
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = List.generate(45, (i) => i + 6); // 6 to 50 participants

    return AlertDialog(
      title: const Text('בחר מספר משתתפים'),
      content: SizedBox(
        width: double.maxFinite,
        height: 200,
        child: ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() {
              _selectedValue = values[index];
            });
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final value = values[index];
              final isSelected = value == _selectedValue;
              return Center(
                child: Text(
                  '$value משתתפים',
                  style: TextStyle(
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
              );
            },
            childCount: values.length,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedValue),
          child: const Text('אישור'),
        ),
      ],
    );
  }
}

