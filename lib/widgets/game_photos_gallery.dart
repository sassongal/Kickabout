import 'package:flutter/material.dart';
import 'package:kattrick/widgets/optimized_image.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';

/// Widget for displaying game photos in a grid gallery
class GamePhotosGallery extends StatelessWidget {
  final List<String> photoUrls;
  final bool canAddPhotos;
  final VoidCallback? onAddPhoto;
  final bool canDelete;
  final Function(String)? onDeletePhoto;

  const GamePhotosGallery({
    super.key,
    required this.photoUrls,
    this.canAddPhotos = false,
    this.onAddPhoto,
    this.canDelete = false,
    this.onDeletePhoto,
  });

  void _viewPhoto(BuildContext context, String photoUrl, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewer(
          photoUrls: photoUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty && !canAddPhotos) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'תמונות מהמשחק',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (canAddPhotos && onAddPhoto != null)
              TextButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('הוסף תמונה'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: photoUrls.length + (canAddPhotos ? 1 : 0),
          itemBuilder: (context, index) {
            // Add photo button
            if (canAddPhotos && index == photoUrls.length) {
              return GestureDetector(
                onTap: onAddPhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'הוסף',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Photo thumbnail
            final photoUrl = photoUrls[index];
            return GestureDetector(
              onTap: () => _viewPhoto(context, photoUrl, index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  if (canDelete && onDeletePhoto != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('מחק תמונה'),
                              content: const Text(
                                  'האם אתה בטוח שברצונך למחוק תמונה זו?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('ביטול'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDeletePhoto!(photoUrl);
                                  },
                                  child: const Text('מחק',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Full-screen photo viewer
class _PhotoViewer extends StatelessWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _PhotoViewer({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
        leading: AppBarHomeLogo(showBackButton: canPop),
        automaticallyImplyLeading: false,
        title: Text(
          '${initialIndex + 1} / ${photoUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: OptimizedImage(
                imageUrl: photoUrls[index],
                fit: BoxFit.contain,
                errorWidget: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                placeholderWidget: const Center(
                  child: KineticLoadingAnimation(
                    size: 40,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
