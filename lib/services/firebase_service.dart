import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/detection_result.dart';
import '../core/utils/id_generator.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseStorage _storage;
  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  late FirebaseRemoteConfig _remoteConfig;
  late FirebaseFirestore _firestore;
  late FirebaseMessaging _messaging;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Initialize Firebase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _remoteConfig = FirebaseRemoteConfig.instance;
      _firestore = FirebaseFirestore.instance;
      _messaging = FirebaseMessaging.instance;

      // Configure Crashlytics
      if (!kDebugMode) {
        FlutterError.onError = _crashlytics.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Configure Remote Config
      await _configureRemoteConfig();

      // Configure FCM
      await _configureFCM();

      _isInitialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  // Configure Remote Config
  Future<void> _configureRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values
      await _remoteConfig.setDefaults({
        'ml_model_version': '1.0.0',
        'max_image_size_mb': 10,
        'enable_cloud_ml': false,
        'app_maintenance_mode': false,
        'feature_flags': '{}',
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error configuring Remote Config: $e');
    }
  }

  // Configure FCM
  Future<void> _configureFCM() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
        
        // Get FCM token
        String? token = await _messaging.getToken();
        print('FCM Token: $token');
        
        // Save token to user profile if logged in
        if (isLoggedIn && token != null) {
          await _saveUserFCMToken(token);
        }
      }
    } catch (e) {
      print('Error configuring FCM: $e');
    }
  }

  // Authentication Methods
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      await _analytics.logLogin(loginMethod: 'anonymous');
      return result;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(loginMethod: 'email');
      return result;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error signing in with email: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logSignUp(signUpMethod: 'email');
      return result;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error creating user: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _analytics.logEvent(name: 'user_logout');
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error signing out: $e');
    }
  }

  // Cloud Storage Methods
  Future<String?> uploadImage(File imageFile, String detectionId) async {
    try {
      String fileName = '${detectionId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String path = 'detections/${currentUser?.uid ?? 'anonymous'}/$fileName';
      
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(imageFile);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _analytics.logEvent(
        name: 'image_uploaded',
        parameters: {'file_size': await imageFile.length()},
      );
      
      return downloadUrl;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error deleting image: $e');
      return false;
    }
  }

  // Firestore Methods
  Future<void> saveDetectionResult(HistoryItem historyItem, {String? imageUrl}) async {
    try {
      Map<String, dynamic> data = {
        'id': historyItem.id,
        'userId': currentUser?.uid ?? 'anonymous',
        'disease': historyItem.result.disease,
        'confidence': historyItem.result.confidence,
        'severity': historyItem.result.severity,
        'description': historyItem.result.description,
        'symptoms': historyItem.result.symptoms,
        'treatment': historyItem.result.treatment,
        'prevention': historyItem.result.prevention,
        'timestamp': FieldValue.serverTimestamp(),
        'localImageUri': historyItem.imageUri,
        'cloudImageUrl': imageUrl,
        'deviceInfo': await _getDeviceInfo(),
      };

      await _firestore.collection('detections').doc(historyItem.id).set(data);
      
      await _analytics.logEvent(
        name: 'detection_saved',
        parameters: {
          'disease': historyItem.result.disease,
          'confidence': (historyItem.result.confidence * 100).round(),
        },
      );
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error saving detection result: $e');
    }
  }

  Future<List<HistoryItem>> getUserDetections({int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('detections')
          .where('userId', isEqualTo: currentUser?.uid ?? 'anonymous')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      List<HistoryItem> detections = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        DetectionResult result = DetectionResult(
          disease: data['disease'] ?? 'Unknown',
          confidence: (data['confidence'] ?? 0.0).toDouble(),
          severity: data['severity'] ?? 'Unknown',
          description: data['description'] ?? '',
          symptoms: List<String>.from(data['symptoms'] ?? []),
          treatment: List<String>.from(data['treatment'] ?? []),
          prevention: List<String>.from(data['prevention'] ?? []),
          timestamp: data['timestamp']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
        );

        HistoryItem historyItem = HistoryItem(
          id: data['id'] ?? IdGenerator.generateHistoryId(),
          imageUri: data['cloudImageUrl'] ?? data['localImageUri'] ?? '',
          result: result,
          timestamp: result.timestamp,
        );

        detections.add(historyItem);
      }

      return detections;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error getting user detections: $e');
      return [];
    }
  }

  Future<void> deleteDetection(String detectionId) async {
    try {
      await _firestore.collection('detections').doc(detectionId).delete();
      await _analytics.logEvent(name: 'detection_deleted');
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error deleting detection: $e');
    }
  }

  // Analytics Methods
  Future<void> logDetectionEvent(DetectionResult result) async {
    try {
      await _analytics.logEvent(
        name: 'plant_disease_detected',
        parameters: {
          'disease_name': result.disease,
          'confidence_score': (result.confidence * 100).round(),
          'severity_level': result.severity,
        },
      );
    } catch (e) {
      print('Error logging detection event: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      print('Error logging screen view: $e');
    }
  }

  // Remote Config Methods
  String getRemoteConfigString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      print('Error getting remote config string: $e');
      return '';
    }
  }

  bool getRemoteConfigBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      print('Error getting remote config bool: $e');
      return false;
    }
  }

  int getRemoteConfigInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      print('Error getting remote config int: $e');
      return 0;
    }
  }

  double getRemoteConfigDouble(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      print('Error getting remote config double: $e');
      return 0.0;
    }
  }

  // Helper Methods
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isPhysicalDevice': !kIsWeb,
    };
  }

  Future<void> _saveUserFCMToken(String token) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // User Profile Methods
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        await currentUser!.updatePhotoURL(photoURL);
        
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'displayName': displayName,
          'photoURL': photoURL,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      print('Error updating user profile: $e');
    }
  }

  // Error Reporting
  Future<void> recordError(dynamic error, StackTrace? stackTrace, {bool fatal = false}) async {
    try {
      await _crashlytics.recordError(error, stackTrace, fatal: fatal);
    } catch (e) {
      print('Error recording error: $e');
    }
  }

  // App State Methods
  bool get isMaintenanceMode => getRemoteConfigBool('app_maintenance_mode');
  bool get isCloudMLEnabled => getRemoteConfigBool('enable_cloud_ml');
  int get maxImageSizeMB => getRemoteConfigInt('max_image_size_mb');
  String get mlModelVersion => getRemoteConfigString('ml_model_version');
}