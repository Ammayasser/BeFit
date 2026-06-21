// lib/features/profile/presentation/screens/account_settings_screen.dart


import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/befit_theme_extension.dart';


class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, 'Security'),
          const SizedBox(height: 12),
          _buildCard(context, [
            _buildTile(
              context,
              'Change Password',
              PhosphorIcons.lock(),
              onTap: () {},
            ),
            _buildDivider(context),
            _buildTile(
              context,
              'Two-Factor Authentication',
              PhosphorIcons.shieldCheck(),
              trailing: Text(
                'Off',
                style: GoogleFonts.montserrat(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Data Management'),
          const SizedBox(height: 12),
          _buildCard(context, [
            _buildTile(
              context,
              'Export My Data',
              PhosphorIcons.export(),
              onTap: () {},
            ),
            _buildDivider(context),
            _buildTile(
              context,
              'Clear Cache',
              PhosphorIcons.trash(),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Account Action'),
          const SizedBox(height: 12),
          _buildCard(context, [
            _buildTile(
              context,
              'Deactivate Account',
              PhosphorIcons.userMinus(),
              onTap: () {},
            ),
            _buildDivider(context),
            _buildTile(
              context,
              'Delete Account',
              PhosphorIcons.userCircleMinus(),
              color: context.customColors.failure,
              onTap: () => _showDeleteDialog(context),
            ),
          ]),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon, {
    Color? color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Open $title',
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: PhosphorIcon(
            icon,
            size: 20,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        trailing:
            trailing ??
            PhosphorIcon(
              PhosphorIcons.caretRight(),
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Divider(
    height: 1,
    indent: 64,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
  );

  void _showDeleteDialog(BuildContext context) {
    final failureColor = context.customColors.failure;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you absolutely sure? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {},
            child: Text('Delete', style: GoogleFonts.inter(color: failureColor)),
          ),
        ],
      ),
    );
  }
}
