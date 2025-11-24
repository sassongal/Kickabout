import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart' as app_models;
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:intl/intl.dart';

/// Manager Inbox - Approve/Deny Join Requests
class HubManageRequestsScreen extends ConsumerWidget {
  final String hubId;

  const HubManageRequestsScreen({
    super.key,
    required this.hubId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = FirebaseFirestore.instance;
    final requestsStream = firestore
        .collection('hubs')
        .doc(hubId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return AppScaffold(
      title: 'בקשות הצטרפות',
      body: StreamBuilder<QuerySnapshot>(
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
            return FuturisticEmptyState(
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
                hubId: hubId,
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
      ),
    );
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
        final memberIds = List<String>.from(hubData['memberIds'] ?? []);
        
        // Check if user is already a member
        if (memberIds.contains(widget.userId)) {
          // User already a member, just update request status
          final requestRef = hubRef.collection('requests').doc(widget.requestId);
          transaction.update(requestRef, {
            'status': 'approved',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': currentUserId,
          });
          return;
        }

        // 2. Add user to memberIds
        memberIds.add(widget.userId);
        
        // 3. Update memberJoinDates
        final memberJoinDates = Map<String, dynamic>.from(hubData['memberJoinDates'] ?? {});
        memberJoinDates[widget.userId] = FieldValue.serverTimestamp();

        // 4. Set role to 'player' (or 'member')
        final roles = Map<String, dynamic>.from(hubData['roles'] ?? {});
        roles[widget.userId] = 'player';

        // 5. Update hub
        transaction.update(hubRef, {
          'memberIds': memberIds,
          'memberJoinDates': memberJoinDates,
          'roles': roles,
        });

        // 6. Update request status
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
                    email: '', // Required field, but not available from request data
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.createdAt != null)
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm', 'he').format(widget.createdAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        icon: const Icon(Icons.check_circle, color: Colors.green),
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

