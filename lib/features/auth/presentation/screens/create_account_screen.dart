// lib/features/auth/presentation/screens/create_account_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/content_wrapper.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import 'package:befit/features/auth/presentation/providers/auth_provider.dart';
import 'package:befit/features/profile/presentation/providers/user_provider.dart';
import 'package:befit/features/setup/presentation/providers/setup_provider.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/auth_success_dialog.dart';

/// Screen responsible for capturing user credentials and completing registration.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _autoValidate = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    final theme = context.customColors;
    setState(() => _autoValidate = true);
    
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must agree to the Terms of Service'),
          backgroundColor: theme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final setup = context.read<SetupProvider>();
    final setupBody = setup.getRegistrationBody();
    final userName = _nameController.text.trim();
    final userEmail = _emailController.text.trim();

    final body = <String, dynamic>{
      ...setupBody,
      'name': userName,
      'email': userEmail,
      'password': _passwordController.text,
    };

    await auth.register(body);
    if (!mounted) return;

    if (auth.isAuthenticated) {
      context.read<UserProvider>().hydrateFromRegistration(
            name: userName,
            email: userEmail,
            setupBody: setupBody,
          );
      AuthSuccessDialog.show(context, userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = context.customColors;

    return Scaffold(
      backgroundColor: theme.setupBg,
      body: SafeArea(
        child: ContentWrapper(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isLoading = auth.status == AuthStatus.loading;

              return Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      AuthBackButton(onTap: () => context.go(AppRoutes.login)),

                      SizedBox(height: 16 * s),

                      // Header Text
                      Text(
                        "Create account",
                        style: GoogleFonts.montserrat(
                          fontSize: Responsive.fontScale(context, 28),
                          fontWeight: FontWeight.w800,
                          color: theme.setupTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Text(
                        "Sign up to continue your fitness journey.",
                        style: GoogleFonts.montserrat(
                          fontSize: Responsive.fontScale(context, 14),
                          color: theme.setupTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24 * s),

                      // Error Banner
                      if (auth.errorMessage != null)
                        AuthErrorBanner(
                          message: auth.errorMessage!,
                          onDismiss: () => auth.clearError(),
                        ),

                      // Username Field
                      AuthTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        label: 'User Name',
                        hint: 'Enter your name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Name is required';
                          return null;
                        },
                      ),

                      SizedBox(height: 20 * s),

                      // Email Field
                      AuthTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: 'Email',
                        hint: 'example@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      SizedBox(height: 20 * s),

                      // Password Field
                      AuthTextField(
                        controller: _passwordController,
                        focusNode: _passFocus,
                        label: 'Password',
                        hint: 'Create password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // Live Password Strength Bar
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _passwordController,
                        builder: (context, value, _) {
                          return PasswordStrengthBar(password: value.text);
                        },
                      ),

                      SizedBox(height: 20 * s),

                      // Confirm Password Field
                      AuthTextField(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        label: 'Confirm password',
                        hint: 'Re-enter password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(auth),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16 * s),

                      // Terms checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (val) {
                                setState(() => _agreeToTerms = val ?? false);
                                HapticFeedback.selectionClick();
                              },
                              activeColor: theme.setupPrimary,
                              checkColor: theme.setupOnPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: GoogleFonts.montserrat(
                                  color: theme.setupTextSecondary,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: GoogleFonts.montserrat(
                                      color: theme.setupTextPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32 * s),

                      // Create Account Button
                      AuthSubmitButton(
                        label: 'Create account',
                        isLoading: isLoading,
                        onSubmit: () => _submit(auth),
                      ),

                      SizedBox(height: 32 * s),

                      // Back to Login link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: GoogleFonts.montserrat(
                                color: theme.setupTextSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: GoogleFonts.montserrat(
                                    color: theme.setupTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40 * s),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
