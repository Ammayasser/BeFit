// lib/features/profile/presentation/screens/help_support_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/widgets/primary_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(context),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Frequently Asked Questions'),
            const SizedBox(height: 12),
            _buildFAQList(context),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Version 1.0.0 (Build 20260525)',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = context.customColors.success;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.headset(),
              color: successColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'How can we help?',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our support team is available 24/7 to assist you with any issues or feedback.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14, 
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: 'Contact Support button',
            child: PrimaryButton(text: 'Contact Support', onPressed: () {}),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList(BuildContext context) {
    return Column(
      children: [
        _buildFAQItem(
          context,
          'How do I track a workout?',
          'Go to the Workouts tab, select an exercise or routine, and tap "Start Session". The app will guide you through sets and reps.',
        ),
        _buildFAQItem(
          context,
          'Can I sync with other devices?',
          'BeFit currently supports local data storage. Cloud sync and wearable device integration are coming in a future update.',
        ),
        _buildFAQItem(
          context,
          'How are my calories calculated?',
          'Calorie targets are based on your age, gender, height, weight, and activity level using the Mifflin-St Jeor Equation.',
        ),
        _buildFAQItem(
          context,
          'How do I unlock badges?',
          'Achievements are unlocked automatically as you reach milestones in workouts, nutrition logging, and consistency.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.onSurfaceVariant,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: [
          Text(
            answer,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
