// lib/features/progress/presentation/widgets/weight_log_sheet.dart

import 'package:befit/features/progress/data/models/weight_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../features/profile/presentation/providers/user_provider.dart';
import '../providers/progress_provider.dart';

class WeightLogSheet extends StatefulWidget {
  final WeightLog? existingLog;

  const WeightLogSheet({super.key, this.existingLog});

  static Future<void> show(BuildContext context, {WeightLog? existingLog}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeightLogSheet(existingLog: existingLog),
    );
  }

  @override
  State<WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<WeightLogSheet> {
  final _formKey = GlobalKey<FormState>();

  late double _weight;
  late DateTime _selectedDate;

  double? _bodyFat;
  double? _muscleMass;
  double? _waist;
  double? _chest;
  double? _hips;
  double? _neck;

  final TextEditingController _notesController = TextEditingController();
  bool _showMeasurements = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProgressProvider>();

    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _weight = provider.toDisplayWeight(log.weightKg);
      _selectedDate = log.loggedAt;
      _bodyFat = log.bodyFatPercentage;
      _muscleMass = log.muscleMassKg != null
          ? provider.toDisplayWeight(log.muscleMassKg!)
          : null; // Weight metric conversions for muscle mass
      _waist = log.waistCm;
      _chest = log.chestCm;
      _hips = log.hipsCm;
      _neck = log.neckCm;
      _notesController.text = log.notes ?? '';
      _showMeasurements = _hasAnyMeasurements(log);
    } else {
      // Default weight is user profile weight or 70.0
      final profileWeight = context.read<UserProvider>().weight;
      _weight = provider.toDisplayWeight(
        profileWeight > 0 ? profileWeight : 70.0,
      );
      _selectedDate = DateTime.now();
      _showMeasurements = false;
    }
  }

  bool _hasAnyMeasurements(WeightLog log) {
    return log.bodyFatPercentage != null ||
        log.muscleMassKg != null ||
        log.waistCm != null ||
        log.chestCm != null ||
        log.hipsCm != null ||
        log.neckCm != null;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _adjustWeight(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _weight = (_weight + amount).clamp(30.0, 660.0);
    });
  }

  Future<void> _pickDate() async {
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
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final userProvider = context.read<UserProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final uid = userProvider.profile?.id ?? 'temp_uid';

    // Convert weight and muscle mass back to kg if units are in lbs
    final weightKg = progressProvider.toStoredWeight(_weight);
    final muscleMassKg = _muscleMass != null
        ? progressProvider.toStoredWeight(_muscleMass!)
        : null;

    final isNew = widget.existingLog == null;
    final log = WeightLog(
      id: widget.existingLog?.id ?? const Uuid().v4(),
      userId: uid,
      weightKg: weightKg,
      bodyFatPercentage: _bodyFat,
      muscleMassKg: muscleMassKg,
      waistCm: _waist,
      chestCm: _chest,
      hipsCm: _hips,
      neckCm: _neck,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      loggedAt: _selectedDate,
      createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isNew) {
      await progressProvider.addWeightLog(log, userHeight: userProvider.height);
      // Keep profile weight current
      if (userProvider.profile != null) {
        final updatedProfile = userProvider.profile!.copyWith(weight: weightKg);
        await userProvider.updateProfile(updatedProfile);
      }
    } else {
      await progressProvider.updateWeightLog(log);
      // If we are updating the latest log, also keep profile current
      if (progressProvider.latestLog?.id == log.id &&
          userProvider.profile != null) {
        final updatedProfile = userProvider.profile!.copyWith(weight: weightKg);
        await userProvider.updateProfile(updatedProfile);
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew ? 'Weight logged successfully' : 'Log updated successfully',
          ),
          backgroundColor: context.customColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final bottomSafe = MediaQuery.of(context).viewInsets.bottom;
    final provider = context.watch<ProgressProvider>();
    final unit = provider.weightUnit;

    // Validation limits
    final double minWeight = provider.weightUnit == 'lbs' ? 66.0 : 30.0;
    final double maxWeight = provider.weightUnit == 'lbs' ? 660.0 : 300.0;

    final isSmallPhone = Responsive.screenWidth(context) < 360;
    final double mainIconSize = isSmallPhone ? 32 : 44;
    final double subIconSize = isSmallPhone ? 20 : 28;
    final double centerPaddingH = isSmallPhone ? 12 : 20;
    final double centerPaddingV = isSmallPhone ? 8 : 12;
    final double weightFontSize = isSmallPhone ? 28 : 38;
    final double unitFontSize = isSmallPhone ? 12 : 16;
    final double centerGap = isSmallPhone ? 4 : 8;

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

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.existingLog == null
                              ? 'Log Weight'
                              : 'Edit Log',
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
                    const SizedBox(height: 24),

                    // Large Weight Picker Display
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _adjustWeight(-1.0),
                            icon: PhosphorIcon(
                              PhosphorIcons.minusCircle(
                                PhosphorIconsStyle.fill,
                              ),
                            ),
                            iconSize: mainIconSize,
                            color: theme.colorScheme.primary,
                          ),
                          IconButton(
                            onPressed: () => _adjustWeight(-0.1),
                            icon: PhosphorIcon(PhosphorIcons.minus()),
                            iconSize: subIconSize,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          SizedBox(width: centerGap),
                          GestureDetector(
                            onTap: () {
                              // Allow direct typing
                              _showDirectWeightEntryDialog(
                                minWeight,
                                maxWeight,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: centerPaddingH,
                                vertical: centerPaddingV,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? custom.surfaceCard
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.05,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _weight.toStringAsFixed(1),
                                    style: GoogleFonts.montserrat(
                                      fontSize: weightFontSize,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    unit,
                                    style: GoogleFonts.montserrat(
                                      fontSize: unitFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: centerGap),
                          IconButton(
                            onPressed: () => _adjustWeight(0.1),
                            icon: PhosphorIcon(PhosphorIcons.plus()),
                            iconSize: subIconSize,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _adjustWeight(1.0),
                            icon: PhosphorIcon(
                              PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
                            ),
                            iconSize: mainIconSize,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logged Date Picker
                    _buildTile(
                      context,
                      title: 'Date',
                      icon: PhosphorIcons.calendar(),
                      trailing: Row(
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
                          PhosphorIcon(PhosphorIcons.caretRight(), size: 16),
                        ],
                      ),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),

                    // Collapsible body measurements
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showMeasurements = !_showMeasurements;
                        });
                      },
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
                                  PhosphorIcons.ruler(),
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Body Measurements',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            PhosphorIcon(
                              _showMeasurements
                                  ? PhosphorIcons.caretUp()
                                  : PhosphorIcons.caretDown(),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showMeasurements) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? custom.surfaceMuted
                              : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Body Fat %',
                                    initialValue: _bodyFat?.toString(),
                                    onChanged: (v) =>
                                        _bodyFat = double.tryParse(v),
                                    validator: (v) {
                                      if (v != null && v.isNotEmpty) {
                                        final num = double.tryParse(v);
                                        if (num == null ||
                                            num < 3 ||
                                            num > 60) {
                                          return '3 - 60%';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Muscle Mass ($unit)',
                                    initialValue: _muscleMass?.toString(),
                                    onChanged: (v) =>
                                        _muscleMass = double.tryParse(v),
                                    validator: (v) {
                                      if (v != null && v.isNotEmpty) {
                                        final num = double.tryParse(v);
                                        if (num == null ||
                                            num < minWeight ||
                                            num > maxWeight) {
                                          return '$minWeight-$maxWeight';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Waist (cm)',
                                    initialValue: _waist?.toString(),
                                    onChanged: (v) =>
                                        _waist = double.tryParse(v),
                                    validator: _measurementValidator,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Chest (cm)',
                                    initialValue: _chest?.toString(),
                                    onChanged: (v) =>
                                        _chest = double.tryParse(v),
                                    validator: _measurementValidator,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Hips (cm)',
                                    initialValue: _hips?.toString(),
                                    onChanged: (v) =>
                                        _hips = double.tryParse(v),
                                    validator: _measurementValidator,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Neck (cm)',
                                    initialValue: _neck?.toString(),
                                    onChanged: (v) =>
                                        _neck = double.tryParse(v),
                                    validator: _measurementValidator,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Notes Input Field
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      maxLength: 140,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add how you felt today...',
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
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _save,
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
                        child: Text(
                          widget.existingLog == null
                              ? 'Save Log'
                              : 'Save Changes',
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

  String? _measurementValidator(String? v) {
    if (v != null && v.isNotEmpty) {
      final num = double.tryParse(v);
      if (num == null || num < 30 || num > 250) return '30 - 250 cm';
    }
    return null;
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? custom.border
                : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                PhosphorIcon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? initialValue,
    required ValueChanged<String> onChanged,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  void _showDirectWeightEntryDialog(double min, double max) {
    final controller = TextEditingController(text: _weight.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter Weight',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: context.read<ProgressProvider>().weightUnit,
            suffixStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
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
              final val = double.tryParse(controller.text);
              if (val != null && val >= min && val <= max) {
                setState(() {
                  _weight = val;
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              'OK',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
