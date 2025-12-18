import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/services/media_service.dart';
import 'package:uuid/uuid.dart';

/// Service for Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage;
  final FirebaseFunctions? _functions;
  final FirebaseAuth? _auth;

  StorageService({
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _functions = functions,
        _auth = auth;

  /// Upload profile photo (works on mobile and web)
  Future<String> uploadProfilePhoto(String uid, XFile imageFile) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profilePhotosPath)
          .child(uid)
          .child('avatar.jpg');

      final compressedBytes = await _compressImage(imageFile);
      await ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

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
          .child(uid)
          .child('avatar.jpg');

      final compressedBytes =
          await _compressImageBytes(Uint8List.fromList(imageBytes));
      final uploadTask = ref.putData(
        compressedBytes,
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
      final newRef = _storage
          .ref()
          .child(AppConstants.profilePhotosPath)
          .child(uid)
          .child('avatar.jpg');
      await newRef.delete();
    } catch (_) {
      // Fallback for legacy flat path profile_photos/uid.jpg
      try {
        final legacyRef = _storage
            .ref()
            .child(AppConstants.profilePhotosPath)
            .child('$uid.jpg');
        await legacyRef.delete();
      } catch (e) {
        throw Exception('Failed to delete profile photo: $e');
      }
    }
  }

  /// Upload game photo via signed URL (Cloud Function enforces permissions).
  Future<String> uploadGamePhoto(String gameId, XFile imageFile) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    if (_functions == null || _auth == null) {
      throw Exception('StorageService not configured for signed uploads');
    }
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated for upload.');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';

      final compressedBytes =
          await _compressImage(imageFile, maxDimension: 1600, quality: 80);
      final token = const Uuid().v4();

      final callable = _functions.httpsCallable('getGamePhotoUploadUrl');
      final result =
          await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'gameId': gameId,
        'fileName': fileName,
        'contentType': 'image/jpeg',
      });

      final uploadUrl = result.data['url'] as String;
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'image/jpeg',
          'x-goog-meta-firebaseStorageDownloadTokens': token,
        },
        body: compressedBytes,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'File upload failed with status: ${response.statusCode}. Response: ${response.body}');
      }

      return 'https://firebasestorage.googleapis.com/v0/b/${_functions.app.options.storageBucket}/o/game_photos%2F$gameId%2F$fileName?alt=media&token=$token';
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Upload failed: ${e.message} (Code: ${e.code})');
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

      final compressedBytes =
          await _compressImage(imageFile, maxDimension: 1600, quality: 80);
      await ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

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

  /// Compress image to JPEG, cap longest side, and reduce quality for storage savings
  Future<Uint8List> _compressImage(
    XFile imageFile, {
    int maxDimension = 1080,
    int quality = 80,
  }) async {
    // Prefer file path when available (mobile); fallback to bytes (web).
    if (imageFile.path.isNotEmpty) {
      return MediaService.compressImage(
        File(imageFile.path),
        maxDimension: maxDimension,
        quality: quality,
      );
    }

    final bytes = await imageFile.readAsBytes();
    return MediaService.compressBytes(
      Uint8List.fromList(bytes),
      maxDimension: maxDimension,
      quality: quality,
    );
  }

  Future<Uint8List> _compressImageBytes(
    Uint8List bytes, {
    int maxDimension = 1080,
    int quality = 80,
  }) async {
    return MediaService.compressBytes(
      bytes,
      maxDimension: maxDimension,
      quality: quality,
    );
  }

  /// Upload hub hero/cover image
  Future<String> uploadHubHeroPhoto(String hubId, XFile imageFile) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final compressedBytes = await _compressImage(
        imageFile,
        maxDimension: 1600,
        quality: 80,
      );
      return uploadHubPhoto(
        hubId: hubId,
        fileName: 'hero.jpg',
        fileBytes: compressedBytes,
        contentType: 'image/jpeg',
      );
    } catch (e) {
      throw Exception('Failed to upload hub hero image: $e');
    }
  }

  Future<void> deleteHubHeroPhoto(String hubId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final ref = _storage
          .ref()
          .child(AppConstants.hubPhotosPath)
          .child(hubId)
          .child('hero.jpg');
      await ref.delete();
    } catch (e) {
      debugPrint('Failed to delete hub hero image: $e');
    }
  }

  /// Upload hub logo/cover via signed URL (Cloud Function enforces permissions).
  ///
  /// Requires [FirebaseFunctions] and [FirebaseAuth] to be provided in constructor.
  Future<String> uploadHubPhoto({
    required String hubId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    if (_functions == null || _auth == null) {
      throw Exception('StorageService not configured for signed uploads');
    }
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated for upload.');
    }

    try {
      final token = const Uuid().v4();
      final callable = _functions.httpsCallable('getHubPhotoUploadUrl');
      final result =
          await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'hubId': hubId,
        'fileName': fileName,
        'contentType': contentType,
      });

      final String uploadUrl = result.data['url'];

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
          'x-goog-meta-firebaseStorageDownloadTokens': token,
        },
        body: fileBytes,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'File upload failed with status: ${response.statusCode}. Response: ${response.body}');
      }

      // Public download URL for the uploaded file
      return 'https://firebasestorage.googleapis.com/v0/b/${_functions.app.options.storageBucket}/o/hub_photos%2F$hubId%2F$fileName?alt=media&token=$token';
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Upload failed: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('An unexpected error occurred during upload: $e');
    }
  }
}
