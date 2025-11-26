import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

/// Mock classes for Firestore testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockTransaction extends Mock implements Transaction {}

/// Helper to create a mock document snapshot
DocumentSnapshot<Map<String, dynamic>> createMockDocumentSnapshot({
  required String id,
  required Map<String, dynamic> data,
  bool exists = true,
}) {
  final mock = MockDocumentSnapshot();
  when(() => mock.id).thenReturn(id);
  when(() => mock.exists).thenReturn(exists);
  when(() => mock.data()).thenReturn(exists ? data : null);
  return mock;
}

/// Helper to create a mock query snapshot
QuerySnapshot<Map<String, dynamic>> createMockQuerySnapshot({
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
}) {
  final mock = MockQuerySnapshot();
  when(() => mock.docs).thenReturn(docs);
  when(() => mock.size).thenReturn(docs.length);
  return mock;
}
// ignore_for_file: subtype_of_sealed_class
