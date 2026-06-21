// lib/features/progress/presentation/widgets/photos_tab_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/progress_photo.dart';
import '../providers/progress_provider.dart';
import '../screens/photo_compare_screen.dart';
import 'progress_photo_sheet.dart';

/// The "Progress Photos" tab content for the Progress Dashboard.
///
/// Shows a filter bar, a compare shortcut card, and a photo grid.
class PhotosTabView extends StatefulWidget {
  const PhotosTabView({super.key});

  @override
  State<PhotosTabView> createState() => _PhotosTabViewState();
}

class _PhotosTabViewState extends State<PhotosTabView> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final filteredPhotos = _filterPhotos(progress.allPhotos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PhotoFilterBar(
          selected: _selectedFilter,
          onChanged: (val) {
            HapticFeedback.selectionClick();
            setState(() => _selectedFilter = val);
          },
        ),
        const SizedBox(height: 24),
        if (progress.allPhotos.isEmpty)
          _EmptyPhotosState()
        else if (filteredPhotos.isEmpty)
          _FilteredEmptyState()
        else ...[
          if (filteredPhotos.length >= 2) ...[
            CompareShortcutCard(
              newest: filteredPhotos.first,
              oldest: filteredPhotos.last,
            ),
            const SizedBox(height: 24),
          ],
          _PhotoGrid(photos: filteredPhotos),
        ],
      ],
    );
  }

  List<ProgressPhoto> _filterPhotos(List<ProgressPhoto> all) {
    if (_selectedFilter == 'all') return all;
    return all
        .where((p) => p.category.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }
}

// ── Filter Bar ───────────────────────────────────────────────────────────────

class _PhotoFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PhotoFilterBar({required this.selected, required this.onChanged});

  static const _filters = [
    ('all', 'All Photos'),
    ('front', 'Front View'),
    ('side', 'Side View'),
    ('back', 'Back View'),
    ('other', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    f.$2,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  selected: selected == f.$1,
                  onSelected: (v) {
                    if (v) onChanged(f.$1);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Empty States ─────────────────────────────────────────────────────────────

class _EmptyPhotosState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.camera(),
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Progress Photos Logged',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Take photos from front, side, and back views to track visual progress over time.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ProgressPhotoSheet.show(context),
            icon: PhosphorIcon(PhosphorIcons.plus()),
            label: const Text('Upload First Photo'),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Text(
          'No photos found in this category.',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Photo Grid ────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<ProgressPhoto> photos;

  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = Responsive.isTablet(context);
        final crossCount = isTablet ? 3 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: photos
              .map(
                (photo) => SizedBox(
                  width: itemWidth,
                  child: PhotoGridCard(photo: photo),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ── Compare Shortcut Card ─────────────────────────────────────────────────────

/// Displays a card prompting the user to compare their first and latest photos.
class CompareShortcutCard extends StatelessWidget {
  final ProgressPhoto newest;
  final ProgressPhoto oldest;

  const CompareShortcutCard({
    super.key,
    required this.newest,
    required this.oldest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.sparkle(),
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transform Comparison',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Analyze your transformation between first and latest entries.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoCompareScreen(
                    initialBefore: oldest,
                    initialAfter: newest,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Compare',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual Photo Card ────────────────────────────────────────────────────

/// A card in the progress photo grid showing the image, date, weight tag,
/// category badge, and a delete action.
class PhotoGridCard extends StatelessWidget {
  final ProgressPhoto photo;

  const PhotoGridCard({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final progress = context.read<ProgressProvider>();

    double? linkedWeightValue;
    if (photo.weightLogId != null) {
      final match = progress.allLogs
          .where((l) => l.id == photo.weightLogId)
          .toList();
      if (match.isNotEmpty) {
        linkedWeightValue = progress.toDisplayWeight(match.first.weightKg);
      }
    }

    return FutureBuilder<String>(
      future: photo.resolveAbsolutePath(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AspectRatio(
            aspectRatio: 0.8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }

        final absPath = snapshot.data!;

        return GestureDetector(
          onTap: () => _showFullImage(context, photo, absPath),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? custom.border
                    : theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PhotoImageArea(
                  absPath: absPath,
                  photo: photo,
                  linkedWeightValue: linkedWeightValue,
                  weightUnit: progress.weightUnit,
                  theme: theme,
                ),
                _PhotoCardDetails(
                  photo: photo,
                  custom: custom,
                  theme: theme,
                  onDelete: () => _confirmDelete(context, photo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullImage(
    BuildContext context,
    ProgressPhoto photo,
    String absPath,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.file(File(absPath), fit: BoxFit.contain),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(context, photo);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(photo.loggedAt),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Angle: ${photo.category.toUpperCase()}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (photo.notes != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          photo.notes!,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ProgressPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Photo',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to permanently delete this progress photo from ${DateFormat('MMMM d, y').format(photo.loggedAt)}?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProgressProvider>().deleteProgressPhoto(photo);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Photo deleted successfully.'),
                  backgroundColor: context.customColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.customColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoImageArea extends StatelessWidget {
  final String absPath;
  final ProgressPhoto photo;
  final double? linkedWeightValue;
  final String weightUnit;
  final ThemeData theme;

  const _PhotoImageArea({
    required this.absPath,
    required this.photo,
    required this.linkedWeightValue,
    required this.weightUnit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(absPath), fit: BoxFit.cover),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(photo.loggedAt),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (linkedWeightValue != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${linkedWeightValue!.toStringAsFixed(1)} $weightUnit',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCardDetails extends StatelessWidget {
  final ProgressPhoto photo;
  final BeFitThemeExtension custom;
  final ThemeData theme;
  final VoidCallback onDelete;

  const _PhotoCardDetails({
    required this.photo,
    required this.custom,
    required this.theme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  photo.category.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDelete();
                },
                child: PhosphorIcon(
                  PhosphorIcons.trash(),
                  size: 14,
                  color: custom.error,
                ),
              ),
            ],
          ),
          if (photo.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              photo.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
