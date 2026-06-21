// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/content_wrapper.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import 'package:befit/features/auth/presentation/providers/auth_provider.dart';
import 'package:befit/features/profile/presentation/providers/user_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_submit_button.dart';

/// Screen responsible for authenticating existing users.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _autoValidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (auth.isAuthenticated) {
      await context.read<UserProvider>().loadProfile();
      if (!mounted) return;
      context.go(AppRoutes.home);
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
                      AuthBackButton(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go(AppRoutes.onboarding);
                          }
                        },
                      ),

                      SizedBox(height: 32 * s),

                      // Logo
                      const AppLogo(size: 64, animate: true),

                      SizedBox(height: 24 * s),

                      // Header Text
                      Text(
                        "Login account",
                        style: GoogleFonts.montserrat(
                          fontSize: Responsive.fontScale(context, 28),
                          fontWeight: FontWeight.w800,
                          color: theme.setupTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      Text(
                        "Welcome back! Sign in to continue your journey.",
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
                          return null;
                        },
                      ),

                      SizedBox(height: 20 * s),

                      // Password Field
                      AuthTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: 'Password',
                        hint: 'Enter password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(auth),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 12 * s),

                      // Keep logged in & Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: true,
                                  onChanged: (_) {},
                                  activeColor: theme.setupPrimary,
                                  checkColor: theme.setupOnPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Text(
                                'Keep me logged in',
                                style: GoogleFonts.montserrat(
                                  color: theme.setupTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.montserrat(
                                color: theme.setupTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32 * s),

                      // Submit Action Button
                      AuthSubmitButton(
                        label: 'Login',
                        isLoading: isLoading,
                        onSubmit: () => _submit(auth),
                      ),

                      SizedBox(height: 32 * s),

                      // Navigation Link
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.setup),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.montserrat(
                                color: theme.setupTextSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Sign up",
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
