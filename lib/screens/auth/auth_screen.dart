import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();
  final _signupConfirm = TextEditingController();
  DateTime? _birthDate; // Date of Birth for age validation

  bool _loginObscure = true;
  bool _signupObscure = true;
  bool _signupConfirmObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    _signupConfirm.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _loginEmail.text.trim(),
        _loginPassword.text.trim(),
      );
      await AnalyticsService().logLogin(loginMethod: 'email');
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'התחברות נכשלה: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    if (_signupPassword.text.trim() != _signupConfirm.text.trim()) {
      SnackbarHelper.showError(context, 'הסיסמאות אינן תואמות');
      return;
    }
    
    // ✅ Age validation - minimum 13 years old
    if (_birthDate == null) {
      SnackbarHelper.showError(context, 'נא לבחור תאריך לידה');
      return;
    }
    if (!AgeUtils.isAgeValid(_birthDate!)) {
      final age = AgeUtils.calculateAge(_birthDate!);
      SnackbarHelper.showError(
        context, 
        'גיל מינימלי להרשמה: ${AgeUtils.minimumAge} שנים (הגיל שלך: $age)'
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      final cred = await authService.createUserWithEmailAndPassword(
        _signupEmail.text.trim(),
        _signupPassword.text.trim(),
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw Exception('שגיאה ביצירת משתמש');
      }

      final user = User(
        uid: uid,
        name: _signupName.text.trim(),
        email: _signupEmail.text.trim(),
        birthDate: _birthDate!, // ✅ Save birth date (validated above)
        createdAt: DateTime.now(),
        isProfileComplete: false,
      );
      await usersRepo.setUser(user);
      await AnalyticsService().logSignUp(signUpMethod: 'email');

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'ההרשמה הצליחה! המשך בהשלמת הפרופיל');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בהרשמה: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
        leading: AppBarHomeLogo(showBackButton: canPop),
        title: const Text('Kattrick'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'התחברות'),
            Tab(text: 'הרשמה'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AuthCard(
                formKey: _loginFormKey,
                children: [
                  _TextField(
                    controller: _loginEmail,
                    label: 'אימייל',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'נא להזין אימייל' : null,
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _loginPassword,
                    label: 'סיסמה',
                    obscure: _loginObscure,
                    toggle: () =>
                        setState(() => _loginObscure = !_loginObscure),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'נא להזין סיסמה' : null,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          SnackbarHelper.showInfo(context, 'בקרוב: איפוס סיסמה'),
                      child: const Text('שכחת סיסמה?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: 'התחבר',
                    onPressed: _isLoading ? null : _signIn,
                  ),
                ],
              ),
              _AuthCard(
                formKey: _signupFormKey,
                children: [
                  _TextField(
                    controller: _signupName,
                    label: 'שם מלא',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'נא להזין שם' : null,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _signupEmail,
                    label: 'אימייל',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'נא להזין אימייל' : null,
                  ),
                  const SizedBox(height: 12),
                  // ✅ Date of Birth Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: AgeUtils.maxBirthDateForMinAge,
                        firstDate: DateTime(1940),
                        lastDate: AgeUtils.maxBirthDateForMinAge,
                        helpText: 'בחר תאריך לידה',
                        cancelText: 'ביטול',
                        confirmText: 'אישור',
                      );
                      if (date != null) {
                        setState(() => _birthDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _birthDate == null
                              ? Colors.red.withOpacity(0.5)
                              : Colors.green.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cake_outlined,
                              color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 12),
                          Text(
                            _birthDate == null
                                ? 'תאריך לידה (חובה) *'
                                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(
                                  _birthDate == null ? 0.5 : 1.0),
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_birthDate != null)
                            Text(
                              'גיל: ${AgeUtils.calculateAge(_birthDate!)}',
                              style: TextStyle(
                                color: Colors.green.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _signupPassword,
                    label: 'סיסמה',
                    obscure: _signupObscure,
                    toggle: () =>
                        setState(() => _signupObscure = !_signupObscure),
                    validator: (v) => v != null && v.length >= 6
                        ? null
                        : 'סיסמה צריכה להיות לפחות 6 תווים',
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _signupConfirm,
                    label: 'אימות סיסמה',
                    obscure: _signupConfirmObscure,
                    toggle: () => setState(
                        () => _signupConfirmObscure = !_signupConfirmObscure),
                    validator: (v) =>
                        v != null && v.isNotEmpty ? null : 'נא לאמת סיסמה',
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: 'הירשם',
                    onPressed: _isLoading ? null : _signUp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  const _AuthCard({required this.formKey, required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback toggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.toggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
