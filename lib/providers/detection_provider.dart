import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_result.dart';

class DetectionProvider extends ChangeNotifier {
  List<HistoryItem> _history = [];
  bool _isLoading = false;

  List<HistoryItem> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('detectionHistory');
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _history = historyList.map((item) => HistoryItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading history: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveToHistory(HistoryItem item) async {
    try {
      _history.insert(0, item);
      
      // Keep only last 50 items
      if (_history.length > 50) {
        _history = _history.take(50).toList();
      }

      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((item) => item.toJson()).toList());
      await prefs.setString('detectionHistory', historyJson);
      
      notifyListeners();
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  Future<void> deleteHistoryItem(String id) async {
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
    // Simulate AI analysis with mock data
    await Future.delayed(const Duration(seconds: 3));
    
    return DetectionResult(
      disease: 'Leaf Spot Disease',
      confidence: 0.87,
      severity: 'Moderate',
      description: 'Leaf spot diseases are caused by various fungi and bacteria. Early detection allows for effective treatment.',
      symptoms: [
        'Dark spots on leaves',
        'Yellowing around spots',
        'Leaf wilting',
      ],
      treatment: [
        'Remove affected leaves immediately',
        'Apply fungicide spray',
        'Improve air circulation',
        'Reduce watering frequency',
      ],
      prevention: [
        'Water at soil level, not on leaves',
        'Ensure proper spacing between plants',
        'Remove plant debris regularly',
      ],
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}