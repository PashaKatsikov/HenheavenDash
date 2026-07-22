import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.body,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.background,
        error: AppColors.cta,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: AppTextStyles.body,
        bodyColor: AppColors.textOnLight,
        displayColor: AppColors.textOnLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// A 300-500ms fade + slide transition, matching the design brief for
/// screen-to-screen navigation (Curves.easeInOut, ~380ms).
class FadeThroughSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
