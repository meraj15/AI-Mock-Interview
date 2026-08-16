import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _expController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final user = auth.user;
    _nameController = TextEditingController(text: user?.name ?? 'Meraj Khan');
    _roleController = TextEditingController(text: user?.targetRole ?? 'Flutter Developer');
    _expController = TextEditingController(text: user?.experienceYears ?? '1.2 years');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save() {
    final auth = context.read<AuthController>();
    auth.updateProfile(
      name: _nameController.text.trim(),
      targetRole: _roleController.text.trim(),
      experienceYears: _expController.text.trim(),
      bio: _bioController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Edit Profile',
            onBack: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 16),

          // Avatar Selector
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.navy,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                        : 'MK',
                    style: AppTypography.bold(26, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 2),
                    ),
                    child: Icon(FeatherIcons.camera, size: 14, color: colors.primaryForeground),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text('Full name', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nameController,
            placeholder: 'Your full name',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),
          Text('Target job role', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _roleController,
            placeholder: 'e.g. Flutter Developer, Senior Backend',
          ),

          const SizedBox(height: 14),
          Text('Years of experience', style: AppTypography.semiBold(12, color: colors.foreground)),
          const SizedBox(height: 8),
          AppTextField(
            controller: _expController,
            placeholder: 'e.g. 2.0 years',
          ),

          const SizedBox(height: 14),
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
            label: 'Save Changes',
            icon: FeatherIcons.check,
            onPress: _save,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
