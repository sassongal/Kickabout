import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/services/analytics_service.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';

/// Register screen with email/password
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
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
      final usersRepo = ref.read(usersRepositoryProvider);

      // Create user account
      final userCredential = await authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      // Create user document in Firestore
      final user = User(
        uid: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
      );

      await usersRepo.setUser(user);

      // Log analytics
      try {
        final analytics = AnalyticsService();
        await analytics.logSignUp(signUpMethod: 'email');
      } catch (e) {
        debugPrint('Failed to log analytics: $e');
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'החשבון נוצר בהצלחה!');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'שגיאה ביצירת חשבון';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'האימייל כבר בשימוש';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'הסיסמה חלשה מדי';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'אימייל לא תקין';
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'הרשמה',
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
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

                  // Title
                  Text(
                    'צור חשבון חדש',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'שם מלא',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'נא להזין שם';
                      }
                      if (value.trim().length < 2) {
                        return 'השם חייב להכיל לפחות 2 תווים';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'אימייל',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
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
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא להזין סיסמה';
                      }
                      if (value.length < 6) {
                        return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'אימות סיסמה',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא לאמת את הסיסמה';
                      }
                      if (value != _passwordController.text) {
                        return 'הסיסמאות לא תואמות';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(_isLoading ? 'יוצר חשבון...' : 'צור חשבון'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('יש לך כבר חשבון? התחבר'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

