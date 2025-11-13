import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/core/constants.dart';

/// Service for Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload profile photo
  Future<String> uploadProfilePhoto(String uid, XFile imageFile) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profilePhotosPath)
          .child('$uid.jpg');

      // Upload file
      final uploadTask = ref.putFile(File(imageFile.path));
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Upload profile photo from bytes (for web)
  Future<String> uploadProfilePhotoFromBytes(
    String uid,
    List<int> imageBytes,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profilePhotosPath)
          .child('$uid.jpg');

      // Upload bytes
      final uploadTask = ref.putData(
        Uint8List.fromList(imageBytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profilePhotosPath)
          .child('$uid.jpg');
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete profile photo: $e');
    }
  }

  /// Upload game photo
  Future<String> uploadGamePhoto(String gameId, XFile imageFile) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child(AppConstants.gamePhotosPath)
          .child(gameId)
          .child('$timestamp.jpg');

      // Upload file
      final uploadTask = ref.putFile(File(imageFile.path));
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload game photo: $e');
    }
  }

  /// Upload feed photo
  Future<String> uploadFeedPhoto(String hubId, String userId, XFile imageFile) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('hubs')
          .child(hubId)
          .child('feed')
          .child('photos')
          .child('${userId}_$timestamp.jpg');

      // Upload file
      final uploadTask = ref.putFile(File(imageFile.path));
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload feed photo: $e');
    }
  }

  /// Delete feed photo
  Future<void> deleteFeedPhoto(String photoUrl) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Extract path from URL
      // Firebase Storage URLs have format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the 'o' segment which precedes the actual path
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex < pathSegments.length - 1) {
        // Reconstruct the path (decode URL encoding)
        final encodedPath = pathSegments.sublist(oIndex + 1).join('/');
        final decodedPath = Uri.decodeComponent(encodedPath);
        final ref = _storage.ref().child(decodedPath);
        await ref.delete();
      } else {
        // Fallback: try to use refFromURL if available
        try {
          final ref = _storage.refFromURL(photoUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Could not delete photo: $e');
          // Silently fail - photo might already be deleted
        }
      }
    } catch (e) {
      debugPrint('Failed to delete feed photo: $e');
      // Don't throw - photo deletion is not critical
    }
  }

  /// Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}

