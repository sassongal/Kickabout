import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class MediaService {
  /// Compresses an image off the UI thread to avoid jank.
  static Future<Uint8List> compressImage(
    File file, {
    int maxDimension = 1920,
    int quality = 80,
  }) async {
    final bytes = await file.readAsBytes();
    return compute(
      _compressInIsolate,
      _CompressPayload(bytes, maxDimension, quality),
    );
  }

  /// Compress raw bytes (useful when no file path exists, e.g. Web).
  static Future<Uint8List> compressBytes(
    Uint8List bytes, {
    int maxDimension = 1920,
    int quality = 80,
  }) {
    return compute(
      _compressInIsolate,
      _CompressPayload(bytes, maxDimension, quality),
    );
  }
}

class _CompressPayload {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;

  _CompressPayload(this.bytes, this.maxDimension, this.quality);
}

Uint8List _compressInIsolate(_CompressPayload payload) {
  var image = img.decodeImage(payload.bytes);
  if (image == null) return payload.bytes;

  final maxDim = payload.maxDimension;
  if (image.width > maxDim || image.height > maxDim) {
    image = img.copyResize(
      image,
      width: maxDim,
      height: maxDim,
      maintainAspect: true,
    );
  }

  return Uint8List.fromList(
    img.encodeJpg(image, quality: payload.quality),
  );
}
