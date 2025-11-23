import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/image_picker_button.dart';
import 'package:kickadoor/widgets/loading_widget.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/services/storage_service.dart';
import 'package:kickadoor/services/location_service.dart';
import 'package:kickadoor/utils/geohash_utils.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/screens/location/map_picker_screen.dart';

/// Edit profile screen
class EditProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedPlayingStyle;
  String? _selectedRegion;
  String? _selectedAvatarColor;
  DateTime? _selectedBirthDate;

  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  User? _currentUser;

  // Predefined color palette for avatars
  static const List<Map<String, dynamic>> _avatarColors = [
    {'name': 'כחול', 'color': Color(0xFF1976D2), 'hex': '1976D2'},
    {'name': 'סגול', 'color': Color(0xFF9C27B0), 'hex': '9C27B0'},
    {'name': 'ירוק', 'color': Color(0xFF4CAF50), 'hex': '4CAF50'},
    {'name': 'כתום', 'color': Color(0xFFFF9800), 'hex': 'FF9800'},
    {'name': 'אדום', 'color': Color(0xFFF44336), 'hex': 'F44336'},
    {'name': 'ציאן', 'color': Color(0xFF00BCD4), 'hex': '00BCD4'},
    {'name': 'ורוד', 'color': Color(0xFFE91E63), 'hex': 'E91E63'},
    {'name': 'חום', 'color': Color(0xFF795548), 'hex': '795548'},
    {'name': 'כחול אפור', 'color': Color(0xFF607D8B), 'hex': '607D8B'},
    {'name': 'ענבר', 'color': Color(0xFFFFC107), 'hex': 'FFC107'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final user = await usersRepo.getUser(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber ?? '';
          _positionController.text = user.preferredPosition;
          _cityController.text = user.city ?? '';
          _selectedPlayingStyle = user.playingStyle;
          _selectedRegion = user.region;
          _selectedAvatarColor = user.avatarColor;
          _selectedBirthDate = user.birthDate;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _setLocation() async {
    // Show dialog with options: current location or search address
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הגדר מיקום'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('מיקום נוכחי'),
              onTap: () => Navigator.pop(context, 'current'),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('חיפוש כתובת'),
              onTap: () => Navigator.pop(context, 'search'),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('בחר במפה'),
              onTap: () => Navigator.pop(context, 'map'),
            ),
          ],
        ),
      ),
    );

    if (option == null) return;

    if (option == 'current') {
      // Get current location
      setState(() {
        _isLoading = true;
      });

      try {
        final locationService = ref.read(locationServiceProvider);
        final position = await locationService.getCurrentLocation();

        if (position != null) {
          final geoPoint = locationService.positionToGeoPoint(position);
          final address = await locationService.coordinatesToAddress(
            position.latitude,
            position.longitude,
          );

          // Update user location
          final usersRepo = ref.read(usersRepositoryProvider);
          await usersRepo.updateUser(widget.userId, {
            'location': geoPoint,
            'geohash': GeohashUtils.encode(position.latitude, position.longitude, precision: 7),
          });

          if (mounted) {
            SnackbarHelper.showSuccess(
              context,
              'מיקום עודכן: ${address ?? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'}',
            );
            _loadUser(); // Reload user data
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
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (option == 'map') {
      // Open map picker
      final result = await context.push<Map<String, dynamic>?>(
        '/map-picker',
        extra: _currentUser?.location,
      );

      if (result != null && mounted) {
        final geoPoint = result['location'] as GeoPoint;
        final address = result['address'] as String?;

        // Update user location
        final usersRepo = ref.read(usersRepositoryProvider);
        await usersRepo.updateUser(widget.userId, {
          'location': geoPoint,
          'geohash': GeohashUtils.encode(geoPoint.latitude, geoPoint.longitude, precision: 7),
        });

        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'מיקום עודכן: ${address ?? '${geoPoint.latitude.toStringAsFixed(6)}, ${geoPoint.longitude.toStringAsFixed(6)}'}',
          );
          _loadUser(); // Reload user data
        }
      }
    } else if (option == 'search') {
      // Show address search dialog
      final addressController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('חיפוש כתובת'),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'הזן כתובת',
              hintText: 'לדוגמה: תל אביב, רחוב רוטשילד 1',
            ),
            autofocus: true,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, addressController.text),
              child: const Text('חפש'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _isLoading = true;
        });

        try {
          final locationService = ref.read(locationServiceProvider);
          final position = await locationService.getLocationFromAddress(result);

          if (position != null) {
            final geoPoint = locationService.positionToGeoPoint(position);

            // Update user location
            final usersRepo = ref.read(usersRepositoryProvider);
            await usersRepo.updateUser(widget.userId, {
              'location': geoPoint,
              'geohash': GeohashUtils.encode(position.latitude, position.longitude, precision: 7),
            });

            if (mounted) {
              SnackbarHelper.showSuccess(context, 'מיקום עודכן: $result');
              _loadUser(); // Reload user data
            }
          } else {
            if (mounted) {
              SnackbarHelper.showError(context, 'לא נמצא מיקום לכתובת זו');
            }
          }
        } catch (e) {
          if (mounted) {
            SnackbarHelper.showError(context, 'שגיאה בחיפוש כתובת: $e');
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      String? photoUrl = _currentUser?.photoUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        setState(() {
          _isUploading = true;
        });

        final storageService = StorageService();
        photoUrl = await storageService.uploadProfilePhoto(
          widget.userId,
          _selectedImage!,
        );

        setState(() {
          _isUploading = false;
        });
      }

      // Update user
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        firstName: _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        preferredPosition: _positionController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        playingStyle: _selectedPlayingStyle,
        region: _selectedRegion,
        photoUrl: photoUrl,
        avatarColor: _selectedAvatarColor,
        birthDate: _selectedBirthDate,
      );

      await usersRepo.setUser(updatedUser);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הפרופיל עודכן בהצלחה!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return AppScaffold(
        title: 'עריכת פרופיל',
        body: const AppLoadingWidget(message: 'טוען פרופיל...'),
      );
    }

    return AppScaffold(
      title: 'עריכת פרופיל',
      body: AppLoadingOverlay(
        isLoading: _isUploading,
        message: 'מעלה תמונה...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile photo
                Center(
                  child: ImagePickerButton(
                    size: 120,
                    currentImageUrl: _currentUser?.photoUrl,
                    onImagePicked: (image) {
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Avatar Color Picker (only if no photo)
                if (_currentUser?.photoUrl == null || _currentUser!.photoUrl!.isEmpty) ...[
                  Text(
                    'צבע אווטר',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _avatarColors.map((colorData) {
                      final color = colorData['color'] as Color;
                      final hex = colorData['hex'] as String;
                      final isSelected = _selectedAvatarColor == hex || 
                          (_selectedAvatarColor == null && 
                           _currentUser?.avatarColor == null &&
                           _avatarColors.indexOf(colorData) == 0);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarColor = hex;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // First Name field
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'שם פרטי',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Last Name field
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'שם משפחה',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Full Name field (computed from first + last, or manual)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם מלא',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                    helperText: 'או הזן שם מלא ידנית',
                  ),
                  onChanged: (value) {
                    // Auto-update if first/last name changes
                    if (_firstNameController.text.isNotEmpty || _lastNameController.text.isNotEmpty) {
                      final fullName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
                      if (fullName.isNotEmpty && value != fullName) {
                        // User is typing manually, don't override
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'נא להזין שם מלא';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Birth Date field
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      locale: const Locale('he'),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedBirthDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'תאריך לידה (אופציונלי)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? DateFormat('dd/MM/yyyy', 'he').format(_selectedBirthDate!)
                          : 'לא נבחר',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'נא להזין אימייל';
                    }
                    if (!value.contains('@')) {
                      return 'נא להזין אימייל תקין';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'טלפון',
                    hintText: '05X-XXXXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'מספר טלפון ייחודי (לא יכול להיות בשימוש על ידי משתמש אחר)',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      // Basic Israeli phone validation
                      final phoneRegex = RegExp(r'^0[2-9]\d{7,8}$');
                      final cleanPhone = value.trim().replaceAll(RegExp(r'[-\s]'), '');
                      if (!phoneRegex.hasMatch(cleanPhone)) {
                        return 'נא להזין מספר טלפון תקין (ישראל)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City field with "Use Current Location" button
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'עיר מגורים',
                    hintText: 'לדוגמה: תל אביב',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_city),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'השתמש במיקום הנוכחי',
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          final locationService = ref.read(locationServiceProvider);
                          final position = await locationService.getCurrentLocation();
                          
                          if (position != null) {
                            final address = await locationService.coordinatesToAddress(
                              position.latitude,
                              position.longitude,
                            );
                            
                            if (address != null && mounted) {
                              // Extract city name from address
                              String cityName = address;
                              final parts = address.split(',');
                              if (parts.isNotEmpty) {
                                cityName = parts[0].trim();
                              }
                              
                              setState(() {
                                _cityController.text = cityName;
                              });
                              
                              // Also update user location in Firestore
                              final usersRepo = ref.read(usersRepositoryProvider);
                              final geoPoint = locationService.positionToGeoPoint(position);
                              await usersRepo.updateUser(widget.userId, {
                                'location': geoPoint,
                                'geohash': GeohashUtils.encode(position.latitude, position.longitude, precision: 7),
                                'city': cityName,
                              });
                              
                              SnackbarHelper.showSuccess(context, 'מיקום עודכן: $cityName');
                            }
                          } else {
                            if (mounted) {
                              SnackbarHelper.showError(context, 'לא ניתן לקבל מיקום. אנא בדוק את ההרשאות.');
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackbarHelper.showError(context, 'שגיאה בקבלת מיקום: $e');
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Position field
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'עמדה מועדפת',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'נא להזין עמדה';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Playing Style field
                DropdownButtonFormField<String>(
                  value: _selectedPlayingStyle,
                  decoration: const InputDecoration(
                    labelText: 'סגנון משחק',
                    hintText: 'בחר סגנון משחק',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.style),
                    helperText: 'משפיע על חלוקת הקבוצות במשחקים',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'goalkeeper',
                      child: Text('שוער'),
                    ),
                    DropdownMenuItem(
                      value: 'defensive',
                      child: Text('הגנתי'),
                    ),
                    DropdownMenuItem(
                      value: 'offensive',
                      child: Text('התקפי'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPlayingStyle = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Region field
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'אזור',
                    hintText: 'בחר אזור',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                    helperText: 'משפיע על הפיד האזורי שתראה',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'צפון',
                      child: Text('צפון'),
                    ),
                    DropdownMenuItem(
                      value: 'מרכז',
                      child: Text('מרכז'),
                    ),
                    DropdownMenuItem(
                      value: 'דרום',
                      child: Text('דרום'),
                    ),
                    DropdownMenuItem(
                      value: 'ירושלים',
                      child: Text('ירושלים'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Set location button
                OutlinedButton.icon(
                  onPressed: _setLocation,
                  icon: const Icon(Icons.location_on),
                  label: const Text('הגדר מיקום'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'שומר...' : 'שמור שינויים'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

