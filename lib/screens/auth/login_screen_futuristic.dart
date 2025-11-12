import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickabout/widgets/futuristic/gradient_button.dart';
import 'package:kickabout/widgets/futuristic/futuristic_card.dart';
import 'package:kickabout/widgets/kicka_ball_logo.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/data/repositories_providers.dart';

/// Futuristic login screen with seamless one-tap sign-in
class LoginScreenFuturistic extends ConsumerStatefulWidget {
  const LoginScreenFuturistic({super.key});

  @override
  ConsumerState<LoginScreenFuturistic> createState() => _LoginScreenFuturisticState();
}

class _LoginScreenFuturisticState extends ConsumerState<LoginScreenFuturistic>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isAnonymousLoading = false;
  bool _obscurePassword = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(context, 'Firebase not available');
      return;
    }

    setState(() => _isAnonymousLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInAnonymously();

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'התחברות נכשלה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAnonymousLoading = false);
      }
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!Env.isFirebaseAvailable) {
      SnackbarHelper.showError(context, 'Firebase not available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'התחברות נכשלה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPasswordResetDialog(BuildContext context) async {
    final emailController = TextEditingController(text: _emailController.text);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('איפוס סיסמה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('הזן את כתובת האימייל שלך ונשלח לך קישור לאיפוס הסיסמה.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'אימייל',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isEmpty) {
                SnackbarHelper.showError(context, 'נא להזין אימייל');
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('שלח'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.trim().isNotEmpty) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.sendPasswordResetEmail(emailController.text.trim());
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'נשלח קישור לאיפוס סיסמה לכתובת האימייל שלך',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'שגיאה בשליחת אימייל: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'KICKABOUT',
      showBackButton: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: FuturisticColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: KickaBallLogo(
                          size: 140,
                          showText: true,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'ברוכים הבאים',
                    style: FuturisticTypography.techHeadline.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'עתיד הכדורגל',
                    style: FuturisticTypography.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  // One-tap sign-in buttons
                  GradientButton(
                    label: 'המשך כאורח',
                    icon: Icons.person_outline,
                    onPressed: _isAnonymousLoading ? null : _signInAnonymously,
                    isLoading: _isAnonymousLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),
                  
                  GradientButton(
                    label: 'התחבר עם Google',
                    icon: Icons.g_mobiledata,
                    onPressed: () {
                      // TODO: Implement Google Sign In
                      SnackbarHelper.showError(context, 'התחברות עם Google בקרוב');
                    },
                    gradient: FuturisticColors.accentGradient,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),
                  
                  GradientButton(
                    label: 'התחבר עם Apple',
                    icon: Icons.apple,
                    onPressed: () {
                      // TODO: Implement Apple Sign In
                      SnackbarHelper.showError(context, 'התחברות עם Apple בקרוב');
                    },
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.grey[800]!,
                      ],
                    ),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: FuturisticColors.surfaceVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                          'או',
                          style: FuturisticTypography.labelMedium,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: FuturisticColors.surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email/Password form
                  FuturisticCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'אימייל וסיסמה',
                            style: FuturisticTypography.techHeadline.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'אימייל',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'נא להזין אימייל';
                              }
                              if (!value.contains('@')) {
                                return 'אימייל לא תקין';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'סיסמה',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'נא להזין סיסמה';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            label: 'התחבר',
                            icon: Icons.login,
                            onPressed: _isLoading ? null : _signInWithEmailPassword,
                            isLoading: _isLoading,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading ? null : () => _showPasswordResetDialog(context),
                            child: Text(
                              'שכחת סיסמה?',
                              style: FuturisticTypography.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NEW USER? ',
                        style: FuturisticTypography.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(
                          'SIGN UP',
                          style: FuturisticTypography.labelLarge.copyWith(
                            color: FuturisticColors.secondary,
                          ),
                        ),
                      ),
                    ],
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

