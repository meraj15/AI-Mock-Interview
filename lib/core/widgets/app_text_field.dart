import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final String? value;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final bool multiline;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.value,
    this.controller,
    this.onChanged,
    this.placeholder,
    this.multiline = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines,
    this.minLines,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.input, width: 1),
      ),
      child: TextFormField(
        initialValue: controller == null ? value : null,
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: multiline ? TextInputType.multiline : keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLines: multiline ? (maxLines ?? 6) : 1,
        minLines: multiline ? (minLines ?? 5) : 1,
        style: AppTypography.regular(14, color: colors.foreground),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTypography.regular(14, color: colors.mutedForeground),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
