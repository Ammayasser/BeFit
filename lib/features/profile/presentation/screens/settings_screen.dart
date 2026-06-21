// lib/features/profile/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../features/progress/presentation/providers/progress_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(context, 'Account Settings', [
            _buildSettingTile(context, 'Change Password', PhosphorIcons.lock()),
            _buildSettingTile(context, 'Notifications', PhosphorIcons.bell()),
            _buildSettingTile(context, 'Privacy Policy', PhosphorIcons.shield()),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'Preferences', [
            _buildSettingTile(context, 'Language', PhosphorIcons.globe()),
            _buildSettingTile(
              context,
              'Units (Metric/Imperial)',
              PhosphorIcons.ruler(),
              subtitle: context.watch<ProgressProvider>().weightUnit == 'kg' ? 'Metric (kg)' : 'Imperial (lbs)',
              onTap: () {
                final progress = context.read<ProgressProvider>();
                if (progress.weightUnit == 'kg') {
                  progress.setWeightUnit('lbs');
                } else {
                  progress.setWeightUnit('kg');
                }
              },
            ),
            _buildSettingTile(
              context,
              'Appearance',
              themeProvider.themeMode == ThemeMode.light
                  ? PhosphorIcons.sun()
                  : themeProvider.themeMode == ThemeMode.dark
                      ? PhosphorIcons.moon()
                      : PhosphorIcons.deviceMobile(),
              subtitle: _getThemeModeLabel(themeProvider.themeMode),
              onTap: () => _showAppearanceBottomSheet(context),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'App Info', [
            _buildSettingTile(context, 'App Version', PhosphorIcons.info(),
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )),
            _buildSettingTile(context, 'Terms of Service', PhosphorIcons.fileText()),
          ]),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
      case ThemeMode.system:
        return 'System Theme';
    }
  }

  void _showAppearanceBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose Light, Dark, or System Theme',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption(
              context,
              'Light',
              ThemeMode.light,
              PhosphorIcons.sun(),
              themeProvider.themeMode == ThemeMode.light,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              'Dark',
              ThemeMode.dark,
              PhosphorIcons.moon(),
              themeProvider.themeMode == ThemeMode.dark,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              'System',
              ThemeMode.system,
              PhosphorIcons.deviceMobile(),
              themeProvider.themeMode == ThemeMode.system,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    PhosphorIconData icon,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        context.read<ThemeProvider>().setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              PhosphorIcon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    PhosphorIconData icon, {
    Widget? trailing,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Open $title',
      child: ListTile(
        leading: PhosphorIcon(
          icon,
          color: theme.colorScheme.primary,
          size: 22,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing ??
            PhosphorIcon(
              PhosphorIcons.caretRight(),
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
        onTap: onTap,
      ),
    );
  }
}
