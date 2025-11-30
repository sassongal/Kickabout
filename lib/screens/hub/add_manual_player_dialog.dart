import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/config/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for hub manager to add a manual player (without app)
class AddManualPlayerDialog extends ConsumerStatefulWidget {
  final String hubId;

  const AddManualPlayerDialog({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<AddManualPlayerDialog> createState() => _AddManualPlayerDialogState();
}

class _AddManualPlayerDialogState extends ConsumerState<AddManualPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _ratingController = TextEditingController(text: '3.3');
  String _selectedPosition = 'Midfielder';
  bool _isLoading = false;

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(context, 'Firebase לא זמין');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final usersRepo = ref.read(usersRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Check if phone number is already taken
      if (_phoneController.text.trim().isNotEmpty) {
        final isTaken = await usersRepo.isPhoneNumberTaken(
          _phoneController.text.trim(),
          '',
        );
        if (isTaken) {
          if (mounted) {
            SnackbarHelper.showError(
              context,
              'מספר הטלפון כבר בשימוש',
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Create a unique ID for the manual player
      final playerId = firestore.collection('users').doc().id;

      // Parse rating (default 3.3 if empty or invalid)
      final ratingText = _ratingController.text.trim();
      final rating = double.tryParse(ratingText) ?? 3.3;
      final finalRating = rating.clamp(0.0, 10.0); // Ensure rating is between 0-10

      // Create user document
      final user = User(
        uid: playerId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : 'manual_$playerId@kickadoor.local', // Fake email for manual players without email
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        preferredPosition: _selectedPosition,
        availabilityStatus: 'notAvailable', // Manual players are not available
        createdAt: DateTime.now(),
        currentRankScore: finalRating,
        totalParticipations: 0,
      );

      // Save user
      await usersRepo.setUser(user);

      // Add to hub
      await hubsRepo.addMember(widget.hubId, playerId);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        SnackbarHelper.showSuccess(
          context,
          'השחקן ${user.name} נוסף בהצלחה',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'הוסף שחקן ידנית',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'הוסף שחקן שמשחק בקבוצה אבל לא מוריד את האפליקציה',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'שם מלא *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'נא להזין שם';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone field (optional)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'מספר טלפון (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: '050-1234567',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 9) {
                      return 'מספר טלפון לא תקין';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email field (optional - for sending invitation)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'אימייל (אופציונלי - לשליחת הזמנה)',
                  border: OutlineInputBorder(),
                  hintText: 'player@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'כתובת אימייל לא תקינה';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // City field (optional)
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'עיר (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: 'חיפה',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              // Rating field
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'ציון (0-10)',
                  border: OutlineInputBorder(),
                  hintText: '3.3',
                  helperText: 'ברירת מחדל: 3.3',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final rating = double.tryParse(value);
                    if (rating == null || rating < 0 || rating > 10) {
                      return 'ציון חייב להיות בין 0 ל-10';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Position dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'עמדה מועדפת',
                  border: OutlineInputBorder(),
                ),
                items: _positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(_getPositionHebrew(position)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPosition = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('ביטול'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addPlayer,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('הוסף'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPositionHebrew(String position) {
    switch (position) {
      case 'Goalkeeper':
        return 'שוער';
      case 'Defender':
        return 'מגן';
      case 'Midfielder':
        return 'קשר';
      case 'Forward':
        return 'חלוץ';
      default:
        return position;
    }
  }
}

