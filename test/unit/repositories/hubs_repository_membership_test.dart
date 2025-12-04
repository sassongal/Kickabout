import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kattrick/data/hubs_repository.dart';
import '../../helpers/mock_firestore.dart';

void main() {
  setUpAll(() {
    // Register fallback values for any() matchers
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(MockDocumentSnapshot());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
  });

  group('HubsRepository - Membership Methods', () {
    late HubsRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockTransaction mockTransaction;
    late MockDocumentReference mockHubRef;
    late MockDocumentReference mockUserRef;
    late MockDocumentReference mockMemberRef;
    late MockCollectionReference mockMembersCollection;
    late MockDocumentSnapshot mockHubDoc;
    late MockDocumentSnapshot mockUserDoc;
    late MockDocumentSnapshot mockMemberDoc;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTransaction = MockTransaction();
      mockHubRef = MockDocumentReference();
      mockUserRef = MockDocumentReference();
      mockMemberRef = MockDocumentReference();
      mockMembersCollection = MockCollectionReference();
      mockHubDoc = MockDocumentSnapshot();
      mockUserDoc = MockDocumentSnapshot();
      mockMemberDoc = MockDocumentSnapshot();

      repository = HubsRepository(firestore: mockFirestore);

      // Setup transaction execution - pass our mockTransaction to callback
      when(() => mockFirestore.runTransaction<void>(any()))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[0]
            as Future<void> Function(Transaction);

        // Setup get() mocks on the transaction
        when(() => mockTransaction.get(any()))
            .thenAnswer((inv) async {
          final ref = inv.positionalArguments[0] as DocumentReference;
          if (ref == mockHubRef) return mockHubDoc;
          if (ref == mockUserRef) return mockUserDoc;
          if (ref == mockMemberRef) return mockMemberDoc;
          throw Exception('Unexpected ref: $ref');
        });

        // Stub void methods to prevent mocktail from returning null
        when(() => mockTransaction.set(any(), any())).thenReturn(null);
        when(() => mockTransaction.update(any(), any())).thenReturn(null);

        // Execute the callback
        return await callback(mockTransaction);
      });
    });

    group('addMember', () {
      setUp(() {
        // Setup default mocks for addMember
        when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);
        when(() => mockFirestore.doc('users/user456')).thenReturn(mockUserRef);
        when(() => mockHubRef.collection('members')).thenReturn(mockMembersCollection);
        when(() => mockMembersCollection.doc('user456')).thenReturn(mockMemberRef);

        when(() => mockTransaction.get(mockHubRef))
            .thenAnswer((_) async => mockHubDoc);
        when(() => mockTransaction.get(mockUserRef))
            .thenAnswer((_) async => mockUserDoc);
        when(() => mockTransaction.get(mockMemberRef))
            .thenAnswer((_) async => mockMemberDoc);

        // Default: hub exists with capacity
        when(() => mockHubDoc.exists).thenReturn(true);
        when(() => mockHubDoc.data()).thenReturn({
          'hubId': 'hub123',
          'name': 'Test Hub',
          'createdBy': 'creator123',
          'memberCount': 5,
        });

        // Default: user exists with available hub slots
        when(() => mockUserDoc.exists).thenReturn(true);
        when(() => mockUserDoc.data()).thenReturn({
          'uid': 'user456',
          'name': 'Test User',
          'hubIds': ['hub999'], // Has 1 hub, can join 9 more
        });

        // Default: member doesn't exist yet (first-time join)
        when(() => mockMemberDoc.exists).thenReturn(false);
      });

      test('creates HubMember doc with correct fields on first join', () async {
        // Arrange
        Map<String, dynamic>? capturedMemberData;
        when(() => mockTransaction.set(mockMemberRef, any())).thenAnswer((inv) {
          capturedMemberData = inv.positionalArguments[1] as Map<String, dynamic>;
          return mockTransaction;
        });

        // Act
        await repository.addMember('hub123', 'user456');

        // Assert
        expect(capturedMemberData, isNotNull);
        expect(capturedMemberData!['hubId'], 'hub123');
        expect(capturedMemberData!['userId'], 'user456');
        expect(capturedMemberData!['role'], 'member');
        expect(capturedMemberData!['status'], 'active');
        expect(capturedMemberData!['veteranSince'], isNull);
        expect(capturedMemberData!['managerRating'], 0.0);
        expect(capturedMemberData!['updatedBy'], 'user456');
      });

      test('updates user.hubIds array', () async {
        // Arrange
        Map<String, dynamic>? capturedUserUpdate;
        when(() => mockTransaction.update(mockUserRef, any())).thenAnswer((inv) {
          capturedUserUpdate = inv.positionalArguments[1] as Map<String, dynamic>;
          return mockTransaction;
        });

        // Act
        await repository.addMember('hub123', 'user456');

        // Assert
        expect(capturedUserUpdate, isNotNull);
        verify(() => mockTransaction.update(mockUserRef, any())).called(1);
      });

      test('rejects when hub is full (50 members)', () async {
        // Arrange
        when(() => mockHubDoc.data()).thenReturn({
          'hubId': 'hub123',
          'name': 'Full Hub',
          'memberCount': 50, // At capacity
        });

        // Act & Assert
        expect(
          () => repository.addMember('hub123', 'user456'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Hub is full'))),
        );
      });

      test('rejects when user has max hubs (10)', () async {
        // Arrange
        when(() => mockUserDoc.data()).thenReturn({
          'uid': 'user456',
          'hubIds': List.generate(10, (i) => 'hub$i'), // Already at limit
        });

        // Act & Assert
        expect(
          () => repository.addMember('hub123', 'user456'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('max hubs'))),
        );
      });

      test('rejects when user is banned', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn({
          'hubId': 'hub123',
          'userId': 'user456',
          'status': 'banned',
          'role': 'member',
        });

        // Act & Assert
        expect(
          () => repository.addMember('hub123', 'user456'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('banned'))),
        );
      });

      test('reactivates when user previously left', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn({
          'hubId': 'hub123',
          'userId': 'user456',
          'status': 'left',
          'role': 'member',
        });

        Map<String, dynamic>? capturedUpdate;
        when(() => mockTransaction.update(mockMemberRef, any())).thenAnswer((inv) {
          capturedUpdate = inv.positionalArguments[1] as Map<String, dynamic>;
          return mockTransaction;
        });

        // Act
        await repository.addMember('hub123', 'user456');

        // Assert
        expect(capturedUpdate, isNotNull);
        expect(capturedUpdate!['status'], 'active');
        expect(capturedUpdate!['updatedBy'], 'user456');
        verify(() => mockTransaction.update(mockMemberRef, any())).called(greaterThan(0));
      });

      test('is idempotent (no error if already member)', () async {
        // Arrange
        when(() => mockUserDoc.data()).thenReturn({
          'uid': 'user456',
          'hubIds': ['hub123'], // Already a member
        });

        // Act & Assert - should not throw
        await repository.addMember('hub123', 'user456');

        // Should return early without creating member doc
        verifyNever(() => mockTransaction.set(mockMemberRef, any()));
      });

      test('throws when hub does not exist', () async {
        // Arrange
        when(() => mockHubDoc.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.addMember('hub123', 'user456'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Hub not found'))),
        );
      });

      test('throws when user does not exist', () async {
        // Arrange
        when(() => mockUserDoc.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.addMember('hub123', 'user456'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('User not found'))),
        );
      });
    });

    group('removeMember', () {
      setUp(() {
        when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);
        when(() => mockFirestore.doc('users/user456')).thenReturn(mockUserRef);
        when(() => mockHubRef.collection('members')).thenReturn(mockMembersCollection);
        when(() => mockMembersCollection.doc('user456')).thenReturn(mockMemberRef);

        when(() => mockTransaction.get(mockMemberRef))
            .thenAnswer((_) async => mockMemberDoc);
        when(() => mockTransaction.get(mockUserRef))
            .thenAnswer((_) async => mockUserDoc);

        when(() => mockTransaction.update(any(), any())).thenAnswer((_) => mockTransaction);
      });

      test('sets status to left (soft-delete)', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn({
          'hubId': 'hub123',
          'userId': 'user456',
          'status': 'active',
          'role': 'member',
        });
        when(() => mockUserDoc.exists).thenReturn(true);

        Map<String, dynamic>? capturedUpdate;
        when(() => mockTransaction.update(mockMemberRef, any())).thenAnswer((inv) {
          capturedUpdate = inv.positionalArguments[1] as Map<String, dynamic>;
          return mockTransaction;
        });

        // Act
        await repository.removeMember('hub123', 'user456');

        // Assert
        expect(capturedUpdate, isNotNull);
        expect(capturedUpdate!['status'], 'left');
        expect(capturedUpdate!['statusReason'], 'User chose to leave');
        expect(capturedUpdate!['updatedBy'], 'user456');
      });

      test('removes from user.hubIds', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockUserDoc.exists).thenReturn(true);

        // Act
        await repository.removeMember('hub123', 'user456');

        // Assert
        verify(() => mockTransaction.update(mockUserRef, any())).called(1);
      });

      test('is idempotent (no error if already gone)', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(false);
        when(() => mockUserDoc.exists).thenReturn(true);

        // Act & Assert - should not throw
        await repository.removeMember('hub123', 'user456');

        // Should return early
        verifyNever(() => mockTransaction.update(mockMemberRef, any()));
      });

      test('throws when user does not exist', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockUserDoc.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.removeMember('hub123', 'user456'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('User not found'))),
        );
      });
    });

    group('updateMemberRole', () {
      setUp(() {
        when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);
        when(() => mockFirestore.doc('hubs/hub123/members/user456')).thenReturn(mockMemberRef);
        when(() => mockHubRef.get()).thenAnswer((_) async => mockHubDoc);
        when(() => mockHubDoc.exists).thenReturn(true);
        when(() => mockHubDoc.data()).thenReturn({
          'hubId': 'hub123',
          'name': 'Test Hub',
          'createdBy': 'creator123',
        });
        when(() => mockMemberRef.update(any())).thenAnswer((_) async {});
      });

      test('updates role in HubMember doc', () async {
        // Arrange
        Map<String, dynamic>? capturedUpdate;
        when(() => mockMemberRef.update(any())).thenAnswer((inv) async {
          capturedUpdate = inv.positionalArguments[0] as Map<String, dynamic>;
        });

        // Act
        await repository.updateMemberRole('hub123', 'user456', 'moderator', 'manager123');

        // Assert
        expect(capturedUpdate, isNotNull);
        expect(capturedUpdate!['role'], 'moderator');
        expect(capturedUpdate!['updatedBy'], 'manager123');
        verify(() => mockMemberRef.update(any())).called(1);
      });

      test('rejects invalid role', () async {
        // Act & Assert
        expect(
          () => repository.updateMemberRole('hub123', 'user456', 'invalid_role', 'manager123'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Invalid role'))),
        );
      });

      test('prevents changing creator role', () async {
        // Act & Assert
        expect(
          () => repository.updateMemberRole('hub123', 'creator123', 'member', 'manager123'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Cannot change creator role'))),
        );
      });

      test('accepts valid roles: member, moderator, manager', () async {
        // Arrange
        when(() => mockMemberRef.update(any())).thenAnswer((_) async {});

        // Act & Assert - should not throw
        await repository.updateMemberRole('hub123', 'user456', 'member', 'manager123');
        await repository.updateMemberRole('hub123', 'user456', 'moderator', 'manager123');
        await repository.updateMemberRole('hub123', 'user456', 'manager', 'manager123');

        verify(() => mockMemberRef.update(any())).called(3);
      });
    });

    group('banMember', () {
      setUp(() {
        when(() => mockFirestore.doc('hubs/hub123')).thenReturn(mockHubRef);
        when(() => mockFirestore.doc('users/user456')).thenReturn(mockUserRef);
        when(() => mockHubRef.collection('members')).thenReturn(mockMembersCollection);
        when(() => mockMembersCollection.doc('user456')).thenReturn(mockMemberRef);

        when(() => mockTransaction.get(mockHubRef))
            .thenAnswer((_) async => mockHubDoc);
        when(() => mockTransaction.get(mockMemberRef))
            .thenAnswer((_) async => mockMemberDoc);

        when(() => mockHubDoc.exists).thenReturn(true);
        when(() => mockHubDoc.data()).thenReturn({
          'hubId': 'hub123',
          'createdBy': 'creator123',
        });

        when(() => mockTransaction.update(any(), any())).thenAnswer((_) => mockTransaction);
      });

      test('sets status to banned with reason', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);

        Map<String, dynamic>? capturedUpdate;
        when(() => mockTransaction.update(mockMemberRef, any())).thenAnswer((inv) {
          capturedUpdate = inv.positionalArguments[1] as Map<String, dynamic>;
          return mockTransaction;
        });

        // Act
        await repository.banMember('hub123', 'user456', 'Violation of rules', 'manager123');

        // Assert
        expect(capturedUpdate, isNotNull);
        expect(capturedUpdate!['status'], 'banned');
        expect(capturedUpdate!['statusReason'], 'Violation of rules');
        expect(capturedUpdate!['updatedBy'], 'manager123');
      });

      test('removes from user.hubIds', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);

        // Act
        await repository.banMember('hub123', 'user456', 'Spam', 'manager123');

        // Assert
        verify(() => mockTransaction.update(mockUserRef, any())).called(1);
      });

      test('prevents banning creator', () async {
        // Act & Assert
        expect(
          () => repository.banMember('hub123', 'creator123', 'Test', 'manager123'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Cannot ban hub creator'))),
        );
      });

      test('rejects if member does not exist', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.banMember('hub123', 'user456', 'Spam', 'manager123'),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('not a member'))),
        );
      });
    });

    group('setPlayerRating', () {
      setUp(() {
        when(() => mockFirestore.doc('hubs/hub123/members/user456')).thenReturn(mockMemberRef);
        when(() => mockMemberRef.get()).thenAnswer((_) async => mockMemberDoc);
        when(() => mockMemberRef.update(any())).thenAnswer((_) async {});
      });

      test('updates managerRating in HubMember doc', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn({
          'status': 'active',
          'role': 'member',
        });

        Map<String, dynamic>? capturedUpdate;
        when(() => mockMemberRef.update(any())).thenAnswer((inv) async {
          capturedUpdate = inv.positionalArguments[0] as Map<String, dynamic>;
        });

        // Act
        await repository.setPlayerRating('hub123', 'user456', 7.5);

        // Assert
        expect(capturedUpdate, isNotNull);
        expect(capturedUpdate!['managerRating'], 7.5);
        verify(() => mockMemberRef.update(any())).called(1);
      });

      test('validates rating range (1.0-10.0)', () async {
        // Act & Assert
        expect(
          () => repository.setPlayerRating('hub123', 'user456', 0.5),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('between 1.0 and 10.0'))),
        );

        expect(
          () => repository.setPlayerRating('hub123', 'user456', 10.5),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('between 1.0 and 10.0'))),
        );
      });

      test('rejects if member not active', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(true);
        when(() => mockMemberDoc.data()).thenReturn({
          'status': 'left',
          'role': 'member',
        });

        // Act & Assert
        expect(
          () => repository.setPlayerRating('hub123', 'user456', 7.5),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Cannot rate inactive member'))),
        );
      });

      test('rejects if member does not exist', () async {
        // Arrange
        when(() => mockMemberDoc.exists).thenReturn(false);

        // Act & Assert
        expect(
          () => repository.setPlayerRating('hub123', 'user456', 7.5),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('not a member'))),
        );
      });
    });
  });
}
