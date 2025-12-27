import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/services_providers.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/config/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/features/hubs/domain/services/hub_membership_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Dialog for hub manager to add a manual player (without app)
class AddManualPlayerDialog extends ConsumerStatefulWidget {
  final String hubId;
  final String? initialName;
  final String? initialPhone;

  const AddManualPlayerDialog({
    super.key,
    required this.hubId,
    this.initialName,
    this.initialPhone,
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
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedPosition = 'Midfielder';
  double _rating = 4.0; // Default rating on 1-7 scale
  bool _isLoading = false;

  // Image picker
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  @override
  void initState() {
    super.initState();
    // Set initial values from contact if provided
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בבחירת תמונה');
      }
    }
  }

  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(context, 'Firebase לא זמין');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersRepo = ref.read(usersRepositoryProvider);

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
      final playerId = usersRepo.generateUserId();

      // Calculate birthDate from age (if provided)
      DateTime birthDate;
      if (_ageController.text.trim().isNotEmpty) {
        final age = int.parse(_ageController.text.trim());
        birthDate = DateTime.now().subtract(Duration(days: 365 * age));
      } else {
        // Default to 25 years old
        birthDate = DateTime.now().subtract(const Duration(days: 365 * 25));
      }

      // Parse physical stats
      final heightCm = _heightController.text.trim().isNotEmpty
          ? double.tryParse(_heightController.text.trim())
          : null;
      final weightKg = _weightController.text.trim().isNotEmpty
          ? double.tryParse(_weightController.text.trim())
          : null;

      // Create user document with isFictitious flag
      final user = User(
        uid: playerId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : 'manual_$playerId@kickadoor.local',
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        preferredPosition: _selectedPosition,
        availabilityStatus: 'notAvailable',
        createdAt: DateTime.now(),
        birthDate: birthDate,
        heightCm: heightCm,
        weightKg: weightKg,
        currentRankScore: _rating, // Use slider value
        totalParticipations: 0,
        isFictitious: true, // Mark as fictitious player
      );

      // Save user
      await usersRepo.setUser(user);

      // Upload image if selected
      if (_selectedImage != null) {
        try {
          final storageService = ref.read(storageServiceProvider);

          // Resize and compress image
          final imageBytes = await _selectedImage!.readAsBytes();
          final decodedImage = img.decodeImage(imageBytes);
          if (decodedImage != null) {
            final resizedImage = img.copyResize(
              decodedImage,
              width: 256,
              height: 256,
            );
            final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

            // Upload to Storage
            final photoUrl = await storageService.uploadProfilePhotoFromBytes(
              playerId,
              compressedBytes,
            );

            // Update user with photo URL
            await usersRepo.updateUser(playerId, {'photoUrl': photoUrl});
          }
        } catch (e) {
          debugPrint('Error uploading player photo: $e');
          // Continue without photo - not critical
        }
      }

      // Add to hub using HubMembershipService for business validation
      final membershipService = ref.read(hubMembershipServiceProvider);
      await membershipService.addMember(
        hubId: widget.hubId,
        userId: playerId,
      );

      // Set manager rating (1-7 scale)
      final hubsRepo = ref.read(hubsRepositoryProvider);
      await hubsRepo.setPlayerRating(widget.hubId, playerId, _rating);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        SnackbarHelper.showSuccess(
          context,
          'השחקן ${user.name} נוסף בהצלחה',
        );
      }
    } on HubCapacityExceededException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context,
          'ה-Hub מלא (${e.currentCount}/${e.maxCount} חברים)',
        );
      }
    } on UserHubLimitException catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context,
          'השחקן הגיע למקסימום של 10 Hubs',
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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

                // Image/Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : null,
                          child: _selectedImage == null
                              ? Icon(
                                  Icons.person_add,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              // Phone field (optional, for merge)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'מספר טלפון (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: '050-1234567',
                  prefixIcon: Icon(Icons.phone),
                  helperText: 'למיזוג אוטומטי כשהשחקן יצטרף',
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
              // Age field
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'גיל (אופציונלי)',
                  border: OutlineInputBorder(),
                  hintText: '25',
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 13 || age > 80) {
                      return 'גיל לא סביר (13-80)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Physical Stats Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'גובה (ס״מ)',
                        border: OutlineInputBorder(),
                        hintText: '175',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final height = double.tryParse(value);
                          if (height == null || height < 140 || height > 220) {
                            return 'גובה לא סביר';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'משקל (ק״ג)',
                        border: OutlineInputBorder(),
                        hintText: '75',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 40 || weight > 150) {
                            return 'משקל לא סביר';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Position dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'עמדה מועדפת',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_soccer),
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
              const SizedBox(height: 16),
              // Rating Slider
              Text(
                'רמת כושר (1-7) - למנהל בלבד',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        activeTrackColor: Theme.of(context).primaryColor,
                      ),
                      child: Slider(
                        value: _rating,
                        min: 1.0,
                        max: 7.0,
                        divisions: 12, // 0.5 increments
                        label: _rating.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => _rating = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
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
