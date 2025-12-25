// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authStateForCacheHash() => r'b13b28b5dbf08b748be9af4d011a1b3882ac9a7c';

/// Auth state stream provider for cache clearing
///
/// Copied from [authStateForCache].
@ProviderFor(authStateForCache)
final authStateForCacheProvider =
    AutoDisposeStreamProvider<firebase_auth.User?>.internal(
  authStateForCache,
  name: r'authStateForCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateForCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateForCacheRef
    = AutoDisposeStreamProviderRef<firebase_auth.User?>;
String _$currentUserIdHash() => r'4470a2c4ec7c4d619a6e21132df470a0e9e18fc7';

/// Current user ID provider - simplified, no side effects
/// Cache clearing is handled in main.dart to avoid rebuild loops
///
/// Copied from [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = AutoDisposeProvider<String?>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserIdRef = AutoDisposeProviderRef<String?>;
String _$isAnonymousUserHash() => r'aaf5e4b9b206abacceaeff83c957b07c58431b25';

/// Check if current user is anonymous
///
/// Copied from [isAnonymousUser].
@ProviderFor(isAnonymousUser)
final isAnonymousUserProvider = AutoDisposeProvider<bool>.internal(
  isAnonymousUser,
  name: r'isAnonymousUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAnonymousUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAnonymousUserRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
