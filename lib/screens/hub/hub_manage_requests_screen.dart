import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart' as app_models;
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Manager Inbox - Approve/Deny Join Requests + Contact Messages
class HubManageRequestsScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubManageRequestsScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<HubManageRequestsScreen> createState() =>
      _HubManageRequestsScreenState();
}

class _HubManageRequestsScreenState
    extends ConsumerState<HubManageRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'אינבוקס',
        body: Column(
          children: [
            // Tab Bar
            const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.person_add),
                  text: 'בקשות הצטרפות',
                ),
                Tab(
                  icon: Icon(Icons.chat),
                  text: 'הודעות קשר',
                ),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildJoinRequestsList(),
                  _buildContactMessagesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRequestsList() {
    final firestore = FirebaseFirestore.instance;
    final requestsStream = firestore
        .collection('hubs')
        .doc(widget.hubId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FuturisticLoadingState(message: 'טוען בקשות...');
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה',
            message: 'שגיאה בטעינת בקשות: ${snapshot.error}',
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const FuturisticEmptyState(
            icon: Icons.inbox,
            title: 'אין בקשות ממתינות',
            message: 'כל הבקשות טופלו',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestDoc = requests[index];
            final requestData = requestDoc.data() as Map<String, dynamic>;

            return _RequestCard(
              hubId: widget.hubId,
              requestId: requestDoc.id,
              userId: requestData['userId'] as String,
              userName: requestData['userName'] as String? ?? 'משתמש לא ידוע',
              userPhotoUrl: requestData['userPhotoUrl'] as String?,
              message: requestData['message'] as String?,
              createdAt: (requestData['createdAt'] as Timestamp?)?.toDate(),
            );
          },
        );
      },
    );
  }

  Widget _buildContactMessagesList() {
    return StreamBuilder<List<app_models.ContactMessage>>(
      stream:
          ref.read(hubsRepositoryProvider).streamContactMessages(widget.hubId),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 120),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת הודעות',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Hub Inbox - Contact Messages',
            ),
            action: ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        // Empty state
        if (messages.isEmpty) {
          return const FuturisticEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'אין הודעות עדיין',
            message: 'כשמישהו יתעניין להצטרף דרך פוסט גיוס, ההודעות יופיעו כאן',
          );
        }

        // Messages list
        return ListView.builder(
          itemCount: messages.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final message = messages[index];
            return _ContactMessageCard(
              message: message,
              onMarkAsRead: () => _markMessageAsRead(message),
              onReply: () => _replyToMessage(message),
            );
          },
        );
      },
    );
  }

  Future<void> _markMessageAsRead(app_models.ContactMessage message) async {
    try {
      await ref.read(hubsRepositoryProvider).updateContactMessageStatus(
            hubId: widget.hubId,
            messageId: message.messageId,
            status: 'read',
          );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הודעה סומנה כנקראה');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה: $e');
      }
    }
  }

  Future<void> _replyToMessage(app_models.ContactMessage message) async {
    // Update status to 'replied'
    try {
      await ref.read(hubsRepositoryProvider).updateContactMessageStatus(
            hubId: widget.hubId,
            messageId: message.messageId,
            status: 'replied',
          );
    } catch (e) {
      debugPrint('Error updating status: $e');
    }

    // Navigate to private chat with sender
    if (mounted) {
      // TODO: Implement navigation to chat when private messaging is ready
      SnackbarHelper.showInfo(
          context, 'צ\'אט פרטי בפיתוח - ניתן ליצור קשר בטלפון');
    }
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final String hubId;
  final String requestId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? message;
  final DateTime? createdAt;

  const _RequestCard({
    required this.hubId,
    required this.requestId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.message,
    this.createdAt,
  });

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isProcessing = false;

  Future<void> _approveRequest() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final notificationsRepo = ref.read(notificationsRepositoryProvider);
      final firestore = FirebaseFirestore.instance;
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      // Transaction: Add user to hub and update request status
      await firestore.runTransaction((transaction) async {
        // 1. Get hub document
        final hubRef = firestore.collection('hubs').doc(widget.hubId);
        final hubDoc = await transaction.get(hubRef);

        if (!hubDoc.exists) {
          throw Exception('Hub לא נמצא');
        }

        final hubData = hubDoc.data()!;
        final memberCount = hubData['memberCount'] as int? ?? 0;

        // Check capacity
        if (memberCount >= 50) {
          throw Exception('ההאב מלא (מקסימום 50 חברים)');
        }

        // Check user
        final userRef = firestore.collection('users').doc(widget.userId);
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('משתמש לא נמצא');

        final userData = userDoc.data()!;
        final userHubIds = List<String>.from(userData['hubIds'] ?? []);

        // Check if user is already a member
        if (userHubIds.contains(widget.hubId)) {
          // User already a member, just update request status
          final requestRef =
              hubRef.collection('requests').doc(widget.requestId);
          transaction.update(requestRef, {
            'status': 'approved',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': currentUserId,
          });
          return;
        }

        // 2. Add to members subcollection
        final memberRef = hubRef.collection('members').doc(widget.userId);
        transaction.set(memberRef, {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'player',
        });

        // 3. Increment memberCount
        transaction.update(hubRef, {
          'memberCount': FieldValue.increment(1),
        });

        // 4. Update user.hubIds
        transaction.update(userRef, {
          'hubIds': FieldValue.arrayUnion([widget.hubId]),
        });

        // 5. Update request status
        final requestRef = hubRef.collection('requests').doc(widget.requestId);
        transaction.update(requestRef, {
          'status': 'approved',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': currentUserId,
        });
      });

      // Get hub name for notification
      final hub = await hubsRepo.getHub(widget.hubId);
      final hubName = hub?.name ?? 'האב';

      // Send welcome notification to user
      final notification = app_models.Notification(
        notificationId: '',
        userId: widget.userId,
        type: 'hub_joined',
        title: 'ברוך הבא ל-$hubName!',
        body: 'הבקשה שלך אושרה. אתה כעת חבר ב-$hubName',
        read: false,
        createdAt: DateTime.now(),
        data: {
          'hubId': widget.hubId,
        },
      );

      await notificationsRepo.createNotification(notification);

      // Invalidate hub cache to refresh state
      await hubsRepo.getHub(widget.hubId, forceRefresh: true);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הבקשה אושרה בהצלחה!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _denyRequest() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('דחיית בקשה'),
        content: const Text('האם אתה בטוח שברצונך לדחות את הבקשה?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('דחה'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      await firestore
          .collection('hubs')
          .doc(widget.hubId)
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': currentUserId,
      });

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הבקשה נדחתה');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                PlayerAvatar(
                  user: app_models.User(
                    uid: widget.userId,
                    name: widget.userName,
                    email:
                        '', // Required field, but not available from request data
                    photoUrl: widget.userPhotoUrl,
                    createdAt: widget.createdAt ?? DateTime.now(),
                  ),
                  size: AvatarSize.md,
                  clickable: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (widget.createdAt != null)
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm', 'he')
                              .format(widget.createdAt!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                    ],
                  ),
                ),
                // Actions
                if (_isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: _approveRequest,
                        tooltip: 'אשר',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: _denyRequest,
                        tooltip: 'דחה',
                      ),
                    ],
                  ),
              ],
            ),
            // Message
            if (widget.message != null && widget.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Contact Message Card Widget
class _ContactMessageCard extends StatelessWidget {
  final app_models.ContactMessage message;
  final VoidCallback onMarkAsRead;
  final VoidCallback onReply;

  const _ContactMessageCard({
    required this.message,
    required this.onMarkAsRead,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = message.status == 'pending';
    final isReplied = message.status == 'replied';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isUnread ? 6 : 2,
      color: isUnread ? Colors.orange.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? Colors.orange.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Player Info + Status
            Row(
              children: [
                // Player Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: message.senderPhotoUrl != null
                      ? NetworkImage(message.senderPhotoUrl!)
                      : null,
                  child: message.senderPhotoUrl == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),

                const SizedBox(width: 14),

                // Player Name & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.senderName ?? 'משתמש',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          // Status Badge
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fiber_manual_record,
                                      size: 8, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'חדש',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isReplied)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check,
                                      size: 12, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'נענה',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Message Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            // Related Post Info (if available)
            if (message.postContent != null &&
                message.postContent!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.post_add, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'הודעה בנוגע ל: ${message.postContent}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                // Reply Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply, size: 19),
                    label: const Text('השב'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Mark as Read Button (only if unread)
                if (isUnread)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMarkAsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('סמן כנקרא'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                // Phone Button (if phone available)
                if (message.senderPhone != null &&
                    message.senderPhone!.isNotEmpty)
                  const SizedBox(width: 10),
                if (message.senderPhone != null &&
                    message.senderPhone!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () async {
                      final url = Uri.parse('tel:${message.senderPhone}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          SnackbarHelper.showError(
                              context, 'לא ניתן לפתוח את אפליקציית הטלפון');
                        }
                      }
                    },
                    tooltip: 'התקשר',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'עכשיו';
    } else if (difference.inHours < 1) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inDays < 1) {
      return 'לפני ${difference.inHours} שעות';
    } else if (difference.inDays < 7) {
      return 'לפני ${difference.inDays} ימים';
    } else {
      return DateFormat('dd/MM/yyyy', 'he').format(time);
    }
  }
}
