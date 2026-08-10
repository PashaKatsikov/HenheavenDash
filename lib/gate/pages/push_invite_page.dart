import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/dash_gate_config.dart';
import '../infra/gate_store.dart';
import '../infra/push_relay.dart';

/// Push opt-in promo shown once before the WebView on first entry into gray
/// mode. Self-contained artwork (gradient + badge) with the required copy and a
/// real, visible Accept + Skip pair.
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
          left: false,
          right: false,
          // LayoutBuilder + SingleChildScrollView means the invite always
          // laysgracefully — landscape iPhones are short vertically, so a
          // fixed Column occasionally overflowed by a few px. The scroll
          // wrapper absorbs that safely without visible scrollbars, while
          // the Row/Column switch actually uses the wide landscape canvas
          // instead of leaving big empty stripes on each side.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape =
                  constraints.maxWidth > constraints.maxHeight;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 36 : 28,
                  vertical: isLandscape ? 20 : 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - (isLandscape ? 40 : 48),
                  ),
                  child: Center(
                    child: isLandscape
                        ? _LandscapeLayout(
                            maxWidth: constraints.maxWidth,
                            working: _working,
                            onAccept: _accept,
                            onSkip: _skip,
                          )
                        : _PortraitLayout(
                            maxWidth: constraints.maxWidth,
                            working: _working,
                            onAccept: _accept,
                            onSkip: _skip,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Portrait: single centered column (badge → copy → buttons). ──────────────

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    required this.maxWidth,
    required this.working,
    required this.onAccept,
    required this.onSkip,
  });

  final double maxWidth;
  final bool working;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final buttonWidth = (maxWidth * 0.80).clamp(280.0, 440.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const _BellBadge(size: 128),
        const SizedBox(height: 26),
        const _InviteTitle(),
        const SizedBox(height: 10),
        const _InviteSubtitle(),
        const SizedBox(height: 32),
        _InviteButton(
          width: buttonWidth,
          height: 74,
          fontSize: 25,
          label: 'Accept',
          emphasized: true,
          busy: working,
          onTap: onAccept,
        ),
        const SizedBox(height: 16),
        _InviteButton(
          width: buttonWidth * 0.9,
          height: 64,
          fontSize: 22,
          label: 'Skip',
          emphasized: false,
          busy: false,
          onTap: onSkip,
        ),
      ],
    );
  }
}

// ── Landscape: two-column Row [copy] | [buttons]. ───────────────────────────
// Uses the wide landscape canvas properly instead of stacking everything in a
// tall column that gets squeezed vertically and grows the buttons much wider
// than they need to be.

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.maxWidth,
    required this.working,
    required this.onAccept,
    required this.onSkip,
  });

  final double maxWidth;
  final bool working;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    // Cap the overall content width so on wide iPads the invite doesn't
    // sprawl edge-to-edge — the column pair reads best around 780 pt.
    final contentWidth = maxWidth.clamp(0.0, 820.0);
    final buttonWidth = (contentWidth * 0.42).clamp(220.0, 320.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentWidth),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Left column: bell + copy, left-aligned so the eye lands on the
          // Accept button on the right of the reading flow.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  _BellBadge(size: 76),
                  SizedBox(height: 18),
                  _InviteTitle(align: TextAlign.left, fontSize: 20),
                  SizedBox(height: 8),
                  _InviteSubtitle(align: TextAlign.left),
                ],
              ),
            ),
          ),
          // Right column: buttons stacked vertically, aligned to the row's
          // vertical center.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _InviteButton(
                width: buttonWidth,
                height: 60,
                fontSize: 21,
                label: 'Accept',
                emphasized: true,
                busy: working,
                onTap: onAccept,
              ),
              const SizedBox(height: 12),
              _InviteButton(
                width: buttonWidth,
                height: 54,
                fontSize: 19,
                label: 'Skip',
                emphasized: false,
                busy: false,
                onTap: onSkip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable pieces (badge / title / subtitle / button) ─────────────────────

class _BellBadge extends StatelessWidget {
  const _BellBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _PushInvitePageState._straw.withValues(alpha: 0.16),
        border: Border.all(
          color: _PushInvitePageState._straw.withValues(alpha: 0.55),
          width: 3,
        ),
      ),
      child: Icon(
        Icons.notifications_active_rounded,
        size: size * 0.5,
        color: _PushInvitePageState._straw,
      ),
    );
  }
}

class _InviteTitle extends StatelessWidget {
  const _InviteTitle({this.align = TextAlign.center, this.fontSize = 23});

  final TextAlign align;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS',
      textAlign: align,
      style: TextStyle(
        color: _PushInvitePageState._cream,
        fontFamily: 'Baloo2',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        height: 1.18,
      ),
    );
  }
}

class _InviteSubtitle extends StatelessWidget {
  const _InviteSubtitle({this.align = TextAlign.center});

  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Stay tuned for special offers and rewards',
      textAlign: align,
      style: TextStyle(
        color: _PushInvitePageState._cream.withValues(alpha: 0.78),
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.3,
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
