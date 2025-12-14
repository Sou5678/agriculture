import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../constants.dart';

class ImageUtils {
  // Optimize image for ML processing
  static Future<File> optimizeImageForML(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');
      
      // Resize if too large
      if (image.width > AppConstants.maxImageSize || image.height > AppConstants.maxImageSize) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? AppConstants.maxImageSize : null,
          height: image.height > image.width ? AppConstants.maxImageSize : null,
        );
      }
      
      // Compress
      final compressedBytes = img.encodeJpg(image, quality: AppConstants.imageQuality);
      
      // Save optimized image
      final tempDir = await getTemporaryDirectory();
      final optimizedFile = File(path.join(
        tempDir.path,
        'optimized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      
      await optimizedFile.writeAsBytes(compressedBytes);
      return optimizedFile;
    } catch (e) {
      print('Error optimizing image: $e');
      return File(imagePath); // Return original if optimization fails
    }
  }
  
  // Get image thumbnail
  static Future<Uint8List?> getImageThumbnail(String imagePath, {int size = 150}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Create thumbnail
      final thumbnail = img.copyResize(image, width: size, height: size);
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }
  
  // Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('optimized_')) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          
          // Delete files older than 1 hour
          if (age.inHours > 1) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
  
  // Get file size in MB
  static Future<double> getFileSizeInMB(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }
}