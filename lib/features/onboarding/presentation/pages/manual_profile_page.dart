import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'profile_ready_page.dart';

class ManualProfilePage extends StatefulWidget {
  const ManualProfilePage({super.key});

  @override
  State<ManualProfilePage> createState() => _ManualProfilePageState();
}

class _ManualProfilePageState extends State<ManualProfilePage> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _skillsController = TextEditingController();

  String _selectedExperience = 'Fresher / Early Career';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _experienceOptions = [
    {'label': 'Fresher / Early Career', 'detail': '0–1 years', 'icon': FeatherIcons.sunrise},
    {'label': '1–2 years', 'detail': 'Hands-on practitioner', 'icon': FeatherIcons.trendingUp},
    {'label': '3–5 years', 'detail': 'Mid-level · Architecture focus', 'icon': FeatherIcons.award},
    {'label': '5–8+ years', 'detail': 'Senior / Lead · System design', 'icon': FeatherIcons.zap},
  ];

  void _submit() async {
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();

    if (name.isEmpty || role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name and target role.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Update auth controller with profile info
    context.read<AuthController>().updateProfile(
      name: name,
      targetRole: role,
      experienceYears: _selectedExperience,
    );

    // Small delay for UX polish
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileReadyPage(
            name: name,
            role: role,
            experience: _selectedExperience,
            skills: _skillsController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            isFromResume: false,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(FeatherIcons.arrowLeft,
                      size: 18, color: colors.foreground),
                ),
              ),

              const SizedBox(height: 28),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'MANUAL SETUP',
                  style: AppTypography.bold(10,
                      color: colors.primary, letterSpacing: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tell us about yourself',
                style: AppTypography.bold(30, color: colors.foreground),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in a few details so the AI can tailor your interview experience.',
                style: AppTypography.regular(13,
                    color: colors.mutedForeground, height: 1.5),
              ),

              const SizedBox(height: 32),

              // Name field
              Text('Your name',
                  style: AppTypography.semiBold(12, color: colors.foreground)),
              const SizedBox(height: 8),
              AppTextField(
                controller: _nameController,
                placeholder: 'e.g. Meraj Khan',
              ),

              const SizedBox(height: 18),

              // Role field
              Text('Target role',
                  style: AppTypography.semiBold(12, color: colors.foreground)),
              const SizedBox(height: 8),
              AppTextField(
                controller: _roleController,
                placeholder: 'e.g. Flutter Developer, Backend Engineer…',
              ),

              const SizedBox(height: 18),

              // Skills field
              Text('Key skills (comma-separated)',
                  style: AppTypography.semiBold(12, color: colors.foreground)),
              const SizedBox(height: 8),
              AppTextField(
                controller: _skillsController,
                placeholder: 'e.g. Flutter, Dart, REST APIs, Firebase…',
              ),

              const SizedBox(height: 24),

              // Experience level
              Text('Experience level',
                  style: AppTypography.semiBold(12, color: colors.foreground)),
              const SizedBox(height: 12),

              ..._experienceOptions.map((opt) {
                final label = opt['label'] as String;
                final detail = opt['detail'] as String;
                final icon = opt['icon'] as IconData;
                final isSelected = _selectedExperience == label;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedExperience = label),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.08)
                              : colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary.withValues(alpha: 0.5)
                                : colors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary.withValues(alpha: 0.12)
                                    : colors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon,
                                  size: 16,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.mutedForeground),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label,
                                      style: AppTypography.semiBold(13,
                                          color: colors.foreground)),
                                  Text(detail,
                                      style: AppTypography.regular(11,
                                          color: colors.mutedForeground)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(FeatherIcons.checkCircle,
                                  size: 18, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 28),

              AppButton(
                label: 'Continue',
                icon: FeatherIcons.arrowRight,
                isLoading: _isSubmitting,
                onPress: _submit,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
