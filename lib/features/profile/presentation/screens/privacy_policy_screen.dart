// lib/features/profile/presentation/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, 'Last Updated: May 2026'),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Data We Collect',
              'We collect information you provide directly to us, such as your name, email, physical metrics (height, weight, etc.), and fitness goals. We also collect data about your workouts, meal logs, and achievement progress.',
            ),
            _buildSection(
              context,
              '2. How We Use Data',
              'Your data is used solely to provide a personalized fitness experience, calculate health metrics like BMI, track your progress over time, and provide intelligent workout recommendations.',
            ),
            _buildSection(
              context,
              '3. Data Sharing',
              'We do not sell your personal data to third parties. Your data is strictly private and stored securely on our servers.',
            ),
            _buildSection(
              context,
              '4. Your Rights',
              'You have the right to access, correct, or delete your personal data at any time through the Account Settings section of this app.',
            ),
            _buildSection(
              context,
              '5. Security',
              'We implement industry-standard security measures to protect your information from unauthorized access or disclosure.',
            ),
            const SizedBox(height: 40),
            Text(
              'If you have any questions about this Privacy Policy, please contact our support team.',
              style: GoogleFonts.montserrat(
                fontSize: 13, 
                color: theme.colorScheme.onSurfaceVariant, 
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 14, 
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), 
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18, 
              fontWeight: FontWeight.w800, 
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.montserrat(
              fontSize: 15, 
              color: theme.colorScheme.onSurface, 
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
