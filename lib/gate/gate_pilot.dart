import 'dart:async';
import 'dart:io';

import 'config/dash_gate_config.dart';
import 'core/gate_models.dart';
import 'infra/cold_tap_reader.dart';
import 'infra/gate_dispatch.dart';
import 'infra/gate_store.dart';
import 'infra/link_probe.dart';
import 'infra/masked_agent.dart';
import 'infra/push_relay.dart';
import 'infra/trail_signal.dart';

/// The routing brain. [route] runs the attribution → config pipeline once and
/// returns where to send the user. The cold-start push tap is consumed FIRST,
/// before anything else, so a killed-app push never loses its destination.
class GatePilot {
  GatePilot({
    required this.store,
    required this.probe,
    required this.trail,
    required this.dispatch,
    required this.push,
    required this.agent,
    required this.runtimeEnabled,
  });

  final GateStore store;
  final LinkProbe probe;
  final TrailSignal trail;
  final GateDispatch dispatch;
  final PushRelay push;
  final MaskedAgent agent;
  final bool runtimeEnabled;

  bool get enabled => runtimeEnabled && DashGateConfig.grayCredentialsReady;

  Future<GateTarget>? _routeFuture;

  /// De-duplicates only *concurrent* calls (the warmup screen can build twice
  /// at startup). The cache clears on completion so a later Retry runs the whole
  /// pipeline again instead of replaying a stale OfflineTarget.
  Future<GateTarget> route({
    required void Function(double value) onProgress,
  }) =>
      _routeFuture ??=
          _route(onProgress: onProgress).whenComplete(() => _routeFuture = null);

  Future<GateTarget> _route({
    required void Function(double value) onProgress,
  }) async {
    if (!enabled) {
      onProgress(1);
      return const DinerTarget();
    }

    push.onTokenChanged = _refreshForToken;
    final coldTap = await ColdTapReader.consume();
    if (coldTap != null) {
      await store.saveRoute(ServeRoute.web);
      await store.consumePushUrl();
      unawaited(_backgroundDispatch());
      onProgress(1);
      return WebTarget(coldTap, coldLaunch: true);
    }

    onProgress(0.12);
    return switch (store.route) {
      ServeRoute.undecided => _firstDecision(onProgress),
      ServeRoute.web => _returningWeb(onProgress),
      ServeRoute.diner => _returningDiner(onProgress),
    };
  }

  Future<GateTarget> _firstDecision(void Function(double) progress) async {
    if (!await probe.hasInterface()) {
      return const OfflineTarget(returnToDiner: false);
    }
    progress(0.28);
    try {
      await push.boot();
    } catch (_) {}
    if (!await probe.canReachNetwork()) {
      return const OfflineTarget(returnToDiner: false);
    }
    progress(0.48);
    await trail.awaitSignals();
    progress(0.72);
    final reply = await _requestConfig();
    progress(1);
    if (reply.hasDestination) {
      await store.saveRoute(ServeRoute.web);
      return WebTarget(reply.url!);
    }
    await store.saveRoute(ServeRoute.diner);
    return const DinerTarget();
  }

  Future<GateTarget> _returningWeb(void Function(double) progress) async {
    if (!await probe.hasInterface()) {
      return const OfflineTarget(returnToDiner: false);
    }
    final pending = await store.consumePushUrl();
    if (pending != null && pending.isNotEmpty) {
      progress(1);
      return WebTarget(pending);
    }
    final cached = await store.savedUrl();
    if (cached != null && !store.cachedUrlExpired) {
      progress(1);
      return WebTarget(cached);
    }

    await Future.wait<void>(<Future<void>>[push.boot(), trail.start()]);
    if (!await probe.canReachNetwork()) {
      return const OfflineTarget(returnToDiner: false);
    }
    progress(0.62);
    await trail.awaitSignals(installTimeout: const Duration(seconds: 5));
    final reply = await _requestConfig();
    progress(1);
    if (reply.hasDestination) return WebTarget(reply.url!);
    if (cached != null) return WebTarget(cached);
    return const OfflineTarget(returnToDiner: false);
  }

  Future<GateTarget> _returningDiner(void Function(double) progress) async {
    if (!await probe.hasInterface()) {
      progress(1);
      return const DinerTarget();
    }
    await Future.wait<void>(<Future<void>>[push.boot(), trail.start()]);
    if (!await probe.canReachNetwork()) {
      progress(1);
      return const DinerTarget();
    }
    progress(0.55);
    await trail.awaitSignals();
    final reply = await _requestConfig();
    progress(1);
    if (!reply.hasDestination) return const DinerTarget();
    await store.saveRoute(ServeRoute.web);
    return WebTarget(reply.url!);
  }

  Future<GateReply> _requestConfig({String? token}) async {
    final body = await trail.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? push.token,
    );
    return dispatch.request(body);
  }

  Future<void> _backgroundDispatch() async {
    try {
      await Future.wait<void>(<Future<void>>[
        push.boot(),
        trail.awaitSignals(),
      ]);
      await _requestConfig();
    } catch (_) {}
  }

  Future<void> _refreshForToken(String token) async {
    try {
      await _requestConfig(token: token);
    } catch (_) {}
  }
}
