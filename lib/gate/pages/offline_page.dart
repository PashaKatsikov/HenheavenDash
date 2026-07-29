import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infra/link_probe.dart';

/// No-internet screen. Retry re-runs the whole pipeline by pushing a fresh
/// [retryBuilder] widget using THIS page's own (mounted) context — never a
/// captured parent context, which would be defunct after pushReplacement.
///
/// Self-contained artwork (gradient + badge), so it never depends on the game's
/// widgets or on external image assets.
class OfflinePage extends StatefulWidget {
  const OfflinePage({
    super.key,
    required this.probe,
    required this.retryBuilder,
  });

  final LinkProbe probe;
  final WidgetBuilder retryBuilder;

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  bool _checking = false;
  bool _stillOffline = false;

  static const Color _dusk = Color(0xFF3D405B);
  static const Color _duskDeep = Color(0xFF262840);
  static const Color _cream = Color(0xFFF2EBD3);
  static const Color _terracotta = Color(0xFFE07A5F);
  static const Color _terracottaDark = Color(0xFFAD4E37);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Warmup gate locks portrait right before routing here; re-enable landscape
    // so the screen rotates with the device.
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _retry() async {
    if (_checking) return;
    HapticFeedback.lightImpact();
    setState(() {
      _checking = true;
      _stillOffline = false;
    });
    bool online = false;
    try {
      online = await widget.probe.canReachNetwork();
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    if (online) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: widget.retryBuilder),
      );
      return;
    }
    setState(() {
      _checking = false;
      _stillOffline = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final landscape = media.orientation == Orientation.landscape;
    final width = landscape
        ? (media.size.width * 0.40).clamp(300.0, 520.0)
        : (media.size.width * 0.66).clamp(260.0, 420.0);
    final badgeSize = landscape ? 96.0 : 132.0;

    return Scaffold(
      backgroundColor: _duskDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF4E5273), _dusk, _duskDeep],
            stops: <double>[0, 0.5, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: _cream.withValues(alpha: 0.35),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: badgeSize * 0.5,
                      color: _cream,
                    ),
                  ),
                  SizedBox(height: landscape ? 18 : 28),
                  const Text(
                    'NO INTERNET CONNECTION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _cream,
                      fontFamily: 'Baloo2',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Check your connection and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _cream.withValues(alpha: 0.78),
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: landscape ? 22 : 34),
                  _RetryButton(
                    width: width,
                    height: landscape ? 66 : 72,
                    busy: _checking,
                    onTap: _retry,
                    gradient: const LinearGradient(
                      colors: <Color>[_terracotta, _terracottaDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    child: _stillOffline
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              'No connection yet',
                              style: TextStyle(
                                color: _cream.withValues(alpha: 0.9),
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.width,
    required this.height,
    required this.busy,
    required this.onTap,
    required this.gradient,
  });

  final double width;
  final double height;
  final bool busy;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: gradient,
          border: Border.all(color: const Color(0xFF7E2E22), width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: busy ? null : onTap,
            child: Center(
              child: busy
                  ? const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: Color(0xFFF2EBD3),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.refresh_rounded,
                            color: Color(0xFFF2EBD3), size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: Color(0xFFF2EBD3),
                            fontFamily: 'Baloo2',
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
