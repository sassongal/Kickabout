# Kickabout Architecture Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Anti-Pattern Remediation](#anti-pattern-remediation)
3. [Domain Layer](#domain-layer)
4. [Value Objects](#value-objects)
5. [Dependency Injection](#dependency-injection)
6. [Layer Boundaries](#layer-boundaries)
7. [Migration Guide](#migration-guide)

---

## Architecture Overview

Kickabout follows **Feature-Based Clean Architecture** with strict layer separation:

```
lib/
├── core/                           # Cross-cutting concerns
│   ├── providers/                  # Riverpod DI container
│   └── infrastructure/             # Framework abstractions
├── features/                       # Feature modules (bounded contexts)
│   ├── identity/                   # User management
│   ├── hubs/                       # Hub management
│   └── games/                      # Game/session management
│       ├── domain/                 # Business logic (pure Dart)
│       │   ├── models/             # Entities, value objects
│       │   ├── services/           # Domain services
│       │   └── use_cases/          # Application logic
│       ├── infrastructure/         # External dependencies
│       │   └── repositories/       # Firestore implementations
│       └── presentation/           # UI layer
│           ├── screens/
│           ├── widgets/
│           └── notifiers/
└── shared/                         # Shared kernel
    ├── domain/                     # Shared value objects
    └── infrastructure/             # Shared converters
```

### Dependency Rule

**Critical:** Dependencies must only point inward:
```
presentation → application → domain ← infrastructure
```

**Forbidden:**
- ❌ Domain importing `cloud_firestore`
- ❌ Domain importing infrastructure
- ❌ Direct repository instantiation (Service Locator pattern)

---

## Anti-Pattern Remediation

This architecture eliminates four critical anti-patterns:

### 1. ✅ Service Locator Pattern → Dependency Injection

**Before (Anti-pattern):**
```dart
class MyScreen extends StatefulWidget {
  void _saveData() {
    final repo = HubsRepository(); // Service Locator!
    repo.save(data);
  }
}
```

**After (Correct):**
```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  void _saveData() {
    final repo = ref.read(hubsRepositoryProvider); // DI via Riverpod
    repo.save(data);
  }
}
```

**Why:** Service Locator breaks testability and hides dependencies.

---

### 2. ✅ Primitive Obsession → Typed Value Objects

**Before (Anti-pattern):**
```dart
void addPlayer(String gameId, String userId) {
  // Compiler can't prevent bugs:
  signupsRepo.create(userId, gameId); // Swapped parameters!
}
```

**After (Correct):**
```dart
void addPlayer(GameId gameId, UserId userId) {
  // Type system enforces correctness:
  signupsRepo.create(userId, gameId); // Compile error!
}
```

**Value Objects Implemented:**
- `GameId`, `HubId`, `UserId`, `EventId`, `VenueId`
- `GeographicPoint` (replaces `GeoPoint`)
- `TimeRange`
- `UserLocation`, `PrivacySettings`, `NotificationPreferences`

---

### 3. ✅ Leaky Abstractions → Domain Primitives

**Before (Anti-pattern):**
```dart
// Domain model coupled to Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class Hub {
  final GeoPoint? location; // Firestore type in domain!
}
```

**After (Correct):**
```dart
// Domain model infrastructure-agnostic
class Hub {
  final GeographicPoint? location; // Domain type
}

// Converter lives in infrastructure layer
class GeographicPointFirestoreConverter {
  GeoPoint toFirestore(GeographicPoint point) => GeoPoint(...);
  GeographicPoint fromFirestore(GeoPoint geoPoint) => GeographicPoint(...);
}
```

**Benefits:**
- Domain layer testable without Firebase SDK
- Can migrate to different database
- Business logic independent of infrastructure

---

### 4. ✅ Anemic Domain Models → Rich Domain Models

**Current State:** Repository + Service pattern (acceptable for CRUD apps)

**Models contain:**
- ✅ Calculated properties (`isUpcoming`, `totalParticipants`)
- ✅ Predicates (`canAddPlayer`, `hasMinimumPlayers`)
- ✅ Business logic queries

**Models do NOT contain:**
- ❌ State transitions (in services)
- ❌ Persistence logic (in repositories)

**Example:**
```dart
class Game {
  // Calculated properties
  bool get isUpcoming => status == GameStatus.teamSelection;
  int get totalParticipants => teams.fold(0, (sum, t) => sum + t.playerIds.length);

  // Business logic predicates
  bool canAddPlayer(UserId userId) {
    if (isFull) return false;
    if (isCompleted || isCancelled) return false;
    return !teams.any((team) => team.playerIds.contains(userId.value));
  }
}
```

---

## Domain Layer

### Core Principles

1. **Pure Dart:** No Flutter, no Firebase, no external frameworks
2. **Business Logic Only:** Domain rules, validations, calculations
3. **Infrastructure-Agnostic:** Use domain types, not vendor types

### Domain Models

Located in: `lib/features/*/domain/models/`

**Characteristics:**
- Immutable (using Freezed)
- Rich with business logic
- Use value objects for complex types
- No infrastructure dependencies

**Example:**
```dart
@freezed
class Hub with _$Hub {
  const factory Hub({
    required HubId hubId,
    required String name,
    required GeographicPoint? location, // Domain type
    @Default([]) List<UserId> activeMemberIds, // Typed IDs
  }) = _Hub;

  const Hub._();

  // Business logic
  bool hasMinimumMembers() => activeMemberIds.length >= 10;
  bool isNearLocation(GeographicPoint point) =>
      location?.distanceToKm(point) ?? double.infinity < 10;
}
```

---

## Value Objects

### Why Value Objects?

1. **Type Safety:** Compiler prevents wrong types
2. **Validation:** Enforce invariants at creation
3. **Encapsulation:** Business logic in one place
4. **Expressiveness:** Code reads like business language

### Available Value Objects

#### Entity IDs

```dart
// lib/shared/domain/models/value_objects/entity_id.dart

final hubId = HubId.generate();           // UUID v4
final userId = UserId.fromAuthUid(uid);   // From Firebase Auth
final gameId = GameId.fromString('abc');  // From string

// Type safety
void joinGame(GameId gameId, UserId userId) {
  // Compiler enforces correct parameter order
}
```

#### Geographic Point

```dart
// lib/shared/domain/models/value_objects/geographic_point.dart

final point = GeographicPoint.fromCoordinates(
  latitude: 32.0853,
  longitude: 34.7818,
);

// Business logic built-in
final distance = point.distanceToKm(otherPoint);
final isNearby = point.isWithinRadius(center, radiusKm: 5);
final bearing = point.bearingTo(destination);
```

#### Time Range

```dart
// lib/shared/domain/models/value_objects/time_range.dart

final range = TimeRange.fromStartDuration(
  start: DateTime.now(),
  duration: const Duration(hours: 2),
);

// Rich API
if (range.isActive) print('Event is happening now');
if (range.overlaps(otherRange)) print('Conflict detected');
final durationMinutes = range.durationMinutes;
```

---

## Dependency Injection

### Riverpod Provider Architecture

All dependencies managed through providers in `lib/core/providers/`.

#### Provider Types

1. **Repository Providers** (`repositories_providers.dart`)
```dart
@riverpod
HubsRepository hubsRepository(HubsRepositoryRef ref) {
  return HubsRepository(
    firestore: ref.watch(firestoreProvider),
  );
}
```

2. **Service Providers** (`services_providers.dart`)
```dart
@riverpod
GameFinalizationService gameFinalizationService(GameFinalizationServiceRef ref) {
  return GameFinalizationService(
    gamesRepository: ref.watch(gamesRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
}
```

3. **Complex Providers** (`complex_providers.dart`)
```dart
@riverpod
Stream<Hub?> hubStream(HubStreamRef ref, HubId hubId) {
  ref.keepAlive(); // Cache across navigation
  final hubsRepo = ref.watch(hubsRepositoryProvider);
  return hubsRepo.watchHub(hubId.value);
}
```

### Using Providers

#### In Widgets

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read once (for callbacks)
    final repo = ref.read(hubsRepositoryProvider);

    // Watch for rebuilds
    final hubAsync = ref.watch(hubStreamProvider(hubId));

    return hubAsync.when(
      data: (hub) => Text(hub.name),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

#### In Services

```dart
class GameManagementService {
  final GamesRepository _gamesRepo;
  final HubsRepository _hubsRepo;

  GameManagementService({
    required GamesRepository gamesRepository,
    required HubsRepository hubsRepository,
  })  : _gamesRepo = gamesRepository,
        _hubsRepo = hubsRepository;

  // Business logic using injected dependencies
  Future<void> cancelGame(GameId gameId) async {
    final game = await _gamesRepo.getGame(gameId.value);
    // ...
  }
}
```

### Provider Rules

**DO:**
- ✅ Always inject dependencies via constructor
- ✅ Make all dependencies `required`
- ✅ Use `ref.read()` for one-time access
- ✅ Use `ref.watch()` to rebuild on changes

**DON'T:**
- ❌ Use `new` keyword for repositories/services
- ❌ Use `??` fallbacks in constructors
- ❌ Create instances directly in methods

---

## Layer Boundaries

### Allowed Dependencies

```
✅ presentation → domain
✅ presentation → infrastructure (via DI only)
✅ infrastructure → domain
❌ domain → infrastructure (FORBIDDEN)
❌ domain → presentation (FORBIDDEN)
```

### Import Rules

**Domain layer (`lib/features/*/domain/`) CAN import:**
- ✅ Other domain models
- ✅ Shared domain types (`lib/shared/domain/`)
- ✅ Dart SDK only

**Domain layer CANNOT import:**
- ❌ `package:cloud_firestore`
- ❌ `package:firebase_*`
- ❌ `package:flutter` (except `package:flutter/foundation.dart` for `@immutable`)

**Infrastructure layer CAN import:**
- ✅ Domain models
- ✅ Firebase packages
- ✅ External SDKs

### Enforcement

Linter rules in `analysis_options.yaml` enforce:
- `unnecessary_new` - Prevents `new` keyword
- `prefer_const_constructors` - Enforces immutability
- `depend_on_referenced_packages` - Enforces dependency rules

---

## Migration Guide

### Migrating to Typed IDs

**Step 1:** Update model
```dart
// Before
class Game {
  final String gameId;
  final String hubId;
}

// After
class Game {
  final GameId gameId;
  final HubId hubId;
}
```

**Step 2:** Update repository
```dart
// Before
Future<Game?> getGame(String gameId) async {
  final doc = await _firestore.doc('games/$gameId').get();
  return Game.fromJson(doc.data()!);
}

// After
Future<Game?> getGame(GameId gameId) async {
  final doc = await _firestore.doc('games/${gameId.value}').get();
  return Game.fromJson(doc.data()!);
}
```

**Step 3:** Update call sites
```dart
// Before
final game = await repo.getGame('abc123');

// After
final game = await repo.getGame(GameId.fromString('abc123'));
```

### Migrating from GeoPoint to GeographicPoint

**Step 1:** Add converter import
```dart
import 'package:kattrick/shared/infrastructure/firestore/converters/geographic_point_firestore_converter.dart';
```

**Step 2:** Update model annotation
```dart
// Before
@GeoPointConverter() GeoPoint? location;

// After
@NullableGeographicPointFirestoreConverter() GeographicPoint? location;
```

**Step 3:** Update business logic
```dart
// Before
final lat = hub.location?.latitude;

// After (same API!)
final lat = hub.location?.latitude;

// But now you can also:
final distance = hub.location?.distanceToKm(userLocation);
```

### Converting Service Locator to DI

**Step 1:** Convert widget to Consumer
```dart
// Before
class MyScreen extends StatefulWidget

// After
class MyScreen extends ConsumerStatefulWidget

class _MyScreenState extends ConsumerState<MyScreen>
```

**Step 2:** Replace instantiation with provider
```dart
// Before
final repo = HubsRepository();

// After
final repo = ref.read(hubsRepositoryProvider);
```

**Step 3:** Add required imports
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
```

---

## Best Practices

### DO

✅ Use value objects for all domain concepts
✅ Inject all dependencies via constructor
✅ Keep domain layer pure Dart
✅ Use providers for all service/repository access
✅ Write business logic in domain models
✅ Use immutable data structures (Freezed)

### DON'T

❌ Import Firebase in domain layer
❌ Use `new` keyword (use const or providers)
❌ Create repositories/services directly
❌ Mix business logic with UI logic
❌ Use primitive types for domain concepts
❌ Add optional parameters with `??` fallbacks

---

## Architecture Decision Records

### ADR-001: Repository + Service Pattern over Full DDD

**Status:** Accepted

**Context:** Domain-Driven Design recommends rich aggregates with command methods for state transitions.

**Decision:** Use Repository + Service pattern where:
- Models contain: predicates, calculations, queries
- Services contain: state transitions, orchestration
- Repositories contain: persistence, queries

**Rationale:**
- Simpler for CRUD-heavy applications
- Easier onboarding for team
- Sufficient for current complexity
- Can evolve to full DDD if needed

**Consequences:**
- Some business logic in services instead of aggregates
- Acceptable trade-off for maintainability

---

### ADR-002: Typed IDs over Primitive Strings

**Status:** Accepted

**Context:** String IDs cause parameter-swapping bugs and lack domain meaning.

**Decision:** All entity IDs use typed value objects (`GameId`, `HubId`, etc.)

**Rationale:**
- Compiler prevents type errors
- Self-documenting code
- Enables ID-specific validation
- Zero runtime cost

**Consequences:**
- Migration effort: ~2-3 weeks
- Breaking change requiring widespread updates
- Long-term benefit: eliminates entire bug class

---

### ADR-003: GeographicPoint over GeoPoint

**Status:** Accepted

**Context:** Firestore's `GeoPoint` couples domain to infrastructure.

**Decision:** Domain uses `GeographicPoint`, infrastructure converts.

**Rationale:**
- Domain independence from Firebase
- Enables rich geographic business logic
- Testable without Firebase SDK
- Future-proof for database migration

**Consequences:**
- Converters in infrastructure layer
- Slight serialization overhead (negligible)
- Full control over geographic operations

---

## Appendix: Code Examples

### Complete Feature Module Example

```dart
// Domain Model
@freezed
class Hub with _$Hub {
  const factory Hub({
    required HubId hubId,
    required String name,
    required GeographicPoint? location,
  }) = _Hub;

  const Hub._();

  bool isNearLocation(GeographicPoint point, double radiusKm) {
    return location?.isWithinRadius(point, radiusKm) ?? false;
  }
}

// Repository (Infrastructure)
class HubsRepository {
  final FirebaseFirestore _firestore;

  HubsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<Hub?> getHub(HubId hubId) async {
    final doc = await _firestore.doc('hubs/${hubId.value}').get();
    if (!doc.exists) return null;
    return Hub.fromJson(doc.data()!);
  }
}

// Provider
@riverpod
HubsRepository hubsRepository(HubsRepositoryRef ref) {
  return HubsRepository(firestore: ref.watch(firestoreProvider));
}

// UI (Presentation)
class HubScreen extends ConsumerWidget {
  final HubId hubId;

  const HubScreen({required this.hubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubAsync = ref.watch(hubStreamProvider(hubId));

    return hubAsync.when(
      data: (hub) => Text(hub.name),
      loading: () => CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }
}
```

---

## Summary

This architecture eliminates anti-patterns and establishes:

1. **Dependency Injection:** All dependencies via Riverpod providers
2. **Typed Domain:** Value objects prevent primitive obsession
3. **Layer Separation:** Domain independent of infrastructure
4. **Testability:** Pure domain logic, mockable dependencies
5. **Maintainability:** Clear boundaries, enforced by linter

**Result:** Scalable, testable, maintainable codebase ready for team growth.
