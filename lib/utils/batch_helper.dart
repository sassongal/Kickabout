import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper for batch operations with automatic batching
class BatchHelper {
  final FirebaseFirestore _firestore;
  final int _maxBatchSize;
  final List<Future<void> Function(WriteBatch)> _operations = [];

  BatchHelper({
    required FirebaseFirestore firestore,
    int maxBatchSize = 500, // Firestore limit is 500
  })  : _firestore = firestore,
        _maxBatchSize = maxBatchSize;

  /// Add a write operation to the batch
  void add(Future<void> Function(WriteBatch batch) operation) {
    _operations.add(operation);
  }

  /// Add a set operation
  void set(DocumentReference ref, Map<String, dynamic> data, {SetOptions? options}) {
    add((batch) async {
      if (options != null) {
        batch.set(ref, data, options);
      } else {
        batch.set(ref, data);
      }
    });
  }

  /// Add an update operation
  void update(DocumentReference ref, Map<String, dynamic> data) {
    add((batch) async {
      batch.update(ref, data);
    });
  }

  /// Add a delete operation
  void delete(DocumentReference ref) {
    add((batch) async {
      batch.delete(ref);
    });
  }

  /// Commit all operations in batches
  Future<void> commit() async {
    if (_operations.isEmpty) {
      debugPrint('⚠️ No operations to commit');
      return;
    }

    debugPrint('📦 Committing ${_operations.length} operations in batches...');

    WriteBatch? batch;
    int batchSize = 0;
    int totalCommitted = 0;

    for (final operation in _operations) {
      // Create new batch if needed
      if (batch == null || batchSize >= _maxBatchSize) {
        // Commit previous batch if exists
        if (batch != null) {
          await batch.commit();
          totalCommitted += batchSize;
          debugPrint('✅ Committed batch of $batchSize operations');
        }
        
        batch = _firestore.batch();
        batchSize = 0;
      }

      // Add operation to batch
      await operation(batch);
      batchSize++;
    }

    // Commit final batch
    if (batch != null && batchSize > 0) {
      await batch.commit();
      totalCommitted += batchSize;
      debugPrint('✅ Committed final batch of $batchSize operations');
    }

    debugPrint('✅ Total committed: $totalCommitted operations');
    _operations.clear();
  }

  /// Clear all pending operations
  void clear() {
    _operations.clear();
  }
}

/// Helper function for batch updates
Future<void> batchUpdate<T>(
  List<T> items,
  Future<void> Function(WriteBatch batch, T item, int index) operation, {
  FirebaseFirestore? firestore,
  int maxBatchSize = 500,
}) async {
  final db = firestore ?? FirebaseFirestore.instance;
  final batchHelper = BatchHelper(firestore: db, maxBatchSize: maxBatchSize);

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    final index = i;
    batchHelper.add((batch) async => await operation(batch, item, index));
  }

  await batchHelper.commit();
}

