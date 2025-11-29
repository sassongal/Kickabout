import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kickadoor/data/hubs_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/config/env.dart';
import '../../helpers/mock_firestore.dart';

void main() {
  group('HubsRepository', () {
    late HubsRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockHubsCollection;
    late MockDocumentReference mockHubRef;
    late MockDocumentSnapshot mockHubDoc;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockHubsCollection = MockCollectionReference();
      mockHubRef = MockDocumentReference();
      mockHubDoc = MockDocumentSnapshot();
      repository = HubsRepository(firestore: mockFirestore);

      // Setup default mocks
      when(() => mockFirestore.collection('hubs'))
          .thenReturn(mockHubsCollection);
      when(() => mockHubsCollection.doc(any())).thenReturn(mockHubRef);
      when(() => mockHubRef.get()).thenAnswer((_) async => mockHubDoc);
    });

    tearDown(() {
      Env.limitedMode = false;
    });

    test('getHub should return null when Firebase is not available', () async {
      // Arrange
      Env.limitedMode = true;

      // Act
      final result = await repository.getHub('hub123');

      // Assert
      expect(result, isNull);
    });

    test('getHub should return null when document does not exist', () async {
      // Arrange
      Env.limitedMode = false;
      when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);
      when(() => mockHubDoc.exists).thenReturn(false);

      // Act
      final result = await repository.getHub('hub123');

      // Assert
      expect(result, isNull);
    });

    test('getHub should return Hub when document exists', () async {
      // Arrange
      Env.limitedMode = false;
      final now = DateTime.now();
      final hubData = {
        'hubId': 'hub123',
        'name': 'Test Hub',
        'description': 'Test Description',
        'createdBy': 'user123',
        'createdAt': Timestamp.fromDate(now),
        'memberCount': 1,
        'roles': {'user123': 'manager'},
        'memberJoinDates': {'user123': Timestamp.fromDate(now)},
        'settings': {'ratingMode': 'basic'},
      };
      when(() => mockHubDoc.exists).thenReturn(true);
      when(() => mockHubDoc.data()).thenReturn(hubData);
      when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);

      // Act
      final result = await repository.getHub('hub123');

      // Assert
      expect(result, isNotNull);
      expect(result!.hubId, 'hub123');
      expect(result.name, 'Test Hub');
    });

    test('getHub should throw exception on error', () async {
      // Arrange
      Env.limitedMode = false;
      when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);
      when(() => mockHubRef.get()).thenThrow(Exception('Firestore error'));

      // Act & Assert
      expect(
        () => repository.getHub('hub123'),
        throwsA(isA<Exception>()),
      );
    });

    test('createHub should throw when Firebase is not available', () async {
      // Arrange
      Env.limitedMode = true;
      final hub = Hub(
        hubId: 'hub123',
        name: 'Test Hub',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        // memberIds removed - creator added via transaction
      );

      // Act & Assert
      expect(
        () => repository.createHub(hub),
        throwsA(isA<Exception>()),
      );
    });

    test('createHub should create hub and return hubId', () async {
      // Arrange
      Env.limitedMode = false;
      final hub = Hub(
        hubId: '',
        name: 'Test Hub',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        // memberIds removed - creator added via transaction
      );

      when(() => mockHubsCollection.doc()).thenReturn(mockHubRef);
      when(() => mockHubRef.id).thenReturn('hub123');
      when(() => mockHubRef.set(any(), any())).thenAnswer((_) async => {});

      // Mock transaction for user update - the transaction callback is wrapped in try-catch
      // so we can just return null and it won't fail the test
      when(() => mockFirestore.runTransaction(any()))
          .thenAnswer((invocation) async {
        try {
          // Get the transaction callback and execute it
          final callback = invocation.positionalArguments[0] as Future<dynamic>
              Function(Transaction);
          final mockTransaction = MockTransaction();
          final mockUserRef = MockDocumentReference();
          final mockUserDoc = MockDocumentSnapshot();
          when(() => mockFirestore.doc(any<String>())).thenReturn(mockUserRef);
          when(() => mockTransaction
                  .get(any<DocumentReference<Map<String, dynamic>>>()))
              .thenAnswer((_) async => mockUserDoc);
          when(() => mockUserDoc.exists).thenReturn(true);
          when(() => mockUserDoc.data()).thenReturn({'hubIds': []});
          return await callback(mockTransaction);
        } catch (e) {
          // Transaction can fail, that's OK - hub creation still succeeds
          return null;
        }
      });

      // Act
      final hubId = await repository.createHub(hub);

      // Assert
      expect(hubId, 'hub123');
      verify(() => mockHubRef.set(any(), any())).called(1);
    });
  });
}
