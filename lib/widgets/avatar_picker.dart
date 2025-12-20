import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/player_avatar.dart';

/// Avatar picker widget - allows selecting photo or color
class AvatarPicker extends StatelessWidget {
  final User? user;
  final XFile? selectedImage;
  final String? selectedAvatarColor;
  final Function(XFile) onImagePicked;
  final Function(String) onColorSelected;
  final Function() onDeletePhoto;
  final double size;

  const AvatarPicker({
    super.key,
    required this.user,
    this.selectedImage,
    this.selectedAvatarColor,
    required this.onImagePicked,
    required this.onColorSelected,
    required this.onDeletePhoto,
    this.size = 120,
  });

  // Predefined color palette for avatars
  static const List<Map<String, dynamic>> avatarColors = [
    {'name': 'כחול', 'color': Color(0xFF1976D2), 'hex': '1976D2'},
    {'name': 'סגול', 'color': Color(0xFF9C27B0), 'hex': '9C27B0'},
    {'name': 'ירוק', 'color': Color(0xFF4CAF50), 'hex': '4CAF50'},
    {'name': 'כתום', 'color': Color(0xFFFF9800), 'hex': 'FF9800'},
    {'name': 'אדום', 'color': Color(0xFFF44336), 'hex': 'F44336'},
    {'name': 'ציאן', 'color': Color(0xFF00BCD4), 'hex': '00BCD4'},
    {'name': 'ורוד', 'color': Color(0xFFE91E63), 'hex': 'E91E63'},
    {'name': 'חום', 'color': Color(0xFF795548), 'hex': '795548'},
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAvatarOptions(context),
      child: Stack(
        children: [
          // Avatar display
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: user != null
                  ? PlayerAvatar(
                      user: user!,
                      radius: size / 2,
                      clickable: false,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: size * 0.6,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
          ),
          // Edit icon
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvatarOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Text(
                  'בחר אווטר',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Upload photo option
                _buildOptionCard(
                  context,
                  icon: Icons.photo_camera,
                  title: 'העלה תמונה',
                  subtitle: 'בחר תמונה מהגלריה או צלם חדשה',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(context);
                  },
                ),
                const SizedBox(height: 16),
                // Color picker option
                _buildOptionCard(
                  context,
                  icon: Icons.palette,
                  title: 'בחר צבע',
                  subtitle: 'בחר צבע רקע לאווטר',
                  onTap: () {
                    Navigator.pop(context);
                    _showColorPicker(context);
                  },
                ),
                const SizedBox(height: 16),
                // Delete photo option (only if photo exists)
                if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  _buildOptionCard(
                    context,
                    icon: Icons.delete,
                    title: 'מחק תמונה',
                    subtitle: 'השתמש בצבע במקום תמונה',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeletePhoto(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    // Show dialog to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר מקור'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('מצלמה'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('גלריה'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      // Check file size (5MB limit)
      final fileSize = await image.length();
      const maxSize = 5 * 1024 * 1024; // 5MB in bytes

      if (fileSize > maxSize) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('התמונה גדולה מדי. מקסימום 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      onImagePicked(image);
    }
  }

  Future<void> _showColorPicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר צבע אווטר'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: avatarColors.map((colorData) {
              final color = colorData['color'] as Color;
              final hex = colorData['hex'] as String;
              final name = colorData['name'] as String;
              final isSelected = selectedAvatarColor == hex;

              return GestureDetector(
                onTap: () {
                  onColorSelected(hex);
                  Navigator.pop(context);
                },
                child: Tooltip(
                  message: name,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePhoto(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת תמונה'),
        content: const Text(
          'האם אתה בטוח שברצונך למחוק את תמונת הפרופיל? '
          'האווטר יוצג עם צבע רקע במקום.',
        ),
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
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDeletePhoto();
    }
  }
}
