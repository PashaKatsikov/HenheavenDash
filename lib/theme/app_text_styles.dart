import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale for Henhaven Dash.
///
/// Baloo2 (rounded, chunky, friendly) is used for headings/logo/HUD numbers
/// -- it reads like hand-lettering, matching the farm-kitchen sign in the
/// loading art. Poppins (clean, modern) is used for body copy and long-form
/// text (webviews, task descriptions) where legibility matters most.
class AppTextStyles {
  AppTextStyles._();

  static const String heading = 'Baloo2';
  static const String body = 'Poppins';

  static const List<Shadow> _readableShadow = [
    Shadow(color: Color(0xCC000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static TextStyle logo = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w800,
    fontSize: 48,
    color: AppColors.accent,
    shadows: _readableShadow,
  );

  static TextStyle h1 = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    color: AppColors.textOnDark,
    shadows: _readableShadow,
  );

  static TextStyle h2 = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    color: AppColors.textOnDark,
    shadows: _readableShadow,
  );

  static TextStyle h3 = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: AppColors.textOnLight,
  );

  static TextStyle button = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: Colors.white,
    letterSpacing: 0.4,
    shadows: _readableShadow,
  );

  static TextStyle bodyRegular = const TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.textOnLight,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.textOnLight,
  );

  static TextStyle caption = const TextStyle(
    fontFamily: body,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static TextStyle hudNumber = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: AppColors.textOnDark,
    shadows: _readableShadow,
  );

  static TextStyle loadingText = const TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: AppColors.textOnDark,
    shadows: _readableShadow,
  );
}
