import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/routing/app_router.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Debug screen to display authentication status
class AuthStatusScreen extends ConsumerWidget {
  const AuthStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final firebaseUser = authService.currentUser;
    final isAuthenticated = authService.isAuthenticated;
    final isAnonymous = authService.isAnonymous;
    final currentUserId = authService.currentUserId;

    // Watch auth state changes
    final authState = ref.watch(authStateProvider);

    return FuturisticScaffold(
      title: 'סטטוס אימות',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authentication Status Card
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAuthenticated ? Icons.check_circle : Icons.cancel,
                        color: isAuthenticated ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'סטטוס אימות',
                        style: FuturisticTypography.heading3.copyWith(
                          color: FuturisticColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'מאומת',
                    isAuthenticated ? 'כן ✅' : 'לא ❌',
                    isAuthenticated ? Colors.green : Colors.red,
                  ),
                  _buildStatusRow(
                    'משתמש אנונימי',
                    isAnonymous ? 'כן' : 'לא',
                    isAnonymous ? Colors.orange : Colors.grey,
                  ),
                  _buildStatusRow(
                    'User ID',
                    currentUserId ?? 'לא זמין',
                    currentUserId != null ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),

            // Firebase User Details
            if (firebaseUser != null)
              FuturisticCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'פרטי משתמש Firebase',
                      style: FuturisticTypography.heading3.copyWith(
                        color: FuturisticColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('UID', firebaseUser.uid),
                    if (firebaseUser.email != null)
                      _buildDetailRow('Email', firebaseUser.email!),
                    if (firebaseUser.displayName != null)
                      _buildDetailRow(
                          'Display Name', firebaseUser.displayName!),
                    if (firebaseUser.phoneNumber != null)
                      _buildDetailRow('Phone', firebaseUser.phoneNumber!),
                    _buildDetailRow(
                      'Email Verified',
                      firebaseUser.emailVerified ? 'כן ✅' : 'לא ❌',
                    ),
                    _buildDetailRow(
                      'Anonymous',
                      firebaseUser.isAnonymous ? 'כן' : 'לא',
                    ),
                    if (firebaseUser.metadata.creationTime != null)
                      _buildDetailRow(
                        'Created At',
                        firebaseUser.metadata.creationTime!
                            .toString()
                            .substring(0, 19),
                      ),
                    if (firebaseUser.metadata.lastSignInTime != null)
                      _buildDetailRow(
                        'Last Sign In',
                        firebaseUser.metadata.lastSignInTime!
                            .toString()
                            .substring(0, 19),
                      ),
                    if (firebaseUser.providerData.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Providers:',
                        style: FuturisticTypography.labelLarge.copyWith(
                          color: FuturisticColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...firebaseUser.providerData.map((info) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              '• ${info.providerId}${info.email != null ? " (${info.email})" : ""}',
                              style: FuturisticTypography.bodySmall.copyWith(
                                color: FuturisticColors.textSecondary,
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),

            // Auth State Stream Status
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auth State Stream',
                    style: FuturisticTypography.heading3.copyWith(
                      color: FuturisticColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  authState.when(
                    data: (user) => _buildStatusRow(
                      'Stream Status',
                      user != null ? 'מחובר ✅' : 'לא מחובר ❌',
                      user != null ? Colors.green : Colors.red,
                    ),
                    loading: () => _buildStatusRow(
                      'Stream Status',
                      'טוען...',
                      Colors.orange,
                    ),
                    error: (error, stack) => _buildStatusRow(
                      'Stream Status',
                      'שגיאה: $error',
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'פעולות',
                    style: FuturisticTypography.heading3.copyWith(
                      color: FuturisticColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAuthenticated)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await authService.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('התנתקת בהצלחה'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('שגיאה בהתנתקות: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('התנתק'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuturisticColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('התחבר'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuturisticColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FuturisticTypography.bodyMedium.copyWith(
              color: FuturisticColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: FuturisticTypography.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FuturisticTypography.labelSmall.copyWith(
              color: FuturisticColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: FuturisticTypography.bodyMedium.copyWith(
              color: FuturisticColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
