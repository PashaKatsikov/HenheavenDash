import 'package:flutter/material.dart';

/// Design tokens for Henhaven Dash.
///
/// A hand-crafted farmstead palette - sage green, terracotta, cream, deep
/// "dusk" blue and warm straw yellow - chosen specifically to move away from
/// the generic toasted-orange/brown look of most mobile cooking games.
/// Deep blue does double duty as the structural/panel colour (instead of
/// plain brown), which is what gives the UI its own identity: shelves,
/// cards and dialogs read as "night barn wood" rather than a stock dark
/// glass overlay.
class AppColors {
  AppColors._();

  // Brand / primary (terracotta)
  static const Color primary = Color(0xFFE07A5F);
  static const Color primaryDark = Color(0xFFAD4E37);
  static const Color primaryLight = Color(0xFFF0A48C);

  // Secondary (barn wood - used for physical wood surfaces: counters, signs)
  static const Color secondary = Color(0xFF8B5E34);
  static const Color secondaryDark = Color(0xFF5A3B1E);
  static const Color secondaryLight = Color(0xFFC19366);

  // Accent (warm straw yellow - progress, coins, stars, highlights)
  static const Color accent = Color(0xFFF2CC8F);
  static const Color accentDark = Color(0xFFD9A94F);

  // Call to action / urgent (deep terracotta-red, not a stock "error red")
  static const Color cta = Color(0xFFBD4B39);
  static const Color ctaDark = Color(0xFF7E2E22);

  // Success (sage green)
  static const Color success = Color(0xFF9CAF88);
  static const Color successDark = Color(0xFF6B8256);

  // Warning
  static const Color warning = Color(0xFFE0A94D);

  // Neutrals / surfaces
  static const Color background = Color(0xFFF2EBD3);
  static const Color backgroundDeep = Color(0xFFE8DDBB);

  // Structural "dusk blue" - replaces plain dark brown for panels, dialogs,
  // shelves and the bottom counter, giving the whole UI a distinct identity.
  static const Color surfaceDark = Color(0xFF3D405B);
  static const Color surfaceDarkAlt = Color(0xFF4E5273);

  static const Color textOnLight = Color(0xFF3D405B);
  static const Color textOnDark = Color(0xFFF2EBD3);
  static const Color textMuted = Color(0xFF8A8DAE);

  // Panels: semi-transparent dusk-blue, used with blur for "glass" cards
  static Color panelGlass = surfaceDark.withValues(alpha: 0.72);
  static Color panelGlassLight = Colors.white.withValues(alpha: 0.14);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    colors: [Color(0xFFF0A48C), primary, primaryDark],
    stops: [0, 0.55, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient ctaButtonGradient = LinearGradient(
    colors: [Color(0xFFD97160), cta, ctaDark],
    stops: [0, 0.55, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successButtonGradient = LinearGradient(
    colors: [Color(0xFFBFCFAE), success, successDark],
    stops: [0, 0.55, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldProgressGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient skyBackdrop = LinearGradient(
    colors: [Color(0xFFEFE2BE), backgroundDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Wood-grain gradient for solid (non-glass) rustic panels: stations,
  // customer counters, menu tiles.
  static const LinearGradient woodPanelGradient = LinearGradient(
    colors: [Color(0xFF4E5273), surfaceDark, Color(0xFF32354A)],
    stops: [0, 0.5, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
