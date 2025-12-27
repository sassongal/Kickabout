import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';

/// Service for Firebase Analytics event tracking
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;

  /// Initialize analytics
  void initialize() {
    if (!Env.isFirebaseAvailable) {
      debugPrint('⚠️ Analytics not available: Firebase not initialized');
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      debugPrint('✅ Analytics initialized');
    } catch (e) {
      debugPrint('⚠️ Analytics initialization failed: $e');
    }
  }

  /// Log a screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null || !Env.isFirebaseAvailable) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null || !Env.isFirebaseAvailable) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// Log user login
  Future<void> logLogin({String? loginMethod}) async {
    await logEvent(
      name: 'login',
      parameters: {
        if (loginMethod != null) 'method': loginMethod,
      },
    );
  }

  /// Log user signup
  Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        if (signUpMethod != null) 'method': signUpMethod,
      },
    );
  }

  /// Log game created
  Future<void> logGameCreated({required String hubId}) async {
    await logEvent(
      name: 'game_created',
      parameters: {
        'hub_id': hubId,
      },
    );
  }

  /// Log game joined
  Future<void> logGameJoined({required String gameId}) async {
    await logEvent(
      name: 'game_joined',
      parameters: {
        'game_id': gameId,
      },
    );
  }

  /// Log hub joined
  Future<void> logHubJoined({required String hubId}) async {
    await logEvent(
      name: 'hub_joined',
      parameters: {
        'hub_id': hubId,
      },
    );
  }

  /// Log hub created
  Future<void> logHubCreated() async {
    await logEvent(name: 'hub_created');
  }

  /// Log post created
  Future<void> logPostCreated({required String hubId}) async {
    await logEvent(
      name: 'post_created',
      parameters: {
        'hub_id': hubId,
      },
    );
  }

  /// Log message sent
  Future<void> logMessageSent({required String hubId}) async {
    await logEvent(
      name: 'message_sent',
      parameters: {
        'hub_id': hubId,
      },
    );
  }

  /// Log rating submitted
  Future<void> logRatingSubmitted({
    required String gameId,
    required String ratingType,
  }) async {
    await logEvent(
      name: 'rating_submitted',
      parameters: {
        'game_id': gameId,
        'rating_type': ratingType,
      },
    );
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_analytics == null || !Env.isFirebaseAvailable) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    if (_analytics == null || !Env.isFirebaseAvailable) return;

    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }
}

