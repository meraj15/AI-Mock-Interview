import 'package:flutter/material.dart';

class AppColors {
  // Light Palette
  static const Color lightText = Color(0xFF10213A);
  static const Color lightTint = Color(0xFF4268E8);
  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color lightForeground = Color(0xFF10213A);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardForeground = Color(0xFF10213A);
  static const Color lightPrimary = Color(0xFF4268E8);
  static const Color lightPrimaryForeground = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFEEF1FA);
  static const Color lightSecondaryForeground = Color(0xFF273B65);
  static const Color lightMuted = Color(0xFFF0F2F8);
  static const Color lightMutedForeground = Color(0xFF71809B);
  static const Color lightAccent = Color(0xFFDDF7ED);
  static const Color lightAccentForeground = Color(0xFF147554);
  static const Color lightDestructive = Color(0xFFC94B61);
  static const Color lightDestructiveForeground = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E6F0);
  static const Color lightInput = Color(0xFFD7DDEB);
  static const Color lightInk = Color(0xFF10213A);
  static const Color lightNavy = Color(0xFF17294E);
  static const Color lightMint = Color(0xFFBCEFD9);
  static const Color lightCoral = Color(0xFFF29B84);
  static const Color lightYellow = Color(0xFFF5C968);
  static const Color lightViolet = Color(0xFF8E82E8);
  static const Color lightSuccess = Color(0xFF28A477);

  // Dark Palette
  static const Color darkText = Color(0xFFF6F8FF);
  static const Color darkTint = Color(0xFF8EA6FF);
  static const Color darkBackground = Color(0xFF0E1629);
  static const Color darkForeground = Color(0xFFF6F8FF);
  static const Color darkCard = Color(0xFF17223A);
  static const Color darkCardForeground = Color(0xFFF6F8FF);
  static const Color darkPrimary = Color(0xFF8EA6FF);
  static const Color darkPrimaryForeground = Color(0xFF101A31);
  static const Color darkSecondary = Color(0xFF202D49);
  static const Color darkSecondaryForeground = Color(0xFFDCE4FF);
  static const Color darkMuted = Color(0xFF1C2942);
  static const Color darkMutedForeground = Color(0xFF9AA9C5);
  static const Color darkAccent = Color(0xFF123D3A);
  static const Color darkAccentForeground = Color(0xFF9DE7C8);
  static const Color darkDestructive = Color(0xFFEF8799);
  static const Color darkDestructiveForeground = Color(0xFF2D1019);
  static const Color darkBorder = Color(0xFF2B3954);
  static const Color darkInput = Color(0xFF34425E);
  static const Color darkInk = Color(0xFFF6F8FF);
  static const Color darkNavy = Color(0xFF233862);
  static const Color darkMint = Color(0xFF63CFA4);
  static const Color darkCoral = Color(0xFFF6A08E);
  static const Color darkYellow = Color(0xFFE4B759);
  static const Color darkViolet = Color(0xFFAAA0FF);
  static const Color darkSuccess = Color(0xFF63D3AB);

  static const double radius = 18.0;
}

class AppColorScheme {
  final Color text;
  final Color tint;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ink;
  final Color navy;
  final Color mint;
  final Color coral;
  final Color yellow;
  final Color violet;
  final Color success;

  const AppColorScheme({
    required this.text,
    required this.tint,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ink,
    required this.navy,
    required this.mint,
    required this.coral,
    required this.yellow,
    required this.violet,
    required this.success,
  });

  static const AppColorScheme light = AppColorScheme(
    text: AppColors.lightText,
    tint: AppColors.lightTint,
    background: AppColors.lightBackground,
    foreground: AppColors.lightForeground,
    card: AppColors.lightCard,
    cardForeground: AppColors.lightCardForeground,
    primary: AppColors.lightPrimary,
    primaryForeground: AppColors.lightPrimaryForeground,
    secondary: AppColors.lightSecondary,
    secondaryForeground: AppColors.lightSecondaryForeground,
    muted: AppColors.lightMuted,
    mutedForeground: AppColors.lightMutedForeground,
    accent: AppColors.lightAccent,
    accentForeground: AppColors.lightAccentForeground,
    destructive: AppColors.lightDestructive,
    destructiveForeground: AppColors.lightDestructiveForeground,
    border: AppColors.lightBorder,
    input: AppColors.lightInput,
    ink: AppColors.lightInk,
    navy: AppColors.lightNavy,
    mint: AppColors.lightMint,
    coral: AppColors.lightCoral,
    yellow: AppColors.lightYellow,
    violet: AppColors.lightViolet,
    success: AppColors.lightSuccess,
  );

  static const AppColorScheme dark = AppColorScheme(
    text: AppColors.darkText,
    tint: AppColors.darkTint,
    background: AppColors.darkBackground,
    foreground: AppColors.darkForeground,
    card: AppColors.darkCard,
    cardForeground: AppColors.darkCardForeground,
    primary: AppColors.darkPrimary,
    primaryForeground: AppColors.darkPrimaryForeground,
    secondary: AppColors.darkSecondary,
    secondaryForeground: AppColors.darkSecondaryForeground,
    muted: AppColors.darkMuted,
    mutedForeground: AppColors.darkMutedForeground,
    accent: AppColors.darkAccent,
    accentForeground: AppColors.darkAccentForeground,
    destructive: AppColors.darkDestructive,
    destructiveForeground: AppColors.darkDestructiveForeground,
    border: AppColors.darkBorder,
    input: AppColors.darkInput,
    ink: AppColors.darkInk,
    navy: AppColors.darkNavy,
    mint: AppColors.darkMint,
    coral: AppColors.darkCoral,
    yellow: AppColors.darkYellow,
    violet: AppColors.darkViolet,
    success: AppColors.darkSuccess,
  );

  static AppColorScheme of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}
