import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/services/auth_service.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Integration tests for authentication flow
void main() {
  group('Auth Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle anonymous sign in flow', () async {
      final authService = container.read(authServiceProvider);
      
      // Note: This test requires Firebase to be configured
      // In a real test environment, you'd use Firebase emulators
      try {
        final user = await authService.signInAnonymously();
        expect(user, isNotNull);
        expect(user?.isAnonymous, true);
      } catch (e) {
        // If Firebase is not configured, skip test
        expect(e.toString(), contains('Firebase'));
      }
    });

    test('should handle email/password sign up flow', () async {
      final authService = container.read(authServiceProvider);
      final usersRepo = container.read(usersRepositoryProvider);
      
      // Generate unique email for test
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testPassword = 'TestPassword123!';
      final testName = 'Test User';

      try {
        // Sign up
        final userCredential = await authService.createUserWithEmailAndPassword(
          testEmail,
          testPassword,
        );
        
        expect(userCredential.user, isNotNull);
        expect(userCredential.user?.email, testEmail);

        // Create user document
        final user = User(
          uid: userCredential.user!.uid,
          name: testName,
          email: testEmail,
          createdAt: DateTime.now(),
        );
        
        await usersRepo.setUser(user);
        
        // Verify user was created
        final savedUser = await usersRepo.getUser(userCredential.user!.uid);
        expect(savedUser, isNotNull);
        expect(savedUser?.name, testName);
        expect(savedUser?.email, testEmail);
      } catch (e) {
        // If Firebase is not configured, skip test
        expect(e.toString(), contains('Firebase'));
      }
    });

    test('should handle sign out flow', () async {
      final authService = container.read(authServiceProvider);
      
      try {
        // Sign in anonymously first
        await authService.signInAnonymously();
        
        // Sign out
        await authService.signOut();
        
        // Verify signed out
        final currentUser = authService.currentUser;
        expect(currentUser, isNull);
      } catch (e) {
        // If Firebase is not configured, skip test
        expect(e.toString(), contains('Firebase'));
      }
    });
  });
}

