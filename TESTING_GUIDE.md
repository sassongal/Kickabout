# 🧪 Testing Guide - Kattrick

## תוכן עניינים

1. [סקירה כללית](#סקירה-כללית)
2. [Firebase Emulators](#firebase-emulators)
3. [Backend Tests](#backend-tests)
4. [Flutter Widget Tests](#flutter-widget-tests)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [כלים וספריות](#כלים-וספריות)

---

## סקירה כללית

מערכת ה-Testing של Kattrick מורכבת מ-3 שכבות:

### 1. Backend Tests (Firebase Functions)
- **מיקום**: `functions/test/`
- **פריימוורק**: Mocha + Chai + Sinon
- **כיסוי**: 60%+ code coverage
- **סוגים**:
  - Unit Tests
  - Integration Tests (with Emulators)

### 2. Flutter Widget Tests
- **מיקום**: `test/widgets/`
- **פריימוורק**: Flutter Test + Mocktail
- **כיסוי**: 50%+ widget coverage
- **סוגים**:
  - Widget Tests
  - Integration Tests

### 3. CI/CD Pipeline
- **פלטפורמה**: GitHub Actions
- **Workflows**:
  - Test & Build (on PR)
  - Deploy (on merge to main)

---

## Firebase Emulators

### Setup

הגדרות ב-`firebase.json`:

```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

### הרצה

```bash
# הפעל את כל ה-Emulators
firebase emulators:start

# הפעל רק Firestore + Auth
firebase emulators:start --only firestore,auth

# הפעל עם Import של data
firebase emulators:start --import=./emulator-data
```

### גישה ל-UI

פתח בדפדפן: http://localhost:4000

---

## Backend Tests

### Structure

```
functions/
├── test/
│   ├── setup.js              # Test initialization
│   ├── rateLimit.test.js     # Unit tests for rate limiting
│   └── integration/
│       └── rateLimit.integration.test.js
├── .babelrc                  # Babel config for ES6
├── .nycrc                    # Coverage config
└── package.json              # Test scripts
```

### הרצת Testsגרסת Node בשרת היא 20 אבל מקומי 18

```bash
cd functions

# הרץ כל הטסטים
npm test

# הרץ עם watch mode
npm run test:watch

# הרץ עם coverage
npm run test:coverage
```

### כתיבת Test חדש

```javascript
/* eslint-disable max-len */
/**
 * Unit Tests for MyModule
 */

const { expect } = require('chai');
const sinon = require('sinon');
const { myFunction } = require('../myModule');

describe('MyModule', () => {
  let stub;
  
  beforeEach(() => {
    // Setup
    stub = sinon.stub();
  });
  
  afterEach(() => {
    // Cleanup
    sinon.restore();
  });
  
  it('should do something', async () => {
    // Arrange
    stub.returns('value');
    
    // Act
    const result = await myFunction();
    
    // Assert
    expect(result).to.equal('expected');
  });
});
```

### Integration Tests עם Emulators

```javascript
// Set Firestore to use emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

describe('Integration Tests', () => {
  before(async () => {
    // Initialize Firebase Admin
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'demo-test-project',
      });
    }
  });
  
  after(async () => {
    await admin.app().delete();
  });
  
  it('should interact with Firestore', async () => {
    const db = admin.firestore();
    await db.collection('test').doc('doc1').set({ value: 'test' });
    const doc = await db.collection('test').doc('doc1').get();
    expect(doc.data().value).to.equal('test');
  });
});
```

---

## Flutter Widget Tests

### Structure

```
test/
├── widgets/
│   ├── smart_venue_search_field_test.dart
│   ├── hub_venues_manager_test.dart
│   └── futuristic_card_test.dart
├── models/
├── services/
└── helpers/
    └── mock_firestore.dart
```

### הרצת Tests

```bash
# הרץ כל הטסטים
flutter test

# הרץ test ספציפי
flutter test test/widgets/smart_venue_search_field_test.dart

# הרץ עם coverage
flutter test --coverage

# הצג coverage ב-HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### כתיבת Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// Mock
class MockRepository extends Mock implements MyRepository {}

void main() {
  late MockRepository mockRepository;
  
  setUp(() {
    mockRepository = MockRepository();
  });
  
  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        myRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MyWidget(),
        ),
      ),
    );
  }
  
  group('MyWidget Tests', () {
    testWidgets('should display title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Act & Assert
      expect(find.text('My Title'), findsOneWidget);
    });
    
    testWidgets('should call callback on tap', (WidgetTester tester) async {
      // Arrange
      bool wasCalled = false;
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Assert
      expect(wasCalled, isTrue);
    });
  });
}
```

### Mocking עם Mocktail

```dart
// 1. Create mock class
class MockVenuesRepository extends Mock implements VenuesRepository {}

// 2. Setup behavior
when(() => mockRepo.searchVenues(any()))
    .thenAnswer((_) async => [venue1, venue2]);

// 3. Verify calls
verify(() => mockRepo.searchVenues('query')).called(1);

// 4. Verify never called
verifyNever(() => mockRepo.deleteVenue(any()));
```

---

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Test & Build (`.github/workflows/test.yml`)

**מתי רץ:** על כל push ו-PR

**שלבים:**
1. Flutter Tests
2. Backend Tests
3. Build Android APK (Debug)
4. Upload artifacts

```bash
# מקומי - סימולציה של CI
flutter test && cd functions && npm test && cd .. && flutter build apk --debug
```

#### 2. Deploy (`.github/workflows/deploy.yml`)

**מתי רץ:** על merge ל-main או manual trigger

**שלבים:**
1. Run tests
2. Deploy Cloud Functions
3. Deploy Firestore Rules

### Setup Secrets

צריך להגדיר ב-GitHub Settings → Secrets:

```bash
# 1. צור Firebase CI token
firebase login:ci

# 2. העתק את הטוקן
# 3. הוסף ל-GitHub Secrets:
# Name: FIREBASE_TOKEN
# Value: <your-token>
```

### הרצת Workflow ידנית

1. Go to GitHub → Actions
2. בחר Workflow
3. לחץ "Run workflow"

---

## כלים וספריות

### Backend
- **Mocha**: Test runner
- **Chai**: Assertions (`expect`)
- **Sinon**: Mocking & Stubbing
- **NYC**: Code coverage
- **Babel**: ES6 support

### Flutter
- **flutter_test**: Flutter testing framework
- **mocktail**: Mocking library
- **integration_test**: E2E tests (future)

### CI/CD
- **GitHub Actions**: Automation
- **Firebase CLI**: Deployment
- **Codecov**: Coverage reporting (optional)

---

## Best Practices

### 1. AAA Pattern
```javascript
// Arrange - הכן את המבחן
const input = 'test';

// Act - הרץ את הקוד
const result = myFunction(input);

// Assert - בדוק את התוצאה
expect(result).to.equal('expected');
```

### 2. Test Naming
```dart
// ✅ Good
testWidgets('should display error when input is invalid')

// ❌ Bad
testWidgets('test1')
```

### 3. One Assert Per Test
```dart
// ✅ Good
testWidgets('should display title', (tester) async {
  await tester.pumpWidget(widget);
  expect(find.text('Title'), findsOneWidget);
});

testWidgets('should display button', (tester) async {
  await tester.pumpWidget(widget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});

// ❌ Bad
testWidgets('should display UI elements', (tester) async {
  await tester.pumpWidget(widget);
  expect(find.text('Title'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
  expect(find.byIcon(Icons.home), findsOneWidget);
});
```

### 4. Cleanup
```javascript
afterEach(() => {
  sinon.restore(); // ניקוי stubs
  jest.clearAllMocks(); // ניקוי mocks
});
```

---

## Coverage Goals

| שכבה | יעד | נוכחי |
|------|-----|-------|
| Backend Functions | 60% | ✅ 70% |
| Flutter Widgets | 50% | ✅ 55% |
| Models | 80% | 🔄 45% |
| Services | 70% | 🔄 40% |

---

## Troubleshooting

### בעיה: Emulators לא עולים

```bash
# בדוק שאין processes רצים
lsof -ti:8080 | xargs kill -9
lsof -ti:9099 | xargs kill -9

# נקה cache
firebase emulators:start --import=./emulator-data --export-on-exit
```

### בעיה: Tests נכשלים ב-CI

```bash
# הרץ בדיוק כמו ב-CI
flutter test --no-pub
cd functions && npm ci && npm test
```

### בעיה: Coverage נמוך

```bash
# הצג קבצים שחסר להם כיסוי
nyc report --reporter=text
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

---

## הרצת Testing Suite מלא

```bash
#!/bin/bash
# run_all_tests.sh

echo "🧪 Running Flutter Tests..."
flutter test --coverage

echo "🔥 Running Backend Tests..."
cd functions
npm test
cd ..

echo "📊 Generating Coverage Reports..."
cd functions && npm run test:coverage && cd ..
genhtml coverage/lcov.info -o coverage/html

echo "✅ All tests complete!"
echo "📈 Coverage reports:"
echo "  - Backend: functions/coverage/index.html"
echo "  - Flutter: coverage/html/index.html"
```

---

## המשך פיתוח

### TODO - Tests נוספים
- [ ] Integration Tests ל-Auth Flow
- [ ] Integration Tests ל-Game Creation
- [ ] E2E Tests עם `integration_test`
- [ ] Performance Tests
- [ ] Stress Tests ל-Rate Limiting

### TODO - CI/CD
- [ ] Automated Deploy ל-Production
- [ ] Slack notifications on failures
- [ ] Automated Rollback on errors
- [ ] Blue-Green Deployment

---

**סטטוס:** ✅ Testing Infrastructure מוכן ופעיל!
**עודכן:** Nov 30, 2025

