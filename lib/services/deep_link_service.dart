import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Service for handling deep links from push notifications and URLs
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  GoRouter? _router;
  // ignore: unused_field
  String? _pendingHubId; // Stored hub id for redirect after auth

  /// Initialize with navigator key and router
  void initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    GoRouter? router,
  }) {
    _router = router;
  }

  /// Handle deep link from URL (e.g., kattrick://hub/HUB_ID)
  Future<void> handleUrlDeepLink(Uri uri) async {
    if (_router == null) {
      debugPrint('⚠️ Router not initialized for deep linking');
      return;
    }

    try {
      final path = uri.path;
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();

      if (segments.isEmpty) return;

      final type = segments[0];
      final id = segments.length > 1 ? segments[1] : null;

      switch (type) {
        case 'hub':
          if (id != null) {
            await _handleHubDeepLink(id);
          }
          break;

        case 'game':
          if (id != null) {
            await _handleGameDeepLink(id);
          }
          break;

        default:
          debugPrint('Unknown deep link type: $type');
      }
    } catch (e) {
      debugPrint('Error handling URL deep link: $e');
    }
  }

  /// Handle hub deep link
  Future<void> _handleHubDeepLink(String hubId) async {
    final auth = firebase_auth.FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      // User is logged in - navigate directly
      _router!.go('/hubs/$hubId');
    } else {
      // User is not logged in - store for redirect after registration
      _pendingHubId = hubId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_hub_redirect', hubId);
      _router!.go('/register');
    }
  }

  /// Handle game deep link
  Future<void> _handleGameDeepLink(String gameId) async {
    final auth = firebase_auth.FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      _router!.go('/games/$gameId');
    } else {
      _router!.go('/register');
    }
  }

  /// Check for pending redirect after registration
  Future<void> checkPendingRedirect() async {
    if (_router == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pendingHubId = prefs.getString('pending_hub_redirect');
    
    if (pendingHubId != null && pendingHubId.isNotEmpty) {
      await prefs.remove('pending_hub_redirect');
      _pendingHubId = null;
      
      // Small delay to ensure navigation is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _router!.go('/hubs/$pendingHubId');
    }
  }

  /// Handle deep link from notification data
  void handleDeepLink(Map<String, dynamic> data) {
    if (_router == null) {
      debugPrint('⚠️ Router not initialized for deep linking');
      return;
    }

    final type = data['type'] as String?;
    if (type == null) return;

    try {
      switch (type) {
        case 'game':
          final gameId = data['gameId'] as String?;
          if (gameId != null) {
            _router!.go('/games/$gameId');
          }
          break;

        case 'hub':
          final hubId = data['hubId'] as String?;
          if (hubId != null) {
            _router!.go('/hubs/$hubId');
          }
          break;

        case 'notification':
          _router!.go('/notifications');
          break;

        case 'message':
          final conversationId = data['conversationId'] as String?;
          if (conversationId != null) {
            _router!.go('/messages/$conversationId');
          } else {
            _router!.go('/messages');
          }
          break;

        case 'profile':
          final userId = data['userId'] as String?;
          if (userId != null) {
            _router!.go('/profile/$userId');
          }
          break;

        case 'post':
          final hubId = data['hubId'] as String?;
          final postId = data['postId'] as String?;
          if (hubId != null && postId != null) {
            _router!.go('/hubs/$hubId/feed/$postId');
          }
          break;

        case 'hub_invite':
          final invitationCode = data['code'] as String?;
          if (invitationCode != null) {
            _router!.go('/invite/$invitationCode');
          }
          break;

        case 'game_reminder_2h':
          final gameId = data['gameId'] as String?;
          if (gameId != null) {
            _router!.go('/games/$gameId/confirm-attendance');
          }
          break;

        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }
}
