import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service for initialization and configuration
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      
      // Configure Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _initialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Get Firebase Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Get Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  /// Sign in anonymously (for demo purposes)
  static Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await auth.signInAnonymously();
      print('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      print('Signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get current user
  static User? get currentUser => auth.currentUser;
}
