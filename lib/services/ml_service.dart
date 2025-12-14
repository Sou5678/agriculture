import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';
import '../core/utils/image_utils.dart';
import '../core/constants.dart';

class MLService {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  static bool _isInitialized = false;
  
  // Model configuration
  static const String _modelPath = 'assets/models/plant_disease_model.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224; // Adjust based on your model
  
  // Memory management
  static const int _maxCacheSize = 10;
  static final Map<String, DetectionResult> _resultCache = {};
  
  static bool get isInitialized => _isInitialized;
  
  // Initialize the model
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load the model with optimized options
      final options = InterpreterOptions()
        ..threads = 2; // Optimize for mobile
      
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      
      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      
      _isInitialized = true;
      
      print('Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('Using ${_interpreter!.getInputTensor(0).type} precision');
    } catch (e) {
      print('Error loading model: $e');
      // Don't throw exception, allow app to continue with mock data
      _isInitialized = false;
    }
  }
  
  // Preprocess image for model input (async for better performance)
  static Future<Uint8List> _preprocessImageAsync(String imagePath) async {
    // Read and decode image
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize image to model input size
    image = img.copyResize(image, width: _inputSize, height: _inputSize);
    
    // Convert to Float32List and normalize (0-1)
    final input = Float32List(_inputSize * _inputSize * 3);
    int pixelIndex = 0;
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }
    
    return input.buffer.asUint8List();
  }
  
  // Cache management
  static String _getCacheKey(String imagePath) {
    final file = File(imagePath);
    final stat = file.statSync();
    return '${imagePath}_${stat.modified.millisecondsSinceEpoch}_${stat.size}';
  }
  
  static void _cacheResult(String key, DetectionResult result) {
    if (_resultCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _resultCache.keys.first;
      _resultCache.remove(oldestKey);
    }
    _resultCache[key] = result;
  }
  
  static DetectionResult _getMockResult() {
    return DetectionResult(
      disease: 'Analysis Unavailable',
      confidence: 0.0,
      severity: 'Unknown',
      description: 'Unable to analyze image. Please ensure you have a stable internet connection and try again.',
      symptoms: ['Unable to determine'],
      treatment: ['Retake image', 'Check internet connection', 'Contact support if issue persists'],
      prevention: ['Use clear, well-lit images', 'Ensure stable connection'],
      timestamp: DateTime.now().toIso8601String(),
    );
  }
  
  // Run inference on image
  static Future<DetectionResult> analyzeImage(String imagePath) async {
    // Check cache first
    final cacheKey = _getCacheKey(imagePath);
    if (_resultCache.containsKey(cacheKey)) {
      print('Returning cached result');
      return _resultCache[cacheKey]!;
    }
    
    if (!_isInitialized || _interpreter == null || _labels == null) {
      print('Model not initialized, using mock data');
      return _getMockResult();
    }
    
    try {
      // Optimize image first
      final optimizedImage = await ImageUtils.optimizeImageForML(imagePath);
      
      // Preprocess image
      final input = await _preprocessImageAsync(optimizedImage.path);
      
      // Prepare output tensor
      final output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);
      
      // Run inference
      final stopwatch = Stopwatch()..start();
      _interpreter!.run([input.reshape([1, _inputSize, _inputSize, 3])], output);
      stopwatch.stop();
      
      print('Inference time: ${stopwatch.elapsedMilliseconds}ms');
      
      // Process results
      final predictions = output[0] as List<double>;
      
      // Find the class with highest confidence
      double maxConfidence = 0.0;
      int maxIndex = 0;
      
      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          maxIndex = i;
        }
      }
      
      final disease = _labels![maxIndex];
      final confidence = maxConfidence;
      
      // Determine severity based on confidence and disease type
      String severity = _determineSeverity(disease, confidence);
      
      final result = DetectionResult(
        disease: disease,
        confidence: confidence,
        severity: severity,
        description: _getDescription(disease),
        symptoms: _getSymptoms(disease),
        treatment: _getTreatment(disease),
        prevention: _getPrevention(disease),
        timestamp: DateTime.now().toIso8601String(),
      );
      
      // Cache result
      _cacheResult(cacheKey, result);
      
      // Clean up optimized image
      try {
        await optimizedImage.delete();
      } catch (e) {
        print('Error deleting optimized image: $e');
      }
      
      return result;
      
    } catch (e) {
      print('Error during inference: $e');
      return _getMockResult();
    }
  }
  
  // Helper methods for disease information
  static String _determineSeverity(String disease, double confidence) {
    if (disease.toLowerCase().contains('healthy')) {
      return 'Healthy';
    } else if (confidence > 0.8) {
      return 'Severe';
    } else if (confidence > 0.6) {
      return 'Moderate';
    } else {
      return 'Mild';
    }
  }
  
  static String _getDescription(String disease) {
    // Add your disease descriptions here
    final descriptions = {
      'Healthy': 'The plant appears to be healthy with no visible signs of disease.',
      'Leaf Spot': 'Leaf spot diseases are caused by various fungi and bacteria.',
      'Blight': 'Blight is a rapid and complete chlorosis, browning, then death of plant tissues.',
      'Rust': 'Rust diseases are caused by fungi that produce rust-colored spores.',
      // Add more diseases as per your model
    };
    
    return descriptions[disease] ?? 'Disease detected. Consult with agricultural expert for detailed information.';
  }
  
  static List<String> _getSymptoms(String disease) {
    final symptoms = {
      'Healthy': ['Green, vibrant leaves', 'Normal growth pattern'],
      'Leaf Spot': ['Dark spots on leaves', 'Yellowing around spots', 'Leaf wilting'],
      'Blight': ['Rapid browning of leaves', 'Wilting', 'Death of plant tissues'],
      'Rust': ['Orange/rust colored spots', 'Powdery appearance', 'Leaf yellowing'],
    };
    
    return symptoms[disease] ?? ['Abnormal leaf appearance', 'Discoloration', 'Potential growth issues'];
  }
  
  static List<String> _getTreatment(String disease) {
    final treatments = {
      'Healthy': ['Continue regular care', 'Monitor for changes'],
      'Leaf Spot': ['Remove affected leaves', 'Apply fungicide', 'Improve air circulation'],
      'Blight': ['Remove infected parts immediately', 'Apply copper-based fungicide', 'Reduce humidity'],
      'Rust': ['Apply fungicide spray', 'Remove affected leaves', 'Improve air circulation'],
    };
    
    return treatments[disease] ?? ['Consult agricultural expert', 'Isolate affected plants', 'Monitor closely'];
  }
  
  static List<String> _getPrevention(String disease) {
    final prevention = {
      'Healthy': ['Regular monitoring', 'Proper watering', 'Good nutrition'],
      'Leaf Spot': ['Water at soil level', 'Proper plant spacing', 'Remove debris'],
      'Blight': ['Avoid overhead watering', 'Ensure good drainage', 'Crop rotation'],
      'Rust': ['Avoid overhead watering', 'Good air circulation', 'Remove plant debris'],
    };
    
    return prevention[disease] ?? ['Regular monitoring', 'Proper plant care', 'Good hygiene practices'];
  }
  
  // Clear cache
  static void clearCache() {
    _resultCache.clear();
  }
  
  // Get cache size
  static int getCacheSize() {
    return _resultCache.length;
  }
  
  // Dispose resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
    _resultCache.clear();
  }
}