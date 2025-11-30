import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'package:kattrick/config/env.dart';

/// Authentication service
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Check if current user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

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
      debugPrint(
          '❌ Anonymous sign in failed: Firebase not available (limited mode)');
      throw Exception('Firebase not available');
    }

    try {
      debugPrint('🔐 Attempting anonymous sign in...');

      final result = await _auth.signInAnonymously();

      if (result.user == null) {
        throw Exception('Anonymous sign in returned null user');
      }

      debugPrint('✅ Anonymous sign in successful: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '❌ Anonymous sign in failed (FirebaseAuthException): ${e.code} - ${e.message}');

      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'auth/operation-not-allowed':
          errorMessage = 'התחברות כאורח לא מופעלת. אנא פנה לתמיכה.';
          break;
        case 'auth/network-request-failed':
          errorMessage = 'שגיאת רשת. נסה שוב.';
          break;
        default:
          errorMessage = 'התחברות נכשלה: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
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
      debugPrint(
          '❌ User registration failed: Firebase not available (limited mode)');
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

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    if (!Env.isFirebaseAvailable) {
      debugPrint('❌ Google sign in failed: Firebase not available');
      throw Exception('Firebase not available');
    }

    try {
      debugPrint('🔐 Attempting Google sign in...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('⚠️ Google sign in canceled by user');
        throw Exception('Google sign in canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final result = await _auth.signInWithCredential(credential);
      debugPrint('✅ Google sign in successful: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      // Handle Web-specific popup errors gracefully
      if (kIsWeb) {
        if (e.code == 'auth/popup-closed-by-user' ||
            e.code == 'auth/cancelled-popup-request' ||
            e.code == 'auth/popup-blocked') {
          debugPrint('⚠️ Google sign in popup closed/blocked by user');
          throw Exception('התחברות בוטלה');
        }
      }
      debugPrint(
          '❌ Google sign in failed (FirebaseAuthException): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      // Handle GoogleSignIn cancellation (especially on Web)
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('popup')) {
        debugPrint('⚠️ Google sign in canceled: $e');
        throw Exception('התחברות בוטלה');
      }
      debugPrint('❌ Google sign in failed: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    if (!Env.isFirebaseAvailable) {
      debugPrint('❌ Apple sign in failed: Firebase not available');
      throw Exception('Firebase not available');
    }

    // Apple Sign In is only available on iOS and macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Apple Sign In is only available on iOS and macOS');
    }

    try {
      debugPrint('🔐 Attempting Apple sign in...');

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final result = await _auth.signInWithCredential(oauthCredential);
      debugPrint('✅ Apple sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('❌ Apple sign in failed: $e');
      rethrow;
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    try {
      await _auth.currentUser?.delete();
      debugPrint('✅ User account deleted successfully');
    } catch (e) {
      debugPrint('❌ User account deletion failed: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    // No internal resources to dispose currently
    // This method is kept for consistency and future use
  }
}
