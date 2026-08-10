import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/dash_gate_config.dart';
import '../infra/gate_store.dart';
import '../infra/push_relay.dart';

/// Push opt-in promo shown once before the WebView on first entry into gray
/// mode. Self-contained artwork (gradient + badge) with the required copy and a
/// real, visible Accept + Skip pair.
///
/// Layout mirrors [OfflinePage]: a single centered column that just shrinks
/// its sizes / paddings in landscape rather than restructuring — matches the
/// look and feel of the sibling gray-flow screens.
class PushInvitePage extends StatefulWidget {
  const PushInvitePage({
    super.key,
    required this.store,
    required this.push,
    required this.nextBuilder,
    this.onTokenReady,
  });

  final GateStore store;
  final PushRelay push;
  final WidgetBuilder nextBuilder;
  final Future<void> Function(String token)? onTokenReady;

  @override
  State<PushInvitePage> createState() => _PushInvitePageState();
}

class _PushInvitePageState extends State<PushInvitePage> {
  bool _working = false;

  static const Color _dusk = Color(0xFF3D405B);
  static const Color _duskDeep = Color(0xFF262840);
  static const Color _cream = Color(0xFFF2EBD3);
  static const Color _straw = Color(0xFFF2CC8F);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Warmup gate locks portrait before routing here; re-enable landscape so
    // the invite rotates with the device (matches the WebView).
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _accept() async {
    if (_working) return;
    setState(() => _working = true);
    final granted = await widget.push.askPermission();
    final token = widget.push.token;
    if (granted && token != null && token.isNotEmpty) {
      await widget.onTokenReady?.call(token);
    }
    if (!granted) await _snooze();
    _continue();
  }

  Future<void> _skip() async {
    if (_working) return;
    setState(() => _working = true);
    await _snooze();
    _continue();
  }

  Future<void> _snooze() {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        DashGateConfig.pushSnoozeSeconds;
    return widget.store.snoozePushInvite(until);
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: widget.nextBuilder));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final landscape = media.orientation == Orientation.landscape;
    // Same tuning knobs as OfflinePage: main call-to-action width and badge
    // shrink in landscape, plus a couple of tighter vertical gaps.
    final acceptWidth = landscape
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
                      color: _straw.withValues(alpha: 0.16),
                      border: Border.all(
                        color: _straw.withValues(alpha: 0.55),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: badgeSize * 0.5,
                      color: _straw,
                    ),
                  ),
                  SizedBox(height: landscape ? 18 : 28),
                  const Text(
                    'ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS',
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
                    'Stay tuned for special offers and rewards',
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
                  _InviteButton(
                    width: acceptWidth,
                    height: landscape ? 66 : 72,
                    fontSize: landscape ? 22 : 25,
                    label: 'Accept',
                    emphasized: true,
                    busy: _working,
                    onTap: _accept,
                  ),
                  SizedBox(height: landscape ? 12 : 16),
                  _InviteButton(
                    width: acceptWidth * 0.9,
                    height: landscape ? 58 : 62,
                    fontSize: landscape ? 20 : 22,
                    label: 'Skip',
                    emphasized: false,
                    busy: false,
                    onTap: _skip,
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

class _InviteButton extends StatelessWidget {
  const _InviteButton({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.label,
    required this.emphasized,
    required this.busy,
    required this.onTap,
  });

  final double width;
  final double height;
  final double fontSize;
  final String label;
  final bool emphasized;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: emphasized
                ? const <Color>[Color(0xFFE07A5F), Color(0xFFAD4E37)]
                : const <Color>[Color(0xFF5A5E82), Color(0xFF3D405B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: emphasized
                ? const Color(0xFF7E2E22)
                : const Color(0xFF23263A),
            width: 3,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
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
                      dimension: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Color(0xFFF2EBD3),
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF2EBD3),
                        fontFamily: 'Baloo2',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
