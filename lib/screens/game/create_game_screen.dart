import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/core/constants.dart';

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
      final gameDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final game = Game(
        gameId: '',
        createdBy: currentUserId,
        hubId: _selectedHubId!,
        gameDate: gameDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        teamCount: _teamCount,
        status: GameStatus.teamSelection,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await gamesRepo.createGame(game);

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

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'מיקום (אופציונלי)',
                  hintText: 'הכנס מיקום המשחק',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textInputAction: TextInputAction.done,
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
