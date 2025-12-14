import 'package:uuid/uuid.dart';

class IdGenerator {
  static const Uuid _uuid = Uuid();

  // Generate a unique ID for detection results
  static String generateDetectionId() {
    return 'detection_${_uuid.v4()}';
  }

  // Generate a unique ID for history items
  static String generateHistoryId() {
    return 'history_${_uuid.v4()}';
  }

  // Generate a unique ID for images
  static String generateImageId() {
    return 'image_${_uuid.v4()}';
  }

  // Generate a simple unique ID
  static String generateId() {
    return _uuid.v4();
  }

  // Generate a short unique ID (first 8 characters)
  static String generateShortId() {
    return _uuid.v4().substring(0, 8);
  }

  // Generate timestamp-based ID
  static String generateTimestampId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${generateShortId()}';
  }

  // Validate UUID format
  static bool isValidUuid(String id) {
    try {
      Uuid.parse(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}