# 🎨 Kattrick - Complete Frontend Guide
## Flutter Architecture, Riverpod, UI Components & Patterns

> **Last Updated:** January 2025  
> **Version:** 2.0  
> **Framework:** Flutter 3.x + Riverpod 2.x

## Overview

Complete guide to Kattrick's Flutter frontend architecture.

## Clean Architecture

```
lib/
├── core/           # Constants, themes
├── models/         # Freezed data models
├── services/       # Firebase services
├── features/
│   └── {feature}/
│       ├── data/       # Repositories
│       ├── domain/     # Business logic
│       └── presentation/
│           ├── providers/  # Riverpod
│           ├── screens/    # Full screens
│           └── widgets/    # Components
├── routing/        # GoRouter
└── utils/          # Helpers
```

## State Management (Riverpod 2.x)

**Pattern:** Code generation with @riverpod

```dart
@riverpod
Future<Hub> hub(HubRef ref, String hubId) async {
  final repository = ref.read(hubRepositoryProvider);
  return repository.getHub(hubId);
}

// Usage:
final hubAsync = ref.watch(hubProvider(hubId));
```

## Models (Freezed)

All models use Freezed for immutability:

```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String displayName,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
```

## Routing (GoRouter)

Declarative routing:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/hubs/:id',
      builder: (context, state) => HubDetailScreen(
        hubId: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

## UI Components

**Design System:** Material 3

**Key Widgets:**
- HubCard
- GameCard
- PlayerCard
- CustomButton
- LoadingIndicator

## Related Documents
- **03_MASTER_ARCHITECTURE.md**
- **01_CURSOR_COMPLETE_GUIDE.md**
