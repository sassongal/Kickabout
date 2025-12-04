# 01_CURSOR_COMPLETE_GUIDE.md
# Cursor AI Complete Integration Guide for Kattrick

**Version:** 2.0  
**Last Updated:** 2025-11-30  
**Project:** Kattrick - Neighborhood Football Social Network  
**Purpose:** Complete guide for integrating Cursor AI IDE with Kattrick project

---

## 📋 Table of Contents

1. [Initial Setup](#initial-setup)
2. [Project Configuration](#project-configuration)
3. [Code Generation Rules](#code-generation-rules)
4. [Business Rules Reference](#business-rules-reference)
5. [Common Commands](#common-commands)
6. [Code Templates](#code-templates)
7. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
8. [Cursor Settings & Configuration](#cursor-settings--configuration)
9. [Working with Cursor Agent](#working-with-cursor-agent)
10. [Step-by-Step Example](#step-by-step-example)

---

## 🚀 Initial Setup

### Prerequisites
- **Cursor IDE** installed (v0.40+)
- **Flutter SDK** 3.16.0+
- **Firebase CLI** 13.0.0+
- **Node.js** 18+ (for Cloud Functions)
- **Git** configured

### First-Time Configuration

1. **Clone the Kattrick repository**
```bash
git clone https://github.com/YourOrg/kattrick.git
cd kattrick
```

2. **Open in Cursor IDE**
```bash
cursor .
```

3. **Install Flutter dependencies**
```bash
flutter pub get
```

4. **Run code generation**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## ⚙️ Project Configuration

### 1. Create `.cursorrules` File

Create a file named `.cursorrules` in the root of your project:

```yaml
# Kattrick Project Rules for Cursor AI
# Version: 2.0

## Tech Stack
- Flutter: 3.16.0+
- Dart: 3.2.0+
- Riverpod: 2.x (flutter_riverpod)
- Freezed: 2.x (for immutable models)
- Firebase: Latest
  - firebase_core
  - cloud_firestore
  - firebase_auth
  - firebase_storage
  - firebase_messaging
  - cloud_functions
- Google Maps Platform
- GoRouter: 13.x

## Architecture
- Clean Architecture + Micro-Sharding
- Feature-First folder structure
- Repository pattern for data access
- Riverpod 2.x for state management
- Firebase-first backend

## Critical Business Rules

### Hub Roles (3 Tiers)
1. **Owner** (hub.ownerId) - Full control, single owner
2. **Manager** (hub.managers array) - Can edit, add members, record games
3. **Veteran** (hub.members with role:'veteran') - Can record games only
4. **Player** (hub.members with role:'player') - Regular member

### Numeric Limits
- MAX_HUBS_AS_MEMBER: 10
- MAX_HUBS_AS_OWNER: 3
- MAX_GAME_CAPACITY: 50
- MAX_HUB_MEMBERS: 500
- MAX_EVENT_CAPACITY: 100

### Game Status Flow
1. **pending** → Player can sign up
2. **active** → Game started (status: 'active')
3. **completed** → Game ended, stats recorded
4. **cancelled** → Game cancelled

### Auto-Close Logic
- **Pending games**: Auto-close 3h after scheduledAt if not started
- **Active games**: Auto-close 5h after startedAt if not ended
- Cloud Function: `scheduledGameAutoClose` (runs every 10 minutes)

### Age Groups (Age = Current Year - Birth Year)
- **Kids**: 13-17
- **Young**: 18-25
- **Adults**: 26-35
- **Veterans**: 36-45
- **Legends**: 46-50+

**Note:** Minimum age is 13 years old (enforced in signup)

---

## 📝 Code Generation Rules

### 1. Freezed Models

**Always use Freezed for data models:**

```dart
// ✅ CORRECT
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    String? photoURL,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<String> hubIds,
    @Default(0) int gamesPlayed,
    @Default(0.0) double rating,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  // Firestore conversion
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data).copyWith(id: doc.id);
  }
}
```

**❌ WRONG - Don't use plain classes:**
```dart
// Don't do this!
class UserModel {
  final String id;
  final String email;
  // ...
}
```

---

### 2. Riverpod 2.x State Management

**Always use Riverpod 2.x code generation:**

```dart
// ✅ CORRECT - Riverpod 2.x
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<UserModel?> build() async {
    // Initial state
    final userId = ref.watch(authRepositoryProvider).currentUserId;
    if (userId == null) return null;
    
    return ref.watch(userRepositoryProvider).getUserById(userId);
  }
  
  Future<void> updateProfile(String displayName, String? photoURL) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authRepositoryProvider).currentUserId!;
      await ref.read(userRepositoryProvider).updateUser(
        userId,
        displayName: displayName,
        photoURL: photoURL,
      );
      return ref.read(userRepositoryProvider).getUserById(userId);
    });
  }
}

// For simple providers
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(ref.watch(firestoreProvider));
}
```

**❌ WRONG - Don't use old Riverpod syntax:**
```dart
// Don't do this!
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref);
});
```

---

### 3. Firebase Firestore Operations

**Always use proper error handling and offline support:**

```dart
// ✅ CORRECT
class UserRepository {
  final FirebaseFirestore _firestore;
  
  UserRepository(this._firestore);
  
  // Read operation with offline support
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.cache)); // Try cache first
      
      if (!doc.exists) {
        // Fallback to server
        final serverDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        return serverDoc.exists ? UserModel.fromFirestore(serverDoc) : null;
      }
      
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }
  
  // Write operation with validation
  Future<void> updateUser(
    String userId, {
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
```

---

### 4. Clean Architecture Folder Structure

**Follow this structure strictly:**

```
lib/
├── core/
│   ├── constants/
│   │   ├── business_constants.dart  # MAX_HUBS_AS_MEMBER, etc.
│   │   └── firebase_constants.dart  # Collection names
│   ├── errors/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── entities/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── hubs/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── games/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── models/
│   ├── providers/
│   └── widgets/
└── main.dart
```

---

### 5. Naming Conventions

**Follow these strictly:**

- **Files:** `snake_case` (e.g., `user_profile_screen.dart`)
- **Classes:** `PascalCase` (e.g., `UserProfileScreen`)
- **Variables/Functions:** `camelCase` (e.g., `getUserById`)
- **Constants:** `SCREAMING_SNAKE_CASE` (e.g., `MAX_HUBS_AS_MEMBER`)
- **Private members:** Prefix with `_` (e.g., `_firestore`)
- **Providers (Riverpod 2.x):** End with `Provider` (e.g., `userNotifierProvider`)

---

### 6. Error Handling

**Always wrap async operations:**

```dart
// ✅ CORRECT
Future<void> someAsyncOperation() async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(() async {
    // Your async operation
    return await repository.doSomething();
  });
}

// In UI
Widget build(BuildContext context, WidgetRef ref) {
  final asyncValue = ref.watch(someProvider);
  
  return asyncValue.when(
    data: (data) => Text('Success: $data'),
    loading: () => const CircularProgressIndicator(),
    error: (error, stack) => Text('Error: $error'),
  );
}
```

---

### 7. Performance Rules

**Critical optimizations:**

1. **Use `select` for specific fields:**
```dart
// ✅ CORRECT - Only rebuilds when displayName changes
final displayName = ref.watch(
  userProvider.select((user) => user.value?.displayName)
);
```

2. **Cache expensive computations:**
```dart
@riverpod
Future<List<GameModel>> userGames(UserGamesRef ref, String userId) async {
  // Cached automatically by Riverpod 2.x
  return ref.watch(gameRepositoryProvider).getUserGames(userId);
}
```

3. **Limit Firestore reads:**
```dart
// ✅ CORRECT - Use limit()
final games = await _firestore
    .collection('games')
    .where('hubId', isEqualTo: hubId)
    .orderBy('scheduledAt', descending: true)
    .limit(20)  // Don't fetch all!
    .get();
```

---

### 8. Security Rules

**Never bypass security in code:**

```dart
// ❌ WRONG - Don't use admin SDK or bypass security
// This should only be done in Cloud Functions

// ✅ CORRECT - Respect Firestore Security Rules
// The rules will enforce permissions automatically
await _firestore.collection('hubs').doc(hubId).update(data);
// If user doesn't have permission, this will throw an error
```

---

## 📋 Business Rules Reference

### Hub Management

**3 Hub Tiers (from Gap Analysis #1):**

1. **Owner** (`hub.ownerId`)
   - Full control (edit, delete, transfer ownership)
   - Can add/remove managers
   - Single owner per hub

2. **Manager** (`hub.managers[]`)
   - Can edit hub details
   - Can add/remove members
   - Can record game results
   - Multiple managers allowed

3. **Veteran** (`hub.members[]` with `role: 'veteran'`)
   - Can record game results
   - Cannot edit hub or manage members
   - Promoted by owner/manager

4. **Player** (`hub.members[]` with `role: 'player'`)
   - Regular member
   - Can join games, post, comment

**Hub Limits:**
```dart
// From business_constants.dart
const MAX_HUBS_AS_MEMBER = 10;
const MAX_HUBS_AS_OWNER = 3;
const MAX_HUB_MEMBERS = 500;
```

---

### Game Management

**Game Status Flow:**

```dart
enum GameStatus {
  pending,    // Initial state, players can sign up
  active,     // Game started (Start Event clicked)
  completed,  // Game ended, stats recorded
  cancelled,  // Game cancelled
}
```

**Auto-Close Logic (from Gap Analysis #8):**

```dart
// Cloud Function: scheduledGameAutoClose (runs every 10 minutes)

// Rule 1: Pending games
// If scheduledAt + 3h < now && status == 'pending'
// → Cancel game

// Rule 2: Active games
// If startedAt + 5h < now && status == 'active'
// → End game automatically
```

**Start Event Logic (from Gap Analysis #7):**

- Game can be started **30 minutes before** `scheduledAt`
- Status changes: `pending` → `active`
- `startedAt` timestamp recorded
- Attendance locked (no more signups)

---

### Age Groups

**Calculation:** `Age = Current Year - Birth Year`

```dart
enum AgeGroup {
  kids,      // 13-17
  young,     // 18-25
  adults,    // 26-35
  veterans,  // 36-45
  legends,   // 46-50+
}

// Minimum age: 13 years old (enforced in signup)
```

**Implementation:**
- Store `dateOfBirth` in `users` collection (new field, see Gap Analysis #2)
- Calculate age on-the-fly in UI
- Filter games by age group in Firestore query

---

### Attendance Confirmation

**From Gap Analysis #5:**

- Cloud Function sends FCM notification **2 hours before** `scheduledAt`
- Title: "Game Reminder"
- Body: "Your game at [venue] starts in 2 hours!"
- User can confirm/cancel attendance in app

**Implementation:**
```typescript
// Cloud Function: scheduledGameReminders (runs every 30 minutes)
// Send notification to all signups where:
// scheduledAt - 2h <= now <= scheduledAt - 1.5h
```

---

## 🔧 Common Commands

### Flutter Development

```bash
# Get dependencies
flutter pub get

# Run code generation (Freezed, Riverpod 2.x)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs

# Run app (debug mode)
flutter run

# Run app (release mode)
flutter run --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean && flutter pub get
```

---

### Firebase Commands

```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore Rules
firebase deploy --only firestore:rules

# Deploy Firestore Indexes
firebase deploy --only firestore:indexes

# Deploy Storage Rules
firebase deploy --only storage

# Deploy everything
firebase deploy

# View logs
firebase functions:log

# Emulators (local testing)
firebase emulators:start
```

---

## 📦 Code Templates

### 1. Freezed Model Template

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'MODEL_NAME.freezed.dart';
part 'MODEL_NAME.g.dart';

@freezed
class MODEL_NAME with _$MODEL_NAME {
  const factory MODEL_NAME({
    required String id,
    // Add your fields here
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MODEL_NAME;

  factory MODEL_NAME.fromJson(Map<String, dynamic> json) => _$MODEL_NAMEFromJson(json);
  
  factory MODEL_NAME.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MODEL_NAME.fromJson(data).copyWith(id: doc.id);
  }
}
```

**After creating:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2. Riverpod Provider Template

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'PROVIDER_NAME.g.dart';

@riverpod
class NOTIFIER_NAME extends _$NOTIFIER_NAME {
  @override
  Future<DATA_TYPE> build() async {
    // Initial state
    return initialData;
  }
  
  Future<void> someMethod() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Your logic here
      return newData;
    });
  }
}
```

**After creating:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 3. Firestore Repository Template

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'REPOSITORY_NAME.g.dart';

class REPOSITORY_NAME {
  final FirebaseFirestore _firestore;
  
  REPOSITORY_NAME(this._firestore);
  
  // Create
  Future<String> createItem(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('COLLECTION_NAME').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
  
  // Read
  Future<MODEL_TYPE?> getItemById(String id) async {
    final doc = await _firestore
        .collection('COLLECTION_NAME')
        .doc(id)
        .get();
    return doc.exists ? MODEL_TYPE.fromFirestore(doc) : null;
  }
  
  // Update
  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('COLLECTION_NAME').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Delete
  Future<void> deleteItem(String id) async {
    await _firestore.collection('COLLECTION_NAME').doc(id).delete();
  }
  
  // Stream (real-time)
  Stream<MODEL_TYPE> streamItem(String id) {
    return _firestore
        .collection('COLLECTION_NAME')
        .doc(id)
        .snapshots()
        .map((doc) => MODEL_TYPE.fromFirestore(doc));
  }
}

@riverpod
REPOSITORY_NAME repositoryName(RepositoryNameRef ref) {
  return REPOSITORY_NAME(ref.watch(firestoreProvider));
}
```

---

### 4. Cloud Functions Template

```typescript
import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

// Scheduled function
export const scheduledFunctionName = functions.scheduler.onSchedule({
  schedule: "every 10 minutes",
  timeZone: "Asia/Jerusalem",
  region: "europe-west1",
}, async (event) => {
  const firestore = admin.firestore();
  
  // Your logic here
  
  console.log("Scheduled function completed");
});

// Firestore trigger
export const onDocumentCreated = functions.firestore.onDocumentCreated({
  document: "collection/{docId}",
  region: "europe-west1",
}, async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;
  
  const data = snapshot.data();
  
  // Your logic here
});

// Callable function (with authentication)
export const callableFunctionName = functions.https.onCall({
  region: "europe-west1",
  invoker: "authenticated", // IMPORTANT: Not public!
}, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }
  
  // Your logic here
  
  return { success: true, data: result };
});
```

---

## ⚠️ Anti-Patterns to Avoid

### 1. Don't Mix State Management

```dart
// ❌ WRONG - Mixing setState with Riverpod
class MyWidget extends ConsumerStatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  String localState = ''; // Don't do this!
  
  @override
  Widget build(BuildContext context) {
    final riverpodState = ref.watch(someProvider);
    // Mixing local and global state - confusing!
  }
}

// ✅ CORRECT - Use Riverpod only
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(someProvider);
    // All state in Riverpod - clean!
  }
}
```

---

### 2. Don't Fetch All Data

```dart
// ❌ WRONG - Fetching all games
final allGames = await _firestore.collection('games').get();
// This will be VERY expensive!

// ✅ CORRECT - Use limit and pagination
final recentGames = await _firestore
    .collection('games')
    .orderBy('scheduledAt', descending: true)
    .limit(20)
    .get();
```

---

### 3. Don't Ignore Offline Mode

```dart
// ❌ WRONG - No offline handling
final doc = await _firestore.collection('users').doc(userId).get();
// What if user is offline?

// ✅ CORRECT - Try cache first
try {
  final doc = await _firestore
      .collection('users')
      .doc(userId)
      .get(const GetOptions(source: Source.cache));
  
  if (!doc.exists) {
    // Fallback to server
    return await _firestore.collection('users').doc(userId).get();
  }
  return doc;
} catch (e) {
  // Handle error
}
```

---

### 4. Don't Bypass Security Rules

```dart
// ❌ WRONG - Trying to bypass security in client
// This won't work anyway, Firestore Rules will block it!

// ✅ CORRECT - Design your security rules properly
// Then let the client code fail gracefully if permission denied
try {
  await _firestore.collection('hubs').doc(hubId).update(data);
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    throw Exception('You don\'t have permission to edit this hub');
  }
  rethrow;
}
```

---

### 5. Don't Create God Objects

```dart
// ❌ WRONG - One provider doing everything
@riverpod
class AppState extends _$AppState {
  // User, hubs, games, posts, everything in one class!
  // This is unmaintainable!
}

// ✅ CORRECT - Separate providers by feature
@riverpod
class UserNotifier extends _$UserNotifier { /* User logic */ }

@riverpod
class HubsNotifier extends _$HubsNotifier { /* Hubs logic */ }

@riverpod
class GamesNotifier extends _$GamesNotifier { /* Games logic */ }
```

---

## 🎯 Cursor Settings & Configuration

### 1. `.cursorrules` File

Already shown above. Place in project root.

---

### 2. `.cursorignore` File

Create `.cursorignore` in project root:

```
# Generated files
*.g.dart
*.freezed.dart
*.config.dart

# Firebase
firebase-debug.log
firestore-debug.log
functions/node_modules/
functions/lib/

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
ios/Pods/
ios/.symlinks/
android/.gradle/

# Tests
coverage/
test/.test_coverage.dart

# IDE
.idea/
.vscode/
*.iml

# Large files
*.png
*.jpg
*.jpeg
*.gif
*.mp4
*.mov
```

**Why?**
- These files are auto-generated or too large
- Cursor doesn't need to index them
- Saves indexing time and improves performance

---

### 3. Manual Document Indexing

**Priority documents for Cursor context:**

1. **11_CURRENT_STATE.md** - What's completed, what's missing
2. **12_KNOWN_ISSUES.md** - Critical bugs to avoid
3. **08_GAP_ANALYSIS.md** - All business rules
4. **10_IMPLEMENTATION_SUPPLEMENT.md** - Code examples
5. **01_CURSOR_COMPLETE_GUIDE.md** - This file!

**How to add in Cursor:**

1. Open Cursor Settings (Cmd+, / Ctrl+,)
2. Navigate to "Indexing & Docs"
3. Click "Add Documentation"
4. Select the 5 files above
5. Cursor will index them for AI context

---

### 4. Cursor Settings from Your Screenshots

**From your images:**

#### Image 1: Rules and Commands
- **Include CLAUDE.md in context:** OFF
- **Include Commands:** ON
- **User Rules:** Managed via `.cursorrules` file

#### Image 2: Indexing & Docs
- **Codebase Indexing:** ON
- **Auto-index new folders:** ON (recommended)
- **Manual docs:** Add the 5 priority docs above

---

## 🤖 Working with Cursor Agent

### Best Practices

1. **Be Specific:**
   ```
   ❌ "Add a feature for games"
   ✅ "Add Date of Birth field to users collection, with:
      - Firestore field: dateOfBirth (Timestamp)
      - Validation: min age 13 years
      - UI: DatePicker in ProfileScreen
      - Update signup flow to require DoB"
   ```

2. **Reference Documentation:**
   ```
   "Implement attendance confirmation as described in 08_GAP_ANALYSIS.md #5"
   ```

3. **Ask for Explanation:**
   ```
   "Explain how the auto-close logic works in scheduledGameAutoClose function"
   ```

4. **Request Code Review:**
   ```
   "Review my Hub Tiers implementation against business rules in .cursorrules"
   ```

---

### Common Pitfalls

1. **Don't ask to rewrite everything:**
   - Cursor is best for incremental changes
   - Refactor one feature at a time

2. **Don't ignore generated code:**
   - Always run `build_runner` after Cursor generates Freezed/Riverpod code
   - Check for compilation errors

3. **Don't skip testing:**
   - Ask Cursor to generate tests too
   - "Write unit tests for this repository"

---

## 📖 Step-by-Step Example: Implementing Date of Birth

### Context
From **12_KNOWN_ISSUES.md #7** and **08_GAP_ANALYSIS.md #2**:
- Add `dateOfBirth` field to users
- Enforce minimum age of 13 years
- Calculate Age Groups dynamically

---

### Step 1: Ask Cursor to Update User Model

**Prompt:**
```
Update UserModel in lib/features/auth/data/models/user_model.dart to add:
- dateOfBirth field (DateTime, required)
- Freezed model with fromJson/fromFirestore
- Follow the pattern in 01_CURSOR_COMPLETE_GUIDE.md
```

**Expected Code (Cursor will generate):**
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    String? photoURL,
    required DateTime dateOfBirth, // NEW
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<String> hubIds,
    @Default(0) int gamesPlayed,
    @Default(0.0) double rating,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data).copyWith(id: doc.id);
  }
}
```

**After Cursor generates:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Step 2: Add Age Calculation Utility

**Prompt:**
```
Create a utility function in lib/core/utils/age_utils.dart to:
- Calculate age from dateOfBirth
- Return AgeGroup enum (kids/young/adults/veterans/legends)
- Follow business rules in .cursorrules (Age = Current Year - Birth Year)
```

**Expected Code:**
```dart
enum AgeGroup {
  kids,      // 13-17
  young,     // 18-25
  adults,    // 26-35
  veterans,  // 36-45
  legends,   // 46-50+
}

int calculateAge(DateTime dateOfBirth) {
  final now = DateTime.now();
  return now.year - dateOfBirth.year;
}

AgeGroup getAgeGroup(DateTime dateOfBirth) {
  final age = calculateAge(dateOfBirth);
  
  if (age < 13) throw Exception('User must be at least 13 years old');
  if (age <= 17) return AgeGroup.kids;
  if (age <= 25) return AgeGroup.young;
  if (age <= 35) return AgeGroup.adults;
  if (age <= 45) return AgeGroup.veterans;
  return AgeGroup.legends;
}
```

---

### Step 3: Update Signup Flow

**Prompt:**
```
Update SignupScreen in lib/features/auth/presentation/screens/signup_screen.dart to:
- Add DatePicker for dateOfBirth
- Validate minimum age 13 years
- Show error if user is too young
- Follow Material 3 design
```

**Expected UI (Cursor will generate):**
```dart
// Inside SignupScreen
DateTime? _selectedDate;

Widget _buildDateOfBirthField() {
  return InkWell(
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
        firstDate: DateTime(1950),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      );
      if (date != null) {
        setState(() => _selectedDate = date);
      }
    },
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Date of Birth',
        hintText: 'Select your date of birth',
      ),
      child: Text(
        _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : 'Not selected',
      ),
    ),
  );
}

// In signup button handler
if (_selectedDate == null) {
  showError('Please select your date of birth');
  return;
}

try {
  final age = calculateAge(_selectedDate!);
  if (age < 13) {
    showError('You must be at least 13 years old to sign up');
    return;
  }
  
  // Proceed with signup
  await ref.read(authRepositoryProvider).signup(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
    dateOfBirth: _selectedDate!,
  );
} catch (e) {
  showError(e.toString());
}
```

---

### Step 4: Update Firestore Repository

**Prompt:**
```
Update AuthRepository to include dateOfBirth in user creation:
- Add dateOfBirth parameter to signup()
- Store in Firestore users collection
- Convert to Timestamp for Firestore
```

**Expected Code:**
```dart
class AuthRepository {
  Future<void> signup({
    required String email,
    required String password,
    required String displayName,
    required DateTime dateOfBirth,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final userId = userCredential.user!.uid;
    
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'displayName': displayName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth), // Store as Timestamp
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'hubIds': [],
      'gamesPlayed': 0,
      'rating': 0.0,
    });
  }
}
```

---

### Step 5: Test the Implementation

**Prompt:**
```
Generate unit tests for age calculation utility in test/core/utils/age_utils_test.dart:
- Test calculateAge() with different dates
- Test getAgeGroup() for all age groups
- Test minimum age validation (should throw for < 13)
```

**Expected Tests:**
```dart
void main() {
  group('Age Utils', () {
    test('calculateAge returns correct age', () {
      final birthDate = DateTime(2000, 1, 1);
      final age = calculateAge(birthDate);
      expect(age, equals(DateTime.now().year - 2000));
    });
    
    test('getAgeGroup returns kids for 13-17', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 365 * 15));
      expect(getAgeGroup(birthDate), equals(AgeGroup.kids));
    });
    
    test('getAgeGroup throws for age < 13', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 365 * 12));
      expect(() => getAgeGroup(birthDate), throwsException);
    });
  });
}
```

**Run tests:**
```bash
flutter test
```

---

### Step 6: Update Firestore Security Rules

**Prompt:**
```
Update firestore.rules to validate dateOfBirth:
- Required field in user creation
- Must be a Timestamp
- Age must be >= 13 years
```

**Expected Rules:**
```javascript
match /users/{userId} {
  allow create: if request.auth != null 
    && request.auth.uid == userId
    && request.resource.data.dateOfBirth is timestamp
    && isValidAge(request.resource.data.dateOfBirth);
  
  function isValidAge(dob) {
    let age = request.time.year() - dob.year;
    return age >= 13;
  }
}
```

**Deploy:**
```bash
firebase deploy --only firestore:rules
```

---

### ✅ Feature Complete!

You've now successfully implemented Date of Birth with:
1. ✅ Updated data model (Freezed)
2. ✅ Age calculation utility
3. ✅ Updated signup UI
4. ✅ Firestore integration
5. ✅ Unit tests
6. ✅ Security rules

**This is how you work with Cursor on Kattrick!**

---

## 🎯 Summary

### Key Takeaways

1. **Use `.cursorrules`** - Defines all business rules and tech stack
2. **Follow Clean Architecture** - Feature-first folder structure
3. **Riverpod 2.x + Freezed** - State management + immutable models
4. **Firebase-First** - Firestore as source of truth
5. **Always test** - Write tests, use emulators
6. **Reference docs** - Point Cursor to 08_GAP_ANALYSIS.md, etc.

---

### Next Steps

1. **Set up your project** with `.cursorrules` and `.cursorignore`
2. **Index documentation** in Cursor settings
3. **Start with Critical Issues** from 12_KNOWN_ISSUES.md
4. **Follow the Roadmap** in 09_PROFESSIONAL_ROADMAP.md
5. **Ask Cursor** to implement features one by one

---

### Need Help?

- **Documentation:** Check other files in Kattrick Documentation Suite
- **Business Rules:** See 08_GAP_ANALYSIS.md
- **Current Status:** See 11_CURRENT_STATE.md
- **Known Issues:** See 12_KNOWN_ISSUES.md
- **Roadmap:** See 09_PROFESSIONAL_ROADMAP.md

---

**You're ready to build Kattrick with Cursor AI! 🚀⚽**

**Good luck, Gal!**
