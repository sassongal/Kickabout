import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/storage_service.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/widgets/game_photos_gallery.dart';
import 'package:kickadoor/core/constants.dart';

/// Create Feed Post Screen - Create a post with text and photos
class CreatePostScreen extends ConsumerStatefulWidget {
  final String hubId;

  const CreatePostScreen({super.key, required this.hubId});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final List<String> _photoUrls = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        try {
          final storageService = ref.read(storageServiceProvider);
          final currentUserId = ref.read(currentUserIdProvider);
          
          if (currentUserId == null) {
            if (mounted) {
              SnackbarHelper.showError(context, 'נא להתחבר');
            }
            return;
          }

          // Upload to feed photos path
          final photoUrl = await storageService.uploadFeedPhoto(
            widget.hubId,
            currentUserId,
            image,
          );

          setState(() {
            _photoUrls.add(photoUrl);
            _isUploading = false;
          });
        } catch (e) {
          setState(() => _isUploading = false);
          if (mounted) {
            SnackbarHelper.showError(context, 'שגיאה בהעלאת תמונה: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בבחירת תמונה: $e');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        try {
          final storageService = ref.read(storageServiceProvider);
          final currentUserId = ref.read(currentUserIdProvider);
          
          if (currentUserId == null) {
            if (mounted) {
              SnackbarHelper.showError(context, 'נא להתחבר');
            }
            return;
          }

          final photoUrl = await storageService.uploadFeedPhoto(
            widget.hubId,
            currentUserId,
            image,
          );

          setState(() {
            _photoUrls.add(photoUrl);
            _isUploading = false;
          });
        } catch (e) {
          setState(() => _isUploading = false);
          if (mounted) {
            SnackbarHelper.showError(context, 'שגיאה בהעלאת תמונה: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בצילום תמונה: $e');
      }
    }
  }

  Future<void> _deletePhoto(String photoUrl) async {
    setState(() {
      _photoUrls.remove(photoUrl);
    });
    // Optionally delete from storage
    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteFeedPhoto(photoUrl);
    } catch (e) {
      debugPrint('Failed to delete photo from storage: $e');
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();
    if (content.isEmpty && _photoUrls.isEmpty) {
      SnackbarHelper.showError(context, 'נא להזין תוכן או להוסיף תמונה');
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      SnackbarHelper.showError(context, 'נא להתחבר');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final feedRepo = ref.read(feedRepositoryProvider);
      
      final post = FeedPost(
        postId: '',
        hubId: widget.hubId,
        authorId: currentUserId,
        type: 'post',
        content: content.isEmpty ? null : content,
        photoUrls: _photoUrls,
        createdAt: DateTime.now(),
      );

      await feedRepo.createPost(post);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הפוסט נוצר בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה ביצירת פוסט: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'צור פוסט',
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Content text field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'מה אתה חושב?',
                  hintText: 'שתף משהו עם הקהילה...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                maxLines: 6,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Photos section
              if (_photoUrls.isNotEmpty || _isUploading)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'תמונות',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (_photoUrls.isNotEmpty)
                          GamePhotosGallery(
                            photoUrls: _photoUrls,
                            canAddPhotos: false,
                            canDelete: true,
                            onDeletePhoto: _deletePhoto,
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Add photo buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('בחר מהגלריה'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('צלם תמונה'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Create button
              ElevatedButton.icon(
                onPressed: _isLoading || _isUploading ? null : _createPost,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'יוצר...' : 'פרסם'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

