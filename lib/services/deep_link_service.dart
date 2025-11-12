import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Service for handling deep links from push notifications
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  GoRouter? _router;

  /// Initialize with navigator key and router
  void initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    GoRouter? router,
  }) {
    _navigatorKey = navigatorKey;
    _router = router;
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

        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }
}

