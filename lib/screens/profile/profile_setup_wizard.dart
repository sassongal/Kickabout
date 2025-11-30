import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:kattrick/utils/snackbar_helper.dart';

class ProfileSetupWizard extends ConsumerStatefulWidget {
  const ProfileSetupWizard({super.key});

  @override
  ConsumerState<ProfileSetupWizard> createState() =>
      _ProfileSetupWizardState();
}

class _ProfileSetupWizardState extends ConsumerState<ProfileSetupWizard> {
  int _step = 0;
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String _position = 'Midfielder';
  bool _allowNotifications = true;
  bool _allowLocation = true;
  bool _saving = false;

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
      await usersRepo.updateUser(uid, {
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'region': CityUtils.getRegionForCity(_cityController.text.trim()),
        'preferredPosition': _position,
        'isProfileComplete': true,
      });
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירת הפרופיל: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next({bool skipOptional = false}) {
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    // Simple loader while auth is resolving
    if (currentUserId == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
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
          _position = _position.isEmpty ? user.preferredPosition : _position;
        }
        final steps = [
      _StepData(
        title: 'פרטים בסיסיים',
        description: 'טלפון אופציונלי להזמנות ישירות',
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'מספר טלפון (אופציונלי)',
            border: OutlineInputBorder(),
          ),
        ),
        isOptional: true,
      ),
      _StepData(
        title: 'מיקום',
        description: 'חובה כדי למצוא שחקנים והאבים לידך',
        content: TextField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'עיר מגורים',
            border: OutlineInputBorder(),
          ),
        ),
        isOptional: false,
      ),
      _StepData(
        title: 'פרופיל שחקן',
        description: 'אופציונלי – בחר עמדה מועדפת',
        content: Wrap(
          spacing: 8,
          children: ['Goalkeeper', 'Defender', 'Midfielder', 'Attacker']
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('שלב ${_step + 1} מתוך 4',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: (_step + 1) / steps.length),
            const SizedBox(height: 24),
            Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(step.description),
            const SizedBox(height: 16),
            step.content,
            const Spacer(),
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
                  child: Text(_step == steps.length - 1 ? 'סיים' : 'הבא'),
                ),
              ],
            ),
          ],
        ),
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
      case 'Midfielder':
        return 'אמצע';
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
