import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickabout/config/env.dart';

/// Authentication service
class AuthService {
  FirebaseAuth? _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth;

  FirebaseAuth get _firebaseAuth {
    if (!Env.isFirebaseAvailable) {
      throw StateError('Firebase not available');
    }
    return _auth ??= FirebaseAuth.instance;
  }

  /// Get current user
  User? get currentUser {
    if (!Env.isFirebaseAvailable) {
      return null;
    }
    return _firebaseAuth.currentUser;
  }

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth state changes stream
  Stream<User?> get authStateChanges {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }
    return _firebaseAuth.authStateChanges();
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    if (!Env.isFirebaseAvailable) {
      debugPrint('❌ Anonymous sign in failed: Firebase not available (limited mode)');
      throw Exception('Firebase not available');
    }
    try {
      debugPrint('🔐 Attempting anonymous sign in...');
      final result = await _firebaseAuth.signInAnonymously();
      debugPrint('✅ Anonymous sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('❌ Anonymous sign in failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    await _firebaseAuth.signOut();
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!Env.isFirebaseAvailable) {
      debugPrint('❌ User registration failed: Firebase not available (limited mode)');
      throw Exception('Firebase not available');
    }
    try {
      debugPrint('🔐 Attempting user registration: $email');
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ User registration successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('❌ User registration failed: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Update user password (requires re-authentication)
  Future<void> updatePassword(String newPassword) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    await _firebaseAuth.currentUser?.updatePassword(newPassword);
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    await _firebaseAuth.currentUser?.reauthenticateWithCredential(credential);
  }
}

