import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/image_picker_button.dart';
import 'package:kickadoor/widgets/loading_widget.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/services/storage_service.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';

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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _cityController = TextEditingController();

  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber ?? '';
          _positionController.text = user.preferredPosition;
          _cityController.text = user.city ?? '';
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
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        preferredPosition: _positionController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        photoUrl: photoUrl,
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
                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'נא להזין שם';
                    }
                    return null;
                  },
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

                // City field
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'עיר מגורים',
                    hintText: 'לדוגמה: תל אביב',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
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

