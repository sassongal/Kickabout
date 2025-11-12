import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickabout/config/env.dart';

/// Authentication service
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Auth state changes stream
  Stream<User?> get authStateChanges {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    if (!Env.isFirebaseAvailable) {
      debugPrint('❌ Anonymous sign in failed: Firebase not available (limited mode)');
      throw Exception('Firebase not available');
    }
    try {
      debugPrint('🔐 Attempting anonymous sign in...');
      final result = await _auth.signInAnonymously();
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
    await _auth.signOut();
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    return await _auth.signInWithEmailAndPassword(
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
      final result = await _auth.createUserWithEmailAndPassword(
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
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Update user password (requires re-authentication)
  Future<void> updatePassword(String newPassword) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    await _auth.currentUser?.updatePassword(newPassword);
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    await _auth.currentUser?.reauthenticateWithCredential(credential);
  }
}

