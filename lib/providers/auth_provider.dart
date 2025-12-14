import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  // Initialize auth provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });

      // Sign in anonymously if no user
      if (_user == null) {
        await signInAnonymously();
      }

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential? result = await _firebaseService.signInAnonymously();
      if (result != null) {
        _user = result.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Failed to sign in anonymously';
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential? result = await _firebaseService.signInWithEmailAndPassword(email, password);
      if (result != null) {
        _user = result.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
      }
    } catch (e) {
      _error = _getAuthErrorMessage(e);
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Create user with email and password
  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserCredential? result = await _firebaseService.createUserWithEmailAndPassword(email, password);
      if (result != null) {
        _user = result.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = _getAuthErrorMessage(e);
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.signOut();
      _user = null;
      
      // Sign in anonymously after sign out
      await signInAnonymously();
    } catch (e) {
      _error = 'Failed to sign out';
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Refresh user data
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile';
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Convert anonymous account to permanent account
  Future<bool> linkWithEmailAndPassword(String email, String password) async {
    if (_user == null || !_user!.isAnonymous) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      UserCredential result = await _user!.linkWithCredential(credential);
      _user = result.user;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getAuthErrorMessage(e);
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getAuthErrorMessage(e);
      await _firebaseService.recordError(e, null);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return 'An unexpected error occurred.';
  }

  // Get user display name
  String get displayName {
    if (_user?.displayName?.isNotEmpty == true) {
      return _user!.displayName!;
    } else if (_user?.email?.isNotEmpty == true) {
      return _user!.email!.split('@')[0];
    } else if (_user?.isAnonymous == true) {
      return 'Guest User';
    }
    return 'User';
  }

  // Get user email
  String get email => _user?.email ?? '';

  // Get user photo URL
  String? get photoURL => _user?.photoURL;

  // Check if user has verified email
  bool get isEmailVerified => _user?.emailVerified ?? false;
}