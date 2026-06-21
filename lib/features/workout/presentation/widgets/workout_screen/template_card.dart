import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/befit_theme_extension.dart';

class TemplateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final bool dense;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const TemplateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    this.dense = false,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final showMenu = onEdit != null && onDuplicate != null && onDelete != null;
    final width = dense ? double.infinity : 240.0;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.customColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 
                    Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.04,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.2,
                          ),
                          maxLines: dense ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showMenu) ...[
                        const SizedBox(width: 10),
                        _TemplateMenu(
                          onEdit: onEdit!,
                          onDuplicate: onDuplicate!,
                          onDelete: onDelete!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle.isNotEmpty ? subtitle : 'No exercises',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    maxLines: dense ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meta,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
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

class _TemplateMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _TemplateMenu({
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TemplateAction>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.customColors.surfaceElevated
              : const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.customColors.border),
        ),
        child: Center(
          child: Icon(
            Icons.more_horiz_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
      onSelected: (action) {
        switch (action) {
          case _TemplateAction.edit:
            onEdit();
          case _TemplateAction.duplicate:
            onDuplicate();
          case _TemplateAction.delete:
            onDelete();
        }
      },
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _TemplateAction.edit,
          child: _MenuRow(icon: Icons.edit_rounded, label: 'Edit'),
        ),
        const PopupMenuItem(
          value: _TemplateAction.duplicate,
          child: _MenuRow(icon: Icons.copy_rounded, label: 'Duplicate'),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: _TemplateAction.delete,
          child: _MenuRow(icon: Icons.delete_rounded, label: 'Delete', color: Colors.redAccent),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: c,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

enum _TemplateAction { edit, duplicate, delete }
