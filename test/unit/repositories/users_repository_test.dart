import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/config/env.dart';
import '../../helpers/mock_firestore.dart';

void main() {
  group('UsersRepository', () {
    late UsersRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockDocumentReference mockUserRef;
    late MockDocumentSnapshot mockUserDoc;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockUserRef = MockDocumentReference();
      mockUserDoc = MockDocumentSnapshot();
      repository = UsersRepository(firestore: mockFirestore);
      
      // Setup default mocks
      when(() => mockFirestore.doc(any())).thenReturn(mockUserRef);
      when(() => mockUserRef.get()).thenAnswer((_) async => mockUserDoc);
      when(() => mockUserRef.snapshots()).thenAnswer((_) => Stream.value(mockUserDoc));
    });

    tearDown(() {
      Env.limitedMode = false; // Reset for next test
    });

    test('getUser should return null when Firebase is not available', () async {
      // Arrange
      Env.limitedMode = true;

      // Act
      final result = await repository.getUser('user123');

      // Assert
      expect(result, isNull);
    });

    test('getUser should return null when document does not exist', () async {
      // Arrange
      Env.limitedMode = false;
      when(() => mockUserDoc.exists).thenReturn(false);

      // Act
      final result = await repository.getUser('user123');

      // Assert
      expect(result, isNull);
      verify(() => mockFirestore.doc(any<String>())).called(1);
    });

    test('getUser should return User when document exists', () async {
      // Arrange
      Env.limitedMode = false;
      final now = DateTime.now();
      final userData = {
        'uid': 'user123',
        'name': 'Test User',
        'email': 'test@example.com',
        'createdAt': Timestamp.fromDate(now),
        'hubIds': [],
        'currentRankScore': 5.0,
        'totalParticipations': 0,
        'followerCount': 0,
        'availabilityStatus': 'available',
      };
      when(() => mockUserDoc.exists).thenReturn(true);
      when(() => mockUserDoc.data()).thenReturn(userData);

      // Act
      final result = await repository.getUser('user123');

      // Assert
      expect(result, isNotNull);
      expect(result!.uid, 'user123');
      expect(result.name, 'Test User');
      expect(result.email, 'test@example.com');
    });

    test('getUser should throw exception on error', () async {
      // Arrange
      Env.limitedMode = false;
      when(() => mockUserRef.get()).thenThrow(Exception('Firestore error'));

      // Act & Assert
      expect(
        () => repository.getUser('user123'),
        throwsA(isA<Exception>()),
      );
    });

    test('watchUser should return null stream when Firebase is not available', () async {
      // Arrange
      Env.limitedMode = true;

      // Act
      final stream = repository.watchUser('user123');

      // Assert
      final result = await stream.first;
      expect(result, isNull);
    });

    test('watchUser should return User stream when document exists', () async {
      // Arrange
      Env.limitedMode = false;
      final now = DateTime.now();
      final userData = {
        'uid': 'user123',
        'name': 'Test User',
        'email': 'test@example.com',
        'createdAt': Timestamp.fromDate(now),
        'hubIds': [],
        'currentRankScore': 5.0,
        'totalParticipations': 0,
        'followerCount': 0,
        'availabilityStatus': 'available',
      };
      when(() => mockUserDoc.exists).thenReturn(true);
      when(() => mockUserDoc.data()).thenReturn(userData);

      // Act
      final stream = repository.watchUser('user123');

      // Assert
      final result = await stream.first;
      expect(result, isNotNull);
      expect(result!.uid, 'user123');
    });

    test('watchUser should return null stream when document does not exist', () async {
      // Arrange
      Env.limitedMode = false;
      when(() => mockUserDoc.exists).thenReturn(false);

      // Act
      final stream = repository.watchUser('user123');

      // Assert
      final result = await stream.first;
      expect(result, isNull);
    });
  });
}

