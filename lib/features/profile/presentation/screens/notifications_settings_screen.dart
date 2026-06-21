// lib/features/profile/presentation/screens/notifications_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/notification_provider.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: !notificationProvider.isInitialized
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle(context, 'Activity Reminders'),
                const SizedBox(height: 12),
                _buildCard(context, [
                  _buildSwitchTile(
                    context,
                    'Workout Reminders',
                    'Get notified to stay on track with your plan',
                    PhosphorIcons.barbell(),
                    notificationProvider.workoutReminders,
                    (v) => notificationProvider.setWorkoutReminders(v),
                  ),
                  _buildDivider(context),
                  _buildSwitchTile(
                    context,
                    'Meal Reminders',
                    'Friendly nudges to log your nutrition',
                    PhosphorIcons.bowlFood(),
                    notificationProvider.mealReminders,
                    (v) => notificationProvider.setMealReminders(v),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'Social & Progress'),
                const SizedBox(height: 12),
                _buildCard(context, [
                  _buildSwitchTile(
                    context,
                    'Achievement Alerts',
                    'Celebrate your milestones and badges',
                    PhosphorIcons.medal(),
                    notificationProvider.achievementAlerts,
                    (v) => notificationProvider.setAchievementAlerts(v),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'General'),
                const SizedBox(height: 12),
                _buildCard(context, [
                  _buildSwitchTile(
                    context,
                    'App Updates',
                    'New features and performance fixes',
                    PhosphorIcons.rocket(),
                    notificationProvider.appUpdates,
                    (v) => notificationProvider.setAppUpdates(v),
                  ),
                  _buildDivider(context),
                  _buildSwitchTile(
                    context,
                    'Marketing & Tips',
                    'Personalized advice and special offers',
                    PhosphorIcons.megaphone(),
                    notificationProvider.marketing,
                    (v) => notificationProvider.setMarketing(v),
                  ),
                ]),
                const SizedBox(height: 40),
                _buildSectionTitle(context, 'Developer Tools'),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'Test Notification',
                  onPressed: () =>
                      NotificationService.instance.showTestNotification(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Push Token: ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}...aware',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
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

  Widget _buildCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$title switch',
      hint: subtitle,
      child: SwitchListTile.adaptive(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: PhosphorIcon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        activeThumbColor: theme.colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Divider(
    height: 1,
    indent: 64,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
  );
}
