import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/image_picker_button.dart';
import 'package:kickadoor/widgets/loading_widget.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/services/storage_service.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/utils/city_utils.dart';

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
  final _displayNameController = TextEditingController(); // Custom nickname
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  // Replaces _positionController and _selectedPlayingStyle
  String? _selectedPosition;
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

  // Valid positions
  final List<Map<String, String>> _positions = [
    {'value': 'Goalkeeper', 'label': 'שוער'},
    {'value': 'Defender', 'label': 'הגנה'},
    {'value': 'Midfielder', 'label': 'קישור'},
    {'value': 'Attacker', 'label': 'התקפה'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
          _displayNameController.text = user.displayName ?? '';
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber ?? '';
          _cityController.text = user.city ?? '';

          // Load position. If current value isn't standard, try to map or default
          _selectedPosition = user.preferredPosition;
          if (!_positions.any((p) => p['value'] == _selectedPosition)) {
            _selectedPosition = 'Midfielder'; // Default fallback
          }

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      String? photoUrl = _currentUser?.photoUrl;

      // Upload image logic
      if (_selectedImage != null) {
        setState(() => _isUploading = true);
        final storageService = StorageService();
        photoUrl = await storageService.uploadProfilePhoto(
            widget.userId, _selectedImage!);
        setState(() => _isUploading = false);
      } else if (_currentUser?.photoUrl != null &&
          _currentUser!.photoUrl!.isNotEmpty &&
          _selectedImage == null) {
        // Keep existing or logic for deletion handled by ImagePickerButton state usually
      }

      // Auto-derive region if city changed
      String? region = _selectedRegion;
      if (_cityController.text.isNotEmpty) {
        region = CityUtils.getRegionForCity(_cityController.text);
      }

      // Update user
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
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

        // Use the selected Dropdown value
        preferredPosition: _selectedPosition ?? 'Midfielder',

        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),

        // Auto-set region
        region: region,

        photoUrl: photoUrl,
        avatarColor: _selectedAvatarColor,
        birthDate: _selectedBirthDate,
      );

      await usersRepo.setUser(updatedUser);

      // --- IMPROVEMENT: Ensure state is updated before navigating ---
      // Invalidate the provider to force a refresh from the database.
      ref.invalidate(userProfileProvider(widget.userId));

      // Wait for the provider to rebuild with the complete profile.
      // This ensures the router's redirect logic will see the updated profile.
      await ref.read(userProfileProvider(widget.userId).future);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הפרופיל עודכן בהצלחה!');
        // Use context.go('/') to re-evaluate the router's state.
        // This correctly navigates to the home screen instead of just popping.
        // It solves the redirect loop issue.
        context.go('/');
      }
    } catch (e) {
      // Note: The userProfileProvider might be an autoDispose family provider.
      // If so, you'd use `userProfileProvider(widget.userId)`.
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

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת חשבון'),
        content: const Text(
            'האם אתה בטוח שברצונך למחוק את החשבון? פעולה זו אינה הפיכה ותמחק את כל הנתונים שלך.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק חשבון'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      // Delete user data from Firestore
      await usersRepo.deleteUser(widget.userId);

      // Delete user account
      await authService.deleteAccount();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'החשבון נמחק בהצלחה');
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        // Handle requires-recent-login error
        if (e.toString().contains('requires-recent-login')) {
          SnackbarHelper.showError(
              context, 'נא להתחבר מחדש כדי למחוק את החשבון');
        } else {
          SnackbarHelper.showErrorFromException(context, e);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Dummy provider for demonstration. Replace with your actual provider.
  // You likely have this in your providers file, e.g., `data/repositories_providers.dart`
  // It should be a FutureProvider or StreamProvider that fetches a user.
  final userProfileProvider =
      FutureProvider.family<User?, String>((ref, userId) async {
    return ref.watch(usersRepositoryProvider).getUser(userId);
  });

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

                // Avatar Color
                Text('צבע רקע (כשאין תמונה)',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _avatarColors.map((colorData) {
                    final hex = colorData['hex'] as String;
                    final isSelected = _selectedAvatarColor == hex ||
                        (_selectedAvatarColor == null &&
                            _currentUser?.avatarColor == null &&
                            _avatarColors.indexOf(colorData) == 0);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarColor = hex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorData['color'],
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 4)
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Display Name (Nickname)
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'כינוי (שם תצוגה)',
                    hintText: 'הכינוי שמוצג לאחרים',
                    helperText: 'אופציונאלי - השאר ריק לשימוש בשם הפרטי',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),

                // Names
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                            labelText: 'שם פרטי', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                            labelText: 'שם משפחה',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // City (Autocomplete)
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return CityUtils.cities.where((String option) =>
                        option.contains(textEditingValue.text));
                  },
                  onSelected: (String selection) {
                    _cityController.text = selection;
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    if (_cityController.text.isNotEmpty &&
                        textEditingController.text != _cityController.text) {
                      textEditingController.text = _cityController.text;
                    }
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                          labelText: 'עיר מגורים',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city)),
                      onChanged: (val) => _cityController.text = val,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Position (Dropdown) - The replacement for text field + playing style
                DropdownButtonFormField<String>(
                  initialValue: _selectedPosition,
                  decoration: const InputDecoration(
                    labelText: 'עמדה מועדפת',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                  items: _positions
                      .map((pos) => DropdownMenuItem(
                            value: pos['value'],
                            child: Text(pos['label']!),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedPosition = value),
                ),
                const SizedBox(height: 16),

                // Phone & Email (Read only mostly, but editable here)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                      labelText: 'טלפון',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 16),

                // Save
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save),
                  label: Text(_isLoading ? 'שומר...' : 'שמור שינויים'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
                const SizedBox(height: 32),

                // Delete Account
                TextButton.icon(
                  onPressed: _isLoading ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('מחק חשבון'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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
