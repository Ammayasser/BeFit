// lib/features/progress/presentation/screens/photo_compare_screen.dart

import 'dart:io';
import 'package:befit/features/progress/data/models/progress_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/widgets/content_wrapper.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/progress_provider.dart';
import '../widgets/interactive_split_slider.dart';

class PhotoCompareScreen extends StatefulWidget {
  final ProgressPhoto? initialBefore;
  final ProgressPhoto? initialAfter;

  const PhotoCompareScreen({super.key, this.initialBefore, this.initialAfter});

  @override
  State<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends State<PhotoCompareScreen> {
  ProgressPhoto? _beforePhoto;
  ProgressPhoto? _afterPhoto;
  bool _useSlider = true; // true = Slider, false = Split View

  @override
  void initState() {
    super.initState();
    _beforePhoto = widget.initialBefore;
    _afterPhoto = widget.initialAfter;
  }

  void _selectPhoto(bool isBefore) {
    HapticFeedback.selectionClick();
    final progressProvider = context.read<ProgressProvider>();
    final allPhotos = progressProvider.allPhotos;

    if (allPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No progress photos available to choose from.'),
        ),
      );
      return;
    }

    // Filter recommendation: if other photo is selected, suggest same category
    final suggestedCategory = isBefore
        ? _afterPhoto?.category
        : _beforePhoto?.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final custom = context.customColors;
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: isDark
                        ? custom.surfaceElevated
                        : theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isBefore
                              ? 'Select Before Photo'
                              : 'Select After Photo',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (suggestedCategory != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Showing same angle: ${suggestedCategory.toUpperCase()}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: allPhotos.length,
                            itemBuilder: (context, idx) {
                              final photo = allPhotos[idx];
                              final isSelected = isBefore
                                  ? _beforePhoto?.id == photo.id
                                  : _afterPhoto?.id == photo.id;
                              final isRecommended =
                                  photo.category == suggestedCategory;

                              return FutureBuilder<String>(
                                future: photo.resolveAbsolutePath(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                    );
                                  }
                                  return InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (isBefore) {
                                          _beforePhoto = photo;
                                        } else {
                                          _afterPhoto = photo;
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            File(snapshot.data!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.4),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 3,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        if (isRecommended && !isSelected)
                                          Positioned(
                                            top: 4,
                                            left: 4,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    theme.colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Match',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    bottom: Radius.circular(12),
                                                  ),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: Text(
                                              DateFormat(
                                                'MMM d',
                                              ).format(photo.loggedAt),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 9,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: custom.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
          icon: PhosphorIcon(
            PhosphorIcons.caretLeft(),
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Compare Photos',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: ContentWrapper(
        child: Column(
          children: [
            // Mode Selectors (Slider / Split-View)
            if (_beforePhoto != null && _afterPhoto != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? custom.surfaceCard
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? custom.border
                          : theme.colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _useSlider = true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _useSlider
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Slider Reveal',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _useSlider
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _useSlider = false);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_useSlider
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Side by Side',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !_useSlider
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Photo Selection Bar / Display Area
            Expanded(
              child: _beforePhoto != null && _afterPhoto != null
                  ? _buildComparisonView()
                  : _buildSetupView(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.squaresFour(),
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Photos to Compare',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Select any two photos (e.g. Front views from January and June) to analyze physical transformation.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSelectorCard(true),
              const SizedBox(width: 16),
              _buildSelectorCard(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard(bool isBefore) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final photo = isBefore ? _beforePhoto : _afterPhoto;

    return GestureDetector(
      onTap: () => _selectPhoto(isBefore),
      child: Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? custom.border
                : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: photo != null
            ? FutureBuilder<String>(
                future: photo.resolveAbsolutePath(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(snapshot.data!), fit: BoxFit.cover),
                        Container(color: Colors.black.withValues(alpha: 0.35)),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isBefore ? 'Before' : 'After',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBefore ? 'Select Before' : 'Select After',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComparisonView() {
    return Column(
      children: [
        // Photo info display with clear buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPhotoInfoCard(true),
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _beforePhoto = null;
                  _afterPhoto = null;
                });
              },
              icon: PhosphorIcon(PhosphorIcons.arrowsCounterClockwise()),
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildPhotoInfoCard(false),
          ],
        ),
        const SizedBox(height: 16),

        // Main compare container
        Expanded(
          child: _useSlider
              ? FutureBuilder<List<String>>(
                  future: Future.wait([
                    _beforePhoto!.resolveAbsolutePath(),
                    _afterPhoto!.resolveAbsolutePath(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return InteractiveSplitSlider(
                      beforeImagePath: snapshot.data![0],
                      afterImagePath: snapshot.data![1],
                    );
                  },
                )
              : _buildSideBySideOrStackedView(),
        ),
      ],
    );
  }

  Widget _buildPhotoInfoCard(bool isBefore) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final photo = isBefore ? _beforePhoto! : _afterPhoto!;

    return GestureDetector(
      onTap: () => _selectPhoto(isBefore),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? custom.border
                : theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isBefore
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              isBefore ? 'Before' : 'After',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d, yyyy').format(photo.loggedAt),
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              photo.category.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySideOrStackedView() {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        _beforePhoto!.resolveAbsolutePath(),
        _afterPhoto!.resolveAbsolutePath(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final pathBefore = snapshot.data![0];
        final pathAfter = snapshot.data![1];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = Responsive.isTablet(context);

            if (isTablet) {
              // Side-by-side on wide screens
              return Row(
                children: [
                  Expanded(child: _buildComparisonImage(pathBefore, 'BEFORE')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildComparisonImage(pathAfter, 'AFTER')),
                ],
              );
            } else {
              // Stacked vertically on phone to maintain details
              return Column(
                children: [
                  Expanded(child: _buildComparisonImage(pathBefore, 'BEFORE')),
                  const SizedBox(width: 10, height: 10),
                  Expanded(child: _buildComparisonImage(pathAfter, 'AFTER')),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildComparisonImage(String absolutePath, String label) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(absolutePath), fit: BoxFit.cover),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
