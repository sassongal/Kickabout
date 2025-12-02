import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/models/models.dart' as model;
import 'package:kattrick/models/age_group.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupWizard extends ConsumerStatefulWidget {
  const ProfileSetupWizard({super.key});

  @override
  ConsumerState<ProfileSetupWizard> createState() => _ProfileSetupWizardState();
}

class _ProfileSetupWizardState extends ConsumerState<ProfileSetupWizard> {
  int _step = 0;
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String _position = 'Defender'; // שינוי ברירת מחדל מ-Midfielder ל-Defender
  bool _allowNotifications = true;
  bool _allowLocation = true;
  bool _saving = false;
  bool _isLoadingLocation = false;
  DateTime? _birthDate; // תאריך לידה

  @override
  void dispose() {
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser;

      // בדוק אם המשתמש קיים
      final existingUser = await usersRepo.getUser(uid);

      if (existingUser == null) {
        // המשתמש לא קיים - צור אותו
        final newUser = model.User(
          uid: uid,
          name: currentUser?.displayName ?? currentUser?.email ?? '',
          email: currentUser?.email ?? '',
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          birthDate: _birthDate!, // ✅ Required - validated in _next()
          city: _cityController.text.trim(),
          region: CityUtils.getRegionForCity(_cityController.text.trim()),
          preferredPosition: _position,
          isProfileComplete: true,
          createdAt: DateTime.now(),
        );
        await usersRepo.setUser(newUser);
      } else {
        // המשתמש קיים - עדכן אותו
        await usersRepo.updateUser(uid, {
          'phoneNumber': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'birthDate':
              _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
          'city': _cityController.text.trim(),
          'region': CityUtils.getRegionForCity(_cityController.text.trim()),
          'preferredPosition': _position,
          'isProfileComplete': true,
        });
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירת הפרופיל: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        // קבל את שם העיר מהמיקום
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // נסה למצוא את שם העיר
          String? cityName;
          if (place.locality != null && place.locality!.isNotEmpty) {
            cityName = place.locality;
          } else if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            cityName = place.subAdministrativeArea;
          } else if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            cityName = place.administrativeArea;
          }

          if (cityName != null && cityName.isNotEmpty) {
            // נסה למצוא התאמה בערים הישראליות
            final cityNameValue = cityName; // שמור את הערך ב-variable מקומי
            String matchingCity = cityNameValue;
            try {
              matchingCity = CityUtils.cities.firstWhere(
                (city) =>
                    city.contains(cityNameValue) ||
                    cityNameValue.contains(city),
                orElse: () => cityNameValue,
              );
            } catch (e) {
              // אם לא נמצאה התאמה, השתמש בשם העיר המקורי
              matchingCity = cityNameValue;
            }

            setState(() {
              _cityController.text = matchingCity;
            });
          } else {
            if (mounted) {
              SnackbarHelper.showError(
                context,
                'לא ניתן לקבוע את שם העיר מהמיקום הנוכחי',
              );
            }
          }
        } else {
          if (mounted) {
            SnackbarHelper.showError(
              context,
              'לא ניתן לקבוע את שם העיר מהמיקום הנוכחי',
            );
          }
        }
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
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _next({bool skipOptional = false}) {
    // ולידציה לשלב 0 - תאריך לידה
    if (_step == 0) {
      if (_birthDate == null) {
        SnackbarHelper.showError(context, 'נא לבחור תאריך לידה');
        return;
      }
      if (!AgeUtils.isAgeValid(_birthDate!)) {
        final age = AgeUtils.calculateAge(_birthDate!);
        SnackbarHelper.showError(
          context,
          'גיל מינימלי: ${AgeUtils.minimumAge} שנים (הגיל שלך: $age)',
        );
        return;
      }
    }
    // ולידציה לשלב 1 - עיר מגורים
    if (_step == 1 && _cityController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'נא להזין עיר מגורים');
      return;
    }
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    }
  }

  Widget _buildMarketingContent(BuildContext context, int step) {
    switch (step) {
      case 0:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.phone,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'צור קשר בקלות',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'אפשר למארגני משחקים ליצור איתך קשר ישיר. חלק מהמשחקים כוללים אפשרות הזמנה ישירה דרך הטלפון.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case 1:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'מצא שחקנים והאבים לידך',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'האפליקציה מציגה לך משחקים והאבים הקרובים אליך. הצטרף למשחקים בסביבה שלך או צור האב חדש עם חברים.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sports_soccer,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'בנה את הפרופיל השחקן שלך',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'עדכן את העמדה המועדפת שלך כדי שמארגנים יוכלו למצוא אותך בקלות. הצטרף למשחקים שמתאימים לך.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case 3:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_active,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'הישאר מעודכן בכל רגע',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'קבל התראות על משחקים חדשים, תזכורות לפני משחקים והעדכונים מההאב שלך. כך תישאר תמיד מעודכן.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    // Simple loader while auth is resolving
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder(
      future: ref.read(usersRepositoryProvider).getUser(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null) {
          if (_phoneController.text.isEmpty && user.phoneNumber != null) {
            _phoneController.text = user.phoneNumber!;
          }
          if (_cityController.text.isEmpty && user.city != null) {
            _cityController.text = user.city!;
          }
          // Note: birthDate is required in model, but may be null for existing users before migration
          // ignore: unnecessary_null_comparison
          if (user.birthDate != null) {
            _birthDate = user.birthDate;
          }
          _position = _position.isEmpty ? user.preferredPosition : _position;
        }
        final steps = [
          _StepData(
            title: 'פרטים בסיסיים',
            description: 'טלפון אופציונלי ותאריך לידה',
            content: Column(
              children: [
                // תאריך לידה (חובה)
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? AgeUtils.maxBirthDateForMinAge,
                      firstDate: DateTime(1940),
                      lastDate: AgeUtils.maxBirthDateForMinAge,
                      helpText: 'בחר תאריך לידה',
                      cancelText: 'ביטול',
                      confirmText: 'אישור',
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _birthDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _birthDate == null
                            ? Colors.red.withOpacity(0.5)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          color: _birthDate == null
                              ? Colors.red.withOpacity(0.7)
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _birthDate == null
                                    ? 'תאריך לידה (חובה) *'
                                    : DateFormat('dd/MM/yyyy', 'he')
                                        .format(_birthDate!),
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? Colors.grey
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                              if (_birthDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'גיל: ${AgeUtils.calculateAge(_birthDate!)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (AgeUtils.isAgeValid(_birthDate!))
                                      Text(
                                        '(${AgeUtils.getAgeGroup(_birthDate!).displayNameHe})',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // מספר טלפון (אופציונלי)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'מספר טלפון (אופציונלי)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],
            ),
            isOptional: false, // תאריך לידה הוא חובה
          ),
          _StepData(
            title: 'מיקום',
            description: 'חובה כדי למצוא שחקנים והאבים לידך',
            content: Column(
              children: [
                // כפתור לבחירת מיקום נוכחי
                OutlinedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('בחר מיקום נוכחי'),
                ),
                const SizedBox(height: 16),
                // דרופדאון ערים
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return CityUtils.cities;
                    }
                    return CityUtils.cities.where((String option) {
                      return option.contains(textEditingValue.text) ||
                          textEditingValue.text.contains(option);
                    });
                  },
                  onSelected: (String selection) {
                    _cityController.text = selection;
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    // סנכרן את ה-controllers
                    if (_cityController.text.isNotEmpty &&
                        textEditingController.text.isEmpty) {
                      textEditingController.text = _cityController.text;
                    }
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'עיר מגורים',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      onChanged: (value) {
                        _cityController.text = value;
                      },
                    );
                  },
                ),
              ],
            ),
            isOptional: false,
          ),
          _StepData(
            title: 'פרופיל שחקן',
            description: 'אופציונלי – בחר עמדה מועדפת',
            content: Wrap(
              spacing: 8,
              children: ['Goalkeeper', 'Defender', 'Attacker']
                  .map((pos) => ChoiceChip(
                        label: Text(_positionLabel(pos)),
                        selected: _position == pos,
                        onSelected: (_) => setState(() => _position = pos),
                      ))
                  .toList(),
            ),
            isOptional: true,
          ),
          _StepData(
            title: 'הרשאות',
            description: 'מומלץ לאפשר התראות ומיקום',
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text('התראות'),
                  value: _allowNotifications,
                  onChanged: (v) => setState(() => _allowNotifications = v),
                ),
                SwitchListTile(
                  title: const Text('מיקום'),
                  value: _allowLocation,
                  onChanged: (v) => setState(() => _allowLocation = v),
                ),
              ],
            ),
            isOptional: true,
          ),
        ];

        final step = steps[_step];

        return Scaffold(
          appBar: AppBar(
            title: const Text('הגדרת פרופיל'),
            leading: _step > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _back,
                  )
                : null,
          ),
          body: Column(
            children: [
              // חצי עליון - הגדרת פרטים
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text('שלב ${_step + 1} מתוך 4',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                            value: (_step + 1) / steps.length),
                        const SizedBox(height: 24),
                        Text(step.title,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(step.description),
                        const SizedBox(height: 16),
                        step.content,
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (step.isOptional)
                              TextButton(
                                onPressed: _next,
                                child: const Text('דלג'),
                              ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _saving ? null : _next,
                              child: Text(
                                  _step == steps.length - 1 ? 'סיים' : 'הבא'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // קו מפריד
              const Divider(height: 1, thickness: 1),
              // חצי תחתון - מידע שיווקי
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: _buildMarketingContent(context, _step),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _positionLabel(String key) {
    switch (key) {
      case 'Goalkeeper':
        return 'שוער';
      case 'Defender':
        return 'הגנה';
      case 'Attacker':
        return 'התקפה';
      default:
        return key;
    }
  }
}

class _StepData {
  final String title;
  final String description;
  final Widget content;
  final bool isOptional;

  _StepData({
    required this.title,
    required this.description,
    required this.content,
    this.isOptional = false,
  });
}
