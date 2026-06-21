// lib/features/profile/presentation/screens/edit_profile_screen.dart


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProvider>().profile;
    _nameController = TextEditingController(text: profile?.name);
    _ageController = TextEditingController(text: profile?.age.toString());
    _heightController = TextEditingController(text: profile?.height.toString());
    _weightController = TextEditingController(text: profile?.weight.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(userProvider),
              const SizedBox(height: 40),
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Full Name',
                controller: _nameController,
                hint: 'Enter your name',
                icon: PhosphorIcons.user(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Age',
                      controller: _ageController,
                      hint: 'Age',
                      icon: PhosphorIcons.calendar(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Gender',
                      controller: TextEditingController(
                        text: userProvider.gender,
                      ),
                      hint: 'Gender',
                      icon: PhosphorIcons.genderIntersex(),
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildSectionTitle('Body Metrics'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Height (cm)',
                      controller: _heightController,
                      hint: 'cm',
                      icon: PhosphorIcons.ruler(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Weight (kg)',
                      controller: _weightController,
                      hint: 'kg',
                      icon: PhosphorIcons.scales(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Save Changes',
                isLoading: userProvider.isLoading,
                onPressed: () => _saveProfile(context, userProvider),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserProvider userProvider) {
    final theme = Theme.of(context);
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              backgroundImage: userProvider.profile?.avatarUrl != null
                  ? NetworkImage(userProvider.profile!.avatarUrl!)
                  : null,
              child: userProvider.profile?.avatarUrl == null
                  ? PhosphorIcon(
                      PhosphorIcons.user(),
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 50,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Semantics(
              button: true,
              label: 'Change profile picture',
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker coming soon!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.camera(PhosphorIconsStyle.fill),
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required PhosphorIconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled
                ? theme.colorScheme.surfaceContainerLow
                : theme.colorScheme.surfaceContainer,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: PhosphorIcon(
                icon,
                color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          validator: (value) {
            if (enabled && (value == null || value.isEmpty)) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _saveProfile(BuildContext context, UserProvider provider) async {
    if (_formKey.currentState!.validate()) {
      final currentProfile = provider.profile;
      if (currentProfile == null) return;

      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? currentProfile.age,
        height:
            double.tryParse(_heightController.text) ?? currentProfile.height,
        weight:
            double.tryParse(_weightController.text) ?? currentProfile.weight,
      );

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final failureColor = context.customColors.failure;

      final success = await provider.updateProfile(updatedProfile);
      if (!mounted) return;
      if (success) {
        _showSuccessFeedback();
        navigator.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to update profile'),
            backgroundColor: failureColor,
          ),
        );
      }
    }
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              'Profile updated successfully!',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: context.customColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
