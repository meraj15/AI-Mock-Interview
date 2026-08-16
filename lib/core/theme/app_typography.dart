import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Pre-configured weights
  static TextStyle regular(double size, {Color? color, double? height, double? letterSpacing}) =>
      inter(fontSize: size, fontWeight: FontWeight.w400, color: color, height: height, letterSpacing: letterSpacing);

  static TextStyle medium(double size, {Color? color, double? height, double? letterSpacing}) =>
      inter(fontSize: size, fontWeight: FontWeight.w500, color: color, height: height, letterSpacing: letterSpacing);

  static TextStyle semiBold(double size, {Color? color, double? height, double? letterSpacing}) =>
      inter(fontSize: size, fontWeight: FontWeight.w600, color: color, height: height, letterSpacing: letterSpacing);

  static TextStyle bold(double size, {Color? color, double? height, double? letterSpacing}) =>
      inter(fontSize: size, fontWeight: FontWeight.w700, color: color, height: height, letterSpacing: letterSpacing);
}
