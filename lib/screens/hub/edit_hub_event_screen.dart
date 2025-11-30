import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/utils/snackbar_helper.dart';

/// Edit hub event screen
class EditHubEventScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const EditHubEventScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<EditHubEventScreen> createState() => _EditHubEventScreenState();
}

class _EditHubEventScreenState extends ConsumerState<EditHubEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _teamCount;
  String? _gameType;
  int? _durationMinutes;
  int? _maxParticipants;
  bool _notifyMembers = false;
  bool _showInCommunityFeed = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  HubEvent? _event;
  Hub? _hub;

  final List<String> _gameTypes = [
    '3v3',
    '4v4',
    '5v5',
    '6v6',
    '7v7',
    '8v8',
    '9v9',
    '10v10',
    '11v11'
  ];

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);

      final event =
          await hubEventsRepo.getHubEvent(widget.hubId, widget.eventId);
      final hub = await hubsRepo.getHub(widget.hubId);

      if (mounted) {
        setState(() {
          _event = event;
          _hub = hub;

          if (event != null) {
            _titleController.text = event.title;
            _descriptionController.text = event.description ?? '';
            _locationController.text = event.location ?? '';
            _selectedDate = event.eventDate;
            _selectedTime = TimeOfDay.fromDateTime(event.eventDate);
            _teamCount = event.teamCount;
            _gameType = event.gameType;
            _durationMinutes = event.durationMinutes;
            _maxParticipants = event.maxParticipants;
            _notifyMembers = event.notifyMembers;
            _showInCommunityFeed = event.showInCommunityFeed;
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load event: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        SnackbarHelper.showError(context, 'שגיאה בטעינת האירוע');
      }
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
    // Create "today" object without time to avoid comparison issues
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // The date shown when opening the calendar: either existing date or tomorrow by default
    final initialDate = _selectedDate ?? today.add(const Duration(days: 1));

    // Fix: firstDate must be the earlier of today or the selected date
    // This prevents crashes if the event date is in the past
    DateTime firstDate = today;
    if (_selectedDate != null) {
      final selectedDateOnly = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      if (selectedDateOnly.isBefore(today)) {
        firstDate = selectedDateOnly;
      }
    }

    // Safety check: ensure firstDate is never after initialDate
    if (firstDate.isAfter(initialDate)) {
      firstDate = initialDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
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
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
      builder: (context) =>
          _DurationPickerDialog(initialValue: _durationMinutes ?? 12),
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
      builder: (context) =>
          _ParticipantsPickerDialog(initialValue: _maxParticipants ?? 15),
    );
    if (result != null) {
      setState(() {
        _maxParticipants = result;
      });
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      SnackbarHelper.showError(context, 'נא לבחור תאריך ושעה');
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    if (_hub == null) {
      SnackbarHelper.showError(context, 'שגיאה בטעינת פרטי ההאב');
      return;
    }

    // Check permissions
    final hubPermissions = HubPermissions(hub: _hub!, userId: currentUserId);
    if (!hubPermissions.canCreateEvents()) {
      SnackbarHelper.showError(context, 'אין לך הרשאה לערוך אירועים בהאב זה');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Check if date is in the past
      if (eventDate.isBefore(DateTime.now())) {
        SnackbarHelper.showError(context, 'לא ניתן לבחור תאריך שכבר עבר');
        setState(() => _isLoading = false);
        return;
      }

      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);

      await hubEventsRepo.updateHubEvent(
        widget.hubId,
        widget.eventId,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'location': _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          'eventDate': eventDate,
          'teamCount': _teamCount,
          'gameType': _gameType,
          'durationMinutes': _durationMinutes,
          'maxParticipants': _maxParticipants,
          'notifyMembers': _notifyMembers,
          'showInCommunityFeed': _showInCommunityFeed,
          'updatedAt': DateTime.now(),
        },
      );

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'אירוע עודכן בהצלחה!');
      if (mounted) {
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

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת אירוע'),
        content: const Text(
            'האם אתה בטוח שברצונך למחוק את האירוע? פעולה זו לא ניתנת לביטול.'),
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

    if (confirmed != true) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    if (_hub == null) {
      SnackbarHelper.showError(context, 'שגיאה בטעינת פרטי ההאב');
      return;
    }

    // Check permissions
    final hubPermissions = HubPermissions(hub: _hub!, userId: currentUserId);
    if (!hubPermissions.canCreateEvents()) {
      SnackbarHelper.showError(context, 'אין לך הרשאה למחוק אירועים בהאב זה');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      await hubEventsRepo.deleteHubEvent(widget.hubId, widget.eventId);

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'אירוע נמחק בהצלחה!');
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return AppScaffold(
        title: 'ערוך אירוע',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return AppScaffold(
        title: 'ערוך אירוע',
        body: const Center(child: Text('אירוע לא נמצא')),
      );
    }

    return AppScaffold(
      title: 'ערוך אירוע',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _isLoading ? null : _deleteEvent,
          tooltip: 'מחק אירוע',
        ),
      ],
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
                subtitle: Text(_selectedDate != null
                    ? DateFormat('dd/MM/yyyy', 'he').format(_selectedDate!)
                    : 'לא נבחר'),
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
                subtitle: Text(_selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'לא נבחר'),
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
                initialValue: _teamCount,
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
                initialValue: _gameType,
                decoration: const InputDecoration(
                  labelText: 'סוג משחק (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('ללא')),
                  ..._gameTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _gameType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Duration (minutes)
              ListTile(
                title: const Text('משך דקות המשחק *'),
                subtitle: Text('${_durationMinutes ?? 12} דקות'),
                trailing: const Icon(Icons.timer),
                onTap: _showDurationPicker,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Max Participants
              ListTile(
                title: const Text('מספר משתתפים *'),
                subtitle: Text('${_maxParticipants ?? 15} משתתפים'),
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
                subtitle: const Text('חברי ההאב יקבלו התראה על עדכון האירוע'),
                value: _notifyMembers,
                onChanged: (value) {
                  setState(() {
                    _notifyMembers = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),

              // Show in Community Feed
              CheckboxListTile(
                title: const Text('להעלות ללוח אירועים הקהילתי?'),
                subtitle: const Text(
                    'האירוע יופיע בלוח הפעילות הקהילתי לכל המשתמשים'),
                value: _showInCommunityFeed,
                onChanged: (value) {
                  setState(() {
                    _showInCommunityFeed = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Update Button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('עדכן אירוע'),
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
  State<_ParticipantsPickerDialog> createState() =>
      _ParticipantsPickerDialogState();
}

class _ParticipantsPickerDialogState extends State<_ParticipantsPickerDialog> {
  late FixedExtentScrollController _scrollController;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
