import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic paginated result container for Firestore queries.
///
/// Usage:
/// ```dart
/// final result = await getHubsPaginated(limit: 20);
/// // Display result.items
/// // If result.hasMore, fetch next page:
/// final nextResult = await getHubsPaginated(
///   limit: 20,
///   startAfter: result.lastDoc,
/// );
/// ```
class PaginatedResult<T> {
  /// The list of items in this page
  final List<T> items;

  /// The last document snapshot, used as cursor for next page
  final DocumentSnapshot? lastDoc;

  /// Whether there are more items available
  final bool hasMore;

  /// Total count (if available from query, otherwise null)
  final int? totalCount;

  const PaginatedResult({
    required this.items,
    this.lastDoc,
    required this.hasMore,
    this.totalCount,
  });

  /// Create an empty result
  factory PaginatedResult.empty() {
    return const PaginatedResult(
      items: [],
      lastDoc: null,
      hasMore: false,
      totalCount: 0,
    );
  }

  /// Create from a Firestore query snapshot
  ///
  /// Automatically detects if there are more pages by requesting limit+1 docs.
  /// If you get more than limit docs, sets hasMore=true and truncates to limit.
  factory PaginatedResult.fromSnapshot({
    required QuerySnapshot snapshot,
    required int limit,
    required T Function(DocumentSnapshot doc) mapper,
  }) {
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final items = (hasMore ? docs.sublist(0, limit) : docs)
        .map(mapper)
        .toList();

    return PaginatedResult(
      items: items,
      lastDoc: items.isNotEmpty ? docs[items.length - 1] : null,
      hasMore: hasMore,
    );
  }

  /// Check if this is the first page (no cursor)
  bool get isFirstPage => lastDoc == null;

  /// Check if this result is empty
  bool get isEmpty => items.isEmpty;

  /// Check if this result is not empty
  bool get isNotEmpty => items.isNotEmpty;
}
