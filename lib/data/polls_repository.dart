import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/poll.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'polls_repository.g.dart';

/// Provider for PollsRepository
@riverpod
PollsRepository pollsRepository(PollsRepositoryRef ref) {
  return PollsRepository();
}

/// Repository for Poll operations
class PollsRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  PollsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new poll
  Future<String> createPoll({
    required String hubId,
    required String createdBy,
    required String question,
    required List<String> optionTexts,
    required PollType type,
    DateTime? endsAt,
    String? description,
    bool allowMultipleVotes = false,
    bool showResultsBeforeVote = false,
    bool isAnonymous = false,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Validations
    if (optionTexts.length < 2) {
      throw Exception('Poll must have at least 2 options');
    }
    if (optionTexts.length > 10) {
      throw Exception('Poll cannot have more than 10 options');
    }
    if (question.trim().isEmpty) {
      throw Exception('Question cannot be empty');
    }

    try {
      // Create poll options
      final options = optionTexts
          .map((text) => PollOption(
                optionId: _uuid.v4(),
                text: text.trim(),
                voteCount: 0,
                voters: [],
              ))
          .toList();

      // Create poll document
      final pollRef = _firestore.collection('polls').doc();

      final poll = Poll(
        pollId: pollRef.id,
        hubId: hubId,
        createdBy: createdBy,
        question: question.trim(),
        options: options,
        type: type,
        status: PollStatus.active,
        createdAt: DateTime.now(),
        endsAt: endsAt,
        totalVotes: 0,
        voters: [],
        allowMultipleVotes: allowMultipleVotes,
        showResultsBeforeVote: showResultsBeforeVote,
        isAnonymous: isAnonymous,
        description: description?.trim(),
      );

      final pollJson = poll.toJson();
      // Explicitly convert options to JSON for Firestore
      pollJson['options'] = options.map((e) => e.toJson()).toList();

      await pollRef.set(pollJson);

      debugPrint('✅ Poll created: ${pollRef.id}');
      return pollRef.id;
    } catch (e) {
      debugPrint('❌ Error creating poll: $e');
      throw Exception('Failed to create poll: $e');
    }
  }

  /// Get poll by ID
  Future<Poll?> getPoll(String pollId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore.collection('polls').doc(pollId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final jsonData = Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
      jsonData['pollId'] = pollId;
      return Poll.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error getting poll: $e');
      return null;
    }
  }

  /// Watch poll by ID (real-time updates)
  Stream<Poll?> watchPoll(String pollId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore.collection('polls').doc(pollId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Poll.fromJson({...data, 'pollId': pollId});
    });
  }

  /// Get polls for a hub
  Future<List<Poll>> getHubPolls({
    required String hubId,
    PollStatus? status,
    int limit = 20,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      Query query =
          _firestore.collection('polls').where('hubId', isEqualTo: hubId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              final jsonData =
                  Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
              jsonData['pollId'] = doc.id;
              return Poll.fromJson(jsonData);
            } catch (e) {
              debugPrint('Error parsing poll ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Poll>()
          .toList();
    } catch (e) {
      debugPrint('Error getting hub polls: $e');
      return [];
    }
  }

  /// Watch polls for a hub (real-time)
  Stream<List<Poll>> watchHubPolls({
    required String hubId,
    PollStatus? status,
    int limit = 20,
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    Query query =
        _firestore.collection('polls').where('hubId', isEqualTo: hubId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              final jsonData =
                  Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
              jsonData['pollId'] = doc.id;
              return Poll.fromJson(jsonData);
            } catch (e) {
              debugPrint('Error parsing poll ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Poll>()
          .toList();
    });
  }

  /// Update poll (only allowed fields)
  Future<void> updatePoll({
    required String pollId,
    String? question,
    String? description,
    DateTime? endsAt,
    PollStatus? status,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final updates = <String, dynamic>{};

      if (question != null) updates['question'] = question.trim();
      if (description != null) updates['description'] = description.trim();
      if (endsAt != null) updates['endsAt'] = Timestamp.fromDate(endsAt);
      if (status != null) {
        updates['status'] = status.name;
        if (status == PollStatus.closed) {
          updates['closedAt'] = FieldValue.serverTimestamp();
        }
      }

      if (updates.isEmpty) return;

      await _firestore.collection('polls').doc(pollId).update(updates);

      debugPrint('✅ Poll updated: $pollId');
    } catch (e) {
      debugPrint('❌ Error updating poll: $e');
      throw Exception('Failed to update poll: $e');
    }
  }

  /// Delete poll
  Future<void> deletePoll(String pollId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.collection('polls').doc(pollId).delete();
      debugPrint('✅ Poll deleted: $pollId');
    } catch (e) {
      debugPrint('❌ Error deleting poll: $e');
      throw Exception('Failed to delete poll: $e');
    }
  }

  /// Close poll manually
  Future<void> closePoll(String pollId) async {
    await updatePoll(pollId: pollId, status: PollStatus.closed);
  }

  /// Get poll summary (with percentages and sorted options)
  Future<PollSummary?> getPollSummary(String pollId, String? userId) async {
    final poll = await getPoll(pollId);
    if (poll == null) return null;

    return PollSummary.fromPoll(poll, userId: userId);
  }

  /// Check if user has voted on a poll
  bool hasUserVoted(Poll poll, String userId) {
    return poll.voters.contains(userId);
  }

  /// Get user's vote on a poll (if not anonymous)
  List<String>? getUserVote(Poll poll, String userId) {
    if (poll.isAnonymous) return null;
    if (!hasUserVoted(poll, userId)) return null;

    return poll.options
        .where((opt) => opt.voters.contains(userId))
        .map((opt) => opt.optionId)
        .toList();
  }
}
