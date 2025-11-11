import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/core/constants.dart';

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

