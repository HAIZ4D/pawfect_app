import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

/// Image processing utilities for compression, resizing, and Base64 conversion
class ImageProcessor {
  /// Compress and convert image to Base64 string for Firestore storage
  /// Returns Base64 string or null if processing fails
  static Future<String?> compressAndConvertToBase64(
    File imageFile, {
    int maxWidth = AppConstants.maxImageWidth,
    int maxHeight = AppConstants.maxImageHeight,
    int quality = AppConstants.imageQuality,
  }) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();

      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize if needed
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress to JPEG
      final compressedBytes = img.encodeJpg(image, quality: quality);

      // Check file size (target: < 500KB for Firestore efficiency)
      if (compressedBytes.length > AppConstants.maxImageSizeKB * 1024) {
        // Try with lower quality
        final recompressedBytes = img.encodeJpg(image, quality: quality - 15);

        // If still too large, resize further
        if (recompressedBytes.length > AppConstants.maxImageSizeKB * 1024) {
          image = img.copyResize(
            image,
            width: (image.width * 0.7).toInt(),
            height: (image.height * 0.7).toInt(),
          );
          final finalBytes = img.encodeJpg(image, quality: quality - 20);
          return base64Encode(finalBytes);
        }
        return base64Encode(recompressedBytes);
      }

      // Convert to Base64
      return base64Encode(compressedBytes);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Convert Base64 string back to image bytes
  static Uint8List? base64ToImageBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64: $e');
      return null;
    }
  }

  /// Get image file size in KB
  static Future<double> getImageSizeKB(File imageFile) async {
    try {
      final bytes = await imageFile.length();
      return bytes / 1024;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Compress image file directly
  static Future<File?> compressImageFile(
    File imageFile, {
    int maxWidth = AppConstants.maxImageWidth,
    int maxHeight = AppConstants.maxImageHeight,
    int quality = AppConstants.imageQuality,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize if needed
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
        );
      }

      // Compress
      final compressedBytes = img.encodeJpg(image, quality: quality);

      // Write to file
      await imageFile.writeAsBytes(compressedBytes);
      return imageFile;
    } catch (e) {
      print('Error compressing image file: $e');
      return null;
    }
  }

  /// Create thumbnail from image
  static Future<String?> createThumbnail(
    File imageFile, {
    int size = 200,
    int quality = 75,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);

      // Compress
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);

      // Convert to Base64
      return base64Encode(thumbnailBytes);
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Validate image file
  static Future<bool> isValidImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Get image dimensions
  static Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      return null;
    }
  }
}
