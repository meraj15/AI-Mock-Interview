import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? right;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: onBack != null
                  ? InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: Icon(FeatherIcons.arrowLeft, size: 20, color: colors.foreground),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.bold(18, color: colors.foreground),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.regular(11, color: colors.mutedForeground),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 44,
              alignment: Alignment.centerRight,
              child: right,
            ),

          ],
        ),
      ),
    );
  }
}
