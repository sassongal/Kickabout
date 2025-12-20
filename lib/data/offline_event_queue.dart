import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/models/models.dart';

/// Offline queue for game events
///
/// Persists events to local SQLite database to prevent data loss
/// Automatically syncs to Firestore when connection is restored
class OfflineEventQueue {
  static const String _tableName = 'pending_game_events';
  static const int _maxRetries = 3;

  Database? _database;
  final _syncController = StreamController<int>.broadcast();

  /// Stream of pending event counts (for UI updates)
  Stream<int> get pendingCountStream => _syncController.stream;

  /// Initialize database
  Future<void> initialize() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'offline_events.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId TEXT NOT NULL,
            hubId TEXT NOT NULL,
            eventType TEXT NOT NULL,
            playerId TEXT NOT NULL,
            playerName TEXT NOT NULL,
            team TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            recordedAt TEXT NOT NULL,
            metadata TEXT NOT NULL,
            retryCount INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            lastRetryAt TEXT
          )
        ''');

        // Index for faster queries
        await db.execute(
          'CREATE INDEX idx_gameId ON $_tableName (gameId)',
        );
      },
    );

    debugPrint('✅ Offline event queue initialized');
  }

  /// Add event to offline queue
  Future<void> enqueue({
    required String gameId,
    required String hubId,
    required EventType eventType,
    required String playerId,
    required String playerName,
    required String team,
    required Duration timestamp,
    required DateTime recordedAt,
    required Map<String, dynamic> metadata,
  }) async {
    await initialize();

    final event = {
      'gameId': gameId,
      'hubId': hubId,
      'eventType': eventType.name,
      'playerId': playerId,
      'playerName': playerName,
      'team': team,
      'timestamp': timestamp.inSeconds,
      'recordedAt': recordedAt.toIso8601String(),
      'metadata': jsonEncode(metadata),
      'retryCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'lastRetryAt': null,
    };

    await _database!.insert(_tableName, event);
    debugPrint('📥 Enqueued event: $eventType for player $playerName in game $gameId');

    _notifyPendingCount();
  }

  /// Get all pending events for a game
  Future<List<Map<String, dynamic>>> getPendingEvents(String gameId) async {
    await initialize();

    return await _database!.query(
      _tableName,
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Get count of pending events
  Future<int> getPendingCount() async {
    await initialize();

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Attempt to sync an event to Firestore
  /// Returns true if successful, false otherwise
  Future<bool> syncEvent(
    int eventId,
    Future<void> Function(Map<String, dynamic>) uploadCallback,
  ) async {
    await initialize();

    // Get event
    final events = await _database!.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (events.isEmpty) return true; // Already deleted

    final event = events.first;
    final retryCount = event['retryCount'] as int;

    if (retryCount >= _maxRetries) {
      debugPrint('⚠️ Event $eventId exceeded max retries, skipping');
      return false;
    }

    try {
      // Attempt upload
      await uploadCallback(event);

      // Success - delete from queue
      await _database!.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [eventId],
      );

      debugPrint('✅ Synced and removed event $eventId');
      _notifyPendingCount();
      return true;
    } catch (e) {
      // Failed - increment retry count
      await _database!.update(
        _tableName,
        {
          'retryCount': retryCount + 1,
          'lastRetryAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [eventId],
      );

      debugPrint('❌ Failed to sync event $eventId (retry ${retryCount + 1}/$_maxRetries): $e');
      return false;
    }
  }

  /// Sync all pending events for a game
  Future<void> syncGameEvents(
    String gameId,
    Future<void> Function(Map<String, dynamic>) uploadCallback,
  ) async {
    final events = await getPendingEvents(gameId);

    if (events.isEmpty) {
      debugPrint('✅ No pending events for game $gameId');
      return;
    }

    debugPrint('🔄 Syncing ${events.length} pending events for game $gameId');

    int successCount = 0;
    for (final event in events) {
      final success = await syncEvent(event['id'] as int, uploadCallback);
      if (success) successCount++;
    }

    debugPrint('✅ Synced $successCount/${events.length} events for game $gameId');
  }

  /// Clear all events for a game (after successful sync)
  Future<void> clearGameEvents(String gameId) async {
    await initialize();

    await _database!.delete(
      _tableName,
      where: 'gameId = ?',
      whereArgs: [gameId],
    );

    debugPrint('🗑️ Cleared all pending events for game $gameId');
    _notifyPendingCount();
  }

  /// Clear old failed events (cleanup)
  Future<void> clearOldFailedEvents({int daysOld = 7}) async {
    await initialize();

    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    await _database!.delete(
      _tableName,
      where: 'retryCount >= ? AND createdAt < ?',
      whereArgs: [_maxRetries, cutoffDate.toIso8601String()],
    );

    debugPrint('🗑️ Cleared failed events older than $daysOld days');
    _notifyPendingCount();
  }

  void _notifyPendingCount() async {
    final count = await getPendingCount();
    _syncController.add(count);
  }

  /// Close database and cleanup
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
    await _syncController.close();
  }
}

/// Singleton instance
final offlineEventQueue = OfflineEventQueue();
