import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/routing/app_router.dart';
import 'package:kattrick/theme/premium_theme.dart';

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

    return PremiumScaffold(
      title: 'סטטוס אימות',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authentication Status Card
            PremiumCard(
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
                        style: PremiumTypography.heading3.copyWith(
                          color: PremiumColors.textPrimary,
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
              PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'פרטי משתמש Firebase',
                      style: PremiumTypography.heading3.copyWith(
                        color: PremiumColors.textPrimary,
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
                        style: PremiumTypography.labelLarge.copyWith(
                          color: PremiumColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...firebaseUser.providerData.map((info) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              '• ${info.providerId}${info.email != null ? " (${info.email})" : ""}',
                              style: PremiumTypography.bodySmall.copyWith(
                                color: PremiumColors.textSecondary,
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),

            // Auth State Stream Status
            PremiumCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auth State Stream',
                    style: PremiumTypography.heading3.copyWith(
                      color: PremiumColors.textPrimary,
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
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'פעולות',
                    style: PremiumTypography.heading3.copyWith(
                      color: PremiumColors.textPrimary,
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
                        backgroundColor: PremiumColors.error,
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
                        backgroundColor: PremiumColors.primary,
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
            style: PremiumTypography.bodyMedium.copyWith(
              color: PremiumColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: PremiumTypography.bodyMedium.copyWith(
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
            style: PremiumTypography.labelSmall.copyWith(
              color: PremiumColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: PremiumTypography.bodyMedium.copyWith(
              color: PremiumColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
