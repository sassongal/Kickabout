import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/data/repositories_providers.dart';

/// Login screen with anonymous sign in
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isAnonymousLoading = false;
  bool _obscurePassword = true;
  bool _showEmailPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(context, 'Firebase לא זמין. אנא הגדר Firebase.');
      return;
    }

    setState(() {
      _isAnonymousLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInAnonymously();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'התחברת בהצלחה!');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnonymousLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(context, 'Firebase לא זמין. אנא הגדר Firebase.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'התחברת בהצלחה!');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'שגיאה בהתחברות';
        if (e.toString().contains('user-not-found') ||
            e.toString().contains('wrong-password')) {
          errorMessage = 'אימייל או סיסמה שגויים';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'אימייל לא תקין';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'החשבון הושבת';
        }
        SnackbarHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      SnackbarHelper.showWarning(context, 'נא להזין אימייל');
      return;
    }

    if (!_emailController.text.contains('@')) {
      SnackbarHelper.showWarning(context, 'נא להזין אימייל תקין');
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'נשלח אימייל לאיפוס סיסמה',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'התחברות',
      showBackButton: false,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo/Icon
                Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                
                // App Name
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'ארגן משחקי כדורגל עם חברים',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Limited Mode Banner
                if (Env.limitedMode)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'מצב מוגבל: Firebase לא מוגדר',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Toggle between anonymous and email/password
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('כניסה אנונימית'),
                      icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('מייל/סיסמה'),
                      icon: Icon(Icons.email),
                    ),
                  ],
                  selected: {_showEmailPassword},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _showEmailPassword = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (_showEmailPassword) ...[
                  // Email/Password Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'אימייל',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'נא להזין אימייל';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'נא להזין אימייל תקין';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'סיסמה',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signInWithEmailPassword(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'נא להזין סיסמה';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: const Text('שכחת סיסמה?'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign in button
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithEmailPassword,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: Text(_isLoading ? 'מתחבר...' : 'התחבר'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Register link
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('אין לך חשבון? הירשם'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Anonymous Sign In Button
                  ElevatedButton.icon(
                    onPressed: _isAnonymousLoading || !Env.isFirebaseAvailable
                        ? null
                        : _signInAnonymously,
                    icon: _isAnonymousLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_outline),
                    label: Text(
                        _isAnonymousLoading ? 'מתחבר...' : 'כניסה אנונימית'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Text
                  Text(
                    'כניסה אנונימית מאפשרת לך להשתמש באפליקציה ללא יצירת חשבון',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

