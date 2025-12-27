import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/features/hubs/data/repositories/polls_repository.dart';
import 'package:kattrick/features/hubs/domain/models/poll.dart';
import 'package:kattrick/routing/app_router.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/premium/gradient_button.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';

/// Screen for creating a new poll in a Hub
class CreatePollScreen extends ConsumerStatefulWidget {
  final String hubId;

  const CreatePollScreen({
    required this.hubId,
    super.key,
  });

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  PollType _selectedType = PollType.singleChoice;
  DateTime? _endsAt;
  bool _allowMultipleVotes = false;
  bool _showResultsBeforeVote = false;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      SnackbarHelper.showWarning(context, 'מקסימום 10 אפשרויות');
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      SnackbarHelper.showWarning(context, 'חייב לפחות 2 אפשרויות');
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _endsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate options
    final optionTexts = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (optionTexts.length < 2) {
      SnackbarHelper.showError(context, 'נדרשות לפחות 2 אפשרויות');
      return;
    }

    // Check for duplicate options
    if (optionTexts.toSet().length != optionTexts.length) {
      SnackbarHelper.showError(context, 'אפשרויות לא יכולות להיות זהות');
      return;
    }

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) {
      SnackbarHelper.showError(context, 'משתמש לא מחובר');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final pollsRepo = ref.read(pollsRepositoryProvider);

      await pollsRepo.createPoll(
        hubId: widget.hubId,
        createdBy: user.uid,
        question: _questionController.text.trim(),
        optionTexts: optionTexts,
        type: _selectedType,
        endsAt: _endsAt,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        allowMultipleVotes:
            _selectedType == PollType.multipleChoice ? true : _allowMultipleVotes,
        showResultsBeforeVote: _showResultsBeforeVote,
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;

      SnackbarHelper.showSuccess(context, 'הסקר נוצר בהצלחה! 🎉');
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'שגיאה ביצירת הסקר: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
        leading: AppBarHomeLogo(showBackButton: canPop),
        title: const Text('יצירת סקר חדש'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Question
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'שאלה *',
                hintText: 'למשל: איפה נשחק השבוע?',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'נא להזין שאלה';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'תיאור (אופציונלי)',
                hintText: 'פרטים נוספים על הסקר',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 24),

            // Poll Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'סוג הסקר',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<PollType>(
                      title: const Text('בחירה אחת'),
                      subtitle: const Text('המשתמש יכול לבחור אפשרות אחת בלבד'),
                      value: PollType.singleChoice,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                    RadioListTile<PollType>(
                      title: const Text('בחירה מרובה'),
                      subtitle: const Text('המשתמש יכול לבחור מספר אפשרויות'),
                      value: PollType.multipleChoice,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                    RadioListTile<PollType>(
                      title: const Text('דירוג'),
                      subtitle: const Text('המשתמש נותן דירוג 1-5 כוכבים'),
                      value: PollType.rating,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'אפשרויות',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף אפשרות'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Option fields
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'אפשרות ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'נא להזין אפשרות';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_optionControllers.length > 2) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => _removeOption(index),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // End Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('תאריך סיום'),
                subtitle: Text(_endsAt == null
                    ? 'ללא תאריך סיום (סקר פתוח)'
                    : 'מסתיים ב-${_endsAt!.day}/${_endsAt!.month}/${_endsAt!.year} בשעה ${_endsAt!.hour}:${_endsAt!.minute.toString().padLeft(2, '0')}'),
                trailing: _endsAt == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endsAt = null),
                      ),
                onTap: _selectEndDate,
              ),
            ),

            const SizedBox(height: 16),

            // Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'הגדרות',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedType != PollType.multipleChoice)
                      SwitchListTile(
                        title: const Text('אפשר הצבעה מרובה'),
                        subtitle: const Text(
                            'המשתמש יוכל לשנות את הצבעתו'),
                        value: _allowMultipleVotes,
                        onChanged: (value) {
                          setState(() => _allowMultipleVotes = value);
                        },
                      ),
                    SwitchListTile(
                      title: const Text('הצג תוצאות לפני הצבעה'),
                      subtitle: const Text(
                          'משתמשים יראו את התוצאות גם לפני שהצביעו'),
                      value: _showResultsBeforeVote,
                      onChanged: (value) {
                        setState(() => _showResultsBeforeVote = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('הצבעה אנונימית'),
                      subtitle: const Text('לא יוצג מי הצביע לכל אפשרות'),
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() => _isAnonymous = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Create Button
            GradientButton(
              label: 'יצירת סקר',
              onPressed: _isSubmitting ? null : _createPoll,
              isLoading: _isSubmitting,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
