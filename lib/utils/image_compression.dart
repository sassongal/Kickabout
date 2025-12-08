import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kattrick/services/media_service.dart';
import 'dart:math' as math;

/// Utility for compressing images before upload to reduce storage costs
/// 
/// Features:
/// - Resize large images
/// - Compress JPEG quality
/// - Maintain aspect ratio
/// - WebP support (optional)
class ImageCompression {
  /// Compress image file
  /// 
  /// [file] - Original image file
  /// [maxWidth] - Maximum width (default: 1200px)
  /// [maxHeight] - Maximum height (default: 1200px)
  /// [quality] - JPEG quality 0-100 (default: 70)
  /// 
  /// Returns compressed file
  static Future<File> compressImage(
    File file, {
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 70,
  }) async {
    try {
      // Read file bytes
      final bytes = await file.readAsBytes();
      
      // For now, use Flutter's built-in image package if available
      // If not, return original file (compression will happen server-side)
      
      // Check file size
      final fileSizeKB = bytes.length / 1024;
      
      // If file is already small (< 500KB), return as-is
      if (fileSizeKB < 500) {
        debugPrint('Image already small (${fileSizeKB.toStringAsFixed(1)}KB), skipping compression');
        return file;
      }
      
      // Try to use image package if available
      // Compress off the UI thread using the shared MediaService
      try {
        final maxDimension = math.min(maxWidth, maxHeight);
        final compressedBytes = await MediaService.compressBytes(
          bytes,
          maxDimension: maxDimension,
          quality: quality,
        );

        // If compression made the file larger, keep the original
        if (compressedBytes.length >= bytes.length) {
          debugPrint(
              'Compression skipped (compressed is larger: ${compressedBytes.length} >= ${bytes.length})');
          return file;
        }

        debugPrint(
            'Compressed image from ${fileSizeKB.toStringAsFixed(1)}KB to ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB');

        // Overwrite the original file with compressed bytes
        return await file.writeAsBytes(compressedBytes, flush: true);
      } catch (e) {
        debugPrint('Image compression failed, returning original: $e');
        return file;
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file; // Return original on error
    }
  }

  /// Get recommended compression settings based on file size
  static Map<String, dynamic> getCompressionSettings(int fileSizeBytes) {
    final fileSizeKB = fileSizeBytes / 1024;
    
    if (fileSizeKB < 500) {
      return {
        'compress': false,
        'reason': 'File already small',
      };
    } else if (fileSizeKB < 2000) {
      return {
        'compress': true,
        'maxWidth': 1200,
        'maxHeight': 1200,
        'quality': 75,
      };
    } else {
      return {
        'compress': true,
        'maxWidth': 1000,
        'maxHeight': 1000,
        'quality': 70,
      };
    }
  }
}
