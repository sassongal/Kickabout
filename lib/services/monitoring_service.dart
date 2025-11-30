import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kattrick/services/error_handler_service.dart';

/// Performance metrics
class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.success,
    this.error,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'duration': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'error': error,
    'metadata': metadata,
  };
}

/// Monitoring service for tracking performance and errors
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final List<PerformanceMetrics> _metrics = [];
  final int _maxMetrics = 100; // Keep last 100 metrics
  final Map<String, int> _operationCounts = {};
  final Map<String, Duration> _operationDurations = {};

  /// Track operation performance
  Future<T> trackOperation<T>(
    String operation,
    Future<T> Function() fn, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();
    String? error;

    try {
      final result = await fn();
      stopwatch.stop();
      
      _recordMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: timestamp,
        success: true,
        metadata: metadata,
      ));

      return result;
    } catch (e) {
      error = e.toString();
      stopwatch.stop();

      _recordMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: timestamp,
        success: false,
        error: error,
        metadata: metadata,
      ));

      // Log error
      ErrorHandlerService().logError(
        e,
        reason: 'Operation failed: $operation',
      );

      rethrow;
    }
  }

  /// Track synchronous operation
  T trackSyncOperation<T>(
    String operation,
    T Function() fn, {
    Map<String, dynamic>? metadata,
  }) {
    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();
    String? error;

    try {
      final result = fn();
      stopwatch.stop();

      _recordMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: timestamp,
        success: true,
        metadata: metadata,
      ));

      return result;
    } catch (e) {
      error = e.toString();
      stopwatch.stop();

      _recordMetric(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        timestamp: timestamp,
        success: false,
        error: error,
        metadata: metadata,
      ));

      ErrorHandlerService().logError(
        e,
        reason: 'Sync operation failed: $operation',
      );

      rethrow;
    }
  }

  /// Record a metric
  void _recordMetric(PerformanceMetrics metric) {
    _metrics.add(metric);
    
    // Keep only last N metrics
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }

    // Update operation statistics
    _operationCounts[metric.operation] = 
        (_operationCounts[metric.operation] ?? 0) + 1;
    
    final currentAvg = _operationDurations[metric.operation] ?? Duration.zero;
    final count = _operationCounts[metric.operation] ?? 1;
    _operationDurations[metric.operation] = Duration(
      milliseconds: ((currentAvg.inMilliseconds * (count - 1) + 
                     metric.duration.inMilliseconds) / count).round(),
    );

    // Log slow operations
    if (metric.duration.inMilliseconds > 1000) {
      debugPrint('🐌 Slow operation: ${metric.operation} took ${metric.duration.inMilliseconds}ms');
      ErrorHandlerService().logMessage(
        'Slow operation: ${metric.operation} (${metric.duration.inMilliseconds}ms)',
      );
    }

    // Log failures
    if (!metric.success) {
      debugPrint('❌ Operation failed: ${metric.operation} - ${metric.error}');
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    final successful = _metrics.where((m) => m.success).length;
    final failed = _metrics.where((m) => !m.success).length;
    final total = _metrics.length;

    final avgDuration = total > 0
        ? _metrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / total
        : 0.0;

    return {
      'totalOperations': total,
      'successful': successful,
      'failed': failed,
      'successRate': total > 0 ? '${(successful / total * 100).toStringAsFixed(2)}%' : '0%',
      'averageDuration': '${avgDuration.toStringAsFixed(2)}ms',
      'operationCounts': Map<String, int>.from(_operationCounts),
      'operationAverages': _operationDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
    };
  }

  /// Get metrics for specific operation
  List<PerformanceMetrics> getOperationMetrics(String operation) {
    return _metrics.where((m) => m.operation == operation).toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _operationCounts.clear();
    _operationDurations.clear();
    debugPrint('📊 Metrics cleared');
  }

  /// Log current statistics
  void logStats() {
    final stats = getStats();
    debugPrint('📊 Performance Statistics:');
    debugPrint('  Total operations: ${stats['totalOperations']}');
    debugPrint('  Success rate: ${stats['successRate']}');
    debugPrint('  Average duration: ${stats['averageDuration']}');
    debugPrint('  Operation counts: ${stats['operationCounts']}');
    
    ErrorHandlerService().logMessage('Performance stats: $stats');
  }
}

