import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class ThemeTextStyles {
  static Color _getDefaultColor({bool? isDark}) {
    return isDark == true ? Colors.white : Colors.black;
  }

  static TextStyle _base(
    double fontSize,
    FontWeight fontWeight, {
    Color? color,
    bool? isDark,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? _getDefaultColor(isDark: isDark),
    );
  }

  // headlines
  static TextStyle h1({Color? color, bool? isDark}) =>
      _base(28, FontWeight.w800, color: color, isDark: isDark);
  static TextStyle h2({Color? color, bool? isDark}) =>
      _base(24, FontWeight.w700, color: color, isDark: isDark);
  static TextStyle h3({Color? color, bool? isDark}) =>
      _base(20, FontWeight.w700, color: color, isDark: isDark);

  // body main font
  static TextStyle bodyLarge({Color? color, bool? isDark}) =>
      _base(18, FontWeight.w600, color: color, isDark: isDark);
  static TextStyle bodyMedium({Color? color, bool? isDark}) =>
      _base(16, FontWeight.w500, color: color, isDark: isDark);
  static TextStyle bodySmall({Color? color, bool? isDark}) =>
      _base(14, FontWeight.w400, color: color, isDark: isDark);

  // labels
  static TextStyle label({Color? color, bool? isDark}) =>
      _base(12, FontWeight.w600, color: color, isDark: isDark);
  static TextStyle caption({Color? color, bool? isDark}) =>
      _base(11, FontWeight.w400, color: color, isDark: isDark);

  static TextStyle custom({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    bool? isDark,
  }) => _base(fontSize, fontWeight, color: color, isDark: isDark);
}
