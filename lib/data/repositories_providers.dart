// This file is kept for backward compatibility
// All providers have been migrated to @riverpod in lib/core/providers/
// This file re-exports the new providers to maintain existing imports

export 'package:kattrick/core/providers/firestore_provider.dart';
export 'package:kattrick/core/providers/repositories_providers.dart';
export 'package:kattrick/core/providers/services_providers.dart';
export 'package:kattrick/core/providers/auth_providers.dart';
export 'package:kattrick/core/providers/complex_providers.dart';

// Note: The old manual Provider syntax has been replaced with @riverpod code generation
// All existing imports will continue to work, but providers are now generated automatically
