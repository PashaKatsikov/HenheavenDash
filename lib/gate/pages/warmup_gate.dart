import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/game_state.dart';
import '../../screens/menu/main_menu_screen.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_progress_bar.dart';
import '../core/gate_models.dart';
import '../gate_pilot.dart';
import 'offline_page.dart';
import 'push_invite_page.dart';
import 'web_counter.dart';

/// Single boot/splash screen. It shows the game's existing loading artwork
/// while it (a) runs the gray attribution → config pipeline and (b) warms the
/// game up, then routes to the WebView (attributed), the game menu (organic) or
/// the offline screen. Keeping one splash avoids a double loading screen.
class WarmupGate extends StatefulWidget {
  const WarmupGate({super.key, required this.gameState, this.pilot});

  final GameState gameState;
  final GatePilot? pilot;

  @override
  State<WarmupGate> createState() => _WarmupGateState();
}

class _WarmupGateState extends State<WarmupGate>
    with SingleTickerProviderStateMixin {
  static const List<String> _criticalAssets = <String>[
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

  double _prepProgress = 0;
  double _gateProgress = 0;
  int _dotCount = 1;
  bool _started = false;
  bool _navigating = false;
  GateTarget? _target;
  bool _prepDone = false;
  late final DateTime _startTime;
  late final AnimationController _pulse;
  Timer? _hardDeadline;

  static const Duration _minSplash = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // Boot supports both orientations so the gray screens can rotate.
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _startDots();
    _hardDeadline = Timer(const Duration(seconds: 9), () {
      if (mounted && !_navigating) {
        _prepDone = true;
        _target ??= const DinerTarget();
        _maybeNavigate();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _beginWork();
    }
  }

  void _startDots() {
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() => _dotCount = _dotCount % 3 + 1);
      _startDots();
    });
  }

  Future<void> _beginWork() async {
    await Future.wait<void>(<Future<void>>[_prepareGame(), _resolveTarget()]);
    _maybeNavigate();
  }

  Future<void> _prepareGame() async {
    try {
      await widget.gameState.init();
      _bumpPrep(0.4);
      await AudioManager.instance.init();
      _bumpPrep(0.55);
      final step = 0.45 / _criticalAssets.length;
      for (final path in _criticalAssets) {
        if (!mounted) break;
        try {
          await precacheImage(AssetImage(path), context);
        } catch (_) {}
        _bumpPrep(_prepProgress + step);
      }
    } catch (_) {}
    _prepDone = true;
    _bumpPrep(1);
  }

  void _bumpPrep(double value) {
    if (!mounted) return;
    setState(() => _prepProgress = value.clamp(0.0, 1.0));
  }

  Future<void> _resolveTarget() async {
    final pilot = widget.pilot;
    if (pilot == null) {
      _target = const DinerTarget();
      _gateProgress = 1;
      return;
    }
    try {
      _target = await pilot.route(
        onProgress: (value) {
          if (mounted) setState(() => _gateProgress = value.clamp(0.0, 1.0));
        },
      );
    } catch (_) {
      _target = const DinerTarget();
    }
    if (mounted) setState(() => _gateProgress = 1);
  }

  double get _progress =>
      (_prepProgress * 0.45 + _gateProgress * 0.55).clamp(0.0, 1.0);

  Future<void> _maybeNavigate() async {
    if (_navigating || _target == null || !_prepDone) return;
    final elapsed = DateTime.now().difference(_startTime);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }
    if (!mounted || _navigating) return;
    _navigating = true;
    _hardDeadline?.cancel();
    await _openTarget(_target!);
  }

  Future<void> _openTarget(GateTarget target) async {
    final pilot = widget.pilot;

    if (target is DinerTarget || pilot == null) {
      // Organic / gate disabled → the game. Lock landscape for gameplay.
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, _, _) => const MainMenuScreen(),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
        ),
      );
      return;
    }

    if (target is OfflineTarget) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OfflinePage(
            probe: pilot.probe,
            retryBuilder: (_) =>
                WarmupGate(gameState: widget.gameState, pilot: pilot),
          ),
        ),
      );
      return;
    }

    if (target is WebTarget) {
      Widget counterBuilder(BuildContext _) => WebCounter(
        url: target.url,
        coldLaunch: target.coldLaunch,
        store: pilot.store,
        probe: pilot.probe,
        push: pilot.push,
        agent: pilot.agent,
      );

      void openCounter() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: counterBuilder),
        );
      }

      if (pilot.store.shouldShowPushInvite &&
          await pilot.push.canOfferPermission()) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PushInvitePage(
              store: pilot.store,
              push: pilot.push,
              nextBuilder: counterBuilder,
            ),
          ),
        );
      } else {
        openCounter();
      }
    }
  }

  @override
  void dispose() {
    _hardDeadline?.cancel();
    _pulse.dispose();
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
        children: <Widget>[
          ClipRect(
            child: Transform.scale(
              scale: 1.18,
              child: Image.asset(bgAsset, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return Opacity(
                        opacity: 0.8 + 0.2 * _pulse.value,
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
