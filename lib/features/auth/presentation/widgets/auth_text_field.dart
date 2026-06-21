// lib/features/auth/presentation/widgets/auth_text_field.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// A professional, focus-aware text field designed for authentication flows.
///
/// Features:
/// - Connects to the custom `BeFitThemeExtension` for unified styling.
/// - Manages obscure/visible password state internally.
/// - Provides dynamic scale sizing using `Responsive`.
/// - Supports semantic labels and accessibility parameters.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = context.customColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4 * s),
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: theme.setupTextPrimary,
              fontSize: Responsive.fontScale(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 8 * s),
        Semantics(
          label: widget.label,
          hint: widget.hint,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            style: GoogleFonts.montserrat(
              color: theme.setupTextPrimary,
              fontSize: Responsive.fontScale(context, 16),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.montserrat(
                color: theme.setupTextSecondary.withValues(alpha: 0.3),
              ),
              prefixIcon: Icon(
                widget.icon,
                color: theme.setupTextSecondary.withValues(alpha: 0.5),
                size: 20 * s,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.setupTextSecondary.withValues(alpha: 0.5),
                        size: 20 * s,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.setupCard,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16 * s,
                vertical: 16 * s,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16 * s),
                borderSide: BorderSide(color: theme.border.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16 * s),
                borderSide: BorderSide(color: theme.border.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16 * s),
                borderSide: BorderSide(
                  color: theme.setupPrimary,
                  width: 1.5,
                ),
              ),
              errorStyle: GoogleFonts.montserrat(
                color: theme.error,
                fontSize: Responsive.fontScale(context, 12),
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}