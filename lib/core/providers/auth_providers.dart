import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/core/providers/services_providers.dart';
import 'package:kattrick/services/cache_service.dart';

part 'auth_providers.g.dart';

/// Auth state stream provider for cache clearing
@riverpod
Stream<firebase_auth.User?> authStateForCache(AuthStateForCacheRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
}

/// Current user ID provider - simplified, no side effects
/// Cache clearing is handled in main.dart to avoid rebuild loops
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
}

/// Check if current user is anonymous
@riverpod
bool isAnonymousUser(IsAnonymousUserRef ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAnonymous;
}

