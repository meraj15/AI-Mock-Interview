import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/profile_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _expController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>();
    _firstNameController = TextEditingController(text: profile.profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile.profile?.lastName ?? '');
    _phoneController = TextEditingController(text: profile.phone);
    _roleController = TextEditingController(text: profile.targetRole);
    _expController = TextEditingController(
      text: profile.experienceYears?.toString() ?? '',
    );
    _bioController = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profileCtrl = context.read<ProfileController>();

    final expText = _expController.text.trim();
    double? expYears;
    if (expText.isNotEmpty) {
      expYears = double.tryParse(expText);
      if (expYears == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number for experience (e.g. 2.5)')),
        );
        return;
      }
    }

    final success = await profileCtrl.updateProfile(
      firstName: _firstNameController.text.trim().isNotEmpty
          ? _firstNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim().isNotEmpty
          ? _lastNameController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      targetRole: _roleController.text.trim().isNotEmpty
          ? _roleController.text.trim()
          : null,
      experienceYears: expYears,
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileCtrl.errorMessage ?? 'Failed to update profile. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final profileCtrl = context.watch<ProfileController>();

    // Derive initials dynamically as user types
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final nameForInitials = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final initials = nameForInitials.isNotEmpty
        ? nameForInitials
            .split(' ')
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join()
        : 'U';

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Edit Profile',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 16),

          // Avatar (static — no image upload)
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.navy,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTypography.bold(26, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // First Name
          Text('First name', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _firstNameController,
            placeholder: 'Your first name',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Last Name
          Text('Last name', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _lastNameController,
            placeholder: 'Your last name',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Phone
          Text('Phone number', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _phoneController,
            placeholder: 'e.g. +91 9876543210',
          ),

          const SizedBox(height: 14),

          // Target Role
          Text('Target job role', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _roleController,
            placeholder: 'e.g. Flutter Developer, Senior Backend',
          ),

          const SizedBox(height: 14),

          // Experience
          Text('Years of experience', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _expController,
            placeholder: 'e.g. 2.5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),

          const SizedBox(height: 14),

          // Bio
          Text('Professional bio', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _bioController,
            placeholder: 'Tell us a bit about your background and technical focus…',
            multiline: true,
            minLines: 3,
            maxLines: 4,
          ),

          const SizedBox(height: 32),

          AppButton(
            label: profileCtrl.isSaving ? 'Saving…' : 'Save Changes',
            icon: FeatherIcons.check,
            onPress: profileCtrl.isSaving ? null : _save,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
