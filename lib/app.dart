import 'package:flutter/material.dart';
import 'core/game_state.dart';
import 'core/game_state_scope.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class HenhavenDashApp extends StatefulWidget {
  const HenhavenDashApp({super.key});

  @override
  State<HenhavenDashApp> createState() => _HenhavenDashAppState();
}

class _HenhavenDashAppState extends State<HenhavenDashApp> {
  final GameState _gameState = GameState();

  @override
  Widget build(BuildContext context) {
    return GameStateScope(
      state: _gameState,
      child: MaterialApp(
        title: 'Henhaven Dash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) => _TabletScaler(child: child!),
        home: SplashScreen(gameState: _gameState),
      ),
    );
  }
}

/// Uniformly enlarges the *entire* UI on tablets. The whole game is laid out
/// for a phone-sized canvas; on a big iPad that same widget tree rendered at
/// the device's native logical resolution left everything looking like a tiny
/// cluster of controls swimming in empty space. Instead of hand-tuning sizes
/// on every screen, this wraps the app once at the root: on a tablet it tells
/// the app the logical canvas is smaller (so layouts size themselves as they
/// would on a roomy phone) and then scales that canvas up to fill the real
/// screen. Every screen, dialog and overlay grows together, in proportion,
/// with zero per-widget changes. Phones (shortestSide < 600) are untouched
/// and render pixel-identical to before.
class _TabletScaler extends StatelessWidget {
  const _TabletScaler({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final shortest = mq.size.shortestSide;
    if (shortest < 600) return child;

    // Normalise toward a ~430pt phone short-side, capped at 1.55 so the UI
    // grows tastefully (and gains a bit of breathing room) rather than being
    // a phone screen blown up 2.4x.
    final scale = (shortest / 430).clamp(1.0, 1.55).toDouble();
    final scaledSize = mq.size / scale;
    final inv = 1 / scale;

    return MediaQuery(
      // Report the smaller logical canvas + physically-correct (down-scaled)
      // safe-area insets, so SafeArea and any MediaQuery.size reads stay right
      // once everything is scaled back up.
      data: mq.copyWith(
        size: scaledSize,
        padding: mq.padding * inv,
        viewPadding: mq.viewPadding * inv,
        viewInsets: mq.viewInsets * inv,
      ),
      // Outer SizedBox pins the real device size regardless of whether the
      // incoming constraints are tight or loose, so the FittedBox always has
      // the full screen to fill. FittedBox uses a Transform under the hood
      // (transformHitTests: true), so taps map back correctly through the
      // scale-up.
      child: SizedBox(
        width: mq.size.width,
        height: mq.size.height,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: scaledSize.width,
            height: scaledSize.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
