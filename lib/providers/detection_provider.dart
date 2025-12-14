import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_result.dart';
import '../services/ml_service.dart';
import '../services/firebase_service.dart';
import '../core/constants.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/id_generator.dart';

class DetectionProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<HistoryItem> _history = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  bool _syncWithCloud = true;

  List<HistoryItem> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get syncWithCloud => _syncWithCloud;
  
  // Statistics
  int get totalDetections => _history.length;
  int get healthyDetections => _history.where((item) => 
    item.result.disease.toLowerCase().contains('healthy')).length;
  int get diseaseDetections => totalDetections - healthyDetections;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize ML Service
      await MLService.initialize();
      
      // Load history from local storage first
      await _loadHistoryFromStorage();
      
      // Sync with cloud if Firebase is available
      if (_firebaseService.isInitialized) {
        await _performFirebaseSync();
      }
      
      // Clean up old temp files
      await ImageUtils.cleanupTempFiles();
      
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize: $e';
      print('Error initializing DetectionProvider: $e');
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadHistoryFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('detectionHistory');
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _history = historyList
            .map((item) => HistoryItem.fromJson(item))
            .take(AppConstants.maxHistoryItems) // Limit history size
            .toList();
      }
    } catch (e) {
      print('Error loading history: $e');
      _history = [];
    }
  }

  Future<void> loadHistory() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    await _loadHistoryFromStorage();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveToHistory(HistoryItem item, {File? imageFile}) async {
    try {
      _history.insert(0, item);
      
      // Keep only last N items
      if (_history.length > AppConstants.maxHistoryItems) {
        final removedItems = _history.skip(AppConstants.maxHistoryItems).toList();
        _history = _history.take(AppConstants.maxHistoryItems).toList();
        
        // Clean up removed images
        for (final removedItem in removedItems) {
          try {
            final file = File(removedItem.imageUri);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Error deleting old image: $e');
          }
        }
      }

      // Save to local storage
      await _saveHistoryToStorage();
      
      // Save to Firebase if enabled and available
      if (_syncWithCloud && _firebaseService.isInitialized) {
        await _saveToFirebase(item, imageFile);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving to history: $e');
      _error = 'Failed to save detection';
      await _firebaseService.recordError(e, null);
      notifyListeners();
    }
  }
  
  Future<void> _saveHistoryToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(_history.map((item) => item.toJson()).toList());
    await prefs.setString('detectionHistory', historyJson);
  }

  // FIXED: Renamed method to avoid conflict
  Future<void> removeHistoryItem(String id) async {
    try {
      _history.removeWhere((item) => item.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((item) => item.toJson()).toList());
      await prefs.setString('detectionHistory', historyJson);
      
      notifyListeners();
    } catch (e) {
      print('Error deleting history item: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _history.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('detectionHistory');
      
      notifyListeners();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  List<HistoryItem> searchHistory(String query) {
    if (query.isEmpty) return _history;
    
    return _history.where((item) {
      return item.result.disease.toLowerCase().contains(query.toLowerCase()) ||
             item.result.severity.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<DetectionResult> analyzeImage(String imagePath) async {
    _error = null;
    
    try {
      // Check file size
      final fileSizeMB = await ImageUtils.getFileSizeInMB(imagePath);
      if (fileSizeMB > 10) {
        throw Exception('Image file too large (${fileSizeMB.toStringAsFixed(1)}MB). Please use a smaller image.');
      }
      
      // Use ML service for actual inference
      final result = await MLService.analyzeImage(imagePath);
      return result;
    } catch (e) {
      print('Error in ML analysis: $e');
      _error = e.toString();
      
      // Fallback to mock data if ML fails
      await Future.delayed(const Duration(seconds: 1));
      
      return DetectionResult(
        disease: 'Analysis Error',
        confidence: 0.0,
        severity: 'Unknown',
        description: 'Unable to analyze image. ${e.toString()}',
        symptoms: ['Unable to determine'],
        treatment: ['Retake image', 'Ensure good lighting', 'Check file size', 'Contact support if issue persists'],
        prevention: ['Use clear, well-lit images', 'Keep file size under 10MB'],
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Get detection statistics
  Map<String, int> getDetectionStats() {
    final stats = <String, int>{};
    for (final item in _history) {
      final disease = item.result.disease;
      stats[disease] = (stats[disease] ?? 0) + 1;
    }
    return stats;
  }
  
  // Get recent detections (last 7 days)
  List<HistoryItem> getRecentDetections() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _history.where((item) {
      final itemDate = DateTime.parse(item.timestamp);
      return itemDate.isAfter(sevenDaysAgo);
    }).toList();
  }

  // Firebase integration methods
  Future<void> _performFirebaseSync() async {
    try {
      if (!_firebaseService.isLoggedIn) return;
      
      // Get cloud detections
      final cloudDetections = await _firebaseService.getUserDetections();
      
      // Merge with local detections (avoid duplicates)
      final localIds = _history.map((item) => item.id).toSet();
      final newCloudDetections = cloudDetections.where((item) => !localIds.contains(item.id)).toList();
      
      if (newCloudDetections.isNotEmpty) {
        _history.addAll(newCloudDetections);
        _history.sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));
        
        // Limit total items
        if (_history.length > AppConstants.maxHistoryItems) {
          _history = _history.take(AppConstants.maxHistoryItems).toList();
        }
        
        await _saveHistoryToStorage();
      }
    } catch (e) {
      print('Error syncing with Firebase: $e');
      await _firebaseService.recordError(e, null);
    }
  }

  Future<void> _saveToFirebase(HistoryItem item, File? imageFile) async {
    try {
      String? imageUrl;
      
      // Upload image to Firebase Storage if available
      if (imageFile != null && await imageFile.exists()) {
        imageUrl = await _firebaseService.uploadImage(imageFile, item.id);
      }
      
      // Save detection result to Firestore
      await _firebaseService.saveDetectionResult(item, imageUrl: imageUrl);
      
      // Log analytics event
      await _firebaseService.logDetectionEvent(item.result);
    } catch (e) {
      print('Error saving to Firebase: $e');
      await _firebaseService.recordError(e, null);
    }
  }

  // Toggle cloud sync
  void toggleCloudSync(bool enabled) {
    _syncWithCloud = enabled;
    notifyListeners();
  }

  // FIXED: Renamed method to avoid conflict with getter
  Future<void> performCloudSync() async {
    if (!_firebaseService.isInitialized || !_syncWithCloud) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _performFirebaseSync();
    } catch (e) {
      _error = 'Failed to sync with cloud';
      await _firebaseService.recordError(e, null);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Delete from cloud
  Future<void> deleteFromCloud(String detectionId) async {
    try {
      if (_firebaseService.isInitialized) {
        await _firebaseService.deleteDetection(detectionId);
      }
    } catch (e) {
      print('Error deleting from cloud: $e');
      await _firebaseService.recordError(e, null);
    }
  }

  // Enhanced delete with cloud sync - FIXED: Using the correct method name
  @override
  Future<void> deleteHistoryItem(String id) async {
    try {
      _history.removeWhere((item) => item.id == id);
      
      // Delete from local storage
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((item) => item.toJson()).toList());
      await prefs.setString('detectionHistory', historyJson);
      
      // Delete from cloud
      if (_syncWithCloud) {
        await deleteFromCloud(id);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting history item: $e');
      await _firebaseService.recordError(e, null);
    }
  }

  // Get cloud sync status
  bool get isCloudSyncAvailable => _firebaseService.isInitialized && _firebaseService.isLoggedIn;
}