// lib/features/progress/presentation/widgets/progress_photo_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/progress_provider.dart';

class ProgressPhotoSheet extends StatefulWidget {
  const ProgressPhotoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProgressPhotoSheet(),
    );
  }

  @override
  State<ProgressPhotoSheet> createState() => _ProgressPhotoSheetState();
}

class _ProgressPhotoSheetState extends State<ProgressPhotoSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String _category = 'front'; // 'front', 'side', 'back', 'other'
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.selectionClick();
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1440,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('ProgressPhotoSheet: Error picking image: $e');
    }
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _save() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select or capture a photo first.'),
          backgroundColor: context.customColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final progressProvider = context.read<ProgressProvider>();

      // Check if a weight log exists on the chosen date to link them
      String? matchedWeightLogId;
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      for (final log in progressProvider.allLogs) {
        final logDateOnly = DateTime(
          log.loggedAt.year,
          log.loggedAt.month,
          log.loggedAt.day,
        );
        if (selectedDateOnly.isAtSameMomentAs(logDateOnly)) {
          matchedWeightLogId = log.id;
          break;
        }
      }

      await progressProvider.addProgressPhoto(
        _imageFile!,
        _category,
        _selectedDate,
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        weightLogId: matchedWeightLogId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Progress photo saved successfully.'),
            backgroundColor: context.customColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving photo: $e'),
            backgroundColor: context.customColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final bottomSafe = MediaQuery.of(context).viewInsets.bottom;
    final progressProvider = context.watch<ProgressProvider>();

    // Check if there is an existing weight log for the selected date
    double? linkedWeight;
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    for (final log in progressProvider.allLogs) {
      final logDateOnly = DateTime(
        log.loggedAt.year,
        log.loggedAt.month,
        log.loggedAt.day,
      );
      if (selectedDateOnly.isAtSameMomentAs(logDateOnly)) {
        linkedWeight = progressProvider.toDisplayWeight(log.weightKg);
        break;
      }
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? custom.surfaceElevated : theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark
                  ? custom.border
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.paddingOf(context).bottom + 24 + bottomSafe,
          ),
          child: Material(
            color: Colors.transparent,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Progress Photo',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: PhosphorIcon(PhosphorIcons.x()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Image Selector / Preview Container
                    GestureDetector(
                      onTap: () => _showImageSourcePicker(),
                      child: Container(
                        height: Responsive.isTablet(context) ? 320 : 240,
                        decoration: BoxDecoration(
                          color: isDark
                              ? custom.surfaceCard
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.04,
                                ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            width: 1.5,
                            style: _imageFile == null
                                ? BorderStyle.solid
                                : BorderStyle.none,
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_imageFile!, fit: BoxFit.cover),
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.cached_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Change Photo',
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to Take or Upload Photo',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'JPG or PNG format, up to 10MB',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Selector Labels
                    Text(
                      'Photo Angle / Category',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildCategoryChip('front', 'Front'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('side', 'Side'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('back', 'Back'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('other', 'Other'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date Selector Tile
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? custom.surfaceCard
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? custom.border
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.15,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.calendar(),
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Date Taken',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('MMMM d, y').format(_selectedDate),
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PhosphorIcon(
                                  PhosphorIcons.caretRight(),
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Linked weight status indicator
                    if (linkedWeight != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              color: custom.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Will link to weight log on this date (${linkedWeight.toStringAsFixed(1)} ${progressProvider.weightUnit})',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: custom.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Describe physical changes or feelings...',
                        labelStyle: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        hintStyle: GoogleFonts.montserrat(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: isDark
                              ? custom.bgPrimary
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Progress Photo',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String categoryValue, String label) {
    final theme = Theme.of(context);
    final isSelected = _category == categoryValue;
    final isSmall = Responsive.screenWidth(context) < 360;

    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        onSelected: (selected) {
          if (selected) {
            HapticFeedback.selectionClick();
            setState(() {
              _category = categoryValue;
            });
          }
        },
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showImageSourcePicker() {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? custom.surfaceElevated
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose Image Source',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Camera',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gallery',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
