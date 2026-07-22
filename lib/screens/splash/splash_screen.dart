import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/game_state.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_progress_bar.dart';
import '../menu/main_menu_screen.dart';

/// Splash screen whose progress bar tracks real work: Flutter engine warm
/// up, precaching the art that the main menu needs immediately, warming
/// the SFX cache, and initializing save/game state. It intentionally never
/// shows 100% until every one of those futures has actually resolved.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.gameState});

  final GameState gameState;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0;
  int _dotCount = 1;
  late final AnimationController _pulseController;

  static const _criticalAssets = <String>[
    'assets/images/chef/chef_idle.png',
    'assets/images/chef/chef_holding_pan.png',
    'assets/images/chef/chef_serving_plate.png',
    'assets/images/chef/chef_celebrating.png',
    'assets/images/backgrounds/kitchen_rustic.webp',
    'assets/images/backgrounds/farmyard_exterior.webp',
    'assets/images/ui/loading_landscape.webp',
    'assets/images/ui/loading_portrait.webp',
    'assets/images/ui/logo_henhaven_dash.webp',
    'assets/images/rewards/rw_coin_single.png',
    'assets/images/rewards/rw_coin_stack_a.png',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startDots();
    _load();
  }

  void _startDots() {
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() => _dotCount = _dotCount % 3 + 1);
      _startDots();
    });
  }

  Future<void> _setProgress(double value) async {
    if (!mounted) return;
    setState(() => _progress = value.clamp(0, 0.98));
    // Small yield so the bar animation is visible even on fast devices.
    await Future.delayed(const Duration(milliseconds: 80));
  }

  Future<void> _load() async {
    // Step 1: engine warm-up (already implicitly done by the time this
    // widget builds, but we still budget visible progress for it).
    await _setProgress(0.08);

    // Step 2: load persisted save + daily tasks + recipe unlocks.
    await widget.gameState.init();
    await _setProgress(0.30);

    // Step 3: warm the SFX cache.
    await AudioManager.instance.init();
    await _setProgress(0.55);

    // Step 4: precache the art needed the instant the main menu appears.
    final step = 0.40 / _criticalAssets.length;
    var acc = 0.55;
    for (final path in _criticalAssets) {
      if (!mounted) return;
      try {
        // ignore: use_build_context_synchronously
        await precacheImage(AssetImage(path), context);
      } catch (_) {
        // Missing/unreadable asset must never crash the app - skip it.
      }
      acc += step;
      await _setProgress(acc);
    }

    // Step 5: lock orientation to landscape for gameplay from here on.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;
    setState(() => _progress = 1.0);
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final bgAsset = orientation == Orientation.portrait
        ? 'assets/images/ui/loading_portrait.webp'
        : 'assets/images/ui/loading_landscape.webp';
    final dots = '.' * _dotCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bgAsset, fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final opacity = 0.8 + 0.2 * _pulseController.value;
                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          'Loading$dots',
                          style: AppTextStyles.loadingText,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GameProgressBar(value: _progress, height: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
